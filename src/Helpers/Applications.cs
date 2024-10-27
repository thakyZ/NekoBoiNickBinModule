using System;
using System.IO;
using System.Linq;
using System.Management.Automation;
using Microsoft.PowerShell.Commands;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

public static class Applications {
  public static ApplicationInfo? GetGitInstallation() {
    return GetInstallation("git.exe");
  }

  public static ApplicationInfo? GetInstallation(params string[] executables) {
    var output = new GetCommandCommand {
      Name = executables
    }.Invoke<ApplicationInfo>();

    if (output is not null) {
      return output.FirstOrDefault();
    }

    throw new FileNotFoundException("Git not on path...");
  }
}