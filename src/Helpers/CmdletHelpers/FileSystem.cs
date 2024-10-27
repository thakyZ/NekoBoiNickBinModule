using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Host;
using Microsoft.PowerShell.Commands;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

public static partial class CmdletHelpers {
  public static DirectoryInfo CurrentWorkingDirectory() {
    return new DirectoryInfo(Environment.CurrentDirectory);
  }

#region Test-Path
  public static bool TestPath(string[] literalPaths, TestPathType type) {
    TestPathCommand command = new() {
      LiteralPath = literalPaths,
      PathType = type,
    };
    var commandOutput = command.Invoke<bool>();
    return commandOutput.All(b => b);
  }

  public static bool TestPath(string literalPath, TestPathType type) {
    TestPathCommand command = new() {
      LiteralPath = [literalPath],
      PathType = type,
    };
    var commandOutput = command.Invoke<bool>();
    return commandOutput.First();
  }
#endregion

#region Get-Item
  public static FileSystemInfo[] GetItem(string[] literalPaths, string? filter = null, string[]? include = null, string[]? exclude = null, bool force = false) {
    GetItemCommand command = new() {
      LiteralPath = literalPaths,
      Force = force,
    };
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    return [..command.Invoke<FileSystemInfo>()];
  }

  public static FileSystemInfo? GetItem(string literalPath, string? filter = null, string[]? include = null, string[]? exclude = null, bool force = false) {
    GetItemCommand command = new() {
      LiteralPath = [literalPath],
      Force = force,
    };
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    return command.Invoke<FileSystemInfo>().FirstOrDefault();
  }

  public static FileInfo[] GetFile(string[] literalPaths, string? filter = null, string[]? include = null, string[]? exclude = null, bool force = false) {
    GetItemCommand command = new() {
      LiteralPath = literalPaths,
      Force = force,
    };
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    var commandOutput = command.Invoke<FileSystemInfo>().Where(Utils.TestForFile).Cast<FileInfo>();
    return [..commandOutput];
  }

  public static FileInfo? GetFile(string literalPath, string? filter = null, string[]? include = null, string[]? exclude = null, bool force = false) {
    GetItemCommand command = new() {
      LiteralPath = [literalPath],
      Force = force,
    };
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    return (FileInfo?)command.Invoke<FileSystemInfo>().FirstOrDefault(Utils.TestForFile);
  }

  public static DirectoryInfo[] GetDirectory(string[] literalPaths, string? filter = null, string[]? include = null, string[]? exclude = null, bool force = false) {
    GetItemCommand command = new() {
      LiteralPath = literalPaths,
      Force = force,
    };
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    var commandOutput = command.Invoke<FileSystemInfo>().Where(Utils.TestForDirectory).Cast<DirectoryInfo>();
    return [..commandOutput];
  }

  public static DirectoryInfo? GetDirectory(string literalPath, string? filter = null, string[]? include = null, string[]? exclude = null, bool force = false) {
    GetItemCommand command = new() {
      LiteralPath = [literalPath],
      Force = force,
    };
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    return (DirectoryInfo?)command.Invoke<FileSystemInfo>().FirstOrDefault((FileSystemInfo path) => Directory.Exists(path.FullName) && TestPath(path.FullName, TestPathType.Container));
  }
#endregion

#region Get-ChildItem
  internal static List<FileSystemInfo> GetChildItem(
    string[] literalPaths,
    bool recurse = false,
    bool hidden = true,
    bool all = false,
    TestPathType type = TestPathType.Any,
    string? filter = null,
    string[]? include = null,
    string[]? exclude = null,
    bool force = false,
    Func<FileSystemInfo, bool>? where = null
  ) {
    GetChildItemCommand command = new() {
      LiteralPath = literalPaths,
      Force = force || hidden || all,
      Recurse = recurse,
    };
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    List<FileSystemInfo> files = [..command.Invoke<FileSystemInfo>()];
    List<FileSystemInfo> files2 = [];
    if (all) {
      GetChildItemCommand command2 = new() {
        LiteralPath = literalPaths,
        Force = false,
        Recurse = recurse,
      };
      if (filter is not null) {
        command2.Filter = filter;
      }
      if (include is not null) {
        command2.Include = include;
      }
      if (exclude is not null) {
        command2.Exclude = exclude;
      }
      files2 = [..command2.Invoke<FileSystemInfo>()];
    }
    files = [..files.Concat(files2)];
    files = type switch {
      TestPathType.Container => [..files.Where(Utils.TestForDirectory)],
      TestPathType.Leaf => [..files.Where(Utils.TestForFile)],
      _ => files,
    };
    if (where is not null) files = [..files.Where(where)];
    return files;
  }
#endregion

#region Remove-Item
  internal static void RemoveItem(
    string[] literalPaths,
    bool force = false,
    bool recurse = false,
    string? filter = null,
    string[]? include = null,
    string[]? exclude = null
  ) {
    RemoveItemCommand command = new() {
      LiteralPath = literalPaths,
      Force = force,
      Recurse = recurse,
    };
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    command.Invoke();
  }
#endregion

#region Resolve-Path
  internal static string ResolvePath(
    string[] literalPaths,
    bool relative = false,
    bool force = false,
    string? relativeBasePath = null,
    string? filter = null,
    string[]? include = null,
    string[]? exclude = null)
  {
    ResolvePathCommand command = new() {
      LiteralPath = literalPaths,
      Force = force,
      Relative = relative,
    };
    if (relative && relativeBasePath is not null) {
      command.RelativeBasePath = relativeBasePath;
    } else if (relative) {
      command.RelativeBasePath = command.SessionState.Path.CurrentFileSystemLocation.Path;
    }
    if (filter is not null) {
      command.Filter = filter;
    }
    if (include is not null) {
      command.Include = include;
    }
    if (exclude is not null) {
      command.Exclude = exclude;
    }
    return command.Invoke<string>().ToArray().Join(", ");
  }
#endregion
}