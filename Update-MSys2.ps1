[CmdletBinding()]
Param()

Push-Location -LiteralPath $env:TEMP;
New-Item -Path (Join-Path -Path $PWD -ChildPath "msys2-update") -ItemType Directory | Out-Null;
Push-Location -LiteralPath (Join-Path -Path $env:TEMP -ChildPath "msys2-update");
Try {
  $WebRequest=(Invoke-WebRequest -Uri "https://repo.msys2.org/distrib/msys2-x86_64-latest.sfx.exe" -OutFile (Join-Path -Path $PWD -ChildPath "msys2-x86_64-latest.sfx.exe") -ErrorAction SilentlyContinue -UserAgent "Chrome" -SkipHttpErrorCheck -PassThru);
  If ($WebRequest.StatusCode -ne 200) {
    Throw "The download threw error code $($WebRequest.StatusCode)";
  }
} Catch {
  Throw $_;
}
Start-Process -NoNewWindow -FilePath (Join-Path -Path $PWD -ChildPath "msys2-x86_64-latest.sfx.exe") -ArgumentList @("-y", "-o$env:APROG_DIR\") -Wait;
$LastCode = $LASTEXITCODE;
If ($LastCode -ne 0) {
  Throw "Installer exited with code $($LastCode)";
}
Remove-Item (Join-Path -Path $PWD -ChildPath "msys2-x86_64-latest.sfx.exe");
Pop-Location
Remove-Item -Recurse (Join-Path -Path $PWD -ChildPath "msys2-update")
Pop-Location
Exit 0;