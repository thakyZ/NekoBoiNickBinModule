using namespace System;
using namespace System.IO;
[CmdletBinding(DefaultParameterSetName = "PSPath")]
Param(
  # Specifies a path to one location.
  [Parameter(Mandatory = $False,
             Position = 0,
             ParameterSetName = "PSPath",
             ValueFromPipeline = $True,
             HelpMessage = "Path to one location.")]
  [Alias("PSPath", "LiteralPath")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path = $PWD
)

Begin {
  [FileSystemInfo[]] $Items = (Get-ChildItem -Path $Path -Directory);

  If ($PSBoundParameters.Contains("Debug")) {
    $DebugPreference = "Continue";
  }

  $Path = (Get-Item -LiteralPath $Path)
  $Items = (Get-ChildItem -Path $Path -Directory);
}
Process {
  Function Get-FilterItem {
    [CmdLetBinding(DefaultParameterSetName = "Item")]
    Param(
      # Specifies an item to filter.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ParameterSetName = "Item",
                 ValueFromPipeline = $True,
                 ValueFromPipelineByPropertyName = $True,
                 HelpMessage = "An item to filter.")]
      [ValidateNotNullOrEmpty()]
      [System.IO.FileSystemInfo]
      $Item
    )

    Begin {
      $Access = $True;
      $VersionFile = (Join-Path -Path $Item.FullName -ChildPath ".version");
    }
    Process {
      Try {
        Get-ChildItem -Path $Item.FullName -ErrorAction Stop;
      } Catch {
        $Access = $False;
      }
    }
    End {
      Write-Output -NoEnumerate -InputObject ($Access -and -not (Test-Path -Path $VersionFile -PathType Leaf));
    }
  }
  Function Write-DebugWrapper {
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0)]
      [System.String[]]
      $Message
    )

    If ($DebugPreference -ne "SilentlyContinue") {
      Write-Host -Object $Message | Out-Host;
    }
  }

  $FilteredItems = ($Items | Where-Object {
    $____Test=(Get-ChildItem -Path $_.FullName -ErrorAction SilentlyContinue);
    $Access=$($____Test -ne $Null);
    $Exists=(Test-Path -Path (Join-Path -Path "$($_.FullName)" -ChildPath ".version") -PathType Leaf);
    $Test=($Access -and -not $Exists);
    Write-DebugWrapper "`$Test=`"$($Test)`"";
    Return $Test;
  });

  Write-DebugWrapper "`$FilteredItems.Length=`"$($FilteredItems.Length)`"";

  [string[]] $Names = ($FilteredItems.Name);
  [string] $JsonList = ($Names | ConvertTo-Json);
  [string] $NewJsonString = "{`"ToBeVersioned`":$($JsonList),`"Versioned`":[]}";
  $LastMatch = $Null;
  $Json = ($NewJsonString | ConvertFrom-Json);

  If ($DebugPreference -ne "SilentlyContinue") {
    $Json | Out-File -FilePath "$PWD\test.json";
  }

  ForEach ($Item in $Json.ToBeVersioned) {
    Write-Host -Object "$Item";

    $Spaced = ($Item -replace '_EN|_Grim.+', '' -replace '_', ' ' -replace '(Queen|Tessa|Vampire)s', '$1' -replace 'LAB2UG', 'LAB2');

    $Converted = ([System.Web.HttpUtility]::UrlEncode($Spaced) -replace '\+', '%20' -split '-')[0];

    If (($Spaced -split '-')[0] -match ' ' -and $Converted -notmatch '%20') {
      Throw "Did not encode correctly `"$($Converted)`"";
    }

    Try {
      $WebRequest = (Invoke-WebRequest -Uri "https://f95zone.to/sam/latest_alpha/latest_data.php?cmd=list&cat=games&page=1&search=$($Converted)" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -Headers $Headers -SkipHttpErrorCheck -ErrorAction SilentlyContinue);
      If ($WebRequest.StatusCode -ne 200) {
        Throw "Failed with code $($WebRequest.StatusCode).";
      }
    } Catch {
      Throw $_;
    }

    $ApiJson=($WebRequest.Content | ConvertFrom-Json);

    If ($ApiJson.status -ne "ok") {
      Throw "Api returned status `"$($ApiJson.status)`"";
    } ElseIf ($Null -eq $ApiJson.msg) {
      Throw "Api returned to not have block `"msg`"";
    } ElseIf ($Null -eq $ApiJson.msg.data) {
      Throw "Api returned to not have block `"msg.data`"";
    } ElseIf ($ApiJson.msg.data.Length -eq 0) {
      Throw "Api returned to have no search results.";
    }

    $Url="https://f95zone.to/threads/$($ApiJson.msg.data[0].thread_id)/"

    If ($Url -eq "" -or $Null -eq $Url -or $Url -match "^\s+$") {
      Throw "Url not found";
    }

    Try {
      $WebRequest2=(Invoke-WebRequest -Uri "$($Url)" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -Headers $Headers -SkipHttpErrorCheck -ErrorAction SilentlyContinue);
      If ($WebRequest.StatusCode -ne 200) {
        Throw "Failed with code $($WebRequest.StatusCode).";
      }
    } Catch {
      Throw $_;
    }
    $VersionMatch = (($WebRequest2.Content -replace "\r?\n", "`n" -split "`n") | Select-String -Pattern "Version: (.*?)(?=\\n)")[0]
    $TestForVersion=($VersionMatch -match "Version: (.*?)(?=\\n)");

    If (-not $TestForVersion) {
      Throw "$((($WebRequest2.Content -replace "\r?\n", "`n" -split "`n") | Select-String -Pattern "Version: (.*?)(?=\\n)")[0])";
    }

    $Match=$Matches;

    If ($Null -ne $LastMatch -and $LastMatch[0] -eq $Match[0]) {
      Throw "`$LastMatch matched `$Match";
    } ElseIf ($Null -ne $LastMatch) {
      Write-Host "`$LastMatch = " | Out-Host;
      Write-Output -InputObject $LastMatch | Out-Host;
    }

    $LastMatch = $Match;
    $Version = $Match[1];

    Write-Host "`$Match = " | Out-Host;
    Write-Output -InputObject $Match | Out-Host;

    If ($Null -eq $Version -or $Version -eq "" -or $Version -match '^\s+$') {
      Throw "No Version Found."
    }

    $GameDirectory = (Join-Path -Path $PWD -ChildPath $Item);
    $GameVersionFile = (Join-Path -Path $GameDirectory -ChildPath ".version");
    If (-not (Test-Path -LiteralPath $GameDirectory -PathType Container)) {
      Throw "Item at `"$Item`" not found";
    } Else {
      If (-not (Test-Path -LiteralPath $GameVersionFile -PathType Leaf)) {
        New-Item -Path $GameVersionFile -ItemType File -Value "$Version"
      } Else {
        $Content=(Get-Content -Path $GameVersionFile);

        If ($Content -ne $Version) {
          Write-Host -ForegroundColor Yellow -Object "Updating version from $Content to $Version";
          $Prompt=(Read-Host -Prompt "Any Key to continue or ^C to close or T to skip");

          If ($Prompt.ToLower() -eq "t") {
            Continue;
          } ElseIf ($Prompt.ToLower() -eq "s") {
            $PromptNewVersion = (Read-Host -Prompt "New Version");
            If (-not [System.String]::IsNullOrEmpty($PromptNewVersion) -and -not [System.String]::IsNullOrWhiteSpace(($PromptNewVersion))) {
              $Version = $PromptNewVersion;
              Write-Host -ForegroundColor Yellow -Object "Updating version from $Content to $Version";
            }
          }

          Set-Content -Path $GameVersionFile -Value "$Version";
        }
      }
    }
    #Break;
  }
}
End {
}
Clean {
}