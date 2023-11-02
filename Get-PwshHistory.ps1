[CmdletBinding(DefaultParameterSetName = "File")]
Param(
  # <>
  [Parameter(Mandatory = $False,
             Position = 0,
             ValueFromRemainingArguments = $True,
             ParameterSetName = "Match",
             HelpMessage = "<>")]
  [string]
  $Match = "",
  # <>
  [Parameter(Mandatory = $False,
             Position = 1,
             ParameterSetName = "File",
             HelpMessage = "<>")]
  [switch]
  $File
)

$SavePath = (Get-PSReadlineOption).HistorySavePath;

If ($PSCmdlet.ParameterSetName -eq "Match") {
  $FileContents = (Get-Content -LiteralPath $SavePath -Encoding utf8)
  $FoundResults = ($FileContents | Select-String -Pattern $Match);
  $FoundResults | Write-Output;
} ElseIf ($PSCmdlet.ParameterSetName -eq "File") {
  $SavePath | Write-Output;
}