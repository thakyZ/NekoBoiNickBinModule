[CmdletBinding(DefaultParameterSetName = "Path")]
Param(
  # Specifies a path to one location.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName="Path",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Path to one location.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path,
  # Specifies a path to one location. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "LiteralPath",
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Literal path to one location.")]
  [Alias("PSLiteralPath")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $LiteralPath,
  # Specifies a fixed string that specifies the algorithm to use for hashing.
  [Parameter(Mandatory = $False,
             Position = 1,
             HelpMessage = "The algorithm to use for hashing. (Default: SHA512)")]
  [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]
  [System.String]
  $Algorithm = "SHA512",
  # Specifies a switch to include subdirectories.
  [Parameter(Mandatory = $False,
             HelpMessage = "A switch to include subdirectories.")]
  [Switch]
  $Recurse = $False,
  # Specifies a switch to keep duplicates that are in subdirectories over that which are not.
  [Parameter(Mandatory = $False,
             HelpMessage = "A switch to keep duplicates that are in subdirectories over that which are not.")]
  [Alias("Keep")]
  [Switch]
  $KeepSubdirectoryItems = $False,
  # Specifies a switch that performs a dry run of removal of files without removing anything.
  [Parameter(Mandatory = $False,
             HelpMessage = "A switch that performs a dry run of removal of files without removing anything.")]
  [Alias("Test")]
  [Switch]
  $DryRun = $False,
  # Specifies a pattern to auto remove if matching...
  [Parameter(Mandatory = $False,
             HelpMessage = "A pattern to auto remove if file name matches.")]
  [Alias("WhenMatching")]
  [System.Object]
  $Pattern = $Null
)

DynamicParam {
  $ErrorActionPreference = "Stop";

  If ($KeepSubdirectoryItems -eq $True -and $Recurse -ne $True) {
    Throw "Switch ``-KeepSubDirectoryItems`` needs to have the switch ``-Recurse`` specified";
  }

  $Debug = $False;

  If ($DebugPreference -ne "SilentlyContinue" -and $DebugPreference -ne "Ignore") {
    $Debug = $True;
  }

  $Verbose = $False;

  If ($VerbosePreference -ne "SilentlyContinue" -and $VerbosePreference -ne "Ignore") {
    $Verbose = $True;
  }

  If ($Null -ne $Pattern) {
    Try {
      [System.Text.RegularExpressions.Regex]$script:RegexRemoveWhenMatching;
      If ($Pattern.GetType() -eq [System.String]) {
        # You can specify the Regex Options via using a traditional regex string starting with a forward slash and ending in a forward slash with or without succeeding regex flags.

        # Set temporary default regex flags.
        $RegexOptions = [System.Text.RegularExpressions.RegexOptions]::None;

        # Funny, ignore regex via cSpell.
        # cSpell:ignoreRegexp \\\/\(\[gmisnxRN\]\*\)\$
        If ($Pattern.StartsWith("/") -and [System.Text.RegularExpressions.Regex]::IsMatch($Pattern, '\/([gmisnxRN]*)$')) {
          $ArgumentMatches = [System.Text.RegularExpressions.Regex]::Matches($Pattern, '\/([gmisnxRN]*)$');
          ForEach ($Flag in $ArgumentMatches.Groups[1].Value.ToCharArray()) {
            If ($Flag -eq "i") {
              $RegexOptions = $RegexOptions -bor  [System.Text.RegularExpressions.RegexOptions]::IgnoreCase;
            } ElseIf ($Flag -eq "m") {
              $RegexOptions = $RegexOptions -bor  [System.Text.RegularExpressions.RegexOptions]::Multiline;
            } ElseIf ($Flag -eq "s") {
              $RegexOptions = $RegexOptions -bor  [System.Text.RegularExpressions.RegexOptions]::Singleline;
            } ElseIf ($Flag -eq "n") {
              $RegexOptions = $RegexOptions -bor  [System.Text.RegularExpressions.RegexOptions]::ExplicitCapture;
            } ElseIf ($Flag -eq "x") {
              $RegexOptions = $RegexOptions -bor  [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace;
            } ElseIf ($Flag -eq "R") {
              $RegexOptions = $RegexOptions -bor  [System.Text.RegularExpressions.RegexOptions]::RightToLeft;
            } ElseIf ($Flag -ne "g") {
              Write-Warning -Message "Unknown regex flag: `"$($Flag)`"";
            }
          }
          $Pattern = ($Pattern -replace '^/', '');
          $Pattern = ($Pattern -replace '\/([gmisnxRN]*)$', '');
        } ElseIf ($Pattern.ToLower() -eq "default") {
          $Pattern = [System.Text.RegularExpressions.Regex]::new(".+ \(\d+\)\..+$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase, [System.TimeSpan]::new(1, 0, 0))
        }

        # System.TimeSpan for 1 hour to limit catastrophic backtracking.
        $script:RegexRemoveWhenMatching = [System.Text.RegularExpressions.Regex]::new($Pattern, $RegexOptions, [System.TimeSpan]::new(1, 0, 0))
      } ElseIf ($Pattern.GetType() -eq [System.Text.RegularExpressions.Regex]) {
        $script:RegexRemoveWhenMatching = $Pattern
      } Else {
        Throw [System.Exception]::new("Type of Pattern is not [System.String] or [System.Text.RegularExpressions.Regex]");
      }
    } Catch {
      If ($Debug) {
        Write-Host -ForegroundColor Green -Object "Regular Expression Error: " -NoNewline;
        Write-Host -ForegroundColor Red -Object $_.Exception.Message;
      }
      Throw;
    }
  }
}
Begin {
  Function Test-SubPath {
    Param(
      # Specifies the path to the main directory.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "The path to the main directory.")]
      [ValidateNotNullOrEmpty()]
      [System.IO.FileSystemInfo]
      $Directory,
      # Specifies a path that contains a potential subdirectory.
      [Parameter(Mandatory = $True,
                 Position = 1,
                 HelpMessage = "A path that contains a potential subdirectory.")]
      [ValidateNotNullOrEmpty()]
      [System.IO.FileSystemInfo]
      $Subpath
    )

    Try {
      $DirectoryPath = [IO.Path]::GetFullPath($Directory.FullName)
      $SubpathPath = [IO.Path]::GetFullPath($Subpath.FullName)
      Write-Output -NoEnumerate -InputObject $SubpathPath.StartsWith($DirectoryPath, [StringComparison]::OrdinalIgnoreCase) -and $SubpathPath -ne $DirectoryPath
    } Catch {
      Throw;
      Exit 1;
    }
  }

  $MainPath = @{};

  $Index = 0;
  $Percent = 0;
  $MaxCount = 0;
  $AllItems = @();

  Write-Progress -Activity "Getting Files" -Status "Starting - 0/? - 0%" -PercentComplete 0 -CurrentOperation "Starting" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

  If ($PSCmdlet.ParameterSetName -eq "Path") {
    $MainPath = (Get-Item -Path $Path -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True));
  } ElseIf ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
    $MainPath = (Get-Item -LiteralPath $LiteralPath -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True));
  }

  If ($Recurse -eq $False -and $PSCmdlet.ParameterSetName -eq "Path") {
    $AllItems = (Get-ChildItem -Path $MainPath -File -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True))
  } ElseIf ($Recurse -eq $True -and $PSCmdlet.ParameterSetName -eq "Path") {
    $AllItems = (Get-ChildItem -LiteralPath $MainPath -File -Recurse -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True))
  } ElseIf ($Recurse -eq $False -and $PSCmdlet.ParameterSetName -eq "LiteralPath") {
    $AllItems = (Get-ChildItem -LiteralPath $MainPath -File -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True))
  } ElseIf ($Recurse -eq $True -and $PSCmdlet.ParameterSetName -eq "LiteralPath") {
    $AllItems = (Get-ChildItem -LiteralPath $MainPath -File -Recurse -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True))
  }

  $MaxCount = $AllItems.Length;

  $Items = @();
  If ($Recurse -eq $False -and $PSCmdlet.ParameterSetName -eq "Path") {
    ForEach ($File in $AllItems) {
      If ($Index -ne 0) {
        $Percent = [System.Math]::Ceiling(($Index / $MaxCount) * 100);
      }

      Write-Progress -Activity "Getting Files" -Status "Parsing - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Starting" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

      $Hash = (Get-FileHash -Path $File.FullName -Algorithm $Algorithm -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True));
      $Items += @{ Path = (Get-Item -Path $File.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True)); Hash = $Hash; Removed = $False; IsSubdirectory = $False; };

      $Index++;
    }
  } ElseIf ($Recurse -eq $True -and $PSCmdlet.ParameterSetName -eq "Path") {
    ForEach ($File in $AllItems) {
      If ($Index -ne 0) {
        $Percent = [System.Math]::Ceiling(($Index / $MaxCount) * 100);
      }

      Write-Progress -Activity "Getting Files" -Status "Parsing - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Starting" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

      $Hash = (Get-FileHash -Path $File.FullName -Algorithm $Algorithm -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True));
      $IsSubdirectory = (Test-SubPath -Directory $MainPath -Subpath $File.Directory -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True));
      $Items += @{ Path = (Get-Item -Path $File.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True)); Hash = $Hash; Removed = $False; IsSubdirectory = $IsSubdirectory; };

      $Index++;
    }
  } ElseIf ($Recurse -eq $False -and $PSCmdlet.ParameterSetName -eq "LiteralPath") {
    ForEach ($File in $AllItems) {
      If ($Index -ne 0) {
        $Percent = [System.Math]::Ceiling(($Index / $MaxCount) * 100);
      }

      Write-Progress -Activity "Getting Files" -Status "Parsing - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Starting" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

      $Hash = (Get-FileHash -LiteralPath $File.FullName -Algorithm $Algorithm -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True));
      $Items += @{ Path = (Get-Item -LiteralPath $File.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True)); Hash = $Hash; Removed = $False; IsSubdirectory = $False; };

      $Index++;
    }
  } ElseIf ($Recurse -eq $True -and $PSCmdlet.ParameterSetName -eq "LiteralPath") {
    ForEach ($File in $AllItems) {
      If ($Index -ne 0) {
        $Percent = [System.Math]::Ceiling(($Index / $MaxCount) * 100);
      }

      Write-Progress -Activity "Getting Files" -Status "Parsing - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Starting" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

      $Hash = (Get-FileHash -LiteralPath $File.FullName -Algorithm $Algorithm);
      $MainPath = (Get-Item -LiteralPath $Path -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True));
      $IsSubdirectory = (Test-SubPath -Directory $MainPath -Subpath $File.Directory -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True));
      $Items += @{ Path = (Get-Item -LiteralPath $File.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True)); Hash = $Hash; Removed = $False; IsSubdirectory = $IsSubdirectory; };

      $Index++;
    }
  }
  Write-Progress -Activity "Getting Files" -Status "Finished - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Finished" -Completed -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
}
Process {
  Function Invoke-RemoveItem() {
    Param(
      # Specifies the custom object for removal of Item A.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "The custom object for removal of Item A.")]
      [PSCustomObject]
      $ItemA,
      # Specifies the custom object for removal of Item B.
      [Parameter(Mandatory = $True,
                 Position = 1,
                 HelpMessage = "The custom object for removal of Item B.")]
      [PSCustomObject]
      $ItemB,
      # Specifies a switch that removes specifically Item A.
      [Parameter(Mandatory = $False,
                 HelpMessage = "A switch that removes specifically Item A.")]
      [Switch]
      $RemoveA = $False,
      # Specifies a switch that removes specifically Item B.
      [Parameter(Mandatory = $False,
                 HelpMessage = "A switch that removes specifically Item B.")]
      [Switch]
      $RemoveB = $False,
      # Specifies a switch that removes specifically Item B.
      [Parameter(Mandatory = $False,
                 HelpMessage = "A switch that removes specifically Item B.")]
      [System.Text.RegularExpressions.Regex]
      $RegexRemoveWhenMatching
    )

    DynamicParam {
      If ($RemoveA -eq $True -and $RemoveB -eq $True) {
        Throw "Parameter -RemoveA and -RemoveB cannot be specified at the same time."
      }
    }
    End {
      If ($RemoveA -eq $False -and $RemoveB -eq $False) {
        If ($Null -ne $Pattern) {
          If ($RegexRemoveWhenMatching.IsMatch($ItemB.Path.Name)) {
            If ($PSCmdlet.ParameterSetName -eq "Path") {
              If ($DryRun -eq $True) {
                Write-Host -ForegroundColor Blue -NoNewline -Object "Would remove item: ";
                Write-Host -ForegroundColor White -Object "$($ItemB.Path.FullName)";
              } Else {
                Remove-Item -Path $ItemB.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
              }
            } ElseIf ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
              If ($DryRun -eq $True) {
                Write-Host -ForegroundColor Blue -NoNewline -Object "Would remove item: ";
                Write-Host -ForegroundColor White -NoNewline -Object "$($ItemB.Path.FullName)";
              } Else {
                Remove-Item -LiteralPath $ItemB.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
              }
            }
          } ElseIf ($RegexRemoveWhenMatching.IsMatch($ItemA.Path.Name)) {
            If ($DryRun -eq $True) {
              Write-Host -ForegroundColor Blue -NoNewline -Object "Would remove item: ";
              Write-Host -ForegroundColor White -Object "$($ItemA.Path.FullName)";
            } Else {
              If ($PSCmdlet.ParameterSetName -eq "Path") {
                Remove-Item -Path $ItemA.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
              } ElseIf ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
                Remove-Item -LiteralPath $ItemA.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
              }
            }
          }
        } Else {
            If ($DryRun -eq $True) {
              Write-Host -ForegroundColor Blue -NoNewline -Object "Would remove item: ";
              Write-Host -ForegroundColor White -Object "$($ItemB.Path.FullName)";
            } Else {
              If ($PSCmdlet.ParameterSetName -eq "Path") {
                Remove-Item -Path $ItemB.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
              } ElseIf ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
                Remove-Item -LiteralPath $ItemB.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
              }
            }
        }
      } Else {
        If ($RemoveA -eq $True) {
          If ($DryRun -eq $True) {
            Write-Host -ForegroundColor Blue -NoNewline -Object "Would remove item: ";
            Write-Host -ForegroundColor White  -Object "$($ItemA.Path.FullName)";
          } Else {
            If ($PSCmdlet.ParameterSetName -eq "Path") {
              Remove-Item -Path $ItemA.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
            } ElseIf ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
              Remove-Item -LiteralPath $ItemA.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
            }
          }
        } Else {
          If ($DryRun -eq $True) {
            Write-Host -ForegroundColor Blue -NoNewline -Object "Would remove item: ";
            Write-Host -ForegroundColor White -Object "$($ItemA.Path.FullName)";
          } Else {
            If ($PSCmdlet.ParameterSetName -eq "Path") {
              Remove-Item -Path $ItemB.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
            } ElseIf ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
              Remove-Item -LiteralPath $ItemB.Path.FullName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
            }
          }
        }
      }
    }
  }



  $CountRemoved = 0;
  Write-Progress -Activity "Removing Duplicates" -Status "Starting - 0/? - 0%" -PercentComplete 0 -CurrentOperation "Starting" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

  $ItemsCloneA = $Items.Clone();
  $ItemsCloneB = $Items.Clone();
  $MaxCount = $ItemsCloneA.Length * $ItemsCloneB.Length;
  $Index = 0;
  $Percent = 0;

  ForEach ($ItemA in $ItemsCloneA) {
    ForEach ($ItemB in $ItemsCloneB) {
      If ($Index -ne 0) {
        $Percent = [System.Math]::Ceiling(($Index / $MaxCount) * 100);
      }

      Write-Progress -Activity "Removing Duplicates" -Status "Parsing - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Parsing" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

      If ($ItemA.Path.FullName -ne $ItemB.Path.FullName -and $ItemA.Removed -eq $False -and $ItemB.Removed -eq $False -and $ItemA.Hash.Hash -eq $ItemB.Hash.Hash) {
        If ($KeepSubdirectoryItems -eq $True -and $ItemA.IsSubdirectory -eq $True -and $ItemB.IsSubdirectory -eq $False) {
          Write-Progress -Activity "Removing Duplicates" -Status "Removing - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Removing" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

          Write-Host -ForegroundColor Yellow -Object "`$ItemA is in a subdirectory.`nKeeping `$ItemA = `"$($ItemA.Path.FullName)`"`nRemoving `$ItemB = `"$($ItemB.Path.FullName)`"" | Out-Host;
          $ConsolePosition = @{ X = [System.Console]::CursorLeft; Y = [System.Console]::CursorTop; }

          If ($Debug) {
            Write-Host -ForegroundColor White -Object "Press any key to continue..." -NoNewline | Out-Host;
            $Null = Read-Host;
            [System.Console]::SetCursorPosition($ConsolePosition.X, $ConsolePosition.Y);
          }

          Invoke-RemoveItem -ItemA $ItemA -ItemB $ItemB -RemoveB -RegexRemoveWhenMatching $script:RegexRemoveWhenMatching

          $CountRemoved++;

          $ItemB.Removed = $True;
        } ElseIf ($KeepSubdirectoryItems -eq $True -and $ItemB.IsSubdirectory -eq $True -and $ItemA.IsSubdirectory -eq $False) {
          Write-Progress -Activity "Removing Duplicates" -Status "Removing - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Removing" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

          Write-Host -ForegroundColor Yellow -Object "`$ItemB is in a subdirectory.`nRemoving `$ItemA = `"$($ItemA.Path.FullName)`"`nKeeping `$ItemB = `"$($ItemB.Path.FullName)`"" | Out-Host;
          $ConsolePosition = @{ X = [System.Console]::CursorLeft; Y = [System.Console]::CursorTop; }

          If ($Debug) {
            Write-Host -ForegroundColor White -Object "Press any key to continue..." -NoNewline | Out-Host;
            $Null = Read-Host;
            [System.Console]::SetCursorPosition($ConsolePosition.X, $ConsolePosition.Y);
          }

          Invoke-RemoveItem -ItemA $ItemA -ItemB $ItemB -RemoveA -RegexRemoveWhenMatching $script:RegexRemoveWhenMatching

          $CountRemoved++;

          $ItemA.Removed = $True;
        } ElseIf ($KeepSubdirectoryItems -eq $True -and $ItemB.IsSubdirectory -eq $True -and $ItemA.IsSubdirectory -eq $True) {
          Write-Host -ForegroundColor Red -Object "Both `$ItemA and `$ItemB are in subdirectories.`n`$ItemA = `"$($ItemA.Path.FullName)`"`n`$ItemB = `"$($ItemB.Path.FullName)`"";
          $ConsolePosition = @{ X = [System.Console]::CursorLeft; Y = [System.Console]::CursorTop; }
          If ($Debug) {
            Write-Host -ForegroundColor White -Object "Press any key to continue..." -NoNewline | Out-Host;
            $Null = Read-Host;
            [System.Console]::SetCursorPosition($ConsolePosition.X, $ConsolePosition.Y);
          }
        } Else {
          $Done = $False;
          $ConsolePosition = @{ X = [System.Console]::CursorLeft; Y = [System.Console]::CursorTop; }

          While ($Done -eq $False) {
            Write-Progress -Activity "Removing Duplicates" -Status "$($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Prompting" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

            $Choice = -2;
            $Auto = $False;

            If ($Null -ne $Pattern -and $script:RegexRemoveWhenMatching.IsMatch($ItemA.Path.Name) -or $script:RegexRemoveWhenMatching.IsMatch($ItemB.Path.Name)) {
              $Choice = -1;
              $Auto = $True;
            } Else {
              Write-Host -Object "`$Pattern = $($Null -ne $Pattern)"
              Write-Host -Object "`$script:RegexRemoveWhenMatching = $($script:RegexRemoveWhenMatching.GetType().FullName)"
              Write-Host -Object "`$IsMatchA = $($script:RegexRemoveWhenMatching.IsMatch($ItemA.Path.Name))"
              Write-Host -Object "`$IsMatchB = $($script:RegexRemoveWhenMatching.IsMatch($ItemB.Path.Name))"
              $Choice = (Read-Host -Prompt "Remove which item?`n0: `"$($ItemA.Path.Name)`"`n1: `"$($ItemB.Path.Name)`"`n[0/1]");
            }

            If (($Choice -eq 0 -or $Choice -eq "0") -and $Auto -eq $False) {
              Write-Progress -Activity "Removing Duplicates" -Status "Removing - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Removing" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

              Invoke-RemoveItem -ItemA $ItemA -ItemB $ItemB -RemoveA -RegexRemoveWhenMatching $script:RegexRemoveWhenMatching

              $CountRemoved++;

              $ItemA.Removed = $True;

              [System.Console]::SetCursorPosition($ConsolePosition.X, $ConsolePosition.Y);

              $Done = $True;
            } ElseIf (($Choice -eq 1 -or $Choice -eq "1") -and $Auto -eq $False) {
              Write-Progress -Activity "Removing Duplicates" -Status "$($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

              Invoke-RemoveItem -ItemA $ItemA -ItemB $ItemB -RemoveB -RegexRemoveWhenMatching $script:RegexRemoveWhenMatching

              $CountRemoved++;

              $ItemB.Removed = $True;

              [System.Console]::SetCursorPosition($ConsolePosition.X, $ConsolePosition.Y);

              $Done = $True;
            } ElseIf (($Choice -eq -1 -or $Choice -eq "-1") -and $Auto -eq $True) {
              Write-Progress -Activity "Removing Duplicates" -Status "$($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);

              Invoke-RemoveItem -ItemA $ItemA -ItemB $ItemB -RegexRemoveWhenMatching $script:RegexRemoveWhenMatching

              $CountRemoved++;

              $ItemB.Removed = $True;

              [System.Console]::SetCursorPosition($ConsolePosition.X, $ConsolePosition.Y);
              $Done = $True;
            } Else {
              $Done = $True;
              Throw;
            }
          }
        }
      }

      $Index++;
    }
  }

  Write-Progress -Activity "Removing Duplicates" -Status "Finished - $($Index)/$($MaxCount) - $($Percent)%" -PercentComplete $Percent -CurrentOperation "Finished" -Completed -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
}
End {
  Write-Host -ForegroundColor Green -Object "Items removed: $($CountRemoved)" -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True);
}
Clean {
  Remove-Variable -Scope Script -Name "RegexRemoveWhenMatching";
}