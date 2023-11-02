Param(
    # The file to output the Chocolatey config to.
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, HelpMessage = "The file to output the Chocolatey config to.")]
    [ValidateNotNullOrEmpty()]
    [Alias("Path", "PSPath", "Out", "o")]
    [string]
    $OutputFile,
    # Saves the versions of the packages install to the config file.
    [Parameter(Mandatory = $False, Position = 1, ValueFromPipelineByPropertyName = $True, HelpMessage = "Save the versions of the packages install to the config file.")]
    [Alias("IncludeVersions", "-includeversion", "-includeversions", "-include-version", "-include-versions")]
    [switch]
    $IncludeVersion = $False,
    # Saves the arguments of the packages install to the config file.
    [Parameter(Mandatory = $False, Position = 2, ValueFromPipelineByPropertyName = $True, HelpMessage = "Save the arguments of the packages install to the config file.")]
    [Alias("-savearguments", "-saveargs", "-save-arguments", "-save-args")]
    [switch]
    $SaveArguments = $False,
    # Disables omitting the cache location.
    [Parameter(Mandatory = $False, Position = 3, ValueFromPipelineByPropertyName = $True, HelpMessage = "Disables omitting the cache location.")]
    [Alias("-includecachelocation", "-include-cache-location", "-include-cachelocation")]
    [switch]
    $IncludeCacheLocation = $False
)

Add-Type -AssemblyName System.Security
$EntropyBytes = [System.Text.UTF8Encoding]::UTF8.GetBytes("Chocolatey")

$ForcedNonSilentPackages = @(
    "sandboxie-plus.install",
    "sandboxie-plus"
)

Function Unprotect-Arguments {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $Data
    )
    $EncryptedByteArray = [System.Convert]::FromBase64String($Data)
    $DecryptedByteArray = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $EncryptedByteArray,
        $EntropyBytes,
        [System.Security.Cryptography.DataProtectionScope]::LocalMachine
    )
    Return [System.Text.UTF8Encoding]::UTF8.GetString($DecryptedByteArray)
}

Function Remove-CacheLocation {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        [Alias("Args", "Arg", "Argument")]
        $Arguments
    )
    Return ($Arguments -Replace " *--cache-location=`"'$($env:Temp -Replace "\\", "`\`\")\\chocolatey\\?'`" *");
}

Function Remove-NbnPackageParameters {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        [Alias("Args", "Arg", "Argument")]
        $Arguments
    )
    $Output = ($Arguments -Replace "NBN_[A-Z0-9]+(?:=(?:\```")?[a-zA-Z0-9\\/:]*(?:\```")?)?");
    Return $Output;
}

Function Remove-NonNbnPackageParameters {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        [Alias("Args", "Arg", "Argument")]
        $Arguments
    )
    $Output = ($Arguments -Match "(NBN_[A-Z0-9]+(?:=(?:\```")?[a-zA-Z0-9\\/:]*(?:\```")?)?)");
    If (-not ([string]::IsNullOrEmpty($Matches[1]))) {
        Return $Matches[0].Replace("```"", "`"");
    }
    Return "";
}

Function Read-Arguments {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageName
    )
    $Directory = (Get-ChildItem -LiteralPath (Join-Path -Path $env:ChocolateyInstall -ChildPath ".chocolatey") -Directory -Filter $RegExp) | Where-Object {
        $_.Name -match ($PackageName + "\.[\d\.]+")
    } | Select-Object -Last 1;
    If (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        Return;
    }
    $ArgsFile = (Join-Path -Path $Directory.FullName -ChildPath ".arguments");
    If (Test-Path -LiteralPath $ArgsFile -PathType Leaf) {
        $ArgsData = (Get-Content -LiteralPath $ArgsFile);
        #Implicitly return result from Unprotect-Arguments
        $UnprotectedArgs = (Unprotect-Arguments -Data $ArgsData);

        If (-not $IncludeCacheLocation) {
            $UnprotectedArgs = (Remove-CacheLocation -Arguments $UnprotectedArgs);
        }

        If (-not [string]::IsNullOrEmpty($UnprotectedArgs)) {
            $UnprotectedArgs = (Remove-NbnPackageParameters -Arguments $UnprotectedArgs);
        }
        Return ($UnprotectedArgs -Replace "^ *", "");
    }
}

