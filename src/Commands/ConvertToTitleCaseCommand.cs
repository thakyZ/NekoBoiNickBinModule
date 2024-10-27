using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.ConvertTo, "TitleCase")]
public class ConvertToTitleCaseCommand : Cmdlet {
}
/*
[CmdletBinding()]
[OutputType([System.String])]
Param(
  # Specifies a string to convert to Title Case
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             HelpMessage = "A string to convert to Title Case.")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $String,
  # Specifies a culture to use. Is CurrentUICulture by default.
  [Parameter(Mandatory = $False,
             HelpMessage = "A culture to use. Is CurrentUICulture by default.")]
  [AllowNull()]
  [System.Globalization.CultureInfo]
  $Culture
)

Begin {
  [System.String]$Output = $String;
} Process {
  If ($Null -eq $Culture) {
    $Culture = [System.Globalization.CultureInfo]::CurrentUICulture;
  }
  $Output = $Culture.TextInfo.ToTitleCase(($String.ToLower()));
} End {
  Return $Output;
}
*/