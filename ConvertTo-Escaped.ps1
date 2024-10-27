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

    Write-Output -NoEnumerate -InputObject $InputObject;
  }

  ForEach ($Input in $InputObject) {
    # $Output += @(Test-ContainsEscapable -InputObject $Input -CharsToEscape $CharsToEscape)
    $Output += @([WildcardPattern]::Escape($Input));
  }
}
End {
  Write-Output -NoEnumerate -InputObject $Output;
}