param(
  # The string to select from
  [Parameter(Position = 0, Mandatory = $True, HelpMessage = "The string to select from", ParameterSetName = "LineSearch")]
  [Parameter(Position = 0, Mandatory = $True, HelpMessage = "The string to select from", ParameterSetName = "StringSearch")]
  [string]
  $InputObject,
  # The line to select
  [Parameter(Position = 1, HelpMessage = "The line to select", ParameterSetName = "LineSearch")]
  [Int32]
  $Line = -1,
  # The string to search for.
  [Parameter(Position = 1, HelpMessage = "The string to search for", ParameterSetName = "StringSearch")]
  [string]
  $Search = $null,
  # The string to search for.
  [Parameter(Position = 2, Mandatory = $True, HelpMessage = "The column to select", ParameterSetName = "LineSearch")]
  [Parameter(Position = 2, Mandatory = $True, HelpMessage = "The column to select", ParameterSetName = "StringSearch")]
  [Int32]
  $Column = 0
)

$Selected = @();
if ($null -ne $Search) {
  $Selected = ($InputObject -split "\n" | Select-String $Search);
}
elseif ($Line -ne -1) {
  $Selected = (($InputObject -replace "\r", "") -split "\n");
}
$i = 0;
$Found = foreach ($Select in $Selected) {
  [pscustomobject]@{
    Index = $i
    Found = ((($Select -split " " | Where-Object { $_ -ne "" })[$Column..(($Select -split " " | Where-Object { $_ -ne "" }).length - 1)] -join " "));
  }
  $i += 1;
}

Write-Output $Found;



