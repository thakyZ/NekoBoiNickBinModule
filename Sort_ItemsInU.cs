#nullable enable
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Management.Automation;

// cSpell:ignoreRegExp /Neko(?=BoiNick)/
// cSpell:ignoreRegExp /(?<=Neko)Boi(?=Nick)/
namespace NekoBoiNick.CSharp.PowerShell.Cmdlets;
public static class FileInfoExtensions {
  public static string BaseName(this FileSystemInfo fileInfo) {
    return Path.GetFileNameWithoutExtension(fileInfo.FullName);
  }

  public static string BaseName(this FileInfo fileInfo) {
    return Path.GetFileNameWithoutExtension(fileInfo.FullName);
  }

  public static string? GetPotentialArtistName(this FileSystemInfo fileInfo) {
    var test = fileInfo.BaseName().Split("-")[0];
    return test != fileInfo.BaseName() ? test : null;
  }

  public static string? GetPotentialArtistName(this FileInfo fileInfo) {
    var test = fileInfo.BaseName().Split("-")[0];
    return test != fileInfo.BaseName() ? test : null;
  }

  public static string? GetPotentialArtistNameOther(this FileSystemInfo fileInfo) {
    var test = fileInfo.BaseName().Split("_")[0];
    return test != fileInfo.BaseName() ? test : null;
  }

  public static string? GetPotentialArtistNameOther(this FileInfo fileInfo) {
    var test = fileInfo.BaseName().Split("_")[0];
    return test != fileInfo.BaseName() ? test : null;
  }
}

public class Sort_ItemsInU_Program {
  private static SortItemsInU? _instance = null;

  public static void Main(string[] args) {
    _instance = new SortItemsInU(null, ParseArgs(args));
    if (_instance is not null) {
      _instance.Run();
    } else {
      throw new NullReferenceException("The SortItemsInU instance was found to be null.");
    }
  }

  private static bool[] ParseArgs(params string[] args) {
    bool[] output = [false, false, false, false];
    string? shortened = null;

    bool[] ParseArgName(string? shortened, bool[] output) {
      if (shortened is null) {
        throw new NullReferenceException("Shorted was found to be null.");
      } else {
        if (shortened.Equals("d", StringComparison.Ordinal) || shortened.Equals("Debug", StringComparison.OrdinalIgnoreCase)) {
          output[0] = true;
        } else if (shortened.Equals("o", StringComparison.Ordinal) || shortened.Equals("OldConsoleMethod", StringComparison.OrdinalIgnoreCase) || shortened.Equals("old-console-method", StringComparison.Ordinal) || shortened.Equals("old_console_method", StringComparison.Ordinal)) {
          output[1] = true;
        } else if (shortened.Equals("D", StringComparison.Ordinal) || shortened.Equals("DryRun", StringComparison.OrdinalIgnoreCase) || shortened.Equals("dry-run", StringComparison.Ordinal) || shortened.Equals("dry_run", StringComparison.Ordinal)) {
          output[2] = true;
        } else if (shortened.Equals("s", StringComparison.Ordinal) || shortened.Equals("SkipNonMatching", StringComparison.OrdinalIgnoreCase) || shortened.Equals("skip-non-matching", StringComparison.Ordinal) || shortened.Equals("skip_non_matching", StringComparison.Ordinal)) {
          output[3] = true;
        }
      }
      return output;
    }

    foreach (string arg in args) {
      if (arg.StartsWith("--")) {
        shortened = arg.Replace("--", "");
        output = ParseArgName(shortened, output);
      } else if (arg.StartsWith("-")) {
        shortened = arg.Replace("-", "");
        output = ParseArgName(shortened, output);
      }
    }
    return output;
  }
}

public class SortItemsInU {
  private bool Debug { get; } = false;
  private bool DryRun { get; } = false;
  private bool OldConsoleMethod { get; } = false;
  private bool SkipNonMatching { get; } = false;
  private string Home { get; }
  private string ProcessingDir { get; }
  private PSCmdlet? Cmdlet { get; } = null;

