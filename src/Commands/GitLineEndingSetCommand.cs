using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "GitLineEndingSet")]
public class GetGitLineEndingSetCommand : Cmdlet {
}
/*
param(
  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory=$true,
             Position=0,
             ParameterSetName="LiteralPath",
             ValueFromPipelineByPropertyName=$true,
             HelpMessage="Literal path to one or more locations.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $LiteralPath
  # Parameter help description
  [Parameter(AttributeValues)]
  [ParameterType]
  $ParameterName
)
*/
