using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Management.Automation;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

// ReSharper disable once MemberCanBePrivate.Global
// ReSharper disable once UnusedMember.Global

[CmdletBinding(DefaultParameterSetName = "PSPath")]
[SuppressMessage("ReSharper", "MemberCanBeProtected.Global")]
public abstract class PathCmdletBase : CmdletBase {
  [Parameter(Mandatory = true,
    Position = 0,
    ValueFromPipeline = true,
    ParameterSetName = "PSPath",
    HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath")]
  public string[] Path { get; set; } = [WildcardPattern.Escape(CmdletHelpers.CurrentWorkingDirectory().FullName)];

  [Parameter(Mandatory = true,
    Position = 0,
    ParameterSetName = "PSLiteralPath",
    HelpMessage = "Path to one or more locations while not being wildcard pattern escaped.")]
  [Alias("PSLiteralPath")]
  public string[] LiteralPath {
    get => [..this.Path.Select(WildcardPattern.Unescape)];
    set => this.Path = [..value.Select(WildcardPattern.Escape)];
  }
}