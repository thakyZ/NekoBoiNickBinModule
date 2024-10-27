using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Set, "DiscordCommandLine")]
public class SetDiscordCommandLineCommand : Cmdlet {
}
/*
Param(
  # Specifies the type of discord to do this to.
  [Parameter(Mandatory = $False, Position = 0, HelpMessage = "Specifies the type of discord to do this to.")]
  [ValidateSet("Stable", "Beta", "PTB", "Canary", "Dev")]
  [string]
  $Type = "Stable",
  # Specifies to force turn on or off.
  [Parameter(Mandatory = $False, Position = 1, HelpMessage = "Specifies to force turn on or off.")]
  [boolean]
  $State = $false
)

$HasDiscordStable = $null -ne (Test-Path -Path "$env:AppData\discord") -and $Type -eq "Stable" ? (Resolve-Path -Path "$env:AppData\discord") : $False;
$HasDiscordBeta = $null -ne (Test-Path -Path "$env:AppData\discordbeta") -and $Type -eq "Beta" ? (Resolve-Path -Path "$env:AppData\discordbeta") : $False;
$HasDiscordPTB = $null -ne (Test-Path -Path "$env:AppData\discordptb") -and $Type -eq "PTB" ? (Resolve-Path -Path "$env:AppData\discordptb") : $False;
$HasDiscordCanary = $null -ne (Test-Path -Path "$env:AppData\discordcanary") -and $Type -eq "Canary" ? (Resolve-Path -Path "$env:AppData\discordcanary") : $False;
$HasDiscordDev = $null -ne (Test-Path -Path "$env:AppData\discorddev") -and $Type -eq "Dev" ? (Resolve-Path -Path "$env:AppData\discorddev") : $False;

Function Set-EditSettings() {
  Param(
    # Specifies a path to one or more locations.
    [Parameter(Mandatory = $true,
      Position = 0,
      ParameterSetName = "ParameterSetName",
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      HelpMessage = "Path to one or more locations.")]
    [Alias("PSPath")]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $Path,
    # Specifies the type.
    [Parameter(Mandatory = $True, Position = 1, HelpMessage = "Specifies the type.")]
    [ValidateSet("Stable", "Beta", "PTB", "Canary", "Dev")]
    [string]
    $Type
  )

  $Json = (Get-Content -LiteralPath "$($Path)\settings.json" | ConvertFrom-Json -Depth 5);
  If ($null -eq ($Json | Get-Member 'DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING')) {
    Write-Host -Object "Enabled DevTools on Discord $($Type).";
    $Json | Add-Member -Type NoteProperty -Name 'DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING' -Value $True;
  }
  Else {
    Write-Host -Object "Disabled DevTools on Discord $($Type).";
    $Json.PSObject.Properties.Remove('DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING');
  }
  $Json | ConvertTo-Json -Depth 5 | Out-File -LiteralPath "$($Path)\settings.json";
}

If ($HasDiscordStable) {
  Set-EditSettings -Path $HasDiscordStable -Type Stable
}
If ($HasDiscordBeta) {
  Set-EditSettings -Path $HasDiscordBeta -Type Beta
}
If ($HasDiscordPTB) {
  Set-EditSettings -Path $HasDiscordPTB -Type PTB
}
If ($HasDiscordCanary) {
  Set-EditSettings -Path $HasDiscordCanary -Type Canary
}
If ($HasDiscordDev) {
  Set-EditSettings -Path $HasDiscordDev -Type Dev
}
Exit 0
*/
