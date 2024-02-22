Param(
  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $False,
             Position = 0,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Literal path to one or more locations.")]
  [Alias("PSPath", "Path")]
  [ValidateNotNullOrWhiteSpace()]
  [System.String]
  $LiteralPath = $PWD,
  # Parameter help description
  [Parameter(Mandatory = $True,
             Position = 1,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Literal path to one or more locations.")]
  [ValidateSet("Mega")]
  [ValidateNotNullOrWhiteSpace()]
  [System.String]
  $Type
)

$CurrentLocation = (Get-Item -LiteralPath $LiteralPath);
$CurrentScript = $MyInvocation.MyCommand.Path;

Function Invoke-WhereObject {
  Param(
    [PSCustomObject]
    $Item
  )

  $HiddenItems = (Get-ChildItem -Hidden -Path $Item.FullName);
  If ($Null -ne $HiddenItems) {
    If ($HiddenItems.Name.GetType() -eq [System.String] -and $HiddenItems.Name -eq "desktop.ini") {
      If ($Null -ne ((Get-Content -LiteralPath (Join-Path -Path $Item.FullName -ChildPath "desktop.ini")).ToLower() | Select-String "$($Type.ToLower())")) {
        Write-Host "Is found at $($Item.FullName)";
        Return $True;
      } Else {
        Write-Host "Not found at $($Item.FullName)";
      }
    } ElseIf ($HiddenItems.Name.GetType() -eq [System.Object[]] -and [System.Linq.Enumerable]::Any([string[]]$HiddenItems.Name, [System.Func[string,bool]]{Param($x)Return $x -eq "desktop.ini"}) -eq $True) {
      If ($Null -ne ((Get-Content -LiteralPath (Join-Path -Path $Item.FullName -ChildPath "desktop.ini")).ToLower() | Select-String "$($Type.ToLower())")) {
        Write-Host "Is found at $($Item.FullName)";
        Return $True;
      } Else {
        Write-Host "Not found at $($Item.FullName)";
      }
    }
    Return $False;
  }
}

$ExitCode = 0;

Function Invoke-ForEachObject {
  Param(
    [PSCustomObject]
    $Item
  )
  $DesktopIniPath = (Join-Path -Path $_.Fullname -ChildPath "desktop.ini");
  $FileText = (Get-Content -Path $DesktopIniPath -Raw);
  $FileTextSplit = $FileText.Split("`n");
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
  Param(
    # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
    # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
    # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
    # characters as escape sequences.
    [Parameter(Mandatory = $True,
               Position = 0,
               ValueFromPipelineByPropertyName = $True,
               HelpMessage="Literal path to one or more locations.")]
    [Alias("PSPath", "Path")]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $LiteralPath
  )
  Write-Host "Trying to remove @ $($LiteralPath)";
  Try {
    Remove-Item -Force -LiteralPath $LiteralPath;
  } Catch {
    Try {
      If ($_.Exception.Message -match "^Access to the path '.+\\desktop.ini' is denied.") {
        Start-Process -FilePath (Get-Command -Name "pwsh.exe").Source -Verb RunAs -Wait -WorkingDirectory (Get-Item -Force -LiteralPath $LiteralPath).Directory.FullName -ArgumentList @("-Command", "'&{Set-Location -LiteralPath $((Get-Item -Force -LiteralPath $LiteralPath).Directory.FullName);Remove-Item -LiteralPath $($LiteralPath) -Force;`$ExitCode=`$LastExitCode;Exit `$ExitCode;}'");
        $ExitCode = $LastExitCode;
        If ($ExitCode -ne 0) {
          Write-Error -Message "Failed with exit code $($ExitCode).";
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

Function Test-VerifyFileChange {
  Param(
    # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
    # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
    # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
    # characters as escape sequences.
    [Parameter(Mandatory = $True,
               Position = 0,
               ValueFromPipelineByPropertyName = $True,
               HelpMessage="Literal path to one or more locations.")]
    [Alias("PSPath", "Path")]
    [ValidateNotNullOrWhiteSpace()]
    [System.String]
    $LiteralPath,
    # Parameter help description
    [Parameter(Mandatory = $True,
               Position = 1,
               HelpMessage="Literal path to one or more locations.")]
    [System.String]
    $Text
  )

  Try {
    $HashA = ($Text | Get-Hash -Algorithm SHA512)
    $HashB = ((Get-Content -LiteralPath $LiteralPath) | Get-Hash -Algorithm SHA512)
    Return $HashA -eq $HashB
  } Catch {
    Try {
      If ($_.Exception.Message -match "^Access to the path '.+\\desktop.ini' is denied.") {
        Start-Process -FilePath (Get-Command -Name "pwsh.exe").Source -Verb RunAs -Wait -WorkingDirectory (Get-Item -Force -LiteralPath $LiteralPath).Directory.FullName -ArgumentList @("-Command", "'&{Set-Location -LiteralPath $((Get-Item -Force -LiteralPath $LiteralPath).Directory.FullName);`$HashA=(`"$($Text)`"|Get-Hash -Algorithm SHA512);`$HashB=((Get-Content -LiteralPath $($LiteralPath)))|Get-Hash -Algorithm SHA512);`$ExitCode=`$LastExitCode;If(`$HashA -eq `$HashB){`$ExitCode=-1}Else{`$ExitCode=-2};Exit `$ExitCode}'");
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
  Param(
    # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
    # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
    # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
    # characters as escape sequences.
    [Parameter(Mandatory = $True,
               Position = 0,
               ValueFromPipelineByPropertyName = $True,
               HelpMessage="Literal path to one or more locations.")]
    [Alias("PSPath", "Path")]
    [ValidateNotNullOrWhiteSpace()]
    [System.String]
    $LiteralPath,
    # Parameter help description
    [Parameter(Mandatory = $True,
               Position = 1,
               HelpMessage="Literal path to one or more locations.")]
    [System.String]
    $Text
  )

  Try {
    $Text | Out-File -FilePath $LiteralPath
  } Catch {
    Try {
      If ($_.Exception.Message -match "^Access to the path '.+\\desktop.ini' is denied.") {
        Start-Process -FilePath (Get-Command -Name "pwsh.exe").Source -Verb RunAs -Wait -WorkingDirectory (Get-Item -Force -LiteralPath $LiteralPath).Directory.FullName -ArgumentList @("-Command", "'&{Set-Location -LiteralPath $((Get-Item -Force -LiteralPath $LiteralPath).Directory.FullName);`$Text=`"$($Text|ConvertTo-Base64)`";`$Text|ConvertFrom-Base64|Out-File -Force -FilePath $($LiteralPath);`$ExitCode=`$LastExitCode;Read-Host;Exit `$ExitCode}'");
        $ExitCode = $LastExitCode;
        If ($ExitCode -ne 0) {
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

Get-ChildItem -Path $CurrentLocation -Directory | Where-Object {
  Return Invoke-WhereObject -Item $_;
} | ForEach-Object {
  $Output = (Invoke-ForEachObject -Item $_);
  If ($Output -eq "Terminate") {
    Write-Host "Success!";
    Break;
  } Else {
    Write-Output $Output | Out-Host;
    Break;
  }
}