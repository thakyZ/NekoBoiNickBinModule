using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Remove, "Base64")]
public class RemoveBase64Command : Cmdlet {
}
/*
param(
  # File path for the log file to remove Base64 out of.
  [Parameter(Position=1,Mandatory=$true,HelpMessage="File path for the log file to remove Base64 out of.")]
  [Alias("Path")]
  [string]
  $FilePath,
  # Parameter for what kind of log file it is.
  # Currently only Dalamud log file supported.
  [Parameter(Position=2,Mandatory=$false,HelpMessage="Parameter for what kind of log file it is.")]
  [ValidateSet("None", "", "Dalamud")]
  [string]
  $Type=""
)

$DefaultRegex = "[a-zA-Z0-9/\+\=]+";
$DalamudRegex = "(\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}.\d{3,}\s-\d{2,}:\d{2}\s\[INF\]\sTroubleshooting:)${DefaultRegex}";

$Content = (Get-Content -Path $FilePath -Raw);
$NewContent = "";
if ($type -eq "None" -or $type -eq "") {
  $NewContent = $Content -replace $DefaultRegex;
} elseif ($type -eq "Dalamud") {
  $NewContent = $Content -replace $DalamudRegex, '$1 [Base64 Removed]';
}
$File = (Get-ChildItem -Path $FIlePath)
$BaseExtension = $File.Extension;
$BaseFileName = $File.BaseName;
$BasePath = $File.DirectoryName;

$NewContent | Out-File -FilePath "${BasePath}\${BaseFileName}.nobase64${BaseExtension}";
*/