Function Read-PatchArguments {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageName
    )
    $Directory = Get-ChildItem -LiteralPath (Join-Path -Path $env:ChocolateyInstall -ChildPath ".chocolatey") -Directory -Filter "$PackageName*" |  Where-Object {
        $_.Name -match ("$PackageName" + "\.[\d\.]+")
    } | Select-Object -Last 1;
    If (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        Return;
    }
    $ArgsFile = (Join-Path -Path $Directory.FullName -ChildPath ".arguments");
    If (Test-Path -LiteralPath $ArgsFile -PathType Leaf) {
        $ArgsData = (Get-Content -LiteralPath $ArgsFile);
        #Implicitly return result from Unprotect-Arguments
        $UnprotectedArgs = (Unprotect-Arguments -Data $ArgsData);

        If (-not [string]::IsNullOrEmpty($UnprotectedArgs)) {
            $UnprotectedArgs = (Remove-NonNbnPackageParameters -Arguments $UnprotectedArgs);
        }
        Return ($UnprotectedArgs -Replace "^ *", "");
    }
}

Function Get-LocalPackageInfo {
    try {
        Return (& (Get-Command -Name "choco").Source "list" "--limit-output" "--confirm");
    } catch {
        Write-Error -Message "Failed to run `"choco list --limit-output --confirm`"." -Exception $_.Exception;
        Exit 1;
    }
}

Function Invoke-EscapeInvalidChars() {
    Param(
        [string]
        $InputObject
    )

    $Escaped = [System.Security.SecurityElement]::Escape($InputObject);
    # $Escaped = ($Escaped -replace "\", "\\");
    Return $Escaped;
}

Function Get-PackagesConfigBody($SaveArguments = $False) {
    $LocalPackageInfo = Get-LocalPackageInfo;
    $LocalPackageInfo | ForEach-Object {
        Try {
            $PackageStats = $($_.Split("|"));
            $PackageName = $PackageStats[0];
            $PackageVersion = $PackageStats[1];
            $Line = [string]::Join("", @("   <package id=`"", $PackageName, "`" "))
            If ($IncludeVersion) {
                $Line = [string]::Join("", @($Line, "version=`"", $PackageVersion, "`" "));
            }

            If ($SaveArguments -and $PackageName -ne "chocolatey") {
                $Arguments = Invoke-EscapeInvalidChars -InputObject $(Read-Arguments -PackageName $PackageName);
                $NbnPatchArguments = Invoke-EscapeInvalidChars -InputObject $(Read-PatchArguments -PackageName $PackageName);

                If (-not [string]::IsNullOrEmpty($Arguments)) {
                    $Line = [string]::Join("", @($Line, "arguments=`"", $Arguments, "`" "))
                }

                If ($ForcedNonSilentPackages -contains $PackageName) {
                    $Line = [string]::Join("", @($Line, "silent=`"false`" "));
                }

                If (-not [string]::IsNullOrEmpty($NbnPatchArguments)) {
                    $Line = [string]::Join("", @($Line, "nbnpatch=`"", $NbnPatchArguments, "`" "))
                }
            }

            $Line = [string]::Join("", @($Line, "/>"))
            Write-Output -InputObject $Line
        } Catch {
            Throw;
        }
    }
}

Function Write-PackagesConfig($OutputFile, $SaveArguments = $false) {
    $header = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n<packages>"
    $footer = "</packages>"
    $body = Get-PackagesConfigBody -SaveArguments $SaveArguments
    Write-Output $header $body $footer | Out-File $OutputFile -Encoding ASCII
}

# choco export -o="choco-packages.config" --include-install-args
Write-PackagesConfig -OutputFile $OutputFile -SaveArguments $SaveArguments
