using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Clear, "VSProject")]
public class ClearVSProjectCommand : PathCmdletBase {
  protected override void BeginProcessing() {
    if (Path.Length == 0) {
      ArgumentOutOfRangeException.ThrowIfEqual(Path.Length, 0);
    }
    foreach ((int index, string item) in Path.Enumerate()) {
      if (CmdletHelpers.TestPath([item], TestPathType.Leaf)) {
        if (CmdletHelpers.GetFile(item)?.Directory?.FullName is not string path) {
          this.ThrowTerminatingError(new ErrorRecord(new FileNotFoundException(), CmdletHelpers.GetErrorID(), ErrorCategory.ReadError, item));
          return;
        }
        Path[index] = path;
      }
    }
  }

  protected override void ProcessRecord() {
    foreach (string item in Path) {
      DirectoryInfo? inputPath = CmdletHelpers.GetDirectory(item);

      if (inputPath is null) {
          this.ThrowTerminatingError(new ErrorRecord(new FileNotFoundException(), CmdletHelpers.GetErrorID(), ErrorCategory.ReadError, item));
          return;
      }

      foreach (string directory in CmdletHelpers.GetChildItem([inputPath.FullName], recurse: true, all: true, type: TestPathType.Container, where: (FileSystemInfo x) => x.Name.EqualsAnyOf(["bin", "obj", ".vs"])).Select(x => x.FullName)) {
        try {
          CmdletHelpers.RemoveItem([directory], force: true, recurse: true);
        } catch {
          this.WriteWarning($"Failed to delete item at \"{CmdletHelpers.ResolvePath([directory], relative: true, relativeBasePath: inputPath.FullName)}\"");
        }
      }
    }
  }
}