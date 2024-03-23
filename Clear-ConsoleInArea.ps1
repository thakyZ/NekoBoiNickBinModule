[CmdletBinding()]
Param(
  # Specifies a PSObject that contains the coordinates to adjust the console position to.
  [Parameter(Mandatory = $True,
             Position = 0,
             HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
  [Alias("Start")]
  [PSCustomObject]
  $CoordinatesStart,
  # Specifies a PSObject that contains the coordinates to adjust the console position to.
  [Parameter(Mandatory = $True,
             Position = 1,
             HelpMessage = "A PSObject that contains the coordinates to adjust the console position to.")]
  [Alias("End")]
  [PSCustomObject]
  $CoordinatesEnd
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

  $Rectangle = @{
    X = 0;
    Y = $CoordinatesStart.Y;
    Width = ([System.Console]::WindowWidth);
    Height = ($CoordinatesStart.Y - $CoordinatesEnd.Y);
    Start = @{
      X = 0;
      Y = $CoordinatesStart.Y
    };
    Size = @{
      Width = ([System.Console]::WindowWidth);
      Height = ($CoordinatesStart.Y - $CoordinatesEnd.Y);
    }
  };
}
Process {
  Set-ConsolePosition -Coordinates @{ X = 0; Y = $CoordinatesStart.Y; } -Debug:($script:Debug -eq $True);

  If ($script:Debug -eq $True) {
    Write-Host [System.String]::new(" ", ($Rectangle.Width * $Rectangle.Height));
  }

  Set-ConsolePosition -Coordinates $CoordinatesStart -Debug:($script:Debug -eq $True);
}
End {
  Remove-Variable -Scope Script -Name "Debug";
  Remove-Variable -Scope Script -Name "Verbose";
}