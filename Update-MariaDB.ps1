using namespace System;
using namespace System.IO;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;
using namespace System.ServiceProcess;

[CmdletBinding()]
Param(
  # Specifies the source to use to install via WinGet.
  [Parameter(Mandatory = $False,
             HelpMessage = 'The source to use to install via WinGet.')]
  [string]
  $Source = 'winget',
  # Specifies for WinGet to use it's commands silently or interactively.
  [Parameter(Mandatory = $False,
             HelpMessage = "WinGet to use it's commands silently or interactively.")]
  [ValidateSet('Default','Silent','Interactive')]
  [string]
  $Mode = 'Silent',
  # Specifies for WinGet to use it's commands with force.
  [Parameter(Mandatory = $False,
             HelpMessage = "WinGet to use it's commands with force.")]
  [switch]
  $Force = $False,
  # Specifies for WinGet to update the package instead of uninstalling and then reinstalling it.
  [Parameter(Mandatory = $False,
             HelpMessage = 'WinGet to update the package instead of uninstalling and then reinstalling it.')]
  [switch]
  $Update = $False,
  # Specifies a location to install the package to.
  [Parameter(Mandatory = $False,
             HelpMessage = 'A location to install the package to.')]
  [AllowNull()]
  [string]
  $Location
)

Begin {
  [ActionPreference]  $OriginalErrorActionPreference = $ErrorActionPreference;
  $ErrorActionPreference = 'Inquire';
  If (-not (Invoke-ElevateScript -Invocation $MyInvocation -BoundParameters $PSBoundParameters -Prompt)) {
    Exit 0;
  }
  [string] $InstallDirectory = (Join-Path -Path 'C:' -ChildPath 'Progra~1');
  [string] $InstallLocation = (Join-Path -Path $InstallDirectory -ChildPath 'MariaDB');
  [bool] $FreshInstall = $False;
  If ($Null -ne $Location -and [Directory]::Exists($Location)) {
    $InstallLocation = $Location;
    $InstallDirectory = (Split-Path -LiteralPath $Location -Parent);
  } ElseIf (-not [Directory]::Exists($Location)) {
    $FreshInstall = $True
  }
  [string] $WinGetPackageName = 'MariaDB.Server';
  [ServiceController] $Service = (Get-Service -Name 'MariaDB' -ErrorAction SilentlyContinue);
  [string[]] $ItemsToBackup = @('data');
  [FileSystemInfo] $BackupDirectory = (Get-BackupDirectory -Root $InstallDirectory -PartialPath 'MariaDB')[1];
  If ($Null -eq $BackupDirectory) {
    Throw "Failed to create backup directory.";
  }
  [PSModuleInfo] $MicrosoftWinGetClientModule = (Get-Module -Name 'Microsoft.WinGet.Client');
  If ($Null -eq $MicrosoftWinGetClientModule) {
    Write-Error -ErrorId 'Update.MariaDB.ModuleNotFound' -Exception <# [ModuleNotFoundException]::new('Microsoft.WinGet.Client') #> [Exception]::new('Microsoft.WinGet.Client') -Category NotInstalled -Message "Could not find the module 'Microsoft.WinGet.Client'";
  }
  Import-Module -Name 'Microsoft.WinGet.Client';
  $WingetPackageInfo = (Get-WinGetPackage -Id $WinGetPackageName);
  # Double check that it is a fresh install.
  If (-not $FreshInstall) {
    $FreshInstall = ($Null -eq $Service -or $Null -eq $WingetPackageInfo);
  }
} Process {
  If (-not $FreshInstall) {
    While ($Service.Status -ne 'Stopped') {
      Stop-Service -InputObject $Service;
      Start-Sleep -Seconds 5;
      $Service = (Get-Service -Name 'MariaDB' -ErrorAction SilentlyContinue);
    }
  }
  ForEach ($ItemToBackup in $ItemsToBackup) {
    Copy-Item -Recurse -LiteralPath (Join-Path -Path $InstallDirectory -ChildPath 'MariaDB' -AdditionalChildPath @($ItemToBackup)) -Destination $BackupDirectory;
  }
  If ($FreshInstall -or -not $Update) {
    Write-Host -Object "Soup1 | FreshInstall = $($FreshInstall) | Service = $($Service) | WingetPackageInfo = $($WingetPackageInfo)" | Out-Host;
    If (-not $FreshInstall) {
      Write-Host -Object 'Soup2' | Out-Host;
      Uninstall-WinGetPackage -Id $WinGetPackageName -Force:($Force -eq $True) -Mode $Mode -Source $Source;
      Write-Host -Object 'Soup3' | Out-Host;
      Remove-Item -Recurse -LiteralPath $InstallLocation -Force;
      Write-Host -Object 'Soup4' | Out-Host;
    }
    Write-Host -Object 'Soup5' | Out-Host;
    Install-WinGetPackage -Id $WinGetPackageName -Version $WingetPackageInfo.Available -Force:($Force -eq $True) -Mode $Mode -Source $Source -Location $InstallLocation;
    Write-Host -Object 'Soup6' | Out-Host;
  } Else {
    Update-WinGetPackage -Id $WinGetPackageName -Version $WingetPackageInfo.Available -Force:($Force -eq $True) -Mode $Mode -Source $Source -Location $InstallLocation;
  }
  ForEach ($ItemToBackup in $ItemsToBackup) {
    Copy-Item -Recurse -LiteralPath (Join-Path -Path $BackupDirectory -ChildPath $ItemToBackup) -Destination (Join-Path -Path $InstallDirectory -ChildPath 'MariaDB') -Force;
  }
  Remove-Item -LiteralPath $BackupDirectory -Recurse -Force;
} End {
  If ($Null -eq $Service) {
    Start-Service 'MariaDB';
  } Else {
    Start-Service -InputObject $Service;
  }
} Clean {
  $ErrorActionPreference = $OriginalErrorActionPreference;
}

