using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Management.Automation;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class DictionaryExtensions {
  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static IEnumerable<KeyValuePair<TKey, TValue>> Enumerate<TKey, TValue>(this Dictionary<TKey, TValue> dictionary) where TKey : notnull {
    return dictionary.Select(x => x);
  }

  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static IEnumerable<KeyValuePair<string, object?>> Enumerate(this OrderedDictionary dictionary) {
    return dictionary.Keys.ToListObject().Cast<string>()
      .Select(x => new KeyValuePair<string, object?>(x, dictionary[x]));
  }

  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static IEnumerable<KeyValuePair<string, TValue?>> EnumerateAs<TValue>(this Dictionary<string, object> dictionary) {
    return dictionary.Keys.Where(x => dictionary[x].GetType().IsEquivalentTo(typeof(TValue))).Select(x => new KeyValuePair<string, TValue?>(x, (TValue)dictionary[x]));
  }
}