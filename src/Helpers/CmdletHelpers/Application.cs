using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Security;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.PowerShell.Commands;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

public static partial class CmdletHelpers {
  internal static ProcessStdCapture? AmpersandApplication(ApplicationInfo application, string[] args, bool wait = true, bool captureStd = false, long timeout = -1, string[]? verbs = null, SecureString? password = null, bool noNewWindow = false, bool loadUserProfile = false)  {
    ProcessStartInfo startInfo = new(application.Source, args) {
      CreateNoWindow = noNewWindow,
      LoadUserProfile = loadUserProfile
    };
    if (noNewWindow) {
      startInfo.RedirectStandardError = true;
      startInfo.RedirectStandardOutput = true;
    }
    if (verbs is not null) {
      startInfo.Verb = verbs.Aggregate((string verb, string joined) => $"{joined} {verb}");
      if (verbs.Contains("RunAs", StringComparer.OrdinalIgnoreCase)) {
        startInfo.Password = password ?? ReadHostSecure("Administrator Password");
      }
    }
    Process process = new Process() {
      StartInfo = startInfo,
    };
    ProcessStdCapture? output = null;
    if (noNewWindow) {
      output = new(process, captureStd);
    }
    if (process.Start()) {
      if (wait) {
        long startTime = process.StartTime.ToUnixTimestamp();
        while (!process.HasExited || (timeout != -1 && DateTime.Now.ToUnixTimestamp() - timeout < startTime)) {
          process.Refresh();
        }
        if (timeout != -1 && DateTime.Now.ToUnixTimestamp() - timeout >= startTime) {
          output?.Write();
          process.Kill(true);
        }
        return output;
      }
    } else {
      throw new ApplicationException($"Failed to start program {new FileInfo(application.Source).BaseName()}, exited with code: {process.ExitCode}");
    }
    return null;
  }
}