  private List<DirectoryInfo> Folders { get; } = [];
  private List<FileInfo> Files { get; } = [];
  public SortItemsInU(PSCmdlet? cmdlet = null, bool debug = false, bool dryRun = false, bool oldConsoleMethod = false) {
    this.Debug = debug;
    this.DryRun = dryRun;
    this.OldConsoleMethod = oldConsoleMethod;
    this.Home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
    this.ProcessingDir = Path.Join(Home, "Downloads", "u");
    this.Folders = GetFolders();
    this.Files = GetFiles();
    this.Cmdlet = cmdlet;
  }

  public SortItemsInU(PSCmdlet? cmdlet = null, params bool[] ddRoCM) {
    this.Debug = ddRoCM.Length >= 1 ? ddRoCM[0] : false;
    this.DryRun = ddRoCM.Length >= 2 ? ddRoCM[1] : false;
    this.OldConsoleMethod = ddRoCM.Length >= 3 ? ddRoCM[2] : false;
    this.SkipNonMatching = ddRoCM.Length >= 4 ? ddRoCM[3] : false;
    this.Home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
    this.ProcessingDir = Path.Join(Home, "Downloads", "u");
    this.Folders = GetFolders();
    this.Files = GetFiles();
    this.Cmdlet = cmdlet;
  }

  public static object[] RunWrapperStatic(PSCmdlet? cmdlet = null, bool debug = false, bool dryRun = false, bool oldConsoleMethod = false) {
    var _instance = new SortItemsInU(cmdlet, debug, dryRun, oldConsoleMethod);
    return _instance.RunWrapper();
  }

  public static object[] RunWrapperStatic(PSCmdlet? cmdlet = null, params bool[] ddRoCM) {
    var _instance = new SortItemsInU(cmdlet, ddRoCM);
    return _instance.RunWrapper();
  }

  public object[] RunWrapper() {
    List<object> output = [];
    try {
      this.Run();
      output.Add("Completed.");
    } catch (Exception exception) {
      if (exception is null) {
        output.Add("Exception turned out to be null.");
      } else {
        output.Add(exception.Message ?? "Exception.Message is null");
        output.Add(exception.StackTrace ?? "Exception.StackTrace is null");
        if (exception.InnerException is not null) {
          output.Add(exception.InnerException.Message ?? "Exception.InnerException.Message is null");
          output.Add(exception.InnerException.StackTrace ?? "Exception.InnerException.StackTrace is null");
        }
      }
    }
    return output.ToArray();
  }

