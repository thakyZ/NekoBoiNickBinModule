$env:PATH = "$($env:APROG_DIR)\Android\Sdk\emulator;$env:PATH"
Start-Process -NoNewWindow -FilePath "emulator.exe" -ArgumentList "-avd", "Pixel_4_API_30", "-netdelay", "none", "-netspeed", "full" -WorkingDirectory "$($env:APROG_DIR)\Android\Sdk\emulator"