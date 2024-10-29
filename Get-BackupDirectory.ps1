using namespace System;
using namespace System.IO;
using namespace System.Management.Automation;
using namespace System.ServiceProcess;

[CmdletBinding(DefaultParameterSetName = 'PartialPath')]
[OutputType([DirectoryInfo])]
Param(
  # TODO: Figure out why you only originally had a partial path parameter as you do not know.
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = 'PartialPath',
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = 'A partial path to the backup location.')]
  [Alias('PSPath','Path')]
  [ValidateNotNullOrEmpty()]
  [string]
  $PartialPath,
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 1,
             ParameterSetName = 'PartialPath',
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = 'The root path to the location the partial path is in.')]
  [ValidateNotNullOrEmpty()]
  [string]
  $Root
)

Begin {
  [ActionPreference] $OriginalErrorActionPreference = $ErrorActionPreference;
  $ErrorActionPreference = 'Continue';
  [DirectoryInfo] $Output;
} Process {
  [string] $BackupPath = (Join-Path -Path $Root -ChildPath "$($PartialPath).backup");
  $Output = [DirectoryInfo]::new($BackupPath);
  If (-not $Output.Exists) {
    New-Item -Path $Output -ItemType Directory | Out-Null;
  } Else {
    Write-Error -ErrorId 'Get.BackupDirectory.AlreadyExists' -Exception [Exception]::new("Backup directory could not be created as it already exists at `"$($Output)`".") -Message "Backup directory could not be created as it already exists at `"$($Output)`"." | Out-Host;
    $Output = $Null;
  }
} End {
  Write-Output -NoEnumerate -InputObject $Output;
} Clean {
  $ErrorActionPreference = $OriginalErrorActionPreference;
}