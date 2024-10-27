using System.Collections;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.Cmdlets.SoupCatUtils.Extensions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("Roslynator", "RCS1170:Use read-only auto-implemented property")]
[Cmdlet(VerbsLifecycle.Build, "VSProject")]
[CmdletBinding(DefaultParameterSetName = "Default")]
public class BuildVsProjectCommand : PathCmdletBase {
  [Parameter(Mandatory = false,
    ParameterSetName = "Default",
    HelpMessage = "The Visual Studio configuration property.")]
  private string Configuration { get; set; } = "None";

  [Parameter(Mandatory = false,
    ParameterSetName = "Default",
    HelpMessage = "The Visual Studio platform property.")]
  private string Platform { get; set; } = "None";

  [Parameter(Mandatory = false,
    ParameterSetName = "Default",
    HelpMessage = "A list of Visual Studio properties and their values.")]
  Hashtable Property { get; set; } = [];

  private static Hashtable GetOutputTypes(FileSystemInfo[] solutions) {
    Hashtable outputTypes = [];
    foreach (var solution in solutions) {
      Hashtable solutionProps = [];
      var solutionFileContent = new GetContentCommand { LiteralPath = [solution.FullName] }.Invoke<string>().ToArray();
      var solutionConfigurationPlatformsBlock = solutionFileContent.SelectString(@"GlobalSection\(SolutionConfigurationPlatforms\) = preSolution");

      for (var i = solutionConfigurationPlatformsBlock.FirstOrDefault()?.LineNumber ?? solutionFileContent.Length; i < solutionFileContent.Length; i++) {
        if (solutionFileContent[i].IsMatch(@"^\s+EndGlobalSection$")) {
          break;
        }

        var props = solutionFileContent[i].Split(" = ")[0].ReplaceRegex(@"\s+", "").Split("|");
        solutionProps[props[0]] = props[1];
      }

      outputTypes[solution] = solutionProps;
    }
    return outputTypes;
  }

  protected override void BeginProcessing() {
    FileSystemInfo[] solutions = [..new GetChildItemCommand { Path = Path, Recurse = true, Depth = 2, Filter = "*.sln" }
      .Invoke()
      .Cast<FileSystemInfo>()
      .Where(x => !x.FullName.Split(System.IO.Path.VolumeSeparatorChar).ContainsAny([".vs",".git","node_modules","obj","bin","release"]))
    ];

    Hashtable outputTypes = GetOutputTypes(solutions);

    if (Configuration != "None") {
      foreach (var outputItem in outputTypes.GetIterator().EnumerateAs<Hashtable>()) {
        foreach (var property in outputItem.Value?.GetIterator() ?? []) {
          if (property.Key != Configuration) {
            _ = new ReadHostCommand {
              Prompt = "Solution at path  does not contain "
            }.Invoke();
          }
        }
      }
    }

    if (Platform != "None") {
      // TODO: Finish this code.
    }

    if (Property.Keys.Cast<string>().ContainsAny(["Configuration"])) {
      // TODO: Finish this code.
    }

    if (Property.Keys.Cast<string>().ContainsAny(["Platform"])) {
      // TODO: Finish this code.
    }
  }

  protected override void ProcessRecord() {
    // TODO: Finish this code.
  }

  protected override void EndProcessing() {
    // TODO: Finish this code.
  }

  protected override void StopProcessing() {
    // TODO: Finish this code.
  }
}
