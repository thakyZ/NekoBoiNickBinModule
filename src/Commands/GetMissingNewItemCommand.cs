using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;
using Microsoft.PowerShell.Commands;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

public class Get_SimplifyName
{
  private static Regex NameMatch { get; } = new(@"(.+) \(\d+\)$");
  /// <summary>
  ///
  /// </summary>
  /// <param name="baseName">Path to one or more locations.</param>
  /// <returns></returns>
  public static string Main(string baseName)
  {
    if (NameMatch.IsMatch(baseName))
    {
      return NameMatch.Replace(baseName, "$1");
    }
    return baseName;
  }
}

[Cmdlet(VerbsCommon.Get, "MissingNewItem")]
public class GetMissingNewItemCommand : Cmdlet
{
  private static void WriteDebug(string message)
  {
    PsInvoker psInvoker = PsInvoker.Create("Write-Debug");
    psInvoker.AddArgument("Message", message);
    psInvoker.Invoke();
  }
  private static void WriteWarning(string message)
  {
    PsInvoker psInvoker = PsInvoker.Create("Write-Warning");
    psInvoker.AddArgument("Message", message);
    psInvoker.Invoke();
  }
  private static void WriteError(Exception? exception = null, string? message = null)
  {
    PsInvoker psInvoker = PsInvoker.Create("Write-Error");
    if (exception is not null && message is not null)
    {
      psInvoker.AddArgument("Message", message);
      psInvoker.AddArgument("Exception", exception);
    }
    else if (exception is null && message is not null)
    {
      psInvoker.AddArgument("Message", message);
    }
    else if (exception is not null && message is null)
    {
      psInvoker.AddArgument("Message", exception.Message);
      psInvoker.AddArgument("Exception", exception);
    }
    else
    {
      psInvoker.AddArgument("Message", "Threw blank error.");
    }
    psInvoker.Invoke();
  }
  public static string Main(string outputPath)
  {
    try
    {
      string parent = Path.GetDirectoryName(outputPath) ?? throw new Exception($"Failed to find parent directory of \"{outputPath}\".");
      string extension = Path.GetExtension(outputPath);
      string baseName = Path.GetFileNameWithoutExtension(outputPath);
      string newName = Get_SimplifyName.Main(baseName);
      Regex regex = new(@$"^({newName}) \((\d+)\)");
      List<FileSystemInfo> existingItems = Directory.EnumerateFileSystemEntries(parent).Select<string, FileSystemInfo>((item) =>
      {
        if (File.Exists(item) && !Directory.Exists(item))
        {
          return new FileInfo(item);
        }
        else if (!File.Exists(item) && Directory.Exists(item))
        {
          return new DirectoryInfo(item);
        }
        throw new FileNotFoundException($"Unknown file type found at \"{item}\"");
      }).Where((item) =>
      {
        if (File.Exists(item.FullName) && !Directory.Exists(item.FullName))
        {
          if (item.Extension == extension)
          {
            if (regex.IsMatch(item.Name))
            {
              return true;
            }
          }
        }
        return false;
      }).ToList();
      if (existingItems.Count < 1)
      {
        WriteWarning($"Outputting `$OutputPath = \"{outputPath}\"");
        return outputPath;
      }
      List<int> ints = [];
      foreach (var item in existingItems)
      {
        var _basename = Path.GetFileNameWithoutExtension(item.FullName);
        var nameMatches = regex.Match(_basename);
        if (nameMatches.Groups.Count == 3)
        {
          try
          {
            int _int = int.Parse(nameMatches.Groups[2].Value);
            ints.Add(_int);
          }
          catch (Exception exception)
          {
            WriteError(exception);
          }
        }
        else
        {
          if (nameMatches.Groups.Count > 3)
          {
            WriteWarning($"Got more than three match to the new name schema on item \"{item.Name}\" ({nameMatches.Groups.Count}).");
          }
          else
          {
            WriteWarning($"Got less than two match(es) to the new name schema on item \"{item.Name}\" ({nameMatches.Groups.Count}).");
          }
        }
      }
      ints.Sort();
      int missingInt = -1;
      for (int i = 1; i < ints[^1]; i++)
      {
        int at = ints.Find(x => x == i);
        if (i != 1 && at == 0)
        {
          missingInt = i;
          break;
        }
      }
      if (missingInt == -1)
      {
        missingInt = ints[^1] + 1;
      }
      if (regex.IsMatch(baseName))
      {
        var matches = regex.Match(baseName);
        if (matches.Groups.Count == 3)
        {
          outputPath = Path.Join(parent, $"{matches.Groups[1].Value} ({missingInt}){extension}");
        }
        else
        {
          if (matches.Groups.Count > 3)
          {
            WriteWarning($"Got more than three match to the new name schema on item \"{baseName}\" ({matches.Groups.Count}).");
          }
          else
          {
            WriteWarning($"Got less than two match(es) to the new name schema on item \"{baseName}\" ({matches.Groups.Count}).");
          }
        }
      }
      else
      {
        outputPath = Path.Join(parent, $"{newName} ({missingInt}){extension}");
      }
      if (File.Exists(outputPath))
      {
        throw new FileExistsException($"File at path \"{outputPath}\" already exists.");
      }
      return outputPath;
    }
    catch (Exception exception)
    {
      return exception.Message + "\n" + exception.StackTrace;
    }
  }
}
public class PsInvoker
{
  public static PSObject[] InvokeCommand(string commandName, Hashtable parameters)
  {
    var sb = ScriptBlock.Create("param($Command, $Params) & $Command @Params");
    return [.. sb.Invoke(commandName, parameters)];
  }
  public static PsInvoker Create(string cmdletName)
  {
    return new PsInvoker(cmdletName);
  }
  private Hashtable Parameters { get; set; }
  public string CmdletName { get; }
  public bool Invoked { get; private set; }
  public PSObject[] Result { get; private set; } = [];
  private PsInvoker(string cmdletName)
  {
    CmdletName = cmdletName;
    Parameters = [];
  }
  public void AddArgument(string name, object value)
  {
    Parameters.Add(name, value);
  }
  public void AddArgument(string name)
  {
    Parameters.Add(name, null);
  }
  public PSObject[] Invoke()
  {
    if (Invoked)
    {
      throw new InvalidOperationException("This instance has already been invoked.");
    }
    var sb = ScriptBlock.Create("param($Command, $Params) & $Command @Params");
    Result = [.. sb.Invoke(CmdletName, Parameters)];
    Invoked = true;
    return Result;
  }
}
public class FileExistsException(string message) : Exception(message);
