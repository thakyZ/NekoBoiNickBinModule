#nullable enable
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

// cSpell:ignoreRegExp /Neko(?=BoiNick)/
// cSpell:ignoreRegExp /(?<=Neko)Boi(?=Nick)/
namespace NekoBoiNick.ProgramFiles.Bin {
  public static class FileInfoExtensions {
    public static string BaseName(this FileSystemInfo fileInfo) {
      return Path.GetFileName(fileInfo.FullName);
    }

    public static string BaseName(this FileInfo fileInfo) {
      return Path.GetFileNameWithoutExtension(fileInfo.FullName);
    }

    public static string? GetPotentialArtistName(this FileSystemInfo fileInfo) {
      var test = fileInfo.BaseName().Split("-")[0];
      return test != fileInfo.BaseName() && Regex.IsMatch(test, @"[\(\)\[\]\{\} \-_\/\\]") ? test : null;
    }

    public static string? GetPotentialArtistName(this FileInfo fileInfo) {
      var test = fileInfo.BaseName().Split("-")[0];
      return test != fileInfo.BaseName() && Regex.IsMatch(test, @"[\(\)\[\]\{\} \-_\/\\]") ? test : null;
    }

    public static string? GetPotentialArtistNameOther(this FileSystemInfo fileInfo) {
      var test = fileInfo.BaseName().Split("_")[0];
      return test != fileInfo.BaseName() && Regex.IsMatch(test, @"[\(\)\[\]\{\} \-_\/\\]") ? test : null;
    }

    public static string? GetPotentialArtistNameOther(this FileInfo fileInfo) {
      var test = fileInfo.BaseName().Split("_")[0];
      return test != fileInfo.BaseName() && Regex.IsMatch(test, @"[\(\)\[\]\{\} \-_\/\\]") ? test : null;
    }
  }

  public class SortItemsInU {
    private bool Debug { get; set; } = false;
    private bool OldConsoleMethod { get; set; } = false;
    private bool DryRun { get; set; } = false;
    private static string HOME => Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
    private static string ProcessingDir => Path.Join(HOME, "Downloads", "u");

    private List<DirectoryInfo> Folders = [];
    private List<FileInfo> Files = [];
    public SortItemsInU(bool debug, bool dryRun, bool oldConsoleMethod) {
      Debug = debug;
      DryRun = dryRun;
      OldConsoleMethod = oldConsoleMethod;
      Folders = GetFolders();
      Files = GetFiles();
    }

