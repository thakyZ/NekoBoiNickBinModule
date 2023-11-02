param(
  [P0arameter(Position = 0,
  Mandatory = $true,
  HelpMessage = 'Boolean to set value')]
  [Boolean]$toggle
)

begin {
  if ($toggle -eq $true) {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Terraria" -Name "Bunny" -Value 1;
  } else {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Terraria" -Name "Bunny" -Value 0;
  }
} process {
  $output = $false;
  $result = [ordered]@{ };
  $result.Add("PATH","HKCU:\SOFTWARE\Terraria");
  if ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Terraria" -Name "Bunny") -match 1) {
    $output = $true;
  } else {
    $output = $false;
  }
  $result.Add("Bunny",$output);
  return $result;
}