  public void Run() {
    (int X, int Y) consolePosition = (X: 0, Y: 0);
    (int X, int Y) consolePositionInter1 = (X: 0, Y: 0);
    (int X, int Y) consolePositionInter2 = (X: 0, Y: 0);
    consolePosition = GetConsolePosition();
    foreach (FileInfo file in Files) {
      SetConsolePosition(consolePosition);
      (bool State, string? Name) hasCurrentDirectory = (State: false, Name: null);
      bool disableOption2 = false;
      if (file.GetPotentialArtistName() is string potentialName && Folders.Any(x => x.Name == potentialName) && !string.IsNullOrEmpty(potentialName) && !string.IsNullOrWhiteSpace(potentialName)) {
        hasCurrentDirectory = (State: true, Name: potentialName);
      } else if (file.GetPotentialArtistNameOther() is string potentialNameOther && Folders.Any(x => x.Name == potentialNameOther) && !string.IsNullOrEmpty(potentialNameOther) && string.IsNullOrWhiteSpace(potentialNameOther)) {
        hasCurrentDirectory = (State: true, Name: potentialNameOther);
      } else {
        disableOption2 = true;
      }

      if (this.SkipNonMatching && hasCurrentDirectory.Name is null) {
        continue;
      } else {
      }

      consolePosition = GetConsolePosition();
      if (consolePosition.Y <= Console.WindowHeight - 1) {
        WriteHost("");
      }
      WriteHost("Info:");
      WriteOutputFileInfo(file);
      WriteHost("Choose an option:");
      WriteHost(" - 0: Make New Directory");
      WriteHost(" - 1: Move into directory" + (hasCurrentDirectory.Name is null ? "" : $" \"{hasCurrentDirectory.Name}\""));
      WriteHost(" - 2: Skip");
      WriteHost(" - 3: Other");
      string choice = "";
      consolePositionInter1 = GetConsolePosition();
      while (choice == "" && !Regex.IsMatch(choice, @"[0-3]") && !(choice == "2" && disableOption2 == false)) {
        SetConsolePosition(consolePositionInter1);
        choice = ReadHost($"[0/1/2/3]") ?? "";
      }

      if (choice == "0") {
        string? newDirName = null;
        consolePositionInter2 = GetConsolePosition();
        while (newDirName is null) {
          SetConsolePosition(consolePositionInter2);
          newDirName = ReadHost("New Folder Name?");
        }

        if (ProcessingDir is null) {
          throw new NullReferenceException("The property ProcessingDir was found to be null. Ref 0");
        }
        string newPath = Path.Join(ProcessingDir, newDirName);
        if (!Path.Exists(newPath) && !Directory.Exists(newPath)) {
          if (DryRun) {
            WriteHost($"Making new directory at {newPath}", foregroundColor: ConsoleColor.Yellow);
            Task.Delay(5000).Wait();
          } else {
            Directory.CreateDirectory(newPath);
          }
        }

        if (ProcessingDir is null) {
          throw new NullReferenceException("The property ProcessingDir was found to be null. Ref 1");
        }
        var relativePath = Path.GetRelativePath(ProcessingDir, newPath);
        string choiceInter = "";
        consolePositionInter2 = GetConsolePosition();
        while (choiceInter == "" || !Regex.IsMatch(choiceInter, "[yn]")) {
          SetConsolePosition(consolePositionInter2);
          choiceInter = ReadHost($"Move item into {relativePath}? [y/N]");
        }

        choiceInter = choiceInter.ToLower();
        if (choiceInter == "y") {
          if (DryRun) {
            WriteHost($"Moving {file.FullName} to Destination {Path.Join(newPath, file.Name)}", foregroundColor: ConsoleColor.Yellow);
            Task.Delay(5000).Wait();
          } else {
            File.Move(file.FullName, Path.Join(newPath, file.Name));
          }
        } else if (choiceInter == "n") {
          WriteHost("Skipping...");
        } else {
          throw new Exception($"Failed with unknown choice \"{choiceInter}\"");
        }

        choiceInter = "";
      } else if (choice == "1") {
        if (ProcessingDir is null) {
          throw new NullReferenceException("The property ProcessingDir was found to be null. Ref 2");
        }
        string newPath = Path.Join(ProcessingDir, hasCurrentDirectory.Name);
        if (!Path.Exists(newPath) && !Directory.Exists(newPath)) {
          if (DryRun) {
            WriteHost($"Making new directory at {newPath}", foregroundColor: ConsoleColor.Yellow);
            Task.Delay(5000).Wait();
          } else {
            Directory.CreateDirectory(newPath);
          }
        }

        if (ProcessingDir is null) {
          throw new NullReferenceException("The property ProcessingDir was found to be null. Ref 3");
        }
        var relativePath = Path.GetRelativePath(ProcessingDir, newPath);
        string choiceInter = "";
        consolePositionInter2 = GetConsolePosition();
        while (choiceInter == "" || !Regex.IsMatch(choiceInter, "[yn]")) {
          SetConsolePosition(consolePositionInter2);
          choiceInter = ReadHost($"Move item into {relativePath}? [y/N]");
        }

        choiceInter = choiceInter.ToLower();
        if (choiceInter == "y") {
          if (DryRun) {
            WriteHost($"Moving {file.FullName} to Destination {Path.Join(newPath, file.Name)}", foregroundColor: ConsoleColor.Yellow);
            Task.Delay(1000).Wait();
          } else {
            File.Move(file.FullName, Path.Join(newPath, file.Name));
          }
        } else if (choiceInter == "n") {
          WriteHost("");
          WriteHost("Skipping...");
          Task.Delay(1000).Wait();
        } else {
          throw new Exception($"Failed with unknown choice \"{choiceInter}\"");
        }

        choiceInter = "";
      } else if (choice == "2") {
        WriteHost("");
        WriteHost("Skipping...");
        Task.Delay(1000).Wait();
      } else if (choice == "3") {
        WriteHost("");
        WriteHost("Not Yet Implemented");
        Task.Delay(1000).Wait();
      } else {
        throw new Exception($"Failed with unknown choice \"{choice}\"");
      }

      choice = "";
      var endConsolePosition = GetConsolePosition();
      ClearConsoleInArea(consolePosition, endConsolePosition);
      SetConsolePosition(consolePosition);
    }
  }

