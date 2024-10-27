using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Update, "VSUpdater")]
public class UpdateVSUpdaterCommand : Cmdlet {
}
/*
Param()

$UserAgent = 'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0';

$DownloadUri = "aHR0cHM6Ly9tb2RzLnZpbnRhZ2VzdG9yeS5hdC9tb2RzdXBkYXRlcg==";

$DownloadUri = (ConvertFrom-Base64 -Base64 $DownloadUri -ToString);

$InstallPath = (Join-Path -Path "D:\" -ChildPath "Modding" -AdditionalChildPath @("Tools", "VintageStory", "VS_ModsUpdater"));
$DownloadPath = (Join-Path -Path $InstallPath -ChildPath "Downloads");
$ExtractPath = $DownloadPath;

$ExcludePaths = @("config.ini");
$Items = (Get-ChildItem -LiteralPath $InstallPath -ErrorAction SilentlyContinue -Exclude $ExcludePaths);
$Progress = 0;
$Percent = 0;

Function Write-HostOverLine() {
  Param(
    # The Object to write over the original line.
    [Parameter(Position = 0, Mandatory = $True)]
    [Object]
    $Object,
    # Foreground color to write the line with
    [Parameter(Position = 0, Mandatory = $False)]
    [ValidateSet("Black", "Blue", "Cyan", "DarkBlue", "DarkCyan", "DarkGray", "DarkGreen", "DarkMagenta", "DarkRed", "DarkYellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
    [string]
    $ForegroundColor = "Yellow"
  )

  $CursorLeft = [System.Console]::CursorLeft;
  $CursorTop = [System.Console]::CursorTop;
  Write-Host -Object $Object -ForegroundColor $ForegroundColor;
  [System.Console]::CursorLeft = $CursorLeft;
  [System.Console]::CursorTop = $CursorTop;
}

ForEach ($Item in $Items) {
  $Percent = "$([Math]::Ceiling(($Progress / $Items.Length) * 100))%";
  If (Test-Path -LiteralPath $Item.FullName -PathType Container) {
    Write-HostOverLine -Object "Removing old files... $($Percent) - $($Progress) / $($Items.Length)"
    Remove-Item -LiteralPath $Item.FullName -ErrorAction Stop -Recurse;
  } Else {
    Write-HostOverLine -Object "Removing old files... $($Percent) - $($Progress) / $($Items.Length)"
    Remove-Item -LiteralPath $Item.FullName -ErrorAction Stop;
  }
  $Progress++;
}

$Progress = 0;

If (-not (Test-Path -LiteralPath $DownloadPath -PathType Container)) {
  New-Item -Path $DownloadPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null;
}

Function Get-DownloadFile() {
  Param(
    # Specifies the uri of the download page.
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Uri of the download page.")]
    [string]
    $Uri,
    # Specifies the position in the list to download.
    [Parameter(Mandatory = $False, Position = 1, HelpMessage = "Position in the list to download.")]
    [int]
    $DownloadIndex = 0
  )

  $Web = $Null;
  $DownloadFile = $Null;
  $DownloadDomain = $Null;
  $_DownloadPath = $DownloadPath;
  $NewUri = $Null;
  $Web2 = $Null;
  Try {
    $Web = (Invoke-WebRequest -UserAgent $UserAgent -Uri $Uri)
    $DownloadDomain = $Web.BaseResponse.RequestMessage.RequestUri.GetLeftPart([System.UriPartial]::Authority).ToString();
    $DownloadFile = $Web.Links.Where({ $_ -match "<a class=`"downloadbutton`" href=`"\/download\?fileid=" });
    If ($DownloadFile.Length -eq 0) {
      Throw "Download links were not found."
    }
    $Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/jxl,image/webp,*\/*;q=0.8"; # "application/octet-stream";
    $AcceptEncoding = "gzip, deflate, br"; # "binary";
    $DownloadFile = $DownloadFile[0].outerHTML.Split(">")[1].Split("<")[0]
    $_DownloadPath = (Join-Path -Path $DownloadPath -ChildPath $DownloadFile);
    $NewUri = "$($DownloadDomain)$($Web.Links.Where({ $_ -match '<a class=`"downloadbutton`" href=`"\/download\?fileid=' })[0].href)";
    $Web2 = (Invoke-WebRequest -UserAgent $UserAgent -Uri $NewUri -PassThru -OutFile $_DownloadPath -Headers @{ Referer = "$($Web.BaseResponse.RequestMessage.RequestUri)"; Host = "$($Web.BaseResponse.RequestMessage.RequestUri.Host)"; Accept = $Accept; "Accept-Encoding" = $AcceptEncoding });
  } Catch {
    Write-Error -Exception $_.Exception -Message $_.Exception.Message | Out-Host;
    Write-Output @{ Error = $True; Arguments = @($Uri, $DownloadIndex); WebFetch = $Web; DownloadFile = (Get-Item -Path $_DownloadPath -ErrorAction SilentlyContinue); DownloadDomain = $DownloadDomain; NewUri = $NewUri; WebDownload = $Web2 };
    Throw;
  }
  Return @{ Error = $False; Arguments = @($Uri, $DownloadIndex); WebFetch = $Web; DownloadFile = (Get-Item -Path $_DownloadPath -ErrorAction SilentlyContinue); DownloadDomain = $DownloadDomain; NewUri = $NewUri; WebDownload = $Web2 };
}

$Web = (Get-DownloadFile -Uri $DownloadUri);

If ($Web.Error -eq $True) {
  Write-Output $Web;
  Exit 1;
}

$DownloadFile = $Web.DownloadFile;

If ($DownloadFile.Extension -eq ".zip") {
  Try {
    Expand-Archive -LiteralPath $DownloadFile -DestinationPath $ExtractPath | Out-Null;
  } Catch {
    Write-Error -Exception $_.Exception -Message $_.Exception.Message;
    Write-Output $Web;
    Exit 1;
  }
} Else {
  Write-Error -Message "Download file was not the expected extension `".zip`" please contact the author of this script.";
  Exit 1;
}

Remove-Item -LiteralPath $DownloadFile -ErrorAction Stop;

$ExtractedDir = (Get-ChildItem -LiteralPath $ExtractPath -Directory);

If ($ExtractedDir.Length -eq 0) {
  Write-Error -Message "Did not find extracted directory, please contact the author of this script..";
  Exit 1;
}

$Items = (Get-ChildItem -LiteralPath $ExtractedDir[0]);

ForEach ($Item in $Items) {
  $Percent = "$([Math]::Ceiling(($Progress / $Items.Length) * 100))%";
  Write-HostOverLine -Object "Removing old files... $($Percent) - $($Progress) / $($Items.Length)"
  Move-Item -Path $Item.FullName -Destination $InstallPath -ErrorAction Stop;
  $Progress++;
}
Remove-Item -LiteralPath $DownloadPath -Recurse -ErrorAction Stop;
*/
