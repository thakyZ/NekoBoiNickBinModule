[CmdletBinding()]
Param()
# cSpell:ignoreRegExp /Neko(?=BoiNick)/
# cSpell:ignoreRegExp /(?<=Neko)Boi(?=Nick)/
$script:OldConsoleMethod = $True;
$script:DryRun = $True;
$script:Debug = $PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True;
$script:Old = $False;
If ($script:Old -eq $False) {
  [System.String]$Code = (Get-Content -Encoding UTF8BOM -Path (Join-Path -Path $PSScriptRoot -ChildPath "Sort_ItemsInU.cs") -Raw);
  Add-Type -Language CSharp -TypeDefinition @"
$($Code)
"@;
  $Temp = [NekoBoiNick.ProgramFiles.Bin.SortItemsInU]::new($script:Debug, $script:DryRun, $script:OldConsoleMethod);
  $Temp.Run();
} Else {
  $ProcessingDir = (Join-Path -Path $HOME -ChildPath "Downloads" -AdditionalChildPath @("u"));
  $Folders = (Get-ChildItem -Path $ProcessingDir -Directory)
  $Items = (Get-ChildItem -Path $ProcessingDir -File | `
            Where-Object {
              Return $_.BaseName -match "^[^-]+-";
            } | Select-Object -Property FullName,Name,BaseName,@{ `
              Name = "PotentialArtistName"; Expression={
                $Test = $_.BaseName.Split("-")[0];
                If ($Test -ne $_.BaseName -and $Test -notmatch "[\(\)\[\]\{\} \-_\/\\]" -and $_.Extension -ne ".zip") {
                  Return $Test;
                }
                Return $Null;
              }
            },@{
              Name = "PotentialArtistNameOther";
              Expression = {
                $Test = $_.BaseName.Split("_")[0];
                If ($Test -ne $_.BaseName -and $Test -notmatch "[\(\)\[\]\{\} \-_\/\\]" -and $_.Extension -ne ".zip") {
                  Return $Test;
                }
                Return $Null
              }
            }
           );
  Function Write-DebugOver {
    [CmdletBinding()]
    Param(
      [System.Object[]]
      $Message
    )
    If ($script:Debug) {
      $TemplateString = "Debug: ";
      If ($Message.GetType() -eq [System.Object[]]) {
        $TemplateString += "$([System.String]::Join(" ", $Message))"
      } Else {
        $TemplateString += "$($Message)"
      }
      $OriginalConsolePosition = (Get-ConsolePosition -NoDebug);
      $TempConsolePosition = (Get-ConsolePosition -NoDebug);
      $TempConsolePosition.X = ([System.Console]::WindowWidth - $TemplateString.Length);
      Set-ConsolePosition -Coordinates $TempConsolePosition -NoDebug;
      If ($Message.GetType() -eq [System.Object[]]) {
        Write-Host -Object "Debug: " -ForegroundColor Blue -NoNewline;
        ForEach ($Item in $Message) {
          Write-Host -Object "$($Item) " -ForegroundColor White -NoNewline;
        }
      } Else {
        Write-Host -Object "Debug: " -ForegroundColor Blue -NoNewline;
        Write-Host -Object "$($Message)" -ForegroundColor White;
      }
      Set-ConsolePosition -Coordinates $OriginalConsolePosition -NoDebug;
    }
  }
  Function Get-ConsolePosition {
    [CmdletBinding()]
    Param(
      [switch]
      $NoDebug = $False
    )
    If ($script:OldConsoleMethod) {
      $x, $y = [Console]::GetCursorPosition() -split '\D' -ne '' -as 'int[]'
      If ($NoDebug -eq $False) {
        Write-DebugOver -Message @($x, $y)
      }
      Return @{ X = $x; Y = $y; }
    } Else {
      $x = [System.Console]::CursorLeft;
      $y = [System.Console]::CursorTop;
      If ($NoDebug -eq $False) {
        Write-DebugOver -Message @($x, $y)
      }
      Return @{ X = $x; Y = $y; }
    }
  }
  Function Set-ConsolePosition {
    Param(
      # Specifies a PSObject that contains the coordinates to adjust the console position to.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromRemainingArguments = $True,
                 HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
      [PSCustomObject]
      $Coordinates,
      [switch]
      $NoDebug = $False
    )
    If ($NoDebug -eq $False) {
      Write-DebugOver -Message @($Coordinates.X, $Coordinates.Y)
    }
    If ($script:OldConsoleMethod) {
      [System.Console]::SetCursorPosition($Coordinates.X, $Coordinates.Y);
      If ($NoDebug -eq $False) {
        $x, $y = [Console]::GetCursorPosition() -split '\D' -ne '' -as 'int[]'
        Write-DebugOver -Message @($x, $y)
      }
    } Else {
      [System.Console]::CursorLeft = $Coordinates.X;
      [System.Console]::CursorTop = $Coordinates.Y;
      If ($NoDebug -eq $False) {
        $x = [System.Console]::CursorLeft;
        $y = [System.Console]::CursorTop;
        Write-DebugOver -Message @($x, $y)
      }
    }
  }
  Function Clear-ConsoleInArea {
    Param(
      # Specifies a PSObject that contains the coordinates to adjust the console position to.
      [Parameter(Mandatory = $True,
                Position = 0,
                ValueFromRemainingArguments = $True,
                HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
      [PSCustomObject]
      $CoordinatesStart,
      # Specifies a PSObject that contains the coordinates to adjust the console position to.
      [Parameter(Mandatory = $True,
                Position = 1,
                ValueFromRemainingArguments = $True,
                HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
      [PSCustomObject]
      $CoordinatesEnd,
      [switch]
      $NoDebug = $False
    )
    $Rectangle = @{ X = 0; Y = $CoordinatesStart.Y; Width = ([System.Console]::WindowWidth); Height = ($CoordinatesStart.Y - $CoordinatesEnd.Y); Start = @{ X = 0; Y = $CoordinatesStart.Y }; Size = @{ Width = ([System.Console]::WindowWidth); Height = ($CoordinatesStart.Y - $CoordinatesEnd.Y); } };
    Set-ConsolePosition -Coordinates @{ X = 0; Y = $CoordinatesStart.Y; } -NoDebug;
    If ($NoDebug -eq $False) {
      Write-Host [System.String]::new("", ($Rectangle.Width * $Rectangle.Height));
    }
    Set-ConsolePosition -Coordinates $CoordinatesStart;
  }
  $ConsolePosition = @{ X = 0; Y = 0; };
  $ConsolePositionInter1 = @{ X = 0; Y = 0; };
  $ConsolePositionInter2 = @{ X = 0; Y = 0; };
  $ConsolePosition = Get-ConsolePosition
  ForEach ($Item in $Items) {
    Set-ConsolePosition $ConsolePosition;
    $HasCurrentDirectory = @($False, $Null);
    $DisableOption2 = $False;
    If ($Folders.Name -contains $Item.PotentialArtistName -and ([System.String]::IsNullOrEmpty($Item.PotentialArtistName) -or [System.String]::IsNullOrWhiteSpace($Item.PotentialArtistName))) {
      $HasCurrentDirectory = @($True, $Item.PotentialArtistName);
    } ElseIf ($Folders.Name -contains $Item.PotentialArtistNameOther -and ([System.String]::IsNullOrEmpty($Item.PotentialArtistNameOther) -or [System.String]::IsNullOrWhiteSpace($Item.PotentialArtistNameOther))) {
      $HasCurrentDirectory = @($True, $Item.PotentialArtistNameOther);
    } ElseIf (([System.String]::IsNullOrEmpty($Item.PotentialArtistName) -or [System.String]::IsNullOrWhiteSpace($Item.PotentialArtistName)) -and ([System.String]::IsNullOrEmpty($Item.PotentialArtistNameOther) -or [System.String]::IsNullOrWhiteSpace($Item.PotentialArtistNameOther)) -and $Folders.Name -notcontains $Item.PotentialArtistNameOther -and $Folders.Name -notcontains $Item.PotentialArtistName) {
      $DisableOption2 = $True;
    }
    Write-Host -Object "Info:";
    Write-Output -InputObject $Item | Out-Host;
    Write-Host -Object "Choose an option:"
    Write-Host -Object " - 0: Make New Directory";
    Write-Host -Object " - 1: Move into directory $($HasCurrentDirectory[1])";
    Write-Host -Object " - 2: Skip";
    Write-Host -Object " - 3: Other";
    $Choice = $Null;
    $ConsolePositionInter1 = Get-ConsolePosition
    While ($Choice -notmatch "[0-3]" -and ($Choice -ne "2" -and $DisableOption2 -ne $True)) {
      Set-ConsolePosition -Coordinates $ConsolePositionInter1;
      $Choice = (Read-Host -Prompt "[0/1/2/3]");
    }
    If ($Choice -eq "0") {
      $NewDirName = (Read-Host -Prompt "New Folder Name?");
      If (-not (Test-Path -Path (Join-Path -Path $ProcessingDir -ChildPath $NewDirName) -PathType Container)) {
        If ($script:DryRun) {
          Write-Host -Object "Making new directory at $(Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1])" -ForegroundColor Yellow;
        } Else {
          New-Item -ItemType Directory -Path (Join-Path -Path $ProcessingDir -ChildPath $NewDirName);
        }
      }
      $RelativePath = (Resolve-Path -Path (Join-Path -Path $ProcessingDir -ChildPath $NewDirName) -Relative -RelativeBasePath $ProcessingDir -ErrorAction SilentlyContinue);
      $ChoiceInter = $Null;
      $ConsolePositionInter2 = Get-ConsolePosition
      While ($ChoiceInter -notmatch "[yn]") {
        Set-ConsolePosition -Coordinates $ConsolePositionInter2;
        $ChoiceInter = (Read-Host -Prompt "Move item into $($RelativePath)? [y/N]").ToLower();
      }
      If ($ChoiceInter -eq "y") {
        If ($script:DryRun) {
          Write-Host -Object "Moving $($Item.Fullname) to Destination $(Join-Path -Path $ProcessingDir -ChildPath $NewDirName -AdditionalChildPath @($Item.BaseName))" -ForegroundColor Yellow;
        } Else {
          Move-Item -Path $Item.FullName -Destination (Join-Path -Path $ProcessingDir -ChildPath $NewDirName -AdditionalChildPath @($Item.BaseName))
        }
      } ElseIf ($ChoiceInter -eq "n") {
        Write-Host -Object "Skipping...";
      } Else {
        Throw "Failed with unknown choice `"$($ChoiceInter)`"";
      }
      $ChoiceInter = $Null;
    } ElseIf ($Choice -eq "1") {
      If (-not (Test-Path -Path (Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1]) -PathType Container)) {
        If ($script:DryRun) {
          Write-Host -Object "Making new directory at $(Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1])" -ForegroundColor Yellow;
        } Else {
          New-Item -ItemType Directory -Path (Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1]);
        }
      }
      $RelativePath = (Resolve-Path -Path (Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1]) -Relative -RelativeBasePath $ProcessingDir -ErrorAction SilentlyContinue);
      $ChoiceInter = $Null;
      $ConsolePositionInter2 = Get-ConsolePosition
      While ($ChoiceInter -notmatch "[yn]") {
        Set-ConsolePosition -Coordinates $ConsolePositionInter2;
        $ChoiceInter = (Read-Host -Prompt "Move item into $($RelativePath)? [y/N]").ToLower();
      }
      If ($ChoiceInter -eq "y") {
        If ($script:DryRun) {
          Write-Host -Object "Moving $($Item.Fullname) to Destination $(Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1] -AdditionalChildPath @($Item.BaseName))" -ForegroundColor Yellow;
        } Else {
          Move-Item -Path $Item.FullName -Destination (Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1] -AdditionalChildPath @($Item.BaseName))
        }
      } ElseIf ($ChoiceInter -eq "n") {
        Write-Host -Object "Skipping...";
      } Else {
        Throw "Failed with unknown choice `"$($ChoiceInter)`"";
      }
      $ChoiceInter = $Null;
    } ElseIf ($Choice -eq "2") {
      Write-Host -Object "Skipping...";
    } ElseIf ($Choice -eq "3") {
      Write-Host -Object "Not Yet Implemented";
    } Else {
      Throw "Failed with unknown choice `"$($Choice)`"";
    }
    $Choice = $Null;
    $EndConsolePosition = Get-ConsolePosition
    Clear-ConsoleInArea -CoordinatesStart $ConsolePosition -CoordinatesEnd $EndConsolePosition;
    Set-ConsolePosition $ConsolePosition;
  }
}