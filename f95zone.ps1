[CmdletBinding(DefaultParameterSetName = "PSPath")]
Param(
  # Specifies a path to one location.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "PSPath",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Path to one location.")]
  [Alias("PSPath", "LiteralPath")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path = $PWD
)

Begin {
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
      Return ($Access -and -not (Test-Path -Path $VersionFile -PathType Leaf));
    }
  }
  $FilteredItems = ($Items | Where-Object { Return (Get-FilterItem -Item $_); });
  $Names = ($FilteredItems.Name);
  $JsonList = ($Names | ConvertTo-Json);
  $NewJsonString = "{`n  `"to_be_versioned`":$($JsonList)`n}";
  $LastMatch = $Null;
  $Json = ($NewJsonString | ConvertFrom-Json -Depth 100);

  ForEach ($Item in $Json.to_be_versioned) {
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
    $TestForVersion = ((($WebRequest2.Content -replace "\r?\n", "`n" -split "`n") | Select-String -Pattern "Version: (.*?)(?=\\n)")[0] -match "Version: (.*?)(?=\\n)");
    If (-not $TestForVersion) {
      Throw "$((($WebRequest2.Content -replace "\r?\n", "`n" -split "`n") | Select-String -Pattern "Version: (.*?)(?=\\n)")[0])";
    }

    $Match = $Matches;

    If ($Null -ne $LastMatch -and $LastMatch[0] -eq $Match[0]) {
      Throw "`$LastMatch matched `$Match";
    } ElseIf ($Null -ne $LastMatch) {
      Write-Host "`$LastMatch = $($LastMatch[1])" | Out-Host;
      Write-Output -InputObject $LastMatch | Out-Host;
    }

    $LastMatch = $Match;
    $Version = $Match[1];
    Write-Host "`$Match = $($Version)" | Out-Host;

    If ($Null -eq $Version -or $Version -eq "" -or $Version -match '^\s+$') {
      Throw "No Version Found."
    }

    If (-not (Test-Path -LiteralPath (Join-Path -Path $Path -ChildPath $Item) -PathType Container)) {
      Throw "Item at `"$Item`" not found";
    } Else {
      If (-not (Test-Path -LiteralPath (Join-Path -Path $Path -ChildPath $Item -AdditionalChildPath @(".version")) -PathType Leaf)) {
        New-Item -Path (Join-Path -Path $Path -ChildPath $Item -AdditionalChildPath @(".version")) -ItemType File -Value "$Version"
      } Else {
        $Content = (Get-Content -Path (Join-Path -Path $Path -ChildPath $Item -AdditionalChildPath @(".version")));
        If ($Content -ne $Version) {
          Write-Host -ForegroundColor Yellow -Object "Updating version from $Content to $Version";
          $Prompt = (Read-Host -Prompt "Press ^C to close or T to skip or S for a custom version or any key to continue.");
          If ($Prompt.ToLower() -eq "t") {
            Continue;
          } ElseIf ($Prompt.ToLower() -eq "s") {
            $PromptNewVersion = (Read-Host -Prompt "New Version");
            If (-not [System.String]::IsNullOrEmpty($PromptNewVersion) -and -not [System.String]::IsNullOrWhiteSpace(($PromptNewVersion))) {
              $Version = $PromptNewVersion;
              Write-Host -ForegroundColor Yellow -Object "Updating version from $Content to $Version";
            }
          }
          Set-Content -Path (Join-Path -Path $Path -ChildPath $Item -AdditionalChildPath @(".version")) -Value "$Version" -ErrorAction Break;
        }
      }
    }
  }
}
End {

}
Clean {

}