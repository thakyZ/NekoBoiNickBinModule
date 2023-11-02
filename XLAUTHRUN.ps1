Param()

$XLAuth = (Get-Command -Name "xlauth");
$Token = $Null;

If (Test-Path -LiteralPath (Join-Path $PSScriptRoot -ChildPath "config.json") -PathType Leaf) {
  $Config = (Get-Content -LiteralPath (Join-Path $PSScriptRoot -ChildPath "config.json") | ConvertFrom-Json);
  $Tokens = ($Config.Tokens | Where-Object { $_.Name -eq "XLAuth" });
  If ($Tokens.Length -gt 0) {
    $Token = (ConvertTo-SecureString -AsPlainText -String $Tokens.Token);
  }
}

If (Test-Path -Path $XLAuth.Source -PathType Leaf) {
  & "$($XLAuth.Source)" "-a" "1" "--password=$(ConvertFrom-SecureString $Token)" "-h";
}