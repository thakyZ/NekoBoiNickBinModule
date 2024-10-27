[CmdletBinding(DefaultParameterSetName = "Default")]
Param(
  # Specifies the operation to use on TeraCopy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Default",
             HelpMessage = "The operation to use on TeraCopy.")]
  [ValidateNotNullOrEmpty()]
  [ValidateSet("Copy","Move","Delete","Test","Check","AddList")]
  [System.String]
  $Operation,
  # Specifies a switch specifying to use the copy operation on TeraCopy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Copy",
             HelpMessage = "A switch specifying to use the copy operation on TeraCopy.")]
  [System.Management.Automation.SwitchParameter]
  $Copy,
  # Specifies a switch specifying to use the move operation on TeraCopy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Move",
             HelpMessage = "A switch specifying to use the move operation on TeraCopy.")]
  [System.Management.Automation.SwitchParameter]
  $Move,
  # Specifies a switch specifying to use the move operation on TeraCopy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Delete",
             HelpMessage = "A switch specifying to use the move operation on TeraCopy.")]
  [System.Management.Automation.SwitchParameter]
  $Delete,
  # Specifies a switch specifying to use the move operation on TeraCopy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Test",
             HelpMessage = "A switch specifying to use the move operation on TeraCopy.")]
  [System.Management.Automation.SwitchParameter]
  $Test,
  # Specifies a switch specifying to use the move operation on TeraCopy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Check",
             HelpMessage = "A switch specifying to use the move operation on TeraCopy.")]
  [System.Management.Automation.SwitchParameter]
  $Check,
  # Specifies a switch specifying to use the move operation on TeraCopy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "AddList",
             HelpMessage = "A switch specifying to use the move operation on TeraCopy.")]
  [System.Management.Automation.SwitchParameter]
  $AddList,
  # Specifies a path to one or more locations. Wildcards are permitted.
  [Parameter(Mandatory = $True,
             Position = 1,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [ValidateNotNullOrEmpty()]
  [SupportsWildcards()]
  [System.String]
  $Source,
  # Specifies a path to one or more locations. Wildcards are permitted.
  [Parameter(Mandatory = $True,
             Position = 2,
             ParameterSetName = "Default",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Parameter(Mandatory = $True,
             Position = 2,
             ParameterSetName = "Copy",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Parameter(Mandatory = $True,
             Position = 2,
             ParameterSetName = "Move",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Target,
  # Specifies a switch to handle file conflicts, by skipping all conflicts.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Default",
             HelpMessage = "A switch to handle file conflicts, by skipping all conflicts.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Copy",
             HelpMessage = "A switch to handle file conflicts, by skipping all conflicts.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Move",
             HelpMessage = "A switch to handle file conflicts, by skipping all conflicts.")]
  [System.Management.Automation.SwitchParameter]
  $SkipAll = $False,
  # Specifies a switch to handle file conflicts, by overwriting all older conflicts.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Default",
             HelpMessage = "A switch to handle file conflicts, by overwriting all older conflicts.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Copy",
             HelpMessage = "A switch to handle file conflicts, by overwriting all older conflicts.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Move",
             HelpMessage = "A switch to handle file conflicts, by overwriting all older conflicts.")]
  [System.Management.Automation.SwitchParameter]
  $OverwriteOlder = $False,
  # Specifies a switch to handle file conflicts, by renaming all conflicts.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Default",
             HelpMessage = "A switch to handle file conflicts, by renaming all conflicts.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Copy",
             HelpMessage = "A switch to handle file conflicts, by renaming all conflicts.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Move",
             HelpMessage = "A switch to handle file conflicts, by renaming all conflicts.")]
  [System.Management.Automation.SwitchParameter]
  $RenameAll = $False,
  # Specifies a switch to handle file conflicts, by overwriting all conflicts.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Default",
             HelpMessage = "A switch to handle file conflicts, by overwriting all conflicts.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Copy",
             HelpMessage = "A switch to handle file conflicts, by overwriting all conflicts.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Move",
             HelpMessage = "A switch to handle file conflicts, by overwriting all conflicts.")]
  [System.Management.Automation.SwitchParameter]
  $OverwriteAll = $False,
  # Specifies a switch to handle the TeraCopy window after ending, by not closing.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Default",
             HelpMessage = "A switch to handle TeraCopy window after ending, by not closing.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Copy",
             HelpMessage = "A switch to handle TeraCopy window after ending, by not closing.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Move",
             HelpMessage = "A switch to handle TeraCopy window after ending, by not closing.")]
  [System.Management.Automation.SwitchParameter]
  $NoClose = $False,
  # Specifies a switch to handle TeraCopy window after ending, by closing.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Default",
             HelpMessage = "A switch to handle TeraCopy window after ending, by closing.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Copy",
             HelpMessage = "A switch to handle TeraCopy window after ending, by closing.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Move",
             HelpMessage = "A switch to handle TeraCopy window after ending, by closing.")]
  [System.Management.Automation.SwitchParameter]
  $Close = $False
)

