using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

// Ignore Spelling: reflog
// cSpell:ignore reflog

[SuppressMessage("ReSharper", "UnusedType.Global")]
[Cmdlet(VerbsCommon.Clear, "Git")]
public class ClearGitCommand : PathCmdletBase {
  private ApplicationInfo? Git { get; set; }

  protected override void BeginProcessing() {
    Git = Applications.GetGitInstallation();
    if (this.Git is not null) return;
    this.WriteError(new ErrorRecord(new Exception("Git not on path..."), "", ErrorCategory.InvalidResult, this.Git));
    this.StopProcessing();
  }

  protected override void ProcessRecord() {
    DirectoryInfo? currentLocation = CmdletHelpers.CurrentWorkingDirectory();

    if (Git is null) {
      this.Throw(new FileNotFoundException(), null, ErrorCategory.ObjectNotFound, nameof(this.Git));
      return;
    }

    foreach (string rawPath in this.Path) {
      FileSystemInfo? path = new GetItemCommand {
          LiteralPath = [rawPath]
        }.Invoke<FileSystemInfo>().FirstOrDefault();
      bool test = new TestPathCommand {
        LiteralPath = [rawPath],
        PathType = TestPathType.Container
      }.Invoke<bool>().FirstOrDefault();
      if (path is null) {
        this.WriteError(new ErrorRecord(new Exception("Git not on path..."), "", ErrorCategory.InvalidResult, path));
        this.StopProcessing();
        return;
      }
      IEnumerable<FileSystemInfo>? gci = new GetChildItemCommand {
        LiteralPath = [path.FullName],
        Force = true,
        Depth = 0
      }.Invoke<FileSystemInfo>().Where(x => x.Name == ".git");

      if (!test || !gci.Any()) continue;
      _ = new SetLocationCommand {
        LiteralPath = path.FullName
      }.Invoke();
      CmdletHelpers.AmpersandApplication(Git, ["reflog", "expire", "--all", "--expire=now"]);
      CmdletHelpers.AmpersandApplication(Git, ["gc", "--prune=now", "--aggressive"]);
    }

    _ = new SetLocationCommand {
      LiteralPath = currentLocation.FullName
    }.Invoke();
  }
}