  private List<DirectoryInfo> GetFolders() {
    if (ProcessingDir is null) {
      throw new NullReferenceException("The property ProcessingDir was found to be null. Ref 4");
    }
    return Directory.GetDirectories(ProcessingDir).Select(x => new DirectoryInfo(x)).ToList();
  }

  private List<FileInfo> GetFiles() {
    if (ProcessingDir is null) {
      throw new NullReferenceException("The property ProcessingDir was found to be null. Ref 5");
    }
    return Directory.GetFiles(ProcessingDir).Where(x => {
      var temp = new FileInfo(x);
      return Regex.IsMatch(temp.BaseName(), @"^[^-]+-") && temp.Extension != ".zip";
    }).Select(x => new FileInfo(x)).ToList();
  }

  private (int X, int Y) GetConsolePosition(bool noDebug = true) {
    if (OldConsoleMethod) {
      var (x, y) = Console.GetCursorPosition();
      y -= y + 1 == Console.WindowHeight ? 1 : 0;
      if (noDebug == false) {
        WriteDebug(x, y);
      }

      return (X: x, Y: y);
    } else {
      var x = Console.CursorLeft;
      var y = Console.CursorTop;
      y -= y + 1 == Console.WindowHeight ? 1 : 0;
      if (noDebug == false) {
        WriteDebug(x, y, Console.BufferHeight, Console.WindowHeight, Console.LargestWindowHeight);
      }

      return (X: x, Y: y);
    }
  }

  private void SetConsolePosition((int X, int Y) coordinates, bool noDebug = true) {
    if (OldConsoleMethod) {
      if (noDebug == false) {
        var (x, y) = Console.GetCursorPosition();
        WriteDebug(x, y, Console.BufferHeight, Console.WindowHeight, Console.LargestWindowHeight);
      }

      Console.SetCursorPosition(coordinates.X, coordinates.Y);
    } else {
      if (noDebug == false) {
        var x = Console.CursorLeft;
        var y = Console.CursorTop;
        WriteDebug(x, y, Console.BufferHeight, Console.WindowHeight, Console.LargestWindowHeight);
      }

      Console.CursorLeft = coordinates.X;
      Console.CursorTop = coordinates.Y;
    }
  }

  private void ClearConsoleInArea((int X, int Y) coordinatesStart, (int X, int Y) coordinatesEnd, bool noDebug = true) {
    var rectangle = new Rectangle(0, coordinatesStart.Y, Console.WindowWidth, coordinatesEnd.Y - coordinatesStart.Y);
    SetConsolePosition((X: 0, coordinatesStart.Y), true);
    for (var i = 0; i < rectangle.Height; i++) {
      Console.WriteLine(new string(' ', rectangle.Width));
    }

    SetConsolePosition(coordinatesStart, true);
  }

  private void WriteOutputFileInfo(FileInfo fileInfo) {
    WriteHost("");
    string[] members = [
      "FullName",
      "Name",
      "BaseName",
      "PotentialArtistName",
      "PotentialArtistNameOther"
    ];
    int longest = members.Aggregate("", (max, cur) => max.Length > cur.Length ? max : cur).Length;
    foreach (string member in members) {
      WriteHost(member + new string(' ', longest - member.Length) + " : ", foregroundColor: ConsoleColor.Green, noNewline: true);
      switch (member) {
        case "FullName":
          WriteHost(fileInfo.FullName);
          break;
        case "Name":
          WriteHost(fileInfo.Name);
          break;
        case "BaseName":
          WriteHost(fileInfo.BaseName());
          break;
        case "PotentialArtistName":
          WriteHost(fileInfo.GetPotentialArtistName() ?? "null");
          break;
        case "PotentialArtistNameOther":
          WriteHost(fileInfo.GetPotentialArtistNameOther() ?? "null");
          break;
        default:
          WriteHost("Error", foregroundColor: ConsoleColor.Red);
          break;
      };
    }

    WriteHost("");
  }

