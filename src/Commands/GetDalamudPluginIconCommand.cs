using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "DalamudPluginIcon")]
public class GetDalamudPluginIconCommand : Cmdlet {
}
/*
[CmdletBinding()] Plugin(   # Specifies   [Parameter(Mandatory = $True,              Position = 0,              ValueFromPipeline = $True,              HelpMessage = "")]   [ValidateNotNullOrEmpty()]   [System.String]   $Plugin,   # Specifies   [Parameter(Mandatory = $False,              Position = 1,              HelpMessage = "")]   [Alias("Destination")]   [System.String]   $OutFile = $PWD )  DynamicParam {   Function Test-IsFilePath {     [CmdletBinding()]     Param(            )   }      $XIVLauncherPath = (Join-Path -Path $env:AppData -ChildPath "XIVLauncher");   $InstalledPluginsPath = (Join-Path -Path $XIVLauncher -ChildPath "installedPlugins");   $InstalledPlugins = (Get-ChildItem -LiteralPath $InstalledPluginsPath -Directory);   $InstalledPlugins | ForEach-Object {     $PluginVersions = (Get-ChildItem -LiteralPath $_ -Directory | Select-Object -Property @(         @{Name="Name";Expression={$_.Name}},         @{Name="FullName";Expression=@{$_.FullName}},         @{Name="Version";Expression={[System.Version]::Parse($_.Name)}}       ) | Sort-Object -Property Version);     $PluginManifests = (Get-ChildItem -LiteralPath ($PluginVersions | Select-Object -Last 1) -File -Filter '.json' | Where-Object { $Null -ne (Get-Content -LiteralPath $_ | Select-String -Pattern '"InternalName"') });     $PluginManifest = ($PluginManifests | Select-Object -Last 1 | ConvertFrom-Json -Depth 100 -AsHashTable);     $_ | Add-Member -Name "PluginManifest" -MemberType NoteProperty -Value $PluginManifest;   }   $Destination = $OutFile;   If ($OutFile | Get-Member -Name Parent) } Begin {   $MainRepoImageUrl = "https://raw.githubusercontent.com/goatcorp/DalamudPlugins/api6/{0}/{1}/images/{2}";   $MainRepoDip17ImageUrl = "https://raw.githubusercontent.com/goatcorp/PluginDistD17/main/{0}/{1}/images/{2}"; } Process { } End { } Clean { }
*/
