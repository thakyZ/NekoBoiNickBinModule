[CmdletBinding()]
Param(
  [System.Object[]]
  $Message
)
If ($script:Debug) {
  $TemplateString = "Debug: ";
  If ($Message.GetType() -eq [System.Object[]]) {
    $TemplateString += "$([System.String]::Join(" ", $Message))"
  } Else {
    $TemplateString += "$($Message)"
  }
  $OriginalConsolePosition = (Get-ConsolePosition -NoDebug);
  $TempConsolePosition = (Get-ConsolePosition -NoDebug);
  $TempConsolePosition.X = ([System.Console]::WindowWidth - $TemplateString.Length);
  Set-ConsolePosition -Coordinates $TempConsolePosition -NoDebug;
  If ($Message.GetType() -eq [System.Object[]]) {
    Write-Host -Object "Debug: " -ForegroundColor Blue -NoNewline;
    ForEach ($Item in $Message) {
      Write-Host -Object "$($Item) " -ForegroundColor White -NoNewline;
    }
  } Else {
    Write-Host -Object "Debug: " -ForegroundColor Blue -NoNewline;
    Write-Host -Object "$($Message)" -ForegroundColor White;
  }
  Set-ConsolePosition -Coordinates $OriginalConsolePosition -NoDebug;
}