Function Get-ProfileConfigJson() {
  [CmdletBinding()]
  Param(
    # Specifies a path to a config file (really just any JSON file.)
    [Parameter(Mandatory = $False,
               Position = 0,
               ValueFromPipeline = $True,
               HelpMessage = "A path to a config file (really just any JSON file.)")]
    [AllowNull()]
    [Alias("LiteralPath","PSPath")]
    [string]
    $Path = $Null
  )

  Begin {
    [string] $ConfigPath = $Null;

    If (-not [string]::IsNullOrEmpty($Path) -and -not [string]::IsNullOrWhiteSpace($Path)) {
      $ConfigPath = $Path;
    } Else {
      If ($Null -ne $global:ProfileDirectory) {
        $ConfigPath = (Join-Path -Path $global:ProfileDirectory -ChildPath "config.json")
      } ElseIf ($Null -ne $env:ProfileDirectory) {
        $ConfigPath = (Join-Path -Path $env:ProfileDirectory -ChildPath "config.json")
      } Else {
        $ConfigPath = (Join-Path -Path (Get-Item -LiteralPath $PROFILE).Directory.FullName -ChildPath "config.json")
      }
    }
  } Process {
    $ConfigJson = (Get-Content -LiteralPath $ConfigPath | ConvertFrom-Json -Depth 100 -AsHashtable)
  } End {
    Write-Output -NoEnumerate -InputObject $ConfigJson;
  }
}