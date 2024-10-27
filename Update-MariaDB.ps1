using namespace System;
using namespace System.IO;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.ServiceProcess;

[CmdletBinding()]
Param()

Begin {
  Function Get-WinGetPackage {
    [CmdletBinding()]
    [OutputType([Dictionary[[System.String],[System.String]]])]
    Param(
      # Specifies the id for a WinGet package.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ParameterSetName = "Id",
                 ValueFromPipeline = $True,
                 HelpMessage = "The id for a WinGet package.")]
      [string]
      $Id
    )

    Begin {
      [Dictionary[[System.String],[System.String]]] $Output = [Dictionary[[System.String],[System.String]]]::new();
    } Process {

    } End {

    }
  }

  [string] $WinGetPackageName = "MariaDB.Server"
  [ActionPreference]  $OriginalErrorActionPreference = $ErrorActionPreference;
  [ServiceController] $Service = (Get-Service -Name "MariaDB" -ErrorAction SilentlyContinue);
  [ApplicationInfo]   $WinGet  = (Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue);
  [FileSystemInfo]    $BackupDirectory = (Get-BackupDirectory -PartialPath "MariaDB");
  [bool] $FreshInstall = ($Null -eq $Service -or (Get-WinGetPackage -Id $WinGetPackageName));
} Process {
  If (-not $FreshInstall) {
    If ($Service.Status -ne "Stopped") {
      Stop-Service -InputObject $Service;
    }
  }
} End {
  Start-Service -InputObject $Service;
} Clean {
  $ErrorActionPreference = $OriginalErrorActionPreference;
}

