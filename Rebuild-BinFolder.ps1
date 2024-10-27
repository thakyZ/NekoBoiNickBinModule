param(
  # Open the log folder
  [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Opens the output log file.", ParameterSetName = "OpenOutputFolder")]
  [Switch]
  $OpenOutput,
  # Pass arguments to the binary file
  [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Displays the help message.")]
  [Switch]
  $Help
)

$CurrentDirectory = $PWD;

Function Get-ProgramDirectory() {
  If (-not ([string]::IsNullOrEmpty($env:APROG_DIR))) {
    Write-Output -NoEnumerate -InputObject $env:APROG_DIR;
  }
  Else {
    Write-Output -NoEnumerate -InputObject (Get-Item -Path $PSScriptRoot).Parent.FullName;
  }
}

$APROG_DIR = Get-ProgramDirectory;

$RebuildBinFolder = (Join-Path -Path $APROG_DIR -ChildPath "Rebuild-BinFolder");

$RebuildBinBinary = (Join-Path -Path $RebuildBinFolder -ChildPath "Rebuild-BinFolder.exe");

Set-Location -Path $RebuildBinFolder;

if ($Help) {
  & "$RebuildBinBinary" "-?"
}
else {
  & "$RebuildBinBinary"
}

if ($OpenOutput) {
  Start-Process (Join-Path -Path $RebuildBinFolder -ChildPath "output.log");
}

Set-Location -Path $CurrentDirectory;