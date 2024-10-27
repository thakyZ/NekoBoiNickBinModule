using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Update, "VSMPLauncher")]
public class UpdateVSMPLauncherCommand : Cmdlet {
}
/*
Param()

$UserAgent = 'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0';

$DownloadUri = "aHR0cHM6Ly93d3cuZHJvcGJveC5jb20vc2NsL2ZpL25nMHJwZHE1aGxwZHcyNW9jOTdjbC9WU01QTGF1bmNoZXItSW5zdGFsbGVyLmV4ZT9ybGtleT1tdXdzYXFmamt5anRmcG9pN2FseWpwemV2JmRsPTE=";

$DownloadUri = (ConvertFrom-Base64 -Base64 $DownloadUri -ToString);


$InstallPath = (Join-Path -Path "D:\" -ChildPath "Modding" -AdditionalChildPath @("Tools", "VintageStory", "VSMPLauncher"));
$DownloadPath = (Join-Path -Path $InstallPath -ChildPath "Downloads");
$DownloadFile = (Join-Path -Path $DownloadPath -ChildPath "Installer.exe");
$ExtractPath = $DownloadPath;

$ExcludePaths = @("Configs");
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

Invoke-WebRequest -Uri $DownloadUri -UserAgent $UserAgent -OutFile $DownloadFile;
Start-Process -NoNewWindow -FilePath $DownloadFile -ArgumentList @("/s", "/x", "/b`"$($ExtractPath)`"", "/v`"/qn`"") -Wait;
$MsiFile = "$((Get-ChildItem -Path $ExtractPath -Filter "*.msi")[0].FullName)"
$MsiExec = (Get-Command -Name "msiexec.exe" -ErrorAction Stop).Source
Start-Process -NoNewWindow -FilePath $MsiExec -ArgumentList @("/a `"$($MsiFile)`"", "/qb", "TARGETDIR=`"$($InstallPath)`"") -Wait;
$ExtractedDir = (Get-ChildItem -LiteralPath $InstallPath -Directory -Recurse -ErrorAction Stop | Where-Object { $_.Name -eq "Vintage Story Mod Pack Launcher" })[0].FullName;
Remove-Item -LiteralPath $DownloadPath -Recurse -ErrorAction Stop;
Remove-Item -LiteralPath (Get-ChildItem -LiteralPath $InstallPath -Filter "*.msi")[0].FullName -Recurse -ErrorAction Stop;
$Items = (Get-ChildItem -LiteralPath $ExtractedDir);
ForEach ($Item in $Items) {
  $Percent = "$([Math]::Ceiling(($Progress / $Items.Length) * 100))%";
  Move-Item -LiteralPath $Item.FullName -Destination $InstallPath;
  Write-HostOverLine -Object "Moving new files... $($Percent) - $($Progress) / $($Items.Length)"
}
$BadDirectory = $ExtractedDir.Replace($InstallPath, "").Split("\").Where({ $_ -ne "" })[0];
Remove-Item -LiteralPath (Get-Item -LiteralPath (Join-Path -Path $InstallPath -ChildPath "$($BadDirectory)")).FullName -Recurse -ErrorAction Stop;
*/