    public static void Main(string[] args) {
      var temp = new SortItemsInU(true, true, true);
      temp.Run();
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
        if (Folders.Any(x => x.Name == file.GetPotentialArtistName()) && (string.IsNullOrEmpty(file.GetPotentialArtistName()) || string.IsNullOrWhiteSpace(file.GetPotentialArtistName()))) {
          hasCurrentDirectory = (State: true, Name: file.GetPotentialArtistName());
        } else if (Folders.Any(x => x.Name == file.GetPotentialArtistNameOther()) && (string.IsNullOrEmpty(file.GetPotentialArtistNameOther()) || string.IsNullOrWhiteSpace(file.GetPotentialArtistNameOther()))) {
          hasCurrentDirectory = (State: true, Name: file.GetPotentialArtistNameOther());
        } else {
          disableOption2 = true;
        }

        consolePosition = GetConsolePosition();
        if (consolePosition.Y <= Console.WindowHeight - 1) {
          WriteHost("");
        }
        WriteHost("Info:");
        WriteOutputFileInfo(file);
        WriteHost("Choose an option:");
        WriteHost(" - 0: Make New Directory");
        WriteHost(" - 1: Move into directory" + hasCurrentDirectory.Name);
        WriteHost(" - 2: Skip");
        WriteHost(" - 3: Other");
        string? choice = null;
        consolePositionInter1 = GetConsolePosition();
        while (choice is null || !Regex.IsMatch(choice, @"[0-3]") || (choice != "2" && disableOption2 != true)) {
          SetConsolePosition(consolePositionInter1);
          choice = ReadHost("[0/1/2/3]");
        }

        if (choice == "0") {
          string? newDirName = null;
          consolePositionInter2 = GetConsolePosition();
          while (newDirName is null) {
            SetConsolePosition(consolePositionInter2);
            newDirName = ReadHost("New Folder Name?");
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

          var relativePath = Path.GetRelativePath(ProcessingDir, newPath);
          string? choiceInter = null;
          consolePositionInter2 = GetConsolePosition();
          while (choiceInter is null || !Regex.IsMatch(choiceInter, "[yn]")) {
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

          choiceInter = null;
        } else if (choice == "1") {
          string newPath = Path.Join(ProcessingDir, hasCurrentDirectory.Name);
          if (!Path.Exists(newPath) && !Directory.Exists(newPath)) {
            if (DryRun) {
              WriteHost($"Making new directory at {newPath}", foregroundColor: ConsoleColor.Yellow);
              Task.Delay(5000).Wait();
            } else {
              Directory.CreateDirectory(newPath);
            }
          }

          var relativePath = Path.GetRelativePath(ProcessingDir, newPath);
          string? choiceInter = null;
          consolePositionInter2 = GetConsolePosition();
          while (choiceInter is null || !Regex.IsMatch(choiceInter, "[yn]")) {
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
            Task.Delay(5000).Wait();
          } else {
            throw new Exception($"Failed with unknown choice \"{choiceInter}\"");
          }

          choiceInter = null;
        } else if (choice == "2") {
          WriteHost("Skipping...");
          Task.Delay(5000).Wait();
        } else if (choice == "3") {
          WriteHost("Not Yet Implemented");
          Task.Delay(5000).Wait();
        } else {
          throw new Exception($"Failed with unknown choice \"{choice}\"");
        }

        choice = null;
        var endConsolePosition = GetConsolePosition();
        ClearConsoleInArea(consolePosition, endConsolePosition);
        SetConsolePosition(consolePosition);
      }
    }

    private static List<DirectoryInfo> GetFolders() {
      return Directory.GetDirectories(ProcessingDir).Select(x => new DirectoryInfo(x)).ToList();
    }

    private static List<FileInfo> GetFiles() {
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

    private void SetConsolePosition((int X, int Y) coordinates, bool noDebug = false) {
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

    private void ClearConsoleInArea((int X, int Y) coordinatesStart, (int X, int Y) coordinatesEnd, bool noDebug = false) {
      var rectangle = new Rectangle(0, coordinatesStart.Y, Console.WindowWidth, coordinatesEnd.Y - coordinatesStart.Y);
      SetConsolePosition((X: 0, coordinatesStart.Y), true);
      for (var i = 0; i < rectangle.Height; i++) {
        WriteHost(new string(' ', rectangle.Width));
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

    private string? ReadHost(string? prompt = null) {
      var startingCursorPosition = GetConsolePosition(true);
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
      if (old) {
        output = Console.ReadLine();
      } else {
        startingCursorPosition = GetConsolePosition(true);
        SetConsolePosition((X: startingCursorPosition.X, Y: startingCursorPosition.Y + 1));
        bool returned = false;
        while (!returned) {
          var input = Console.Read();
          char character;
          try {
            character = Convert.ToChar(input);
            if (char.IsWhiteSpace(character)) {
              if (character == 0x0a || character == 0x0d) {
                returned = true;
              } else {
                output ??= "";
                output = string.Join("", values: output.Append(character));
              }
            } else {
              output ??= "";
              output = string.Join("", values: output.Append(character));
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
      return output;
    }

    private static void WriteHost(string message, ConsoleColor? foregroundColor = null, ConsoleColor? backgroundColor = null, bool noNewline = false) {
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
    }

    private void WriteDebug(params object[] message) {
      if (!Debug) {
        return;
      }

      var templateString = "Debug: ";
      if (message.Length > 1) {
        templateString += string.Join(" ", message.Select(x => x.ToString() is not null ? x : "null")) + " ";
      } else {
        templateString += message;
      }

      var originalConsolePosition = GetConsolePosition();
      var tempConsolePosition = GetConsolePosition();
      tempConsolePosition.X = Console.WindowWidth - templateString.Length;
      Console.GetCursorPosition();
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
}