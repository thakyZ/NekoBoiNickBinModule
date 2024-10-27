[CmdletBinding(DefaultParameterSetName = "Open")]
Param(
  # Specifies the text to find on each line. The pattern value is treated as a regular expression.
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromRemainingArguments = $True,
             ParameterSetName = "Pattern",
             HelpMessage = "Specifies the text to find on each line. The pattern value is treated as a regular expression.`n`nTo learn about regular expressions, see about_Regular_Expressions (../Microsoft.PowerShell.Core/About/about_Regular_Expressions.md).")]
  [System.String]
  $Pattern = "",
  # Indicates that the cmdlet uses a simple match rather than a regular expression match. In a simple match, `Select-String` searches the input for the text in the Pattern parameter. It doesn't interpret the value of the Pattern parameter as a regular expression statement.
  #
  # Also, when SimpleMatch is used, the Matches property of the MatchInfo object returned is empty.
  #
  # > [!NOTE] > When this parameter is used with the AllMatches parameter, the AllMatches is ignored.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Pattern",
             HelpMessage = "Indicates that the cmdlet uses a simple match rather than a regular expression match. In a simple match, `Select-String` searches the input for the text in the Pattern parameter. It doesn't interpret the value of the Pattern parameter as a regular expression statement.`n`nAlso, when SimpleMatch is used, the Matches property of the MatchInfo object returned is empty.`n`n> [!NOTE] > When this parameter is used with the AllMatches parameter, the AllMatches is ignored.")]
  [System.Management.Automation.SwitchParameter]
  $SimpleMatch,
  # Only the first instance of matching text is returned from each input file. This is the most efficient way to retrieve a list of files that have contents matching the regular expression.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Pattern",
             HelpMessage = "Only the first instance of matching text is returned from each input file. This is the most efficient way to retrieve a list of files that have contents matching the regular expression.`n`nBy default, `Select-String` returns a MatchInfo object for each match it finds.")]
  [System.Management.Automation.SwitchParameter]
  $List,
  # Specifies a switch to find text that doesn't match the specified pattern.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Pattern",
             HelpMessage = "The NotMatch parameter finds text that doesn't match the specified pattern.")]
  [System.Management.Automation.SwitchParameter]
  $NotMatch,
  # By default, `Select-String` highlights the string that matches the pattern you searched for with the Pattern parameter. The NoEmphasis parameter disables the highlighting.
  # 
  # The emphasis uses negative colors based on your PowerShell background and text colors. For example, if your PowerShell colors are a black background with white text. The emphasis is a white background with black text.
  # 
  # This parameter was introduced in PowerShell 7.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Pattern",
             HelpMessage = "By default, `Select-String` highlights the string that matches the pattern you searched for with the Pattern parameter. The NoEmphasis parameter disables the highlighting.`n`nThe emphasis uses negative colors based on your PowerShell background and text colors. For example, if your PowerShell colors are a black background with white text. The emphasis is a white background with black text.`n`nThis parameter was introduced in PowerShell 7.")]
  [System.Management.Automation.SwitchParameter]
  $NoEmphasis,
  # Specifies a switch to indicate that the cmdlet returns a Boolean value (True or False), instead of a MatchInfo object. The value is True if the pattern is found; otherwise the value is False.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Pattern",
             HelpMessage = "Indicates that the cmdlet returns a Boolean value (True or False), instead of a MatchInfo object. The value is True if the pattern is found; otherwise the value is False.")]
  [System.Management.Automation.SwitchParameter]
  $Quiet,
  # Specifies a switch to print the file path to the history log.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "File",
             HelpMessage = "A switch to print the file path to the history log.")]
  [System.Management.Automation.SwitchParameter]
  $File,
  # Specifies a switch to open the file path to the history log.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Open",
             HelpMessage = "A switch to open the file path to the history log.")]
  [System.Management.Automation.SwitchParameter]
  $Open
)

Begin {
  $SavePath = (Get-PSReadlineOption).HistorySavePath;
  $Output = $Null;
} Process {
  If ($PSCmdlet.ParameterSetName -eq "Pattern") {
    $Output = (Select-String -Path $SavePath -Encoding "UTF8" -Pattern $Pattern -SimpleMatch:($SimpleMatch) -List:($List) -NotMatch:($NotMatch) -NoEmphasis:($NoEmphasis) -Quiet:($Quiet));
  } ElseIf ($PSCmdlet.ParameterSetName -eq "File") {
    $Output = (Get-Item -LiteralPath $SavePath);
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Open") {
    & "$((Get-Item -LiteralPath $SavePath).FullName)";
  }
} End {
  $Output | Write-Output;
}
