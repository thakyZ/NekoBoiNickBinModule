using System.Linq;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Text.RegularExpressions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;
using System.Reflection;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

[SuppressMessage("ReSharper", "UnusedMember.Global")]
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class RegexExtensions {
  public static IEnumerable<(int index, Match value)> Enumerate(this MatchCollection matchList) {
    return matchList.ToList().Enumerate();
  }

  public static IEnumerable<Match> ToList(this MatchCollection matchList) {
    return [..matchList.Select((Match x) => x)];
  }


  public static bool TryParseAll<T>(this GroupCollection collection, int start, int end, out T[]? vars) {
    List<T> output = [];

    if (!GetMethodHelper.TryGetTryParseMethod<T>(out MethodInfo? method, out var _) || method is null) {
      vars = null;
      return false;
    }

    for (var i = start; i < end + 1; i++) {
      T? tempVar = default;

      if ((bool?)method.Invoke(collection[i].Value, [tempVar]) != true) continue;

      if (tempVar is null) {
        vars = null;
        return false;
      }

      output.Add(tempVar);
    }

    vars = [..output];
    return true;
  }
}