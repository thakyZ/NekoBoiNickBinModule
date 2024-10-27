using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.PowerShell.Commands;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class StringExtensions {
  public static bool ContainsAny(this string[] strings, string[] compare, StringComparison comparisonType = StringComparison.CurrentCulture) {
    return Array.Exists(strings, (string item) => Array.Exists(compare, (string x) => x.Equals(item, comparisonType)));
  }

  public static string[] SplitRegex(this string @string, Regex regex) {
    return regex.Split(@string);
  }

  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static string[] SplitRegex(this string @string, string regex) {
    var cRegex = new Regex(regex);
    return @string.SplitRegex(cRegex);
  }

  public static IEnumerable<char> Reverse(this string @string) {
    return @string.ToCharArray().Reverse();
  }

  public static string TrimEnd(this string @string, string text) {
    foreach (char @char in text.Reverse()) {
      @string = @string.TrimEnd(@char);
    }
    return @string;
  }

  public static string TrimStart(this string @string, string text) {
    foreach (char @char in text) {
      @string = @string.TrimStart(@char);
    }
    return @string;
  }

  public static string ReplaceRegex(this string @string, Regex regex, string replacement) {
    return regex.Replace(@string, replacement);
  }

  public static string ReplaceRegex(this string @string, string regex, string replacement) {
    var cRegex = new Regex(regex);
    return @string.ReplaceRegex(cRegex, replacement);
  }

  public static bool IsMatch(this string @string, Regex regex) {
    return regex.IsMatch(@string);
  }

  public static bool IsMatch(this string @string, string regex) {
    var cRegex = new Regex(regex);
    return @string.IsMatch(cRegex);
  }

  public static string Join(this string[] strings, string separator) {
    return string.Join(separator, strings);
  }

  public static string Join(this string[] strings, char separator) {
    return strings.Join(separator.ToString());
  }

  public static MatchInfo[] SelectString(this string[] strings, Regex regex) {
    return [..new SelectStringCommand { InputObject = new PSObject(strings), Pattern = [regex.ToString()] }.Invoke().Cast<MatchInfo>()];
  }

  public static MatchInfo[] SelectString(this string[] strings, string regex) {
    var cRegex = new Regex(regex);
    return strings.SelectString(cRegex);
  }

  public static bool EqualsAnyOf(this string @string, string[] matches, StringComparison comparisonType = StringComparison.CurrentCulture) {
    return Array.Exists(matches, (string x) => x.Equals(@string, comparisonType));
  }

  public static bool ContainsAllOf(this string @string, string[] matches, StringComparison comparisonType = StringComparison.CurrentCulture) {
    return Array.TrueForAll(matches, (string x) => x.Contains(@string, comparisonType));
  }

  public static string ConvertFromBase64(this string @string) {
    return Encoding.Default.GetString(Convert.FromBase64String(@string));
  }

  /// <summary>
  /// Parses a python ByteArray to a CSharp <see cref="byte"/>.
  /// </summary>
  /// <param name="hex">The Python ByteArray as a string.</param>
  /// <returns>Bytes parsed. Or null if invalid.</returns>
  public static byte[] PythonByteArrayToCSharpByteArray(this string hex) {
    #region Notes
    /// <summary>
    /// <para>
    /// All of this is bad and a waste of time. Could be useful in the future.
    /// </para>
    /// <code>
    /// List<byte> bytes = [];
    /// Regex regex = new(@"(\\x?[0-9a-fA-F]{1,2}|\\?[^0-9a-fA-F])");
    /// if (!regex.IsMatch(hex)) {
    ///   return null;
    /// }
    /// Regex group1_regex = new(@"^\\[0-9a-fA-F]");
    /// Regex group2_regex = new(@"^\\?[^0-9a-fA-F]");
    /// foreach ((int i, Mat\ch match)in regex.Matches(hex).Enumerate()) {
    ///   int byte_index = 0;
    ///   if (i > 1) {
    ///     byte_index = (int)Math.Floor((double)i / 2);
    ///   }
    ///
    ///   string val = match.Groups[1].Value;
    ///
    ///   if (val.StartsWith("\\x")) {
    ///     val = val.TrimStart('\\').TrimStart('x');
    ///   }
    ///   else
    ///   {
    ///     if (group1_regex.IsMatch(val)) {
    ///       val = val.TrimStart('\\');
    ///     } else if (group2_regex.IsMatch(val)) {
    ///       var encoding = Encoding.UTF8.GetBytes(val);
    ///       var hex_string = BitConverter.ToString(encoding);
    ///       val = hex_string.Replace("-", "");
    ///     } else {
    ///       throw new NotImplementedException($"Hex code handler for {val} not yet implemented.");
    ///     }
    ///   }
    ///   if (val.Length == 1) {
    ///     val = $"0{val}";
    ///   }
    ///   if (val.Length == 2) {
    ///     bytes.Add(Convert.ToByte(val, 16));
    ///   } else if (val.Length > 2 && val.Length % 2 == 0) {
    ///     for (int j = 0; j < val.Length; j++) {
    ///       string _val = val.Substring(j, 2);
    ///       bytes.Add(Convert.ToByte(_val, 16));
    ///       j++;
    ///     }
    ///   } else if (val.Length > 2) {
    ///     throw new NotImplementedException($"Hex code handler for {val} not yet implemented. Length of {val.Length}.");
    ///   }
    /// }
    ///
    /// return bytes.ToArray();
    /// </code>
    /// </summary>
    #endregion
    return [..hex.Select(Convert.ToByte)];
  }
}