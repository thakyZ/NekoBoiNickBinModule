using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Management.Automation;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.Cmdlets.SoupCatUtils.Extensions;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class HashtableExtensions {
  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static OrderedDictionary GetIterator(this OrderedHashtable hashtable) {
    var output = new OrderedDictionary();
    object[] keys = [..hashtable.Keys.ToListObject()];
    object[] values = [..hashtable.Values.ToListObject()];

    for (var i = 0; i < hashtable.Keys.Count; i++) {
      output.Add(keys[i], values[i]);
    }

    return output;
  }

  public static Dictionary<string, object> GetIterator(this Hashtable hashtable) {
    var output = new Dictionary<string, object>();
    string[] keys = [..hashtable.Keys.ToListObject().Cast<string>()];
    object[] values = [..hashtable.Values.ToListObject()];

    for (var i = 0; i < hashtable.Keys.Count; i++) {
      output.Add(keys[i], values[i]);
    }

    return output;
  }
}