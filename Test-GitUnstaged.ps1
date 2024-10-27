Param(
  [Parameter(Mandatory = $False, Position = 0,
             ValueFromPipeline= $True,
             ValueFromPipelineByPropertyName= $True,
             HelpMessage = "Path to one or more items")]
  [ValidateNotNullOrEmpty()]
  [Alias("PSPath")]
  [string[]]
  $Path = @($PWD),
  [Parameter(Mandatory = $False, Position = 1, HelpMessage = "Process the path(s) provided recursively")]
  [Alias("r")]
  [switch]
  $Recurse
)

$OriginalLocation = $PWD;

$ParsedItems = @();

If ($Recurse) {
  $Items = (Get-ChildItem -LiteralPath $Path -Recurse -Directory | Where-Object { (Test-Path -LiteralPath (Join-Path -Path $_.FullName -ChildPath ".git") -PathType Any) });
  ForEach ($Item in $Items) {
    Set-Location -LiteralPath $Item.FullName;
    $Output=(git status);
    If ($Null -ne ($Output | Select-String "Changes not staged for commit") -or
        $Null -ne ($Output | Select-String "Untracked files") -or
        $Null -ne ($Output | Select-String "Untracked files")) {
      $ParsedItems += $Item;
    }
  }
} Else {
  $Items = (Get-Item -LiteralPath $Path | Where-Object { (Test-Path -LiteralPath (Join-Path -Path $_.FullName -ChildPath ".git") -PathType Any) });
  ForEach ($Item in $Items) {
    Set-Location -LiteralPath $Item.FullName;
    $Output=(git status);
    If ($Null -ne ($Output | Select-String "Changes not staged for commit") -or
        $Null -ne ($Output | Select-String "Untracked files") -or
        $Null -ne ($Output | Select-String "Untracked files")) {
      $ParsedItems += $Item;
    }
  }
}

Set-Location -LiteralPath $OriginalLocation;

Write-Output -NoEnumerate -InputObject $ParsedItems