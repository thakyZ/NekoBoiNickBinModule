using System;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;
using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.ConvertFrom, "RegexNamedGroupCapture")]
public class ConvertFromRegexNamedGroupCaptureCommand : Cmdlet
{
  internal static object Invoke(Match match, Regex regex)
  {
    throw new NotImplementedException();
  }
}
/*
[CmdletBinding()]
Param (
  [Parameter(Mandatory = $True,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             Position = 0)]
  [System.Text.RegularExpressions.Match]
  $Match,
  [Parameter(Mandatory = $True,
             ValueFromPipelineByPropertyName = $True,
             Position = 1)]
  [System.Text.RegularExpressions.Regex]
  $Regex
)
Process {
  If (-not $Match.Groups[0].Success) {
    Throw [System.ArgumentException]::new("Match does not contain any captures.", "Match");
  }
  $H = @{}
  ForEach ($Name in $Regex.GetGroupNames()) {
    If ($Name -eq 0) {
      Continue;
    }
    $H["$($Name)"] = $Match.Groups["$($Name)"].Value
  }
  Return $H
}
*/
