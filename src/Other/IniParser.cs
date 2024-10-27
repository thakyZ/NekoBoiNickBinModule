using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Numerics;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.Cmdlets;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

[SuppressMessage("ReSharper", "UnusedType.Global")]
public static partial class IniParser {
  private static object? ParseValue(string value) {
    if (value.StartsWith("@ByteArray")) {
      if (ByteArrayRegex().Match(value) is Match match) {
        return match.Groups[1].Value.PythonByteArrayToCSharpByteArray();
      }

      throw new ParseException($"Failed to parse value of \"{value}\" to type byte[].");
    }

    if (value.StartsWith("@Invalid") || string.IsNullOrEmpty(value) || string.IsNullOrWhiteSpace(value)) {
      return null;
    }

    if (value.StartsWith("@Variant")) {
      if (VariantRegex().Match(value) is Match match) {
        return match.Groups[1].Value.PythonByteArrayToCSharpByteArray();
      }

      throw new ParseException($"Failed to parse value of \"{value}\" to type Variant.");
    }

    if (value.StartsWith("@Size")) {
      if (SizeRegex().Match(value) is not Match match) {
        throw new ParseException($"Failed to parse value of \"{value}\" to type Vector2.");
      }

      var x = int.Parse(match.Groups[1].Value);
      var y = int.Parse(match.Groups[2].Value);
      return new Vector2(x, y);
    }

    if (value.StartsWith("@Rect")) {
      if (RectRegex().Match(value) is not Match match || match.Groups.TryParseAll<int>(1, 4, out int[]? vars) || vars is not int[] vector) {
        throw new ParseException($"Failed to parse value of \"{value}\" to type Vector4.");
      }

      return new Vector4(vector[0], vector[1], vector[2], vector[3]);

    }

    string type = OtherRegex().Match(value).Groups[1].Value;
    throw new NotImplementedException($"Type handler {type} not yet implemented please report to the author.");
  }

  public static async Task<Dictionary<string, Dictionary<string, object?>>> ParseFileToHashtableAsync(string filePath) {
    await using var fileStream = new FileStream(filePath, FileMode.Open);
    using var streamReader = new StreamReader(fileStream);
    var text = await streamReader.ReadToEndAsync();
    return ParseStringToHashtable(text);
  }

  private static Dictionary<string, Dictionary<string, object?>> ParseStringToHashtable(string input) {
    Dictionary<string, Dictionary<string, object?>> output = [];
    foreach (Group[] groups in IniRegex().Matches(input).Cast<Match>().Select(x => x.Groups.Cast<Group>()).Cast<Group[]>()) {
      Dictionary<string, object?> subTable = [];

      if (groups.Length > 2 && groups[2].Captures.Count > 0 && groups[2].Captures.Count == groups[3].Captures.Count) {
        for (var i = 0; i < groups[2].Captures.Count; i++) {
          var key = groups[2].Captures[i].Value;
          object? rawValue = groups[3].Captures[i].Value.TrimStart('"').TrimEnd('\r').TrimEnd('"');

          if (rawValue is string value && value.StartsWith('@')) {
            rawValue = ParseValue(value);
          }

          subTable.Add(key, rawValue);
        }
      }

      output.Add(groups[1].Value, subTable);
    }

    return output;
  }

  [GeneratedRegex(@"@ByteArray\((.+(?=\)$))\)")]
  private static partial Regex ByteArrayRegex();
  [GeneratedRegex(@"@Size\((\d+) (\d+)\)")]
  private static partial Regex SizeRegex();
  [GeneratedRegex(@"@Rect\((\d+) (\d+) (\d+) (\d+)\)")]
  private static partial Regex RectRegex();
  [GeneratedRegex(@"^@(\w+)\(")]
  private static partial Regex OtherRegex();
  [GeneratedRegex(@"@Variant\((.+(?=\)$))\)")]
  private static partial Regex VariantRegex();
  [GeneratedRegex(@"^\[([^\]]+)\](?:\r?\n(?:(.+)=(.*)))*", RegexOptions.Multiline)]
  private static partial Regex IniRegex();
}