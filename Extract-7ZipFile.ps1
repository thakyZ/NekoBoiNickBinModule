param(
  # The path for the zip file.
  [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The path for the zip file.")]
  [string]
  $Path,
  # The path to extract the zip file to.
  [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The path to extract the zip file to.")]
  [string]
  $Destination,
  # The path that the extracted single file gets named to.
  [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The path that the extracted single file gets named to.")]
  [string]
  $DestFileName,
  # Do not keep the date monidifed attruibute.
  [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Do not keep the date monidifed attruibute.")]
  [switch]
  $NoDateModified
)

function Test-7ZipA() {
  $7zip = (Get-Command -Name "7z.exe");
  if ($null -ne $7zip) {
    Write-Output -NoEnumerate -InputObject $7zip.Path
  }
  Write-Output -NoEnumerate -InputObject "C:\Program Files\7-Zip\7za.exe"
}

$now = Get-Date
$nowf = "$($env:Temp)\$((Get-Date).ToString("yyyyMMdd_hhssmmmtt"))"
New-Item -ItemType Directory -Force -Path $nowf

if ($NoDateModified) {
  Start-Process (Test-7ZipA).ToString() -ArgumentList "x `"$Path`" -o$nowf" -NoNewWindow -Wait

  $i = Get-ChildItem -LiteralPath $nowf -File -Recurse
  $i | ForEach-Object { Process {
      If (Test-Path -LiteralPath $_.FullName) {
        Set-ItemProperty -LiteralPath $_.FullName -Name LastWriteTime -Value $now
        if ($i.Count -eq 1 -and $null -ne $DestFileName) {
          Copy-Item -LiteralPath $_.FullName -Destination "$Destination\$DestFileName" -Force
        }
        else {
          Copy-Item -LiteralPath $_.FullName -Destination $Destination -Force
        }
      }
    }
  };
  Remove-Item -LiteralPath "$nowf" -Force -Recurse;
}
else {
  Start-Process (Test-7ZipA).ToString() -ArgumentList "x `"$Path`" -o$nowf" -NoNewWindow -Wait
  $i = Get-ChildItem -LiteralPath $nowf -File -Recurse
  $i | ForEach-Object { Process {
      If (Test-Path -LiteralPath $_.FullName) {
        if ($i.Count -eq 1 -and $null -ne $DestFileName) {
          Copy-Item -LiteralPath $_.FullName -Destination "$Destination\$DestFileName" -Force
        }
        else {
          Copy-Item -Path $_.FullName -Destination $Destination -Force
        }
      }
    }
  };
  Remove-Item -LiteralPath "$nowf" -Force -Recurse;
}