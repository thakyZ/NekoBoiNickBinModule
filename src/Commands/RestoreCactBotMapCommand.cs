using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Restore, "CactBotMap")]
public class RestoreCactBotMapCommand : Cmdlet {
}
/*
param(
  [int]
  $Container = 75,
  [int]
  $Padding = 80
)

$path = "E:\FFXIV\Tools\ACT\Plugins\cactbot\cactbot\ui\eureka\eureka.css"

$fileText = (Get-Content -Path $path)

$Replaced = ($fileText -replace "#container{height:\d{1,3}%;width:\d{1,3}%}\.map-padding{height:\d{1,3}%;padding:\d{1,3}%;width:\d{1,3}%}", "#container{height:$($Container)%;width:$($Container)%}.map-padding{height:$($Padding)%;padding:5%;width:$($Padding)%}")

Set-Content -Path $path -Value $Replaced
*/
