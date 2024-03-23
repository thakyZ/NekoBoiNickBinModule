[CmdletBinding()]
Param(
  # Specifies a PSObject that contains the coordinates to adjust the console position to.
  [Parameter(Mandatory = $True,
             Position = 0,
             HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
  [Alias("Pos", "Position", "Coord")]
  [PSCustomObject]
  $Coordinates
)

Begin {
  $script:Debug = $False;

  If ($DebugPreference -ne "SilentlyContinue" -and $DebugPreference -ne "Ignore") {
    $script:Debug = $True;
  }

  $script:Verbose = $False;

  If ($VerbosePreference -ne "SilentlyContinue" -and $VerbosePreference -ne "Ignore") {
    $script:Verbose = $True;
  }

  $script:OldConsoleMethod = $False;

  If ($script:Debug -eq $True) {
    Write-DebugOver -Message @($Coordinates.X, $Coordinates.Y)
  }
}
Process {
  If ($script:OldConsoleMethod) {
    [System.Console]::SetCursorPosition($Coordinates.X, $Coordinates.Y);
    If ($script:Debug -eq $True) {
      $X, $Y = [Console]::GetCursorPosition() -split '\D' -ne '' -as 'int[]'
      Write-DebugOver -Message @($X, $Y)
    }
  } Else {
    [System.Console]::CursorLeft = $Coordinates.X;
    [System.Console]::CursorTop = $Coordinates.Y;
    If ($script:Debug -eq $True) {
      $X = [System.Console]::CursorLeft;
      $Y = [System.Console]::CursorTop;
      Write-DebugOver -Message @($X, $Y);
    }
  }
}
End {
  Remove-Variable -Scope Script -Name "OldConsoleMethod";
  Remove-Variable -Scope Script -Name "Debug";
  Remove-Variable -Scope Script -Name "Verbose";
}
