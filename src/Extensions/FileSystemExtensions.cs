using System;
using System.IO;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

public static class FileSystemExtensions {
  public static string BaseName(this FileInfo fileInfo) {
    return fileInfo.Name.TrimEnd(fileInfo.Extension);
  }
}