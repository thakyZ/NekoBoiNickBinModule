using System;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Host;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommunications.Write, "DebugOver")]
public class WriteDebugOverCommand : PSCmdletBase {
  [Parameter(Mandatory = true,
    Position = 0,
    HelpMessage = "")]
  public object[] Message { get; set; } = [string.Empty];

  private string TemplateString { get; set; } = string.Empty;

  protected override void BeginProcessing(){
    if (this.Message.Length > 0) {
      this.TemplateString += string.Join(' ', this.Message);
    } else {
      this.TemplateString += Message[0];
    }
  }

  protected override void ProcessRecord() {
    if (!this.MyInvocation.BoundParameters.ContainsKey("Debug")) return;
    TemplateString = "Debug: ";
    var originalConsolePosition = new GetConsolePositionCommand {
      NoDebug = true
    }.Invoke<Coordinates>().FirstOrDefault();
    var tempConsolePosition = new GetConsolePositionCommand {
      NoDebug = true
    }.Invoke<Coordinates>().FirstOrDefault();
    tempConsolePosition.X = Console.WindowWidth - TemplateString.Length;
    _ = new SetConsolePositionCommand {
      Coordinates = tempConsolePosition,
      NoDebug = true
    }.Invoke();
    if (Message.Length > 0)
    {
      this.WriteHost("Debug: ", foregroundColor: ConsoleColor.Blue, noNewLine: true);
      foreach (var item in Message) {
        this.WriteHost(item.ToString() ?? string.Empty, foregroundColor: ConsoleColor.White, noNewLine: true);
      }
    } else {
      this.WriteHost("Debug: ", foregroundColor: ConsoleColor.Blue, noNewLine: true);
      this.WriteHost(Message[0].ToString() ?? string.Empty, foregroundColor: ConsoleColor.White, noNewLine: true);
    }
    _ = new SetConsolePositionCommand {
      Coordinates = originalConsolePosition,
      NoDebug = true
    }.Invoke();
  }
}