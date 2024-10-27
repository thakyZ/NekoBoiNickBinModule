using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.ConvertTo, "PascalCase")]
public class ConvertToPascalCaseCommand : Cmdlet {
}
/*
[CmdletBinding()]
[OutputType([System.String])]
Param(
  # Specifies a string to convert to PascalCase
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             HelpMessage = "A string to convert to PascalCase.")]
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
  [System.Text.RegularExpressions]$CaseMatchRegex = [System.Text.RegularExpressions]::new("(?:([A-Z]?[a-z]+)[ _-]?)+");
  [System.Text.StringBuilder]     $Output         = [System.Text.StringBuilder]::new();
} Process {
  ForEach ($Match in $CaseMatchRegex.Matches($String)) {
    ForEach ($Group in $Match.Groups.Values) {
      If ($Group.Value -ne $String) {
        $Output.Append((ConvertTo-TitleCase -String $Group -Culture $Culture));
      }
    }
  }
} End {
  Return $Output.ToString();
}
*/
