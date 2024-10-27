[CmdletBinding(DefaultParameterSetName = "LiteralPath")]
Param(
  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "LiteralPath",
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Literal path to one or more locations.")]
  [Alias("PSLiteralPath")]
  [ValidateNotNullOrEmpty()]
  [System.String[]]
  $LiteralPath,
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             ParameterSetName = "Path",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [System.String[]]
  $Path,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 5,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 5,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [Switch]
  $Force,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 4,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 4,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [System.String]
  $Filter,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 3,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 3,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [System.String[]]
  $Exclude,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 6,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 6,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [System.String[]]
  $Include,
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 1,
             ParameterSetName = "Path",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Parameter(Mandatory = $True,
             Position = 1,
             ParameterSetName = "LiteralPath",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSDestination")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Destination,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 2,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 2,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [System.Management.Automation.PSCredential]
  $Credential,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [Switch]
  $RemoveFolder
)

Begin {
  If ($Null -eq $Destination) {
    $Destination = $PWD;
  }
  If ($PSCmdlet.ParameterSetName -eq "Path" -and ($Null -eq $Path -or $Path -eq "")) {
    Throw "Parameter Path is empty.";
    Exit 1;
  } ElseIf ($PSCmdlet.ParameterSetName -eq "LiteralPath" -and ($Null -eq $LiteralPath -or $LiteralPath -eq "")) {
    Throw "Parameter LiteralPath is empty.";
    Exit 1;
  }
  [System.Management.Automation.ActionPreference]$OriginalErrorActionPreference = $ErrorActionPreference;
  [System.Management.Automation.ActionPreference]$ErrorActionPreference = "Stop";

  [System.Boolean]$EnableDebug = $False;
  [System.Boolean]$EnableVerbose = $False;
  If ($DebugPreference -ne "SilentlyContinue") {
    $EnableDebug = $True;
  }
  If ($VerbosePreference -ne "SilentlyContinue") {
    $EnableVerbose = $True;
  }
  [System.String]$EscapedPath = "";
  [System.IO.FileSystemInfo]$SourcePath
  [System.IO.FileSystemInfo[]]$SourceItems = @();

  Write-Progress -Id 0 -Activity "Starting" -Status "Querying items of source path..." -PercentComplete 0;
  If ($PSCmdlet.ParameterSetName -eq "Path") {
    If (-not (Test-Path -Path $Path -Debug:$EnableDebug -Verbose:$EnableVerbose -PathType Container)) {
      Write-Progress -Id 0 -Activity "Starting" -Complete;
      Throw "Directory not found at path: $Path";
      Exit 1;
    }
    $EscapedPath = (ConvertTo-Escaped -InputObject (Resolve-Path -Path $Path -Debug:$EnableDebug -Verbose:$EnableVerbose) -Debug:$EnableDebug -Verbose:$EnableVerbose);
  } Else {
    If (-not (Test-Path -LiteralPath $LiteralPath -Debug:$EnableDebug -Verbose:$EnableVerbose -PathType Container)) {
      Write-Progress -Id 0 -Activity "Starting" -Complete;
      Throw "Directory not found at path: $LiteralPath";
      Exit 1;
    }
    $EscapedPath = (ConvertTo-Escaped -InputObject (Resolve-Path -LiteralPath $LiteralPath -Debug:$EnableDebug -Verbose:$EnableVerbose) -Debug:$EnableDebug -Verbose:$EnableVerbose);
  }
  If ($Null -eq $EscapedPath -or $EscapedPath -eq "") {
    Write-Progress -Id 0 -Activity "Starting" -Complete;
    Throw "Variable EscapedPath is empty.";
    Exit 1;
  }
  $SourceItems = (Get-ChildItem -Path $EscapedPath -Recurse -Debug:$EnableDebug -Verbose:$EnableVerbose);
  Write-Progress -Id 0 -Activity "Starting" -Status "Done." -Complete;

  [System.IO.FileSystemInfo]$DestinationPath = (Get-Item -Path (ConvertTo-Escaped (Resolve-Path -Path $Destination -Debug:$EnableDebug -Verbose:$EnableVerbose) -Debug:$EnableDebug -Verbose:$EnableVerbose));
  [System.IO.FileSystemInfo[]]$DestinationItems = @();
  Write-Progress -Id 1 -Activity "Starting" -Status "Querying items of destination path..." -PercentComplete 0;
  $DestinationItems = (Get-ChildItem -Path $Destination -Recurse -Exclude:$(If ($Null -ne $Exclude) { Return $Exclude }) -Debug:$EnableDebug -Verbose:$EnableVerbose);
  Write-Progress -Id 1 -Activity "Starting" -Status "Done." -Complete;
}
Process {
  Function Get-RelativeForDestination {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $True,
                 ParameterSetName = "Path")]
      [Alias("Path","PSPath","APSPath")]
      [System.IO.FileSystemInfo]
      $APath,
      [Parameter(Mandatory = $True,
                 ParameterSetName = "Path")]
      [Parameter(Mandatory = $True,
                 ParameterSetName = "LiteralPath")]
      [System.IO.FileSystemInfo]
      $ParentPath,
      [Parameter(Mandatory = $True,
                 ParameterSetName = "Path")]
      [Parameter(Mandatory = $True,
                 ParameterSetName = "LiteralPath")]
      [System.IO.FileSystemInfo]
      $Destination
    )

    Begin {
      [System.String]$Output = "undefined";
      [System.String]$BasePathFromSource = "";
      [System.String]$EscapedParentPath = [System.Text.RegularExpressions.Regex]::Escape($ParentPath.FullName);
      [System.String[]]$PathSplit = ($APath.FullName -split "$EscapedParentPath");
      $BasePathFromSource = $PathSplit[$PathSplit.Count - 1];
    }
    Process {
      $Output = (Join-Path -Path $Destination.FullName -ChildPath $BasePathFromSource);
    }
    End {
      If ($EnableDebug) {
        #Write-Host -Object "Get-RelativeForDestination(`"$($EscapedPath)`", `"$($ParentPath)`", `"$($Destination)`") => `"$Output`"" | Out-Host;
      }
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  [System.String]$MovingPath = [System.String]::Empty;

  Try {
    [System.Int32]$Progress = 0;
    [System.Int32]$Total = $SourceItems.Length
    [System.Int32]$Index = 0;
    ForEach ($SourceItem in $SourceItems) {
      If ($Index -gt 0) {
        $Progress = [System.Math]::Ceiling(($Index / $Total) * 100);
      }

      Try {
        $_temp = (Resolve-Path -LiteralPath $SourceItem -Relative -RelativeBasePath $SourcePath);
        $MovingPath = "$($_temp)"
      } Catch {
        $MovingPath = ($SourceItem.FullName -replace [System.Text.RegularExpressions.Regex]::Escape("$($SourcePath.FullName)\?"), '.\');
      }

      Write-Progress -Id 2 -Activity "Moving Items" -Status "Moving $($MovingPath) - $($Index)/$($Total) - $($Progress)%" -PercentComplete $Progress;
      [System.String]$PotentialDestinationPath = (Get-RelativeForDestination -APath $SourceItem -ParentPath (Get-Item -Path $EscapedPath) -Destination $DestinationPath);
      If (Test-Path -LiteralPath $SourceItem.FullName -PathType Container -Verbose:$EnableVerbose -Debug:$EnableDebug) {
        If (Test-Path -LiteralPath $PotentialDestinationPath -PathType Container -Verbose:$EnableVerbose -Debug:$EnableDebug) {
          If ($EnableVerbose -or $EnableDebug) {
            Write-Verbose -Verbose -Message "Passing over container at '$($SourceItem.FullName)'"
          }
        } Else {
          If (Test-Path -Path $PotentialDestinationPath -PathType Leaf -Verbose:$EnableVerbose -Debug:$EnableDebug) {
            Write-Warning -Message "Path at '$PotentialDestinationPath' does not match type of '$($SourceItem.FullName)' (Expected Container got Leaf).";
          } Else {
            Move-Item -LiteralPath $SourceItem -Destination $PotentialDestinationPath -Force -Verbose:$EnableVerbose -Debug:$EnableDebug;
          }
        }
      } ElseIf (Test-Path -LiteralPath $SourceItem.FullName -PathType Leaf -Verbose:$EnableVerbose -Debug:$EnableDebug) {
        If (Test-Path -Path $PotentialDestinationPath -PathType Leaf -Verbose:$EnableVerbose -Debug:$EnableDebug) {
          Move-Item -LiteralPath $SourceItem -Destination $PotentialDestinationPath -Force -Verbose:$EnableVerbose -Debug:$EnableDebug;
        } Else {
          If (Test-Path -LiteralPath $PotentialDestinationPath -PathType Container -Verbose:$EnableVerbose -Debug:$EnableDebug) {
            Write-Warning -Message "Path at '$PotentialDestinationPath' does not match type of '$($SourceItem.FullName)' (Expected Leaf got Container).";
          } Else {
            Move-Item -LiteralPath $SourceItem -Destination $PotentialDestinationPath -Verbose:$EnableVerbose -Debug:$EnableDebug;
          }
        }
      }
      $Index++;
    }
    Write-Progress -Id 2 -Activity "Starting" -Status "Done." -Complete;
  } Catch {
    Throw;
    Exit 1;
  }
}
End {
  Write-Progress -Id 3 -Activity "Cleaning up" -Status "Cleaning $($MovingPath) - $($Index)/$($Total) - $($Progress)%" -PercentComplete $Progress;
  $AfterSourceItems = (Get-ChildItem -Path $EscapedPath -Recurse -Verbose:$EnableVerbose -Debug:$EnableDebug);
  $Progress = 0;
  $Total = $AfterSourceItems.Length
  [System.Int32]$Index = 0;
  If ($AfterSourceItems.Length -gt 0) {
    ForEach ($AfterSourceItem in $AfterSourceItems) {
      If ($Index -gt 0) {
        $Progress = [System.Math]::Ceiling(($Index / $Total) * 100);
      }

      [System.String]$RemovingPath = [System.String]::Empty;

      Try {
        $_temp = (Resolve-Path -LiteralPath $EscapedPath -Relative -RelativeBasePath $SourcePath);
        $RemovingPath = "$($_temp)"
      } Catch {
        $RemovingPath = ($EscapedPath -replace [System.Text.RegularExpressions.Regex]::Escape("$($SourcePath.FullName)\?"), '.\');
      }

      Write-Progress -Id 3 -Activity "Cleaning up" -Status "Removing $($RemovingPath) - $($Index)/$($Total) - $($Progress)%" -PercentComplete $Progress;
      If ($RemoveFolder) {
        Remove-Item -Recurse -Force -Path $EscapedPath -Verbose:$EnableVerbose -Debug:$EnableDebug;
      }
      $Index++;
    }
  }
  If ($RemoveFolder) {
    Remove-Item -Path $EscapedPath -Verbose:$EnableVerbose -Debug:$EnableDebug;
  }
  Write-Progress -Id 3 -Activity "Starting" -Status "Done." -Complete;
} Clean {
  $ErrorActionPreference = $OriginalErrorActionPreference;
}