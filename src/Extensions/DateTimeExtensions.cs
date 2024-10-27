using System;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

public static class DateTimeExtensions {
  public static long ToUnixTimestamp(this DateTime dateTime) {
    return ((DateTimeOffset)dateTime).ToUnixTimeMilliseconds();
  }
}