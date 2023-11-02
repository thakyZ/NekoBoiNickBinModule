param()

Write-Host "Install fonts";
$AllFiles = @();
$Fonts = (Get-ChildItem -Path $PWD);
ForEach ($Font in $Fonts) {
  $Files = (Get-ChildItem -Path $Font.FullName -Recurse -Filter "*Windows Compatible*" -Include "*.ttf", "*.ttc", "*.otf")
  If ($Files.Length -gt 0) {
    ForEach ($File in $Files) {
      $AllFiles += $File.FullName
    }
  }
  else {
    $Files = (Get-ChildItem -Path $Font -Include "*.ttf", "*.ttc", "*.otf")
    If ($Files -gt 0) {
      ForEach ($File in $Files) {
        $AllFiles += $File.FullName
      }
    }
  }
}
For ($i = 0; $i -lt $AllFiles.Length; $i++) {
  $Test = ([System.Math]::Ceiling((($i / $AllFiles.Length) * 100)));
  Write-Progress -Activity "Installing Fonts" -Status "$i% Complete:" -PercentComplete $Test
  Write-Host ((Get-ChildItem -Path $AllFiles[$i]).Name -replace '\.(ttf|ttc|otf)$', "")
  #Install-Font $AllFiles[$i].FullName -Scope User -Method Shell
}