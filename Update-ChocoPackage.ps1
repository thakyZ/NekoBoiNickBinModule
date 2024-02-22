Param(
  # Provides the package name.
  [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, HelpMessage = "Provide the package name.")]
  [Alias("P")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $Packages,
  # Automatically confirm package upgrade.
  [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Automatically confirm package upgrade.")]
  [Alias("Y", "Yes")]
  [switch]
  $Confirm = $False,
  # Automatically confirm package upgrade.
  [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Automatically confirm package upgrade.")]
  [Alias("S")]
  [switch]
  $Safe = $False,
  # Specifies packages to exclude when parameter Packages is set to all.
  [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Specify packages to exclude when parameter Packages is set to all.")]
  [string[]]
  $Exclude = @()
)

Class PackageUpgradeInfo {
  [string]$PackageName = $Null;
  [string]$CurrentVersion = $Null;
  [string]$LatestVersion = $Null;
  [boolean]$Pinned = $False;
  #[boolean]$Silent = $False;

  PackageUpgradeInfo([string]$Stats) {
    #Write-Debug -Message "`"$($Stats)`""
    $PackageStats = $($Stats.Split("|"));
    $this.PackageName = $PackageStats[0];
    $this.CurrentVersion = $PackageStats[1];
    $this.LatestVersion = $PackageStats[2];
    $this.Pinned = [boolean]::Parse($PackageStats[3]);
    #$this.Silent = [boolean]::Parse($PackageStats[4]);
  }
}

$Choco = (Get-Command -Name "choco" -ErrorAction Stop);
$ExportBackup = (Join-Path -Path $env:Temp -ChildPath "choco-export.config");
Export-ChocoConfig -Path $ExportBackup -SaveArguments

Function Get-LocalOutdatedPackageInfo {
  try {
    $Output = (& $Choco.Source "outdated" "--limit-output" "--confirm");
    Return ($Output | Where-Object { $Exclude -notcontains $_.Split("|")[0]});
  } catch {
    Write-Error -Message "Failed to run `"choco outdated --limit-output --confirm`"." -Exception $_.Exception;
    Write-Host -ForegroundColor Red -Object "$($_.ScriptStackTrace)"
    Exit 1;
  }
}

Function Invoke-BypassPackageInstallDir {
  Param(
    [PackageUpgradeInfo]
    $PackageInfo,
    [string]
    $Arguments,
    [string]
    $NbnArguments,
    [bool]
    $Silent = $False
  )

  $WebRequest = $Null;

  $InstallFile = (Join-Path -Path "C:\" -ChildPath "ProgramData" -AdditionalChildPath @("chocolatey", "lib", "$($PackageInfo.PackageName)", "tools", "chocolateyinstall.ps1"));

  Try {
    $Null = New-Item -ItemType Directory -Path (Join-Path -Path "C:\" -ChildPath "ProgramData" -AdditionalChildPath @("chocolatey", "lib", "$($PackageInfo.PackageName)")) -ErrorAction SilentlyContinue;
    $Null = New-Item -ItemType Directory -Path (Join-Path -Path "C:\" -ChildPath "ProgramData" -AdditionalChildPath @("chocolatey", "lib", "$($PackageInfo.PackageName)", "tools")) -ErrorAction SilentlyContinue;

    While ($Null -eq $WebRequest -or $WebRequest.StatusCode -ne 200 -or $WebRequest.StatusCode -ne -1) {
      $WebRequest = (Invoke-WebRequest -Uri "https://github.com/Jarcho/chocolatey-packages/raw/master/$($PackageInfo.PackageName)/tools/chocolateyinstall.ps1" -OutFile $InstallFile -ErrorAction SilentlyContinue);

      If ($WebRequest.StatusCode -ne 200) {
        Write-Warning -Message "Failed to fetch `"chocolateyinstall.ps1`" from `"https://github.com/Jarcho/chocolatey-packages/raw/master/$($PackageInfo.PackageName)/tools/chocolateyinstall.ps1`"";
        $ManualInput = (Read-Host -Prompt "Custom URL");

        If ($ManualInput -match "https:\/\/[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?\/tools\/chocolateyinstall\.ps1") {
          $WebRequest = (Invoke-WebRequest -Uri $ManualInput -OutFile $InstallFile -ErrorAction SilentlyContinue);
        } ElseIf ($ManualInput -eq "quit" -or $ManualInput -eq "exit" -or $ManualInput -eq "q") {
          $WebRequest = @{ StatusCode = -1 };
        } Else {
          $WebRequest = $Null;
        }
      }
    }

    If ($WebRequest.StatusCode -eq -1) {
      Return $False;
    }

    $TempText = (Get-Content -Path $InstallFile);
    $TempText = ($TempText -Replace "^\`$toolsDir = `"\`$\(Split-Path -Parent (.*)\)`"`$", "`$toolsDir = `"$($NbnArguments.InstallDir)`";`nWrite-Output `$1 | Out-Host;");
    $TempText = ($TempText -Replace " = \`$toolsDir", " = `"$($NbnArguments.InstallDir)`"");
    $TempText | Out-File -FilePath $InstallFile;

    If ($DebugPreferences -ne "SilentlyContinue") {
      Write-Debug -Message "Contents patched `"chocolateyinstall.ps1`": ";
      Write-Debug -Message (Get-Content -Path $InstallFile);
      $Okay = (Read-Host -Prompt "Is this okay? [Y/n]");
      If ($Okay.ToLower() -eq "n") {
        Write-Host -Object "Quitting..."
        Return $False;
      }
    }
  } Catch {
    If ($Null -eq $WebRequest) {
      Write-Error -Exception $_.Exception -Message "Failed to create package directory or something else`n$($_.Exception.Message)";
      Return $False;
    }

    Write-Error -Exception $_.Exception -Message "Failed to invoke web request (Status Code: $($WebRequest.StatusCode))`n$($_.Exception.Message)";
    Return $False;
  }
}

Function Invoke-UpdatePackage {
  Param(
    [PackageUpgradeInfo]
    $PackageInfo,
    [string]
    $Arguments,
    [bool]
    $Silent = $False
  )
  Try {
    $_Arguments = @("upgrade", "$($PackageInfo.PackageName)", "--version $($PackageInfo.LatestVersion)", "$($Arguments)")
    If ($PackageInfo.Pinned -and $Package -ne "all") {
      & $Choco.Source "pin" "remove" "-n $($PackageInfo.PackageName)";
      $_Arguments += "--pin";
    } ElseIf ($PackageInfo.Pinned -and $Package -eq "all") {
      Write-Host "Package, $($PackageInfo.PackageName) is pinned to version $($PackageInfo.CurrentVersion) and you tried to do a broad upgrade."
      Return;
    }
    If ($Confirm) {
      $_Arguments += "--confirm";
    }
    #$Silent = $True;
    If ($Silent -eq $True) {
      $_Arguments += "--not-silent";
    }
    $Confirmed = $False;
    If ($Safe) {
      Write-Host -Object "We will run this command:";
      Write-Host -Object "& $($Choco.Source) `"upgrade`" `"$($PackageInfo.PackageName)`" $([string]::Join(' ', [System.Linq.Enumerable]::Select([string[]]$_Arguments, [Func[string,string]]{Param([string]$x)Return ("`""$x"`"")})))";
      $Read = (Read-Host -Prompt "Use this command? [Y/n]");
      Write-Host -Object "";
      If ($Read -match "Y") {
        Write-Host -Object "Confirmed";
        $Confirmed = $True;
      } Else {
        Write-Host -Object "Denied";
      }
    } Else {
      $Confirmed = $True;
    }

    If ($Confirmed) {
      $Process = (Start-Process -NoNewWindow -FilePath $Choco.Source -ArgumentList $_Arguments -PassThru -ErrorAction SilentlyContinue);
      $Process.WaitForExit();
      $ExitCode = $LASTEXITCODE;
      If ($Process.HasExited -eq $True) {
        Write-Debug -Message "`$Process exited with code; $($ExitCode).";
        Write-Host "Invoke-UpdatePackage: $($ExitCode)";
        Return $ExitCode;
      } Else {
        Write-Host "Invoke-UpdatePackage: `"Process has not exited properly and reached the end.`"";
        Throw "Process has not exited properly and reached the end.";
      }
    }
  } Catch {
    Write-Error -Message "Failed to run Update Invoke-UpdatePackage -PackageInfo:[$($PackageInfo)] -Arguments:`"$($Arguments)`" -Silent:`$$($Silent).`nOn Package, `"$($PackageInfo.PackageName)`"" -Exception $_.Exception;
    #Write-Host -ForegroundColor Red -Object ("**$($_.ScriptStackTrace)**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString;
    #(([string]::Join("   `n", [System.Linq.Enumerable]::Select($Test.Split("`n"), [Func[string,string]]{Param($x)Return "**$($x.Replace("<","ESC[0;60").Replace(">","ESC[0;62"))**"}))) | ConvertFrom-MarkDown -AsVT100EncodedString).VT100EncodedString
    Write-Host -ForegroundColor Red -Object "$($_.Exception.Message)";
    Write-Host -ForegroundColor Red -Object "$($_.ScriptStackTrace)";
    Exit 1;
  }
}

Function ConvertFrom-Xml {
  <#
.SYNOPSIS
    Converts XML object to PSObject representation for further ConvertTo-Json transformation
.EXAMPLE
    # JSON->XML
    $xml = ConvertTo-Xml (get-content 1.json | ConvertFrom-Json) -Depth 4 -NoTypeInformation -as String
.EXAMPLE
    # XML->JSON
    ConvertFrom-Xml ([xml]($xml)).Objects.Object | ConvertTo-Json
#>
  Param(
    [System.Xml.XmlElement]
    $Object
  )

  If (($Null -ne $Object) -and ($Null -ne $Object.Property)) {
    $PSObject = New-Object PSObject

    ForEach ($Property in @($Object.Property)) {
      If ($Property.Property.Name -like 'Property') {
        $PSObject | Add-Member NoteProperty $Property.Name ($Property.Property | ForEach-Object { ConvertFrom-Xml $_ })
      } Else {
        If ($Null -ne $Property.'#text') {
          $PSObject | Add-Member NoteProperty $Property.Name $Property.'#text'
        } Else {
          If ($Null -ne $Property.Name) {
            $PSObject | Add-Member NoteProperty $Property.Name (ConvertFrom-Xml $Property)
          }
        }
      }
    }

    Write-Output -InputObject $PSObject
  }
}

Function ConvertFrom-Xml {
  Param(
    [string]
    $InputObject
  )

  ConvertFrom-Xml -Object [System.Xml.XmlElement]::Parse($InputObject)
}

Function Invoke-HandlePackageUpgrade() {
  Param(
    [PackageUpgradeInfo]
    $PackageInfo
  )

  $Xml = (Select-Xml -LiteralPath (Join-Path -Path $env:Temp -ChildPath "choco-export.config") -XPath "/packages/package[@id=`"$($PackageInfo.PackageName)`"]");
  $Testing = ($Xml | Where-Object { $Null -ne $_.Node.arguments })
  $Arguments = "";
  $NbnArguments = "";
  $Silent = $False;

  If ($Null -ne $Testing.Node.arguments) {
    $Arguments = $Testing.Node.arguments;
  }

  If ($Null -ne $Testing.Node.silent) {
    $Silent = [bool]::Parse($Testing.Node.silent);
    Write-Host -Object "`$Silent = `"$($Silent)`"";
    Write-Host -Object "typeof(`$Silent) = `"$($Silent.GetType())`"";
    If ($Silent.GetType() -ne [bool]) {
      Write-Error -Message "The type of variable `$Silent is not type Boolean. It is instead [$($Silent.GetType())]";
      Exit 1;
    }
  }

  If ($Null -ne $Testing.Node.nbnpatch) {
    $NbnArguments = $Testing.Node.arguments;
  }

  $PackageUpdateExitCode = -1;

  If (-not ([string]::IsNullOrEmpty($NbnArguments))) {
    Write-Host "Performing custom upgrade with the following arguments:";
    Write-Host -ForegroundColor Blue "$($Arguments)";
    Write-Host "And NBN Arguments:";
    Write-Host -ForegroundColor Blue "$($NbnArguments)";
    Write-Host "";
    $PackageUpdateExitCode = (Invoke-UpdatePackage -PackageInfo $PackageInfo -Arguments $Arguments -Silent $Silent);
    Write-Host "";
    Write-Debug "Invoke-HandlePackageUpgrade: $($PackageUpdateExitCode)";
    Write-Debug "";
  } Else {
    Write-Host "Upgrading with the following arguments:";
    Write-Host -ForegroundColor Blue "$($Arguments)";
    Write-Host "";
    $PackageUpdateExitCode = (Invoke-UpdatePackage -PackageInfo $PackageInfo -Arguments $Arguments -Silent $Silent);
    Write-Host "";
    Write-Debug "Invoke-HandlePackageUpgrade: $($PackageUpdateExitCode)";
    Write-Debug "";
  }
  Return $PackageUpdateExitCode;
}

Function Update-Package() {
  Param(
    [string[]]
    $Packages
  )

  If ($Packages.Length -eq 1 -and $Packages.ToLower() -eq "all") {
    $LocalOutdatedPackageInfo = Get-LocalOutdatedPackageInfo;
    Write-Host -Object "Upgrading the following packages:";
    For ($Index = 0; $Index -lt $LocalOutdatedPackageInfo.Count; $Index++) {
      $Item = $LocalOutdatedPackageInfo[$Index].Split("|")[0];

      If ($Index -gt 0) {
        Write-Host -ForegroundColor Green -Object ";" -NoNewline;
      }
      Write-Host -ForegroundColor Green -Object "$($Item)" -NoNewline;
    }
    Write-Host -ForegroundColor Green -Object "";
    Get-LocalOutdatedPackageInfo | ForEach-Object {
      $PackageUpgradeInfo = (New-Object -TypeName PackageUpgradeInfo -ArgumentList @($_));
      $PackageUpdateExitCode = (Invoke-HandlePackageUpgrade -PackageInfo $PackageUpgradeInfo);
      If ($PackageUpdateExitCode -ne 0) {
        Write-Error -Message "Failed to update package $($PackageUpgradeInfo.PackageName) ($($PackageUpdateExitCode)). Ending..."
        Exit 1;
      }
    }
  } Else {
    $LocalOutdatedPackageInfo = @();
    ForEach ($Package in $Packages) {
      $LocalOutdatedPackageInfo += (Get-LocalOutdatedPackageInfo | Where-Object { $_.Split("|")[0] -eq $Package.ToLower() });
    }
    Write-Host -Object "Upgrading the following packages:";
    For ($Index = 0; $Index -lt $LocalOutdatedPackageInfo.Count; $Index++) {
      $Item = $LocalOutdatedPackageInfo[$Index].Split("|")[0];

      If ($Index -gt 0) {
        Write-Host -ForegroundColor Green -Object ";" -NoNewline;
      }
      Write-Host -ForegroundColor Green -Object "$($Item)" -NoNewline;
    }
    Write-Host -ForegroundColor Green -Object "";
    ForEach ($Package in $LocalOutdatedPackageInfo) {
      $PackageUpgradeInfo = (New-Object -TypeName PackageUpgradeInfo -ArgumentList $Package);
      $PackageUpdateExitCode = (Invoke-HandlePackageUpgrade -PackageInfo $PackageUpgradeInfo);
      If ($PackageUpdateExitCode -ne 0) {
        Write-Error -Message "Failed to update package $($PackageUpgradeInfo.PackageName) ($($PackageUpdateExitCode)). Ending..."
        Exit 1;
      }
    }
  }
}

# choco export -o="choco-packages.config" --include-install-args
Update-Package -Package $Packages

Remove-Item $ExportBackup
