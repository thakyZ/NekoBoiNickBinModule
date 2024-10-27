using namespace System;
using namespace System.IO;
[CmdletBinding()]
[OutputType([bool])]
Param(
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName="ParameterSetName",
             ValueFromPipeline=$true,
             ValueFromPipelineByPropertyName=$true,
             HelpMessage="Path to one or more locations.")]
  [ValidateNotNullOrEmpty()]
  [Alias("PSPath")]
  [string[]]
  $Path,
  # Specifies a type of file to check against.
  [Parameter(Mandatory = $True,
             Position = 1,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Path to one or more locations.")]
  [ValidateNotNullOrEmpty()]
  [ValidateSet("")]
  [string]
  $FileType
)

DynamicParam {
} Begin {
  . "$($PSCommandPath)\classFileSignatures.ps1";
  [System.Boolean] $Output = $True;
} Process {
  If ($Path -is [string]) {
    $Path = @($Path);
  }
  ForEach ($PathItem in $Path) {
    If (-not (Get-UnknownFileType -)) {
      $Output = $False;
    }
  }
} End {
  Write-Output -NoEnumerate -InputObject $Output;
}