Begin {
  # Import Class Accessor
  . "$($PSCommandPath | Split-Path -Parent)\classAccessor.ps1"

  Class ApplicationInfo {
    ApplicationInfo([System.String]$name, [System.String]$path, [System.Threading.ExecutionContext]$context) {
      $ItemPath = (Get-Item -Path $path);
      If ($Null -eq $ItemPath -or -not (Test-Path -Path $ItemPath -PathType Leaf)) {
        Throw "Failed to find valid item at path $($path).";
      }
      $this.Path = $ItemPath.FullName;
      $this.Extension = $ItemPath.Extension;
    }
    ApplicationInfo([System.Management.Automation.ApplicationInfo]$Old) : base($Old.Name, $Old.CommandType) {
      $this.Path = $Old.Source;
      $this.Extension = $Old.Extension;
    }
    Hidden Static [System.Threading.ExecutionContext]$_context;
    Hidden [System.String]$Path = [System.String]::Empty;
    Hidden [System.String]$Extension = [System.String]::Empty;
    [System.String]$_Definition = $(Accessor $this {
      Get {
        Return $this.Path;
      }
    })
    [System.String]$_Source = $(Accessor $this {
      Get {
        Return $this.Definition;
      }
    });
    [System.Version]$_Version = $(Accessor $this {
      Get {
        If ($Null -eq $this._version) {
            [System.Diagnostics.FileVersionInfo] $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($this.Path);
            $this._version = [System.Version]::new($versionInfo.ProductMajorPart, $versionInfo.ProductMinorPart, $versionInfo.ProductBuildPart, $versionInfo.ProductPrivatePart);
        }
        Return $this._version;
      }
    });
    Hidden [System.Version]$__version;
    [System.Management.Automation.SessionStateEntryVisibility]$_Visibility = $(Accessor $this {
      Get {
        Return $this._context.EngineSessionState.CheckApplicationVisibility($this.Path);
      }
      Set {
        Param (
          # Specifies an argument for the setter of this property.
          [Parameter(Mandatory = $True,
                     Position = 0,
                     ValueFromPipeline = $True,
                     HelpMessage = "An argument for the setter of this property.")]
          [System.Object]
          $Arg
        )
        Throw [System.Management.Automation.PSTraceSource]::NewNotImplementedException();
      }
    });
    [System.Collections.ObjectModel.ReadOnlyCollection[[System.Management.Automation.PSTypeName]]]$_OutputType = $(Accessor $this {
      Get {
        If ($Null -eq $this._outputType) {
          [System.Collections.Generic.List[[System.Management.Automation.PSTypeName]]] $l = [System.Collections.Generic.List[[System.Management.Automation.PSTypeName]]]::new();
          $l.Add([System.Management.Automation.PSTypeName]::new([System.String]));
            $this._outputType = [System.Collections.ObjectModel.ReadOnlyCollection[[System.Management.Automation.PSTypeName]]]::new($l);
        }

        return $this.__outputType;
      }
    });
    Hidden [System.Collections.ObjectModel.ReadOnlyCollection[[System.Management.Automation.PSTypeName]]] $__outputType = $Null;
  }
  Function Find-TeraCopyInstall {
    [CmdletBinding()]
    [OutputType([ApplicationInfo])]
    Param()

    Begin {
      [ApplicationInfo]$Output = $Null;
      [System.Threading.ExecutionContext]$_context = [System.Threading.ExecutionContext]::Capture();
    } Process {
      # Search in system path.
      [System.Management.Automation.ApplicationInfo]$Temp = (Get-Command -Name "TeraCopy" -ErrorAction SilentlyContinue);
      If ($Null -eq $Temp) {
        # Search in each drive's "Program Files" and "Program Files (x86)"
        ForEach ($Drive in (Get-PSDrive | Where-Object { $_.Provider -match "FileSystem" -and $_.Root.Length -eq 3 })) {
          ForEach ($ProgramDir in @("Program Files", "Program Files (x86)")) {
            $FullProgramDir = (Join-Path -Path $Drive.Root -ChildPath $ProgramDir);
            If (Test-Path -Path $FullProgramDir -PathType Container) {
              $FullTeraCopyDir = (Join-Path -Path $FullProgramDir -ChildPath "TeraCopy");
              If (Test-Path -Path $FullTeraCopyDir -PathType Container) {
                $FullTeraCopyPath = (Join-Path -Path $FullTeraCopyDir -ChildPath "TeraCopy.exe");
                If (Test-Path -Path $FullTeraCopyPath -PathType Leaf) {
                  $Output = [ApplicationInfo]::new("TeraCopy.exe", $FullTeraCopyPath, $_context)
                }
              }
            }
          }
        }
      } Else {
        $Output = [ApplicationInfo]::new($Temp);
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Test-ExitCode {
    [CmdletBinding()]
    Param(
      # Specifies an exit code to exit the process with.
      # If the exit code is not equal to 0 it will exit with that code.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "An exit code to exit the process with.`nIf the exit code is not equal to 0 it will exit with that code.")]
      [System.Int32]
      $ExitCode,
      # Specifies a message to print if we exit.
      [Parameter(Mandatory = $False,
                 Position = 1,
                 HelpMessage = "A message to print if we exit.")]
      [System.String]
      $ExitMessage = $Null,
      # Specifies a switch to print the exit code upon exit.
      [Parameter(Mandatory = $False,
                 Position = 2,
                 HelpMessage = "A switch to print the exit code upon exit.")]
      [System.Management.Automation.SwitchParameter]
      $ShowExitCode = $False
    )

    Begin {
      $DoExit = ($ExitCode -ne 0);
    } Process {
      If ($DoExit -eq $True) {
        Write-Host -NoNewLine -Object "Exiting!";
        If ($ShowExitCode -eq $True) {
          Write-Host -Object " ($($ExitCode))";
        } Else {
          Write-Host -Object "";
        }
        If ($Null -ne $ExitMessage) {
          Write-Host -ForegroundColor Red -Object $ExitMessage;
        }
      }
    } End {
      If ($DoExit -eq $True) {
        Exit $ExitCode;
      }
    }
  }

  $TeraCopy = (Find-TeraCopyInstall);
  If ($Null -eq $TeraCopy) {
    Throw "TeraCopy not found on the system."
  }
  Write-Host $TeraCopy.Source;
  Exit 0;
} Process {
  $ArgumentList = @();

  # Argument Builder;
  If ($PSCmdlet.ParameterSetName -eq "Default") {
    $ArgumentList += "$($Operation)"
  } Else {
    $ArgumentList += "$($PSCmdlet.ParameterSetName)"
  }

  If ($ArgumentList[0] -eq "Copy" -or $ArgumentList[0] -eq "Move") {
    $ArgumentList += "$($Source)"
    $ArgumentList += "$($Target)"
    If ($SkipAll -eq $True) {
      $ArgumentList += "/SkipAll"
    } ElseIf ($OverwriteOlder -eq $True) {
      $ArgumentList += "/OverwriteOlder"
    } ElseIf ($RenameAll -eq $True) {
      $ArgumentList += "/RenameAll"
    } ElseIf ($OverwriteAll -eq $True) {
      $ArgumentList += "/OverwriteAll"
    }
  } ElseIf ($ArgumentList[0] -eq "Delete") {
    $ArgumentList += "$($Source)"
  } ElseIf ($ArgumentList[0] -eq "Test") {
    $ArgumentList += "$($Source)"
  } ElseIf ($ArgumentList[0] -eq "Check") {
    $ArgumentList += "$($Source)"
  } ElseIf ($ArgumentList[0] -eq "AddList") {
    $ArgumentList += "$($Source)"
  }

  If ($NoClose -eq $True) {
    $ArgumentList += "/NoClose"
  } ElseIf ($Close -eq $True) {
    $ArgumentList += "/Close"
  }

  $Process = (Start-Process -NoNewWindow -Wait -FilePath $TeraCopy.Source -ArgumentList $ArgumentList -ErrorAction "Continue" -PassThru);
  Test-ExitCode -ExitCode $Process.ExitCode -ShowExitCode -ExitMessage "Failed to run `"$($TeraCopy.Source)`" with arguments @(`"$($ArgumentList -join "`", `"")`")";
} End {
  Exit 0;
}
