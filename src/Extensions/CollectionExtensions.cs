using System;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;
using System.Reflection;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class CollectionExtensions {
  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static bool ContainsAny<TSource>(this ICollection<TSource> collection, TSource[] compare) {
    return collection.Any((TSource item) => item is not null && Array.Exists(compare, (TSource x) => x is not null && x.Equals(item)));
  }

  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static IEnumerable<TSource> ToList<TSource>(this ICollection<TSource> collection) {
    List<TSource> output = [];
    output.AddRange(collection);
    return output;
  }

  public static bool Any(this ICollection collection, Func<object, bool> predicate) {
    return collection.ToListObject().Any(predicate);
  }

  public static IEnumerable<object> ToListObject(this ICollection collection) {
    List<object> output = [];
    output.AddRange(collection.Cast<object>());
    return output;
  }

  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static bool TryParseAll<TSource>(this ICollection collection, int start, int end, out TSource[]? vars) {
    List<TSource> output = [];
    List<object> list = [..collection.ToListObject()];

    if (!GetMethodHelper.TryGetTryParseMethod<TSource>(out MethodInfo? method, out var _) || method is null) {
      vars = null;
      return false;
    }

    for (var i = start; i < end + 1; i++) {
        TSource? tempVar = default;

        if ((bool?)method.Invoke(list[i], [tempVar]) != true) continue;

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