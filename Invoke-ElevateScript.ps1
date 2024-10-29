using namespace System;
using namespace System.IO;
using namespace System.Collections.Generic;
using namespace System.Diagnostics;
using namespace System.Management.Automation;
using namespace System.Security.Principal;
using namespace System.ServiceProcess;

[CmdletBinding()]
[OutputType([bool])]
Param(
  # Specifies the original script's invocation info.
  [Parameter(Mandatory = $True,
             HelpMessage = "The original script's invocation info.")]
  [InvocationInfo]
  $Invocation,
  # Specifies the original script's bound parameters.
  [Parameter(Mandatory = $True,
             HelpMessage = "The original script's bound parameters.")]
  [Dictionary[[string], [object]]]
  $BoundParameters,
  # Specifies that the CmdLet will prompt the user before elevation.
  [Parameter(Mandatory = $False,
             HelpMessage = 'The CmdLet will prompt the user before elevation.')]
  [switch]
  $Prompt
)

Begin {
  [bool] $Output = $False;
  [WindowsIdentity] $MyWindowsID = [WindowsIdentity]::GetCurrent();
  [WindowsPrincipal] $MyWindowsPrincipal= [WindowsPrincipal]::new($MyWindowsID);
  [WindowsBuiltInRole] $AdminRole = [WindowsBuiltInRole]::Administrator;
} Process {
  If (-not $MyWindowsPrincipal.IsInRole($AdminRole)) {
    # Make sure to test this with all sorts of different scripts and parameters as some may require specific ways of supplying arguments.
    [string[]] $Arguments = @('-File', $Invocation.MyCommand.Definition);
    ForEach ($Key in $BoundParameters.Keys) {
      [object] $Value = $BoundParameters[$Key];
      If ($Value -eq 'True' -or $Value -eq 'False') {
        $Value = "`$$($Value)";
      }
      $Arguments += " -$($Key) $($Value)";
    }
    If ($Prompt) {
      Write-Host -Object "Running command `"pwsh`" with arguments `"$($Arguments)`"";
      [string] $Prompt = (Read-Host -Prompt 'Continue?');
    }
    # Start the new process
    Start-Process -Wait -FilePath 'pwsh' -WorkingDirectory $PWD -ArgumentList $Arguments -Verb "RunAs";
  } Else {
    $Output = $True;
  }
} End {
  Write-Output -NoEnumerate -InputObject $Output;
}