[CmdletBinding()]
Param (
  [Parameter(Mandatory = $True,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             Position = 0)]
  [System.Text.RegularExpressions.Match]
  $Match,
  [Parameter(Mandatory = $True,
             ValueFromPipelineByPropertyName = $True,
             Position = 1)]
  [System.Text.RegularExpressions.Regex]
  $Regex
)
Process {
  If (-not $Match.Groups[0].Success) {
    Throw [System.ArgumentException]::new("Match does not contain any captures.", "Match");
  }
  $H = @{}
  ForEach ($Name in $Regex.GetGroupNames()) {
    If ($Name -eq 0) {
      Continue;
    }
    $H["$($Name)"] = $Match.Groups["$($Name)"].Value
  }
  Write-Output -NoEnumerate -InputObject $H
}