  private string ReadHost(string? prompt = null) {
    var startingCursorPosition = GetConsolePosition();
    SetConsolePosition((X: startingCursorPosition.X, Y: startingCursorPosition.Y + 1));
    if (prompt is not null) {
      string template = prompt + ": ";
      WriteHost(template, noNewline: true);
      startingCursorPosition.X += template.Length;
    }
    WriteHost(new string(' ', Console.WindowWidth - startingCursorPosition.X), noNewline: true);
    SetConsolePosition(startingCursorPosition);
    var old = false;

    string? output = null;
    string character = "";
    bool returned = false;
    int input = 0;
    if (old) {
      output = Console.ReadLine();
    } else {
      startingCursorPosition = GetConsolePosition();
      SetConsolePosition((X: startingCursorPosition.X, Y: startingCursorPosition.Y + 1));
      while (!returned) {
        input = Console.Read();
        try {
          character = Convert.ToChar(input).ToString();
          if (char.IsWhiteSpace(character[0])) {
            if (character[0] == 0x0a) {
            } else if (character[0] == 0x0d) {
              returned = true;
            } else {
              output ??= "";
              output += $"{output}{character}";
            }
          } else {
            output ??= "";
            output += $"{output}{character}";
          }
        } catch (OverflowException overflowException) {
          WriteHost($"{overflowException.Message} Value read = {input}.", foregroundColor: ConsoleColor.Red);
          throw;
        } catch (Exception exception) {
          WriteHost($"{exception.Message} Value read = {input}.", foregroundColor: ConsoleColor.Red);
          throw;
        }
      }
    }
    SetConsolePosition((X: 0, Y: startingCursorPosition.Y + (startingCursorPosition.Y + 1 == Console.WindowHeight ? 0 : 1)));
    return output ?? "";
  }

  private void WriteHost(string message, ConsoleColor? foregroundColor = null, ConsoleColor? backgroundColor = null, bool noNewline = false) {
    if (Cmdlet is null) {
      if (foregroundColor is not null && foregroundColor is ConsoleColor _foregroundColor) {
        Console.ForegroundColor = _foregroundColor;
      }

      if (backgroundColor is not null && backgroundColor is ConsoleColor _backgroundColor) {
        Console.BackgroundColor = _backgroundColor;
      }

      if (noNewline) {
        Console.Write(message);
      } else {
        Console.WriteLine(message);
      }

      if (foregroundColor is not null || backgroundColor is not null) {
        Console.ResetColor();
      }
    } else {
      List<string> arguments = [];
      if (foregroundColor is not null && foregroundColor is ConsoleColor _foregroundColor) {
        arguments.Add($"-ForegroundColor {_foregroundColor}");
      }

      if (backgroundColor is not null && backgroundColor is ConsoleColor _backgroundColor) {
        arguments.Add($"-BackgroundColor {_backgroundColor}");
      }

      if (noNewline) {
        arguments.Add($"-NoNewline");
      }

      Cmdlet.WriteInformation($"{message}", arguments.ToArray());
    }
  }

  private void WriteDebug(params object[] message) {
    if (!Debug) {
      return;
    }

    var templateString = "Debug: ";
    if (message.Length > 1) {
      templateString += string.Join(" ", message.Select(x => x is not null ? x.ToString() : "null")) + " ";
    } else {
      templateString += message.ToString();
    }

    var originalConsolePosition = GetConsolePosition();
    var tempConsolePosition = GetConsolePosition();
    tempConsolePosition.X = Console.WindowWidth - templateString.Length - 3;
    SetConsolePosition(tempConsolePosition, true);
    WriteHost("Debug: ", foregroundColor: ConsoleColor.Blue, noNewline: true);
    int index = 0;
    foreach (var item in message) {
      bool newLine = index < message.Length - 1;
      WriteHost((item.ToString() ?? "null") + " ", foregroundColor: ConsoleColor.White, noNewline: newLine);
      index++;
    }

    SetConsolePosition(originalConsolePosition, true);
  }
}