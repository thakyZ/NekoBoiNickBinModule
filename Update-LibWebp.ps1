[CmdletBinding()]
Param()

Begin {
  Function Get-Versions {
    [CmdletBinding()]
    Param(
      # Specifies a list of string to extract the versions from.
      [Parameter(Mandatory = $True,
                Position = 0,
                HelpMessage = "A list of string to extract the versions from.")]
      [ValidateNotNullOrEmpty()]
      [System.String[]]
      $Hrefs
    )

    $AnchorVersionRegex = [System.Text.RegularExpressions.Regex]::new("\/libwebp-(\d+\.\d+\.\d+)-.+\.(?:zip|tar\.gz)$");
    [System.Collections.Generic.Dictionary[[System.Version],[System.String]]]$Output = (New-Object -TypeName "System.Collections.Generic.Dictionary[[System.Version],[System.String]]");
    [System.Collections.Generic.Dictionary[[System.Version],[System.String]]]$VersionList = (New-Object -TypeName "System.Collections.Generic.Dictionary[[System.Version],[System.String]]");

    ForEach ($Href in $Hrefs) {
      $Match = $AnchorVersionRegex.Match($Href);

      If ($Null -ne $Match -and $Null -ne $Match.Groups -and $Match.Groups.Length -gt 0) {
        $VersionList["$($Match.Groups[1].Value)"] = "https:$($Href)";
      }
    }
    ForEach ($Version in ($VersionList | Sort-Object -Unique).GetEnumerator()) {
      $Output[[System.Version]::new($Version.Key)] = $Version.Value;
    }

    Write-Output -NoEnumerate -InputObject $Output;
  }

  Function Add-Extensions() {
    Try {
      Add-Type -ErrorAction "Stop" -Language CSharp (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "Extensions.cs") -Raw);
    } Catch {
      If ($DebugPreference -ne "SilentlyContinue" -or $VerbosePreference -ne "SilentlyContinue") {
        Write-Error -ErrorRecord $_;
      }
      # Otherwise ignore.
    }
  }

  Function Find-LatestVersion {
    [CmdletBinding()]
    Param(
      # Specifies a list of version objects to find the latest of.
      [Parameter(Mandatory = $True,
                Position = 0,
                HelpMessage = "A list of version objects to find the latest of.")]
      [ValidateNotNullOrEmpty()]
      [System.Collections.Generic.List[System.Version]]
      $Versions
    )

    Add-Extensions;
    Return [NekoBoiNick.CSharp.AProgramDirectory.Bin.Extensions]::Max($Versions);
  }

  $UrlToFetchFrom = (ConvertFrom-Base64 -ToString -Base64 "aHR0cHM6Ly9zdG9yYWdlLmdvb2dsZWFwaXMuY29tL2Rvd25sb2Fkcy53ZWJtcHJvamVjdC5vcmcvcmVsZWFzZXMvd2VicC9pbmRleC5odG1s");
}
Process {
  Write-Host "Determining latest release..."

  [Microsoft.PowerShell.Commands.WebResponseObject]$Website = $Null

  Try {
    $Website = (Invoke-WebRequest -Uri "$($UrlToFetchFrom)" -SkipHttpErrorCheck -ErrorAction SilentlyContinue -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome));

    If ($Website.StatusCode -ne "200") {
      Throw [Microsoft.PowerShell.Commands.HttpResponseException]::new("Failed to get url `"$($UrlToFetchFrom)`" got status code $($Website.StatusCode)");
    }
  } Catch {
    Write-Error -Exception $_.Exception -Message $_.Exception.Message;
    Exit 1;
  }

  [Microsoft.PowerShell.Commands.WebResponseObject]$Download = $Null

  If ($Null -ne $Website) {
    Try {
      [System.Collections.Generic.Dictionary[[System.Version],[System.String]]]$Versions = (Get-Versions -Hrefs $Website.Links.href);
      [System.Version]$Latest = (Find-LatestVersion -Versions $Versions.Keys);
      $Download = (Invoke-WebRequest -Uri "$($Versions[$Latest])" -SkipHttpErrorCheck -ErrorAction SilentlyContinue -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -OutFile (Join-Path -Path $env:APROG_DIR -ChildPath "libwebp" -AdditionalChildPath @("libwebp.zip")) -PassThru);

      If ($Download.StatusCode -ne "200") {
        Throw [Microsoft.PowerShell.Commands.HttpResponseException]::new("Failed to get url `"$($Versions[$Latest])`" got status code $($Download.StatusCode)");
      } Else {
        Push-Location (Join-Path -Path $env:APROG_DIR -ChildPath "libwebp");
        Expand-Archive -Path (Join-Path -Path $env:APROG_DIR -ChildPath "libwebp" -AdditionalChildPath @("libwebp.zip")) -Force;
        Pop-Location;
      }
    } Catch {
      Write-Error -Exception $_.Exception -Message $_.Exception.Message;
      Exit 1;
    }
  }
}
End {
  Exit 0;
}