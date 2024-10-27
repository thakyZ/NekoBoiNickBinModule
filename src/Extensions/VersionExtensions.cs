using System;
using System.Linq;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
public static class VersionExtensions {
  /// <summary>
  /// Gets the highest <see cref="Version"/> from the list passed.
  /// </summary>
  /// <param name="versionList">A list of one or more versions containing</param>
  /// <returns>The highest <see cref="Version"/> of the list of versions.</returns>
  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static Version Max(List<Version> versionList) {
    if (versionList.Count == 0) throw new ArgumentException("The list passed is null.", nameof(versionList));
    if (versionList.Count == 1) return versionList[0];
    return versionList.OrderBy(v => v.Major).ThenBy(v => v.Minor).ThenBy(v => v.Build).ThenBy(v => v.Revision).Last();
  }

  /// <summary>
  /// Gets the lowest <see cref="Version"/> from the list passed.
  /// </summary>
  /// <param name="versionList">A list of one or more versions containing</param>
  /// <returns>The lowest <see cref="Version"/> of the list of versions.</returns>
  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  public static Version Min(List<Version> versionList) {
    if (versionList.Count == 0) throw new ArgumentException("The list passed is null.", nameof(versionList));
    if (versionList.Count == 1) return versionList[0];
    return versionList.OrderBy(v => v.Major).ThenBy(v => v.Minor).ThenBy(v => v.Build).ThenBy(v => v.Revision).First();
  }
}