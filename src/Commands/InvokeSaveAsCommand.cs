using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Invoke, "SaveAs")]
public class InvokeSaveAsCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "Path")]
Param(
  # Specifies a path to the temporary file to save into another location. Unlike the Path parameter, the value of
  # the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the
  # path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows
  # PowerShell not to interpret any characters as escape sequences.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "LiteralPath",
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Literal path to the temporary file to save into another location.")]
  [Alias("PSLiteralPath")]
  [ValidateNotNullOrWhiteSpace()]
  [System.String]
  $LiteralPath,
  # Specifies the path to the temporary file to save into another location.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Path",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Path to the temporary file to save into another location.")]
  [Alias("PSPath")]
  [ValidateNotNullOrWhiteSpace()]
  [System.String]
  $Path
)

Begin {

}
*/
