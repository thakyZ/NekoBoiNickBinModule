using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "Browser")]
public class GetBrowserCommand : Cmdlet  {
}
/*
Param(
  # Specifies the type of browser to download
  [Parameter(Mandatory = $True,
    Position = 0,
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "The type of browser to download.")]
  [Alias("Type", "BrowserType")]
  [ValidateSet("Brave", "FireFox", "WaterFox", "Chrome")]
  [string]
  $Browser,
  # Specifies the path to download the browser to
  [Parameter(Mandatory = $False,
    Position = 1,
    ValueFromPipeline = $True,
    ValueFromRemainingArguments = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "The path to download the browser to.")]
  [Alias("PSPath", "Destination", "OutFile", "File")]
  [string[]]
  $Path
)

[string[]]$Destinations = @();
If ($Path.Length -ne 0 -or -not ([string]::IsNullOrEmpty($Path))) {
  If ($Path.GetType() -eq "[string]") {
    If (Test-Path -Path $Path -PathType Container) {
      $Path = (Join-Path -Path $Path -ChildPath "browser.exe")
    }
    [string[]]$Destinations += $Path;
  } ElseIf ($Path.GetType() -eq "[string[]]") {
    [string[]]$Destinations = $Path;
  }
} Else {
  [string[]]$Destinations = (Join-Path -Path (Get-Item -LiteralPath $PWD).FullName -ChildPath "browser.exe");
}

If ($Browser -eq "Brave") {
  $DownloadPageUri = "https://brave.com/download/";
  Try {
    If ($PSVersionTable.PSVersion.Major -gt 5) {
      $DownloadPage = (Invoke-WebRequest -Uri $DownloadPageUri -SkipHttpErrorCheck -ErrorAction SilentlyContinue);
    } Else {
      $DownloadPage = (Invoke-WebRequest -Uri $DownloadPageUri -ErrorAction SilentlyContinue);
    }
    If ($DownloadPage.StatusCode -ne 200) {
      Write-Error -Message "Download of page $($DownloadPageUri) returned status code $($DownloadPage.StatusCode)";
    } Else {
      $Matches = [Regex]::Matches(($DownloadPage.Links | Where-Object { Return $_.outerHTML -match "^<a id=`"download-page-download-button-hero`"" }).outerHTML, "[\w\-]+=\`"[a-zA-Z0-9\/\:\-\.\\\ ]*?\`"");
      $LastMatch = $Matches | Where-Object { $_.Value.ToLower().StartsWith("href") } | Select-Object -Last 1;
      $DownloadUri = [Regex]::Replace($LastMatch.Value, "(?:^href=\`"|\`"$)", "");
      Try {
        Invoke-WebRequest -Uri $DownloadUri -OutFile $Destinations[0];
        If ($Destinations.Length -gt 1) {
          ForEach ($Destination in $Destinations) {
            If ($Destination -eq $Destinations[0]) {
              Continue;
            }
            Copy-Item -Path $Destinations[0] -Destination $Destination;
          }
        }
      } Catch {
        Write-Output -InputObject $Matches | Out-Host;
        Write-Output -InputObject $LastMatch | Out-Host;
        Write-Host -Object $DownloadUri;
        Throw;
      }
    }
  } Catch {
    Write-Error -Exception $_.Exception -Message $_.Exception.Message;
    If ($Null -ne $_.Exception.InnerException) {
      Write-Error -Exception $_.Exception.InnerException -Message $_.Exception.InnerException.Message;
      If ($Null -ne $_.Exception.InnerException.InnerException) {
        Write-Error -Exception $_.Exception.InnerException.InnerException -Message $_.Exception.InnerException.InnerException.Message;
      }
    }
    Write-Output $_.Exception.InnerException.InnerException.StackTrace | Out-Host;
    Throw;
  }
} Else {
  throw [System.NotImplementedException]::new("Browser of type $($Browser) not yet implemented.")
}
*/
