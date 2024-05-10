Param(
  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $False,
             Position = 1,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Literal path to one or more locations.")]
  [Alias("PSPath", "Path")]
  [ValidateNotNullOrWhiteSpace()]
  [System.String]
  $LiteralPath = $PWD,
  # Specifies the type of icon to remove from the desktop.ini file.
  [Parameter(Mandatory = $True,
    Position = 0,
    HelpMessage = "The type of icon to remove from the desktop.ini file.")]
  [ValidateSet("Mega")]
  [ValidateNotNullOrWhiteSpace()]
  [System.String]
  $Type,
  # Specifies a switch to recurse through the provided path.
  [Parameter(Mandatory = $False,
    HelpMessage = "A switch to recurse through the provided path.")]
  [Switch]
  $Recurse = $False,
  # Specifies a depth of which to recurse through the provided path (Defaults to 0).
  [Parameter(Mandatory = $False,
    HelpMessage = "A depth of which to recurse through the provided path (Defaults to 0).")]
  [System.Int32]
  $Depth = 0,
  # Specifies a switch to specify elevating this script before running.
  [Parameter(Mandatory = $False,
    HelpMessage = "A switch to specify elevating this script before running.")]
  [Switch]
  $AsAdmin = $False
)

Begin {
  $CurrentLocation = (Get-Item -LiteralPath $LiteralPath);
  $CurrentScript = $MyInvocation.MyCommand.Path;

  $PowerShellProcess = (Get-Command ((Get-Process -PID $PID).CommandLine -replace '^"|"$', '') -ErrorAction Stop);
  $ExitCode = 0;

  If ($AsAdmin) {
    $ElevateScript = $CurrentScript;
    $ArgumentList = @("-Command", "`"$($CurrentScript)`" -LiteralPath $($LiteralPath) -Type $($Type) -Recurse:`$$($Recurse) -Depth $($Depth)");
    Start-Process -FilePath $PowerShellProcess -ArgumentList $ArgumentList -Verb RunAs -Wait;
  }
} Process {
  Function Invoke-WhereObject {
    [CmdletBinding()]
    Param(
      # Specifies the item to check against the custom Where-Object block.
      [Parameter(Mandatory = $True,
        HelpMessage = "The item to check against the custom Where-Object block.")]
      [ValidateNotNull()]
      [System.IO.FileSystemInfo]
      $Item
    )

    $HiddenItems = (Get-ChildItem -Hidden -Path $Item.FullName -ErrorAction SilentlyContinue);
    If ($Null -ne $HiddenItems) {
      If ($HiddenItems.Name.GetType() -eq [System.String] -and $HiddenItems.Name -eq "desktop.ini") {
        If ($Null -ne ((Get-Content -LiteralPath (Join-Path -Path $Item.FullName -ChildPath "desktop.ini")).ToLower() | Select-String "$($Type.ToLower())")) {
          Write-Host "Is found at $($Item.FullName)";
          Return $True;
        } Else {
          Write-Host "Not found at $($Item.FullName)";
        }
      } ElseIf ($HiddenItems.Name.GetType() -eq [System.Object[]] -and [System.Linq.Enumerable]::Any([string[]]$HiddenItems.Name, [System.Func[string, bool]] { Param($x)Return $x -eq "desktop.ini" }) -eq $True) {
        If ($Null -ne ((Get-Content -LiteralPath (Join-Path -Path $Item.FullName -ChildPath "desktop.ini")).ToLower() | Select-String "$($Type.ToLower())")) {
          Write-Host "Is found at $($Item.FullName)";
          Return $True;
        } Else {
          Write-Host "Not found at $($Item.FullName)";
        }
      }
      Return $False;
    } Else {
      Return $False;
    }
  }

  Function Invoke-ForEachObject {
    [CmdletBinding()]
    Param(
      # Specifies the item to check against the custom ForEach-Object block.
      [Parameter(Mandatory = $True,
        HelpMessage = "The item to check against the custom ForEach-Object block.")]
      [ValidateNotNull()]
      [System.IO.FileSystemInfo]
      $Item
    )

    $DesktopIniPath = (Join-Path -Path $Item.Fullname -ChildPath "desktop.ini");
    $FileText = (Get-Content -Path $DesktopIniPath -Raw);
    $FileTextSplit = ($FileText -split "\r?\n|\n\r?");
    $FileTextOut = "";

    Write-Host -ForegroundColor Green -Object "`nWriting to file:"
    ForEach ($Line in $FileTextSplit) {
      $NewLine = "$($Line)";
      If ($NewLine -match "^IconResource=.+\\.+\.(exe|dll|ico),\d+") {
        Continue;
      }
      If ($NewLine -match "\s?=\s?$Type\s?") {
        Continue;
      }
      If ($Null -eq $NewLine) {
        Continue;
      }
      Write-Host -Object ">>> $($NewLine)"
      $FileTextOut += "$($NewLine)`n";
    }

    Write-OverFile -LiteralPath $DesktopIniPath -Text $FileTextOut;

    [System.Boolean]$Verify = (Test-VerifyFileChange -LiteralPath $DesktopIniPath -Text $FileTextOut);
    If ($Verify -ne $True) {
      Write-Host -ForegroundColor Red -Object "Verification failed!"
      Remove-FileAt -LiteralPath $DesktopIniPath;
    } Else {
      Write-Host -ForegroundColor Green -Object "Verification complete!"
    }
  }

  Function Remove-FileAt {
    [CmdletBinding()]
    Param(
      # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
      # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
      # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
      # characters as escape sequences.
      [Parameter(Mandatory = $True,
        Position = 0,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Literal path to one or more locations.")]
      [Alias("PSPath", "Path")]
      [ValidateNotNullOrEmpty()]
      [System.String]
      $LiteralPath
    )

    Write-Host "Trying to remove @ $($LiteralPath)";

    Try {
      Remove-Item -Force -LiteralPath $LiteralPath;
    } Catch {
      Try {
        If ($_.Exception.Message -match "^Access to the path '.+\\desktop.ini' is denied.") {
          Start-Process -FilePath $PowerShellProcess -Verb RunAs -Wait -ArgumentList @("-Command", "'&{Remove-Item -LiteralPath `"$($LiteralPath)`" -Force;`$ExitCode=`$LastExitCode;Exit `$ExitCode;}'");
          $ExitCode = $LastExitCode;
          If ($ExitCode -ne 0) {
            Write-Error -Message "Failed with exit code $($ExitCode).";
            Write-Error -ErrorRecord $_;
            Throw "Failed to run as administrator...";
          }
        } Else {
          Write-Error -Message "Failed with exit code $($ExitCode).";
          Write-Error -ErrorRecord $_;
          Throw;
        }
      } Catch {
        Write-Error -Message "Failed with exit code $($ExitCode).";
        Write-Error -ErrorRecord $_;
        Throw;
      }
    }
  }

  Function Test-VerifyFileChange {
    [CmdletBinding()]
    Param(
      # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
      # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
      # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
      # characters as escape sequences.
      [Parameter(Mandatory = $True,
        Position = 0,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Literal path to one or more locations.")]
      [Alias("PSPath", "Path")]
      [ValidateNotNullOrWhiteSpace()]
      [System.String]
      $LiteralPath,
      # Parameter help description
      [Parameter(Mandatory = $True,
        Position = 1,
        HelpMessage = "Literal path to one or more locations.")]
      [System.String]
      $Text
    )

    Try {
      $HashA = ($Text | Get-Hash -Algorithm SHA512)
      $FileContent = ((Get-Content -LiteralPath $LiteralPath) -join "`n");
      $HashB = ($FileContent | Get-Hash -Algorithm SHA512)
      Return $HashA -eq $HashB
    } Catch {
      Try {
        If ($_.Exception.Message -match "^Access to the path '.+\\desktop.ini' is denied.") {
          Start-Process -FilePath $PowerShellProcess -Verb RunAs -Wait -ArgumentList @("-Command", "'&{`$HashA=(`"$($Text|ConvertTo-Base64)`"|ConvertFrom-Base64 -ToString|Get-Hash -Algorithm SHA512);`$HashB=((Get-Content -LiteralPath `"$($LiteralPath)`"))|Get-Hash -Algorithm SHA512);`$ExitCode=`$LastExitCode;If(`$HashA.Hash -eq `$HashB.Hash){`$ExitCode=-1}Else{`$ExitCode=-2};Exit `$ExitCode}'");
          $ExitCode = $LastExitCode;
          If ($ExitCode -eq -1) {
            Return $True;
          } ElseIf ($ExitCode -eq -2) {
            Return $False;
          } Else {
            Write-Host "Failed with exit code $($ExitCode).";
            Throw "Failed to run as administrator...";
          }
        } Else {
          Write-Error -Message "Failed with exit code $($ExitCode).";
          Throw;
        }
      } Catch {
        Write-Error -Message "Failed with exit code $($ExitCode).";
        Throw;
      }
    }
  }

  Function Write-OverFile {
    [CmdletBinding()]
    Param(
      # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
      # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
      # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
      # characters as escape sequences.
      [Parameter(Mandatory = $True,
        Position = 0,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Literal path to one or more locations.")]
      [Alias("PSPath", "Path")]
      [ValidateNotNullOrWhiteSpace()]
      [System.String]
      $LiteralPath,
      # Parameter help description
      [Parameter(Mandatory = $True,
        Position = 1,
        HelpMessage = "Literal path to one or more locations.")]
      [System.String]
      $Text
    )

    Try {
      $Text | Set-Content -Force -LiteralPath $LiteralPath
    } Catch {
      Try {
        If ($_.Exception.Message -match "^Access to the path '.+\\desktop.ini' is denied.") {
          Write-Host "Start-Process -FilePath `"$($PowerShellProcess.Source)`" -Verb RunAs -Wait -ArgumentList @(`"-Command`", `"&{```$Text=```"$($Text|ConvertTo-Base64)```";```$Text|ConvertFrom-Base64 -ToString|Set-Content -Force -LiteralPath ```"$($LiteralPath)```";```$ExitCode=```$LastExitCode;Read-Host;Exit```$ExitCode }`");"
          Start-Process -FilePath $PowerShellProcess -Verb RunAs -Wait -ArgumentList @("-Command", "&{`$Text=`"$($Text|ConvertTo-Base64)`";`$Text|ConvertFrom-Base64 -ToString|Set-Content -Force -LiteralPath `"$($LiteralPath)`";`$ExitCode=`$LastExitCode;Read-Host;Exit `$ExitCode}");
          $ExitCode = $LastExitCode;
          If ($ExitCode -ne 0) {
            Write-Host "Failed with exit code $($ExitCode).";
            Throw "Failed to run as administrator...";
          }
        } Else {
          Write-Error -Message "Failed with exit code $($ExitCode).";
          Write-Error -ErrorRecord $_;
          Throw;
        }
      } Catch {
        Write-Error -Message "Failed with exit code $($ExitCode).";
        Write-Error -ErrorRecord $_;
        Throw;
      }
    }
  }

  If ($Null -eq $ElevateScript) {
    Try {
      $Items = (Get-ChildItem -Path $CurrentLocation -Directory -Recurse:$($Recurse -eq $True) -Depth $($Depth))
      $ItemsFiltered = ($Items | Where-Object {
          Return Invoke-WhereObject -Item $_;
        })
      ForEach ($Item in $ItemsFiltered) {
        $Output = (Invoke-ForEachObject -Item $Item);
        If ($Output -eq "Terminate") {
          Write-Host "Success!" | Out-Host;
          Break;
        }
      }
    } Catch {
      Write-Error -ErrorRecord $_;
      Read-Host -Prompt "Press any key to continue...";
    }
  }
} End {
}