using System.Linq;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class ListExtensions {
  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static IEnumerable<(int index, T value)> Enumerate<T>(this List<T> list) {
    return list.Select((T e, int i) => (i, e)).ToList();
  }
}