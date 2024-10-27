using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Host;
using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[Cmdlet(VerbsCommon.Clear, "ConsoleInArea")]
public class ClearConsoleInAreaCommand : PSCmdlet {
  [Parameter(Mandatory = true,
    Position = 0,
    HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
  [Alias("Start")]
  public Coordinates CoordinatesStart { get; set; }
  [Parameter(Mandatory = true,
    Position = 1,
    HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
  [Alias("End")]
  public Coordinates CoordinatesEnd { get; set; }

  private CustomRectangle Rectangle { get; set; }

  protected override void BeginProcessing(){
    this.Rectangle = new CustomRectangle(0, CoordinatesStart.Y, Console.WindowWidth, CoordinatesStart.Y - CoordinatesEnd.Y);
  }

  protected override void ProcessRecord() {
    new SetConsolePositionCommand {
      Coordinates = this.Rectangle.Start
    }.Invoke();

    this.WriteObject(new string(' ', this.Rectangle.Width * this.Rectangle.Height));

    new SetConsolePositionCommand {
      Coordinates = this.Rectangle.Start
    }.Invoke();
  }
}
