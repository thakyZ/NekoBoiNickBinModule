using System.Diagnostics.CodeAnalysis;
using System.Management.Automation;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

// ReSharper disable once UnusedType.Global
// ReSharper disable once UnusedMember.Global

[CmdletBinding(DefaultParameterSetName = "PSFilePath")]
public abstract class FilePathCmdletBase : CmdletBase {
  [Parameter(Mandatory = false,
    Position = 0,
    ValueFromPipeline = true,
    ParameterSetName = "PSFilePath",
    HelpMessage = "")]
  [Alias("PSFilePath")]
  public string FilePath {
    get => this._filePath;
    set => this._filePath = WildcardPattern.Escape(value);
  }
  string _filePath = WildcardPattern.Escape(CmdletHelpers.CurrentWorkingDirectory().FullName);
}