Param()

Function Get-ProfileConfig() {
  Param()

  $Returned = $Null;
  $ConfigPath = (Join-Path -Path (Get-Item -LiteralPath $Profile).Directory.FullName -ChildPath "config.json");

  Try {
    $ConfigText = (Get-Content -LiteralPath $ConfigPath);
    $Returned = ($ConfigText | ConvertFrom-Json);
  }
  Catch {
    Write-Error -Exception $_.Exception -Message "Failed to load the PowerShell profile config at, $($ConfigPath)"
    Exit 1;
  }

  Return $Returned;
}

$script:Config = (Get-ProfileConfig);

Function Test-ScoopOnPath() {
  Param()

  if ($Null -eq (Get-Command -Name "scoop" -ErrorAction SilentlyContinue)) {
    Return $False;
  }
  Return $True;
}

Function Import-PoshGit() {
  Param()

  $PoshGitModule = Get-Module posh-git -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1;
  If ($PoshGitModule) {
    $PoshGitModule | Import-Module;
  }
  ElseIf (Test-Path -LiteralPath ($ModulePath = (Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -ChildPath (Join-Path -Path src -ChildPath "posh-git.psd1")))) {
    Import-Module $ModulePath;
  }
  ElseIf (Test-ScoopOnPath -and Test-Path -LiteralPath ($ModulePath = (Join-Path -Path (Split-Path -Path "$(scoop prefix posh-git)") -ChildPath (Join-Path -Path "current" -ChildPath "posh-git.psd1")))) {
    Import-Module $ModulePath;
  }
  Else {
    Throw "Failed to import posh-git.";
  }
}

Function Import-OhMyPosh() {
  Param()

  $ModulePath = (Get-Command -Name "oh-my-posh" -ErrorAction SilentlyContinue);
  $OhMyPoshTheme = "slimfat";
  If ($Null -ne $ModulePath -and (Test-Path -LiteralPath (Join-Path -Path (Split-Path -Path "$($ModulePath.Source)" -Parent) -ChildPath "themes\$($OhMyPoshTheme).omp.json"))) {
    (& "$($ModulePath.Source)" init pwsh --config "$(scoop prefix oh-my-posh)\themes\$($OhMyPoshTheme).omp.json") | Invoke-Expression;
  }
  ElseIf (Test-ScoopOnPath -and Test-Path -LiteralPath (Join-Path -Path (Split-Path -Path "$(scoop prefix oh-my-posh)") -ChildPath "oh-my-posh.exe")) {
    (& "$($ModulePath.Source)" init pwsh --config "$(scoop prefix oh-my-posh)\themes\$($OhMyPoshTheme).omp.json") | Invoke-Expression;
  }
  Else {
    Throw "Failed to import oh-my-posh.";
  }
}

Function Start-GnuPGAgent() {
  Param(
    # Path to the GnuPG Connect Agent
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Path to the GnuPG Connect Agent")]
    [string[]]
    $GpgConnectAgent,
    # Path to the GnuPG Agent
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Path to the GnuPG Agent")]
    [string[]]
    $GpgAgent
  )

  If ($Null -ne (Get-Process -Name "$((Get-Item -LiteralPath $GpgAgent).BaseName)" -ErrorAction SilentlyContinue)) {
    Return $True;
  }

  $Array = (& "$($GpgConnectAgent)" "/bye" 2>&1);

  If ($Array.Length -ge 3 -and $Array[-1] -match ".*connection to the agent established$") {
    Write-Debug -Message "The GPG Agent has been started.";

    Return $True;
  }
  Else {
    Write-Error -Message "Failed to start the GPG Agent.";

    Return $False;
  }
}

