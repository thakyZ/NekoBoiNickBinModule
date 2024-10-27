[CmdletBinding()]
Param()

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
}
Process {
  If ($script:OldConsoleMethod) {
    $x, $y = [Console]::GetCursorPosition() -split '\D' -ne '' -as 'int[]'
    If ($script:Debug -eq $True) {
      Write-DebugOver -Message @($x, $y)
    }
    Write-Output -NoEnumerate -InputObject @{ X = $x; Y = $y; }
  } Else {
    $x = [System.Console]::CursorLeft;
    $y = [System.Console]::CursorTop;
    If ($script:Debug -eq $True) {
      Write-DebugOver -Message @($x, $y)
    }
    Write-Output -NoEnumerate -InputObject @{ X = $x; Y = $y; }
  }
}
End {
  Remove-Variable -Scope Script -Name "OldConsoleMethod";
  Remove-Variable -Scope Script -Name "Debug";
  Remove-Variable -Scope Script -Name "Verbose";
}