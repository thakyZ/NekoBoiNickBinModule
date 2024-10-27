using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Invoke, "Prettier")]
public class InvokePrettierCommand : Cmdlet {
}
/*
Param()

$Npx = (Get-Command -Name "npx.cmd" -ErrorAction SilentlyContinue);

If ($Null -ne $Npx) {
  Throw "Failed to find npx.cmd";
}

& "$($Npx.Source)" "prettier" ($Args -join " ");
Exit $LASTEXITCODE;
*/
