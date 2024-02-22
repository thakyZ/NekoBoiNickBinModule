Param(
  # Automatically confirm package upgrade.
  [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Automatically confirm package upgrade.")]
  [Alias("Y", "Yes")]
  [switch]
  $Confirm = $False,
  # Automatically confirm package upgrade.
  [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Automatically confirm package upgrade.")]
  [Alias("S")]
  [switch]
  $Safe = $False,
  # Specifies packages to exclude when parameter Packages is set to all.
  [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True, HelpMessage = "Specify packages to exclude when parameter Packages is set to all.")]
  [string[]]
  $Exclude = @()
)

Function Invoke-Exit() {
  Param(
    [int]
    $Code = 0
  )
  [Console]::OutputEncoding = $OriginalOutputEncoding;
  Exit $Code;
}

$OriginalOutputEncoding = [Console]::OutputEncoding;
If ($Null -ne $OriginalOutputEncoding -and $OriginalOutputEncoding.GetType() -ne [System.Text.UTF8Encoding]) {
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new();
}

$Scoop = (Get-Command -Name "scoop" -ErrorAction SilentlyContinue);

If ($Null -eq $Scoop) {
  Write-Error -Message "Could not find process scoop on the environment path."
  Invoke-Exit -Code 1;
}

$WinGet = (Get-Command -Name "winget" -ErrorAction SilentlyContinue);

If ($Null -eq $WinGet) {
  Write-Error -Message "Could not find process winget on the environment path."
  Invoke-Exit -Code 1;
}

$Pwsh = (Get-Command -Name "pwsh" -ErrorAction SilentlyContinue);

If ($Null -eq $Pwsh) {
  Write-Error -Message "Could not find process pwsh on the environment path."
  Invoke-Exit -Code 1;
}

If ($Null -eq (Get-Command -Name "Update-ChocoPackage" -ErrorAction SilentlyContinue)) {
  Write-Error -Message "Could not find script called Update-ChocoPackage on the environment path."
  Invoke-Exit -Code 1;
}

$Outdated = @{ Scoop = @(); WinGet = @(); };

Start-Process -FilePath "$($Scoop.Source)" -ArgumentList @("update") -Wait;
$Temp = (& "$($Scoop.Source)" "status");
$Outdated.Scoop = ($Temp | Where-Object { $Exclude -notcontains $_.Name } | Select-Object -Property Name);
ForEach ($Item in $Outdated.Scoop) {
  Start-Process -FilePath "$($Scoop.Source)" -ArgumentList @("update", "$Item") -Wait;
}
Start-Process -FilePath "$($Scoop.Source)" -ArgumentList @("cleanup", "-a") -Wait;

$Temp = (& "$($WinGet.Source)" "list" "--upgrade-available")
$TempMatch = [regex]::Match($Temp, "\d+ package\(s\) have version numbers that cannot be determined\. Use --include-unknown to see all results\.");
If ($TempMatch.Length -gt 0) {
  $Choice = (Read-Host -Prompt "$($TempMatch.Split(". ")[0]). Would you like to Include unknown packages as well? [Y/n]");
  If ($Choice.ToLower() -eq "y") {
    $Temp = (& "$($WinGet.Source)" "list" "--upgrade-available" "--include-unknown")
  }
}

$WinGetOutput = (($Temp | ConvertFrom-SourceTable -Omit "`n   -`n`n`n   -`n   \`n`n" | Where-Object { $_.Name -notmatch "upgrades? available\." } | Format-Table) | Where-Object { $Exclude -notcontains $_.Name -or $Exclude -notcontains $_.Id });

$WinGetOutput | ForEach-Object {
  $Item = $_;

  If (-not $Confirm) {
    $WinGetConfirm = (Read-Host -Prompt "Would you like to update package $($Item.Name)? [y/N]");

    If ($WinGetConfirm.ToLower() -eq "n") {
      Continue;
    }
  }

  (& "$($WinGet.Source)" "upgrade" "-q" "$($Item.Id)" "-e" "-i" )
}

$ScriptBlock = "& { " +
"& `"Update-ChocoPackage`" all ";
if ($Null -ne $Exclude -and $Exclude.Length -gt 0) {
  $ScriptBlock = $ScriptBlock + "-Exclude @(`"$($Exclude.Join(", "))`")"
}
if ($Null -ne $Confirm -and $Confirm -eq $True) {
  $ScriptBlock = $ScriptBlock + "-Confirm"
}
if ($Null -ne $Safe -and $Safe -eq $True) {
  $ScriptBlock = $ScriptBlock + "-Safe"
}
$ScriptBlock = $ScriptBlock + ";Exit `$LASTEXITCODE }";
$ScriptBlock = $ScriptBlock + " }";

$Process = (Start-Process -Verb RunAs -FilePath $Pwsh.Source -ArgumentList @("-Command", "$($ScriptBlock)") -Wait);

If ($Process.ExitCode -ne 0) {
  Write-Warning -Message "Last exit code for Chocolatey updating returned not equal to 0";
  Invoke-Exit -Code 1;
}

Invoke-Exit -Code 0;