using System;
using System.Diagnostics.CodeAnalysis;
using System.Reflection;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class GetMethodHelper {
  public static MethodInfo? GetTryParseMethod<T>() {
    var tType = typeof(T);
    var tMethods = tType.GetMethods();
    if (!Array.Exists(tMethods, x => x.Name.Equals("TryParse"))) {
      return null;
    }
    return Array.Find(tMethods, x => x.Name.Equals("TryParse"));
  }

  public static bool TryGetTryParseMethod<T>(out MethodInfo? methodInfo, out Exception? exception) {
    methodInfo = null;
    exception = null;

    try {
      methodInfo = GetTryParseMethod<T>();
      return methodInfo is not null;
    } catch (Exception _exception) {
      exception = _exception;
    }

    return false;
  }
}