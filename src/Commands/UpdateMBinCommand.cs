using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Update, "MBin")]
public class UpdateMBinCommand : Cmdlet {
}
/*
param()  $repo = "monkeyman192/MBINCompiler"  $releases = "https://api.github.com/repos/${repo}/releases"  $DownloadDest = "D:\Modding\Tools\NoMansSky\MBINCompiler"  Write-Host "Determining latest release..." $repoData = (Invoke-WebRequest "${releases}" | ConvertFrom-Json)[0].assets  $filesToDownloadApi = @() $filesToDownload    = @() $fileNames = @()  $repoData | ForEach-Object {$filesToDownloadApi += $_.url}  $filesToDownloadApi | ForEach-Object {   $data = (Invoke-WebRequest $_ | ConvertFrom-Json)   $filesToDownload += $data.browser_download_url   $fileNames += $data.name }  Write-Host "Dowloading latest release..."  for ($i = 0; $i -lt $filesToDownload.length; $i++) {   $fileName = $fileNames[$i]   Invoke-WebRequest $filesToDownload[$i] -Out "${DownloadDest}\${fileName}" }
*/
