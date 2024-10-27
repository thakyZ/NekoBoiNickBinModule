using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using JetBrains.Annotations;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class EnumerableExtensions {
  public static bool ContainsAny<TSource>(this IEnumerable<TSource> enumerable, TSource[] compare) {
    return enumerable.Any((TSource item) => item is not null && Array.Exists(compare, (TSource x) => x is not null && x.Equals(item)));
  }

  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static bool ContainsAny<TSource>(this IEnumerable enumerable, TSource[] compare) {
    return enumerable.Cast<TSource>().ContainsAny(compare);
  }

  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static TSource? FirstOrDefault<TSource>([InstantHandle] this IEnumerable enumerable) {
    return enumerable.OfType<TSource>().FirstOrDefault();
  }

  public static IEnumerable<(int index, TSource value)> Enumerate<TSource>(this IEnumerable<TSource> list) {
    return list.Select((TSource e, int i) => (i, e)).ToList();
  }
}