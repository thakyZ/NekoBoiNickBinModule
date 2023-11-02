Param()

$env:ProfileDirectory = (Get-Item -Path $Profile).Directory;

Function Get-ProfileConfig() {
  Param()

  $Returned = $Null;
  $ConfigPath = (Join-Path -Path (Get-Item -LiteralPath $Profile).Directory.FullName -ChildPath "config.json");

  Try {
    $ConfigText = (Get-Content -LiteralPath $ConfigPath);
    $Returned = ($ConfigText | ConvertFrom-Json);
  } Catch {
    Write-Error -Exception $_.Exception -Message "Failed to load the PowerShell profile config at, $($ConfigPath)"
    Exit 1;
  }

  Return $Returned;
}

$script:Config = (Get-ProfileConfig);

Function Test-ScoopOnPath() {
  Param()

  If ($Null -eq (Get-Command -Name "scoop" -ErrorAction SilentlyContinue)) {
    Return $False;
  }
  Return $True;
}

Function Test-HomebrewOnPath() {
  Param()

  If ($Null -eq (Get-Command -Name "brew" -ErrorAction SilentlyContinue)) {
    Return $False;
  }
  Return $True;
}

Function Import-Ugit() {
  Param()

  $UgitModule = Get-Module ugit -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1;
  If ($UgitModule) {
    $UgitModule | Import-Module;
  } Else {
    Throw "Failed to import ugit.";
  }
}

Function Import-PoshGit() {
  Param()

  $PoshGitModule = Get-Module posh-git -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1;
  If ($PoshGitModule) {
    $PoshGitModule | Import-Module;
  } ElseIf (Test-Path -LiteralPath ($ModulePath = (Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -ChildPath (Join-Path -Path src -ChildPath "posh-git.psd1")))) {
    Import-Module $ModulePath;
  } ElseIf (Test-HomebrewOnPath) {
    If (Test-Path -LiteralPath "$HOME/.local/share/powershell/Modules/posh-git/1.1.0/posh-git.psd1") {
      Import-Module $ModulePath;
    }
  } ElseIf (Test-ScoopOnPath) {
    If (Test-Path -LiteralPath ($ModulePath = (Join-Path -Path (Split-Path -Path "$(scoop prefix posh-git)") -ChildPath (Join-Path -Path "current" -ChildPath "posh-git.psd1")))) {
      Import-Module $ModulePath;
    }
  } Else {
    Throw "Failed to import posh-git.";
  }
}

Function Import-OhMyPosh() {
  Param()

  $ModulePath = (Get-Command -Name "oh-my-posh" -ErrorAction SilentlyContinue);
  $OhMyPoshTheme = "slimfat";
  If ($Null -eq $ModulePath) {
    Throw "Oh My Posh does not exist on path!"
  } ElseIf (Test-HomebrewOnPath) {
    If ((Test-Path -LiteralPath "/home/linuxbrew/.linuxbrew/bin/oh-my-posh") -and (Test-Path -LiteralPath "/home/linuxbrew/.linuxbrew/opt/oh-my-posh/themes/$($OhMyPoshTheme).omp.json")) {
      & "$($ModulePath.Source)" init pwsh --config "/home/linuxbrew/.linuxbrew/opt/oh-my-posh/themes/$($OhMyPoshTheme).omp.json" | Invoke-Expression;
    }
  } ElseIf (Test-ScoopOnPath) {
    If ((Test-Path -LiteralPath (Join-Path -Path "$(scoop prefix oh-my-posh)" -ChildPath "oh-my-posh.exe")) -and (Test-Path -LiteralPath (Join-Path -Path "$(scoop prefix oh-my-posh)" -ChildPath "themes" -AdditionalChildPath "$($OhMyPoshTheme).omp.json"))) {
      (& "$($ModulePath.Source)" init pwsh --config "$(scoop prefix oh-my-posh)\themes\$($OhMyPoshTheme).omp.json") | Invoke-Expression;
    }
  } Else {
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
  } Else {
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
      } ElseIf ($Index -eq 2) {
        $Returned.Item2 = $False;
      } ElseIf ($Index -gt 2) {
        $Returned["Item$($Index)"] = $False;
      }
    } Else {
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
    } Catch {
      Write-Error -Exception $_.Exception -Message "Failed to preset passphrase.";
      Exit 1;
    }
  }
}

Function Get-GnupgPath() {
  Param(
    [Parameter(Mandatory = $False, Position = 0, HelpMessage = "CurrentPath")]
    [string]
    $Path = ""
  )

  If ($Path -ne "" -and $Null -ne $Path) {
    $env:PATH = $Path;
  }

  $GpgConnectAgent = (Get-Command -Name "gpg-connect-agent" -ErrorAction SilentlyContinue);
  $Gpg = (Get-Command -Name "gpg" -ErrorAction SilentlyContinue);
  $GpgConf = (Get-Command -Name "gpgconf" -ErrorAction SilentlyContinue);
  $GpgAgent = (Get-Command -Name "gpg-agent" -ErrorAction SilentlyContinue);
  $GpgPresetPass = (Get-Command -Name "gpg-preset-passphrase" -ErrorAction SilentlyContinue);

  If ($Null -eq $GpgConnectAgent) {
    $GpgConnectAgent = @{ Source = $False };
  }

  If ($Null -eq $Gpg) {
    $Gpg = @{ Source = $False };
  }

  If ($Null -eq $GpgConf) {
    $GpgConf = @{ Source = $False };
  }

  If ($Null -eq $GpgAgent) {
    $GpgAgent = @{ Source = $False };
  }

  If ($Null -eq $GpgPresetPass) {
    $GpgPresetPass = @{ Source = $False };
  }

  return @($GpgConnectAgent, $Gpg, $GpgConf, $GpgAgent, $GpgPresetPass);
}

Function Test-GnupgOnPath() {
  Param(
    [Parameter(Mandatory = $False, Position = 0, HelpMessage = "CurrentPath")]
    [string]
    $Path = "",
    [Parameter(Mandatory = $False, Position = 0, HelpMessage = "Current Interation Step")]
    [int]
    $Step = 0
  )

  $MaxSteps = 2;

  If ($Step -gt $MaxSteps) {
    Throw "Failed to find GnuPG tools."
  }

  If ($Path -ne "" -and $Null -ne $Path) {
    $env:PATH = $Path;
  }

  $Gnupg = (Get-GnupgPath -Path $Path);

  $GpgConnectAgent = $Gnupg[0];
  $Gpg = $Gnupg[1];
  $GpgConf = $Gnupg[2];
  $GpgAgent = $Gnupg[3];
  $GpgPresetPass = $Gnupg[4];

  If (-not (Test-Path -LiteralPath $GpgConnectAgent.Source -PathType Leaf) -or
    -not (Test-Path -LiteralPath $GpgAgent.Source -PathType Leaf) -or
    -not (Test-Path -LiteralPath $GpgPresetPass.Source -PathType Leaf) -or
    -not (Test-Path -LiteralPath $Gpg.Source -PathType Leaf)) {
    If (Test-ScoopOnPath -and $Step -eq 0) {
      $Path = "$($env:PATH)$([System.IO.Path]::PathSeparator)$(scoop prefix gnupg)";
      Test-GnupgOnPath -Path $Path -Step ($Step + 1);
    } ElseIf ((Test-Path -Path (Join-Path -Path $HOME -ChildPath "scoop" -AdditionalChildPath @("apps", "gnupg", "current", "bin"))) -and $Step -eq 1) {
      $Path = "$($env:PATH)$([System.IO.Path]::PathSeparator)$(Join-Path -Path "$HOME" -ChildPath "scoop" -AdditionalChildPath @("apps", "gnupg", "current", "bin"))";
      Test-GnupgOnPath -Path $Path -Step ($Step + 1);
    } ElseIf ($GpgConf -ne $False -and (Test-Path -Path "$(& "$GpgConf" --list-dirs libexecdir)") -and $Step -ge 0) {
      $Path = "$($env:PATH)$([System.IO.Path]::PathSeparator)$(& "$GpgConf" --list-dirs libexecdir)";
      Test-GnupgOnPath -Path $Path -Step ($Step + 1);
    }
  }

  return $Gnupg;
}

Function Import-GnuPGKey() {
  Param()

  $ConfigFile = (Join-Path -Path $PSScriptRoot -ChildPath Config.ps1);
  . $ConfigFile;

  #$gpgConf = (Get-ProfileConfigJson).gnupg;

  $Gnupg = Test-GnupgOnPath;
  $GpgConnectAgent = $Gnupg[0];
  $Gpg = $Gnupg[1];
  $GpgAgent = $Gnupg[3];
  $GpgPresetPass = $Gnupg[4];

  If (Start-GnuPGAgent -GpgConnectAgent $GpgConnectAgent.Source -GpgAgent $GpgAgent.Source) {
    $CacheKeyInfo = (Test-KeyCached -Path $GpgConnectAgent.Source -Gpg $Gpg.Source)
    If (-not $CacheKeyInfo.Item1 -or -not $CacheKeyInfo.Item2) {
      Invoke-CacheKey -Path $GpgPresetPass -Items $CacheKeyInfo.Items;
    }
  }
}

If ($Null -eq $env:VSAPPIDNAME) {
  Import-PoshGit && Import-OhMyPosh
}

Import-GnuPGKey

Clear-Variable Config -Scope Script

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
