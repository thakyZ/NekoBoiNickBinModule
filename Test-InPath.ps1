[CmdletBinding()]
[OutputType([System.Boolean])]
Param(
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath", "LiteralPath", "PSLiteralPath")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path,
  # Specifies the partial path variable to check if the full name is in.
  [Parameter(Mandatory = $True,
             Position = 1,
             HelpMessage = "The partial path variable to check if the full name is in.")]
  [Alias("PSMatch", "Paths", "PSPaths", "Matches", "PSMatches")]
  [ValidateNotNullOrEmpty()]
  [System.String[]]
  $Match
)

Begin {
  [System.Boolean]$Output = $False;
} Process {
  [System.String[]]$SplitPath = ($Path.Split([System.IO.Path]::DirectorySeparatorChar));
  ForEach ($SingleMatch in $Match) {
    If ($SplitPath.Contains($SingleMatch)) {
      $Output = $True;
      Break;
    }
  }
} End {
  Write-Output -NoEnumerate -InputObject $Output;
}