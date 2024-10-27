using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Invoke, "Locale")]
public class InvokeLocaleCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "Run")]
Param(
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Run",
             ValueFromPipeline = $True)]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Run,
  [Parameter(Mandatory = $True,
             ParameterSetName = "Manage")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Manage,
  [Parameter(Mandatory = $True,
             ParameterSetName = "Global")]
  [Switch]
  $Global = $False,
  [Parameter(Mandatory = $False,
             ParameterSetName = "Run")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Manage")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Global")]
  [Switch]
  $NoNewWindow = $False
)

Begin {
  $LEProc = (Get-Command -Name "LEProc.exe" -ErrorAction SilentlyContinue)
  If ($Null -eq $LEProc) {
    Write-Error -Message "Locale.Emulator was not found on the system path.";
    Exit 1;
  }

  $Argument = @();
  If ($PSCmdlet.ParameterSetName -eq "Run") {
    $Argument = @("-run", $Run);
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Manage") {
    $Argument = @("-manage", $Manage);
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Global") {
    $Argument += @("-global");
  }
  $ExitCode = -1;
}
Process {
  Write-Host $Argument
  Start-Process -FilePath $LEProc.Source -WorkingDirectory $PWD -NoNewWindow:($NoNewWindow) -ArgumentList $Argument -Wait:($NoNewWindow -eq $True);
  $ExitCode = $LastExitCode;
}
End {
  If ($NoNewWindow -eq $True) {
    Exit $ExitCode;
  }
}
*/
