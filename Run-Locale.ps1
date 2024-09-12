using namespace System;
using namespace System.Management.Automation;

[CmdletBinding(DefaultParameterSetName = "Run")]
Param(
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Run",
             ValueFromPipeline = $True)]
  [ValidateNotNullOrEmpty()]
  [string]
  $Run,
  [Parameter(Mandatory = $True,
             ParameterSetName = "Manage",
             HelpMessage = "Start with the manage configuration window.")]
  [ValidateNotNullOrEmpty()]
  [string]
  $Manage,
  [Parameter(Mandatory = $True,
             ParameterSetName = "Global",
             HelpMessage = "Start with the global configuration.")]
  [switch]
  $Global = $False,
  [Parameter(Mandatory = $False,
             HelpMessage = "Start the process within the current terminal.")]
  [switch]
  $NoNewWindow = $False
)

Begin {
  [ApplicationInfo] $LEProc = (Get-Command -Name "LEProc.exe" -ErrorAction SilentlyContinue)
  [int] $ExitCode = -1;

  If ($Null -eq $LEProc) {
    Write-Error -Message "Locale.Emulator was not found on the system path.";
    Exit 1;
  }

  [string[]] $Argument = @();
  If ($PSCmdlet.ParameterSetName -eq "Run") {
    $Argument = @("-run", $Run);
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Manage") {
    $Argument = @("-manage", $Manage);
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Global") {
    $Argument += @("-global");
  }
}
Process {
  Write-Host $Argument
  Start-Process -FilePath $LEProc.Source -WorkingDirectory $PWD -NoNewWindow:($NoNewWindow) -ArgumentList $Argument -Wait:($NoNewWindow);
  $ExitCode = $LastExitCode;
}
End {
  If ($NoNewWindow -eq $True) {
    Exit $ExitCode;
  }
}