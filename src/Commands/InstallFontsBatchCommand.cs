using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Install, "FontsBatch")]
public class InstallFontsBatchCommand : Cmdlet {
}
/*
Param(
  # Specifies a path to one or more locations.
  [Parameter(Mandatory=$True,
             Position=0,
             ValueFromPipeline=$True,
             ValueFromPipelineByPropertyName=$True,
             HelpMessage="Path to one or more locations.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [string]
  $Path,
  # Specifies the method to install the font via.
  [Parameter(Mandatory=$False,
             HelpMessage="The method to install the font via.")]
  [ValidateSet("Manual", "Shell")]
  [string]
  $Method = "Manual",
  # Specifies the scope to install the font via.
  [Parameter(Mandatory=$False,
             HelpMessage="The scope to install the font via.")]
  [ValidateSet("User", "System")]
  [string]
  $Scope = "User"
)

Write-Host "Installing fonts";
$AllFiles = @();
$Fonts = (Get-ChildItem -LiteralPath $Path -Directory);

ForEach ($Font in $Fonts) {
  $Files = (Get-ChildItem -LiteralPath $Font.FullName -Recurse -Filter "*Windows Compatible*" -Include "*.ttf", "*.ttc", "*.otf")
  If ($Files.Length -gt 0) {
    ForEach ($File in $Files) {
      $AllFiles += $File
    }
  } Else {
    $Files = (Get-ChildItem -LiteralPath $Font.FullName -Recurse -Include "*.ttf", "*.ttc", "*.otf")
    If ($Files.Length -gt 0) {
      ForEach ($File in $Files) {
        $AllFiles += $File
      }
    }
  }
}

$Percentage = 0;
$Index = 0;

ForEach ($File in $AllFiles) {
  $RelativePath = (Resolve-Path -Path $File.FullName -RelativeBasePath $Path -Relative);
  Write-Progress -Activity "Installing Fonts" -Status "$($Index)% Complete: $($RelativePath)" -PercentComplete $Percentage;
  If ($DebugPreference -ne "SilentlyContinue") {
    Write-Host -Object "Installing: $($RelativePath)";
  }
  Install-Font -Path $File.FullName -Scope $Scope -Method $Method -UninstallExisting;
  $Index++;
  $Percentage = ([System.Math]::Ceiling((($Index / $AllFiles.Length) * 100)));
}
*/
