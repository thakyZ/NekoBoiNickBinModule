using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.ConvertTo, "Escaped")]
public class ConvertToEscapedCommand : Cmdlet {
}
/*
[CmdletBinding()]
Param(
  # The string to escape.
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             HelpMessage = "The string to escape.")]
  [ValidateNotNullOrEmpty()]
  [System.String[]]
  $InputObject
)

Begin {
  [System.String[]]$CharsToEscape = @( '[', ']', '"' );
  [System.String[]]$Output = @()
}
Process {
  Function Test-ContainsEscapable() {
    [CmdletBinding()]
    Param(
      # The string to escape.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "The string to escape.")]
      [ValidateNotNullOrEmpty()]
      [System.String]
      $InputObject,
      # The string to escape.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "The string to escape.")]
      [ValidateNotNullOrEmpty()]
      [System.String[]]
      $CharsToEscape
    )

    ForEach ($Char in $CharsToEscape) {
      $MatchEscaped = [System.Text.RegularExpressions.Regex]::new("(?<!``)\$($Char)");
      If ($MatchEscaped.IsMatch($InputObject)) {
        $InputObject = $MatchEscaped.Replace($InputObject, "``$($Char)");
      }
    }

    Return $InputObject;
  }

  ForEach ($Input in $InputObject) {
    # $Output += @(Test-ContainsEscapable -InputObject $Input -CharsToEscape $CharsToEscape)
    $Output += @([WildcardPattern]::Escape($Input));
  }
}
End {
  Return $Output;
}
*/
