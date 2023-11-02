Param()

$Code = 1;
$Choco = (Get-Command -Name "choco");
$List = @();
$Outdated = (& $Choco.Source "outdated");
$OutdatedSplit = ($Outdated -split '`r?`n');
ForEach ($Item in $OutdatedSplit) {
  If ($Item.Contains('|') -and -not $Item.Contains(' | ')) {
    $ItemSplit = ($Item -Split '\|');
    $PackageName = $ItemSplit[0];
    $List += @($PackageName);
  }
}
$FilteredList = ($List | Where-Object { $_ -ne "imhex" -and $_ -ne "llvm" });
$List = @($FilteredList);
Write-Host "Modifying these packages:"
$JoinedList = [string]::Join('", "', $List);
Write-Host -ForegroundColor Blue "`"$($JoinedList)`"";
$Prompt = (Read-Host -Prompt "Is this okay? [y/N]");
If ($Prompt.ToLower() -eq "y") {
  Update-ChocoPackage.ps1 -Packages $List -y;
  $Code = $LASTEXITCODE;
}
Exit $Code;