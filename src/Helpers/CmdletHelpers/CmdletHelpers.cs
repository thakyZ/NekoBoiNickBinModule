using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Security;
using Microsoft.PowerShell.Commands;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

public static partial class CmdletHelpers {
  internal static string GetErrorID(int depth = 1, string fallback = "unknown") {
    StackTrace stackTrace = new();
    var name = stackTrace.GetFrame(depth)?.GetMethod()?.Name ?? fallback;
    return name switch {
      "BeginProcessing" => "Begin",
      "ProcessRecord" => "Process",
      "EndProcessing" => "End",
      "StopProcessing" => "Stop",
      _ => name,
    };
  }

  internal static IEnumerable<PSVariable> GetVariable(string[] name, string? scope = null, string[]? include = null, string[]? exclude = null) {
    GetVariableCommand command = new() { Name = name, };
    if (include is not null) {
      command.Include = include;
    }
    if (scope is not null) {
      command.Scope = scope;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    return command.Invoke<PSVariable>();
  }

  internal static void RemoveAlias(string[] name, string? scope = null, bool force = false) {
    RemoveAliasCommand command = new() { Name = name, Force = force };
    if (scope is not null) {
      command.Scope = scope;
    }
    command.Invoke();
  }

  internal static string? ReadHost(string? prompt = null) {
    ReadHostCommand command = new();
    if (prompt is not null) {
      command.Prompt = prompt;
    }
    return command.Invoke<string>().FirstOrDefault();
  }

  internal static SecureString? ReadHostSecure(string? prompt = null) {
    ReadHostCommand command = new() {
      AsSecureString = true,
    };
    if (prompt is not null) {
      command.Prompt = prompt;
    }
    return command.Invoke<SecureString>().FirstOrDefault();
  }

  internal static void SetAlias(string v1, string v2)
  {
    throw new NotImplementedException();
  }
}