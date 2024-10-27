using System.IO;
using Microsoft.PowerShell.Commands;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

public static class Utils {
  internal static bool TestForDirectory(FileSystemInfo path) => (Directory.Exists(path.FullName) && CmdletHelpers.TestPath(path.FullName, TestPathType.Container)) || path is DirectoryInfo;
  internal static bool TestForFile(FileSystemInfo path) => File.Exists(path.FullName) || CmdletHelpers.TestPath(path.FullName, TestPathType.Leaf) || path is FileInfo;

  /// <summary>
  /// <para>
  /// </para>
  /// <code>
  /// import os
  /// import argparse
  ///
  /// parser = argparse.ArgumentParser(description="Outputs the hashes of all subdirectories of target.")
  /// parser.add_argument("--silent", action="store_true", help="Disables console output.")
  /// parser.add_argument("--fileA", type=str, help="Input file A.")
  /// parser.add_argument("--fileB", type=str, help="Input file B.")
  /// parser.add_argument("--output", type=str, help="Output file.")
  /// parser.add_argument("--open", action="store_true", help="Opens file upon completion.")
  /// parser.add_argument("--force", action="store_true", help="Overwrite without prompt.")
  ///
  /// args = parser.parse_args()
  ///
  /// pathA = args.fileA or "fileA.txt"
  /// pathB = args.fileB or "fileB.txt"
  ///
  /// fileA = open(pathA, "r")
  /// dictA = {}
  /// for line in fileA:
  ///     split = line.split(",")
  ///     dictA[split[0]] = split[1][:-1]
  /// fileA.close()
  ///
  /// fileB = open(pathB, "r")
  /// dictB = {}
  /// for line in fileB:
  ///     split = line.split(",")
  ///     dictB[split[0]] = split[1][:-1]
  /// fileA.close()
  ///
  /// if args.output:
  ///     if not args.force and os.path.exists(args.output) and input("The file \"" + args.output + "\" already exists, would you like to overwrite? [y/n] ").lower() != 'y':
  ///             quit()
  ///     text_file = open(args.output, "w")
  ///
  /// for id,hash in dictA.items():
  ///     if id in dictB and dictA[id] != dictB[id]:
  ///         if not args.silent:
  ///             print(id)
  ///         if args.output:
  ///             text_file.write(id + "\n")
  ///
  /// if args.output:
  ///     text_file.close()
  ///     if args.open:
  ///         os.startfile(args.output)
  /// </code>
  /// </summary>
}