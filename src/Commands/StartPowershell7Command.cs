using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Start, "Powershell7")]
public class StartPowershell7Command : Cmdlet {
}
/*
Param(
  [Parameter(Position=1)]$ps1 = ''
)

if ($ps1 -ne '')
{
  Set-Location $ps1
} else {
  Set-Location ~
}

*/
