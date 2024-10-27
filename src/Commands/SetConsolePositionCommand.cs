using System;
using System.Management.Automation;
using System.Management.Automation.Host;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Set, "ConsolePosition")]
public class SetConsolePositionCommand : PSCmdlet {
  [Parameter(Mandatory = true,
    Position = 0,
    HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
  [Alias("Pos", "Position", "Coord")]
  public Coordinates Coordinates { get; set; }
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

    if (this.Debug) {
      _ = new WriteDebugOverCommand {
        Message = [Coordinates.X, Coordinates.Y]
      }.Invoke();
    }
  }

  protected override void ProcessRecord() {
    if (OldConsoleMethod) {
      Console.SetCursorPosition(Coordinates.X, Coordinates.Y);
      if (this.Debug) {
        var (x, y) = Console.GetCursorPosition();
        _ = new WriteDebugOverCommand {
          Message = [x, y]
        }.Invoke();
      }
    } else {
      Console.CursorLeft = Coordinates.X;
      Console.CursorTop = Coordinates.Y;
      if (this.Debug) {
        _ = new WriteDebugOverCommand {
          Message = [Console.CursorLeft, Console.CursorTop]
        }.Invoke();
      }
    }
  }
}