Function Test-KeyCached() {
  Param(
    # Path to the GnuPG Connect Agent
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Path to the GnuPG Connect Agent")]
    [Alias("Path", "LiteralPath")]
    [string[]]
    $GpgConnectAgent,
    # Path to the GnuPG Connect Agent
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Path to the GnuPG Connect Agent")]
    [string[]]
    $Gpg
  )

  $Returned = @{ Items = @(); Item1 = $True; Item2 = $True };

  $KeyGrips = ((Invoke-Expression -Command "& `"$Gpg`" --fingerprint --with-keygrip `"$($script:Config.gnupg.email)`"") | Select-String "Keygrip" | ForEach-Object { Return ($_ -split "\s+")[3]; });

  $KeyInfo = ((Invoke-Expression -Command "& `"$GpgConnectAgent`" -q `"KeyInfo --list`" `"/bye`" 2>&1") | Select-String "KEYINFO" | ForEach-Object { Return ($_ -split "\s+")[6]; });

  For ($Index = 0; $Index -lt $KeyGrips.Length; $Index++) {
    If ($KeyInfo[$Index] -eq "-") {
      $Returned.Items += "$($KeyGrips[$Index])";
      If ($Index -eq 1) {
        $Returned.Item1 = $False;
      }
      ElseIf ($Index -eq 2) {
        $Returned.Item2 = $False;
      }
      ElseIf ($Index -gt 2) {
        $Returned["Item$($Index)"] = $False;
      }
    }
    Else {
      If ($Index -gt 2) {
        $Returned["Item$($Index)"] = $True;
      }
    }
  }

  Return $Returned;
}

Function Get-UnhashedPassword() {
  Param()

  If ($script:Config.gnupg.password_hashed -eq "") {
    $Secure = Read-Host -AsSecureString -Prompt "Insert Password";
    $Encrypted = ConvertFrom-SecureString -SecureString $Secure;
    $script:Config.gnupg.password_hashed = $Encrypted;

    ($script:Config | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path -Path (Get-Item -LiteralPath $Profile).Directory.FullName -ChildPath "config.json");
  }

  $Test = (New-Object -TypeName System.Net.NetworkCredential -ArgumentList @([string]::Empty, (ConvertTo-SecureString -String $script:Config.gnupg.password_hashed))).Password;
  Return $Test;
}

Function Invoke-CacheKey() {
  Param(
    # Path to the GnuPG Preset Pass Command
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Path to the GnuPG Preset Pass Command")]
    [Alias("Path", "LiteralPath")]
    [string[]]
    $GpgPresetPass,
    # The keygrips to cache.
    [Parameter(Mandatory = $True, Position = 1, HelpMessage = "The keygrips to cache.")]
    [Alias("Item", "KeyGrip", "KeyGrips")]
    [string[]]
    $Items
  )

  ForEach ($Item in $Items) {
    Try {
      $Test = "-P `"$(Get-UnhashedPassword)`"";
      Invoke-Expression -Command "& `"$($GpgPresetPass)`" --preset $Test `"$($Item)`"";
    }
    Catch {
      Write-Error -Exception $_.Exception -Message "Failed to preset passphrase.";
      Exit 1;
    }
  }
}

Function Import-GnuPGKey() {
  Param()

  $ConfigFile = (Join-Path -Path $PSScriptRoot -ChildPath Config.ps1);
  . $ConfigFile;

  #$gpgConf = (Get-ProfileConfigJson).gnupg;

  $GpgConnectAgent = (Get-Command -Name "gpg-connect-agent" -ErrorAction SilentlyContinue);
  $Gpg = (Get-Command -Name "gpg" -ErrorAction SilentlyContinue);
  $GpgAgent = (Get-Command -Name "gpg-agent" -ErrorAction SilentlyContinue);
  $GpgPresetPass = (Get-Command -Name "gpg-preset-passphrase" -ErrorAction SilentlyContinue);
  If (-not (Test-Path -LiteralPath $GpgConnectAgent.Source -PathType Leaf) -or
    -not (Test-Path -LiteralPath $GpgAgent.Source -PathType Leaf) -or
    -not (Test-Path -LiteralPath $GpgPresetPass.Source -PathType Leaf)) {
    Throw "Failed to find GnuPG tools."
  }

  If (Start-GnuPGAgent -GpgConnectAgent $GpgConnectAgent.Source -GpgAgent $GpgAgent.Source) {
    $CacheKeyInfo = (Test-KeyCached -Path $GpgConnectAgent.Source -Gpg $Gpg.Source)
    If (-not $CacheKeyInfo.Item1 -or -not $CacheKeyInfo.Item2) {
      Invoke-CacheKey -Path $GpgPresetPass -Items $CacheKeyInfo.Items;
    }
  }
}

Import-PoshGit && Import-OhMyPosh && Import-GnuPGKey

Clear-Variable Config -Scope Script