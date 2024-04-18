Param(
  # The string to escape.
  [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, HelpMessage = "The string to escape.")]
  [string[]]
  $InputObject
)

Begin {
  $CharsToEscape = @(
    "["
    "]"
    "+"
    "'"
    "`""
  );
  $Output = @()
}
Process {
  Function Test-ContainsEscapable() {
    Param(
      # The string to escape.
      [Parameter(Mandatory = $True, Position = 0, ValueFromPipelineByPropertyName = $True, ValueFromRemainingArguments = $True, ValueFromPipeline = $True, HelpMessage = "The string to escape.")]
      [Alias("InputObject")]
      [string]
      $InputObject2
    )

    ForEach ($Char in $CharsToEscape) {
      If ($InputObject2 -Match "(?<!``)\$($Char)") {
        $InputObject2 = $InputObject2 -Replace "\$($Char)", "``$($Char)"
      }
    }

    Return $InputObject2;
  }

  If ($InputObject.Length -le 0 -or $Null -eq $InputObject) {
    Throw "`$InputObject is empty or null.";
  }

  ForEach ($Input in $InputObject) {
    $Output += @(Test-ContainsEscapable -InputObject $Input)
  }
}
End {
  Return $Output;
}