using System;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Host;
using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "ConsolePosition")]
[OutputType(typeof(Coordinates))]
public class GetConsolePositionCommand : PSCmdletBase {
  [Parameter(Mandatory = false)]
  public bool NoDebug { get; set; }

  private bool Debug { get; set; }
  private bool Verbose { get; set; }
  private bool OldConsoleMethod { get; set; }

  protected override void BeginProcessing(){
    if (this.MyInvocation.BoundParameters.ContainsKey("Debug")) {
      this.Debug = true;
    }

    if (this.MyInvocation.BoundParameters.ContainsKey("Verbose")) {
      this.Verbose = true;
    }

    this.OldConsoleMethod = false;
  }

  protected override void ProcessRecord() {
    if (this.OldConsoleMethod) {
      var (x, y) = Console.GetCursorPosition();

      if (this.Debug) {
        _ = new WriteDebugOverCommand {
          Message = [x, y]
        }.Invoke();
      }

      WriteObject(new Coordinates(x, y));
    } else {
      var x = Console.CursorLeft;
      var y = Console.CursorTop;

      if (this.Debug) {
        _ = new WriteDebugOverCommand {
          Message = [x, y]
        }.Invoke();
      }

      WriteObject(new Coordinates(x, y));
    }
  }
}
/*
[CmdletBinding()]
Param()

Begin {
  $script:Debug = $False;

  If ($DebugPreference -ne "SilentlyContinue" -and $DebugPreference -ne "Ignore") {
    $script:Debug = $True;
  }

  $script:Verbose = $False;

  If ($VerbosePreference -ne "SilentlyContinue" -and $VerbosePreference -ne "Ignore") {
    $script:Verbose = $True;
  }

  $script:OldConsoleMethod = $False;
}
Process {
  If ($script:OldConsoleMethod) {
    $x, $y = [Console]::GetCursorPosition() -split '\D' -ne '' -as 'int[]'
    If ($script:Debug -eq $True) {
      Write-DebugOver -Message @($x, $y)
    }
    Return @{ X = $x; Y = $y; }
  } Else {
    $x = [System.Console]::CursorLeft;
    $y = [System.Console]::CursorTop;
    If ($script:Debug -eq $True) {
      Write-DebugOver -Message @($x, $y)
    }
    Return @{ X = $x; Y = $y; }
  }
}
End {
  Remove-Variable -Scope Script -Name "OldConsoleMethod";
  Remove-Variable -Scope Script -Name "Debug";
  Remove-Variable -Scope Script -Name "Verbose";
}
*/
