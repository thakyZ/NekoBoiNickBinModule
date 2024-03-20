[CmdletBinding()]
Param(
  # Specifies which discord build to install into.
  [Parameter(Mandatory = $False,
             HelpMessage = "Which discord build to install into.")]
  [Alias("Discord")]
  [ValidateSet("Stable", "PTB", "Canary")]
  [System.String]
  $InstallInto = "Stable",
  # Specifies whether to build from source or download for GitHub.
  [Parameter(Mandatory = $False,
             HelpMessage = "Whether to build from source or download for GitHub.")]
  [Alias("Source")]
  [switch]
  $FromSource = $False
)

# cSpell:word discordptb, discordcanary, betterdiscord

Begin {
  . "$((Join-Path -Path (Get-Item -Path $Profile).Directory -ChildPath "Utils.ps1"))";

  $script:Config = (Get-Config -Path (Join-Path -Path $PSScriptRoot -ChildPath "config.json"));

  If ($FromSource) {
    Throw "From source has not been implemented yet."

    $Git = (Get-Command -Name "git" -ErrorAction SilentlyContinue);

    If ($Null -ne $Git) {
      Throw "The command git was not found on system paths.";
    }

    $Pnpm = (Get-Command -Name "pnpm" -ErrorAction SilentlyContinue);

    If ($Null -ne $Pnpm) {
      Throw "The command pnpm was not found on system paths.";
    }

    If ($Null -ne $script:Config.Installs.DevelopmentDirectory) {
      $local:Development = (Join-Path -Path $script:Config.Installs.DevelopmentDirectory -ChildPath "Discord" -AdditionalChildPaths @("BetterDiscord"));
    } Else {
      Throw "Key ``DevelopmentDirectory`` not set or is blank in Config > Installs";
    }
  }
}
Process {
  $script:StoppedDiscordFilePath = $Null;
  Function Stop-Discord {
    Param(
      # Specifies which discord build to stop the process of.
      [Parameter(Mandatory = $True,
                 HelpMessage = "Which discord build to stop the process of.")]
      [Alias("Discord")]
      [ValidateSet("Stable", "PTB", "Canary")]
      [System.String]
      $Branch
    )

    $Processes = (Get-Process "discord" -ErrorAction SilentlyContinue)


    If ($Null -ne $Processes) {
      $Process = ($Processes | Select-Object -Property @(@{
        Name="Id";
        Expression={$_.Id};
      }; @{
        Name="FilePath";
        Expression={
          $Split = ($_.CommandLine -Split " ");
          $FilePath = ($Split[0] -Replace "\`"([^`"]+)\`"", '$1');
          Return $FilePath;
        }
      }) | Sort-Object -Unique | Select-Object -Property @(@{
        Name="Id";
        Expression={$_.Id};
      }; @{
        Name="FilePath";
        Expression={$_.FilePath};
      }; @{
        Name="Build";
        Expression={
          $EscapedLocalAppData = $([System.Text.RegularExpressions.Regex]::Escape($env:LocalAppData));
          $FullRegex = "$($EscapedLocalAppData)\\([^\\)]+)\\.+\\.+\.exe"
          Return ($_.FilePath -Replace $FullRegex, '$1');
        }
      }) | Where-Object {
        If ($Branch.ToLower() -eq "stable") {
          Return $_.Build.ToLower() -eq "discord";
        } ElseIf ($Branch.ToLower() -eq "ptb") {
          Return $_.Build.ToLower() -eq "discordptb";
        } ElseIf ($Branch.ToLower() -eq "canary") {
          Return $_.Build.ToLower() -eq "discordcanary";
        }
      });

      If ($Null -eq $Process) {
        Throw "Failed to find running process amongst discord processes for build type $($Branch)"
      }

      Try {
        $script:StoppedDiscordFilePath =  $Process.FilePath;
        Stop-Process -Id $Process.Id -ErrorAction SilentlyContinue;
      } Catch {
        Throw;
      }
    }
  }

  Function Start-Discord {
    Param(
      # Specifies which discord build to start the process of.
      [Parameter(Mandatory = $True,
                 HelpMessage = "Which discord build to start the process of.")]
      [Alias("Discord")]
      [ValidateSet("Stable", "PTB", "Canary")]
      [System.String]
      $Branch
    )

    If ($Branch.ToLower() -eq "stable") {
      $Discord = "Discord"
      Start-Process -FilePath (Join-Path -Path $env:LocalAppData -ChildPath "$Discord" -AdditionalChildPath "Update.exe") -ArgumentList @("--processStart", "Discord.exe") -ErrorAction SilentlyContinue
    } ElseIf ($Branch.ToLower() -eq "ptb") {
      $Discord = "DiscordPTB"
      Start-Process -FilePath (Join-Path -Path $env:LocalAppData -ChildPath "$Discord" -AdditionalChildPath "Update.exe") -ArgumentList @("--processStart", "Discord.exe") -ErrorAction SilentlyContinue
    } ElseIf ($Branch.ToLower() -eq "canary") {
      $Discord = "DiscordCanary"
      Start-Process -FilePath (Join-Path -Path $env:LocalAppData -ChildPath "$Discord" -AdditionalChildPath "Update.exe") -ArgumentList @("--processStart", "Discord.exe") -ErrorAction SilentlyContinue
    }
  }

  Function Get-DiscordPath {
    [CmdletBinding()]
    Param(
      # Specifies which discord build to start the process of.
      [Parameter(Mandatory = $True,
                 HelpMessage = "Which discord build to start the process of.")]
      [Alias("Discord")]
      [ValidateSet("Stable", "PTB", "Canary")]
      [System.String]
      $Branch
    )

    $Discord = $Null;

    If ($Branch.ToLower() -eq "stable") {
      $Discord = "Discord"
    } ElseIf ($Branch.ToLower() -eq "ptb") {
      $Discord = "DiscordPTB"
    } ElseIf ($Branch.ToLower() -eq "canary") {
      $Discord = "DiscordCanary"
    }

    $DiscordPath = (Get-ChildItem -LiteralPath (Join-Path -Path $env:LocalAppData -ChildPath $Discord.ToLower()) -Directory | Where-Object { ($_.BaseName -split "\.").Length -gt 1 } | Sort-Object -Property BaseName -Descending | Select-Object -First 1);
    $ModulePath = (Join-Path -Path $DiscordPath -ChildPath "modules");
    $CoreWrap = (Get-ChildItem -LiteralPath $ModulePath -Directory | Where-Object { $_.BaseName -match ".*discord_desktop_core.*" } | Sort-Object -Property BaseName -Descending | Select-Object -First 1);
    Return (Get-Item -LiteralPath (Join-Path -Path $CoreWrap -ChildPath "discord_desktop_core"));
  }

  $InstallLocation = (Join-Path -Path $env:AppData -ChildPath "BetterDiscord" -AdditionalChildPath @("data", "betterdiscord.asar"));
  $script:TempDirectory = (Join-Path -Path $env:Temp -ChildPath "update_better_discord");

  If ($FromSource) {
    Push-Location -LiteralPath (Join-Path -Path $local:Development -ChildPath "..");

    If (-not (Test-Path -LiteralPath (Join-Path -Path $local:Development -ChildPath ".."))) {
      Start-Process -FilePath $Git.Source -Wait -WorkingDirectory $PWD -ArgumentList @("checkout", "--recurse-submodules", "https://github.com/BetterDiscord/BetterDiscord.git", "BetterDiscord");
    }

    Pop-Location;

    Push-Location -LiteralPath $local:Development;

    Start-Process -FilePath $Pnpm.Source -Wait -WorkingDirectory $PWD -ArgumentList @("install");

    # Build Better Discord

    $DistDirectory = (Get-Item -Path (Join-Path -Path $PWD -ChildPath "dist"));

    Pop-Location;

    Stop-Discord -Branch $InstallInto;

    # Install betterdiscord.asar
    Move-Item -Force -LiteralPath (Join-Path -Path $DistDirectory -ChildPath "betterdiscord.asar") -Destination $InstallLocation;

  } Else {
    Try {
      $Headers = @{
        Accept = "application/octet-stream";
      };

      $Token = $script:Config.Tokens.Where({ $_.Addresses -contains "github.com" });

      If ($Token.Count -ne 0) {
        $Headers["Authorization"] = "Bearer $($Token[0].Token)";
      }

      $WebRequest = (Invoke-WebRequest -Uri "https://github.com/BetterDiscord/BetterDiscord/releases/latest/download/betterdiscord.asar" -Headers $Headers -SkipHttpErrorCheck -ErrorAction SilentlyContinue -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome));

      If ($WebRequest.StatusCode -ne 200) {
        Throw "❌ The web request returned with status code $($WebRequest.StatusCode)";
      } Else {
        New-Item -Path $script:TempDirectory -ItemType Directory -ErrorAction SilentlyContinue | Out-Null;

        [System.IO.File]::WriteAllBytes("$(Join-Path -Path $script:TempDirectory -ChildPath "betterdiscord.asar")", $WebRequest.Content);

        Stop-Discord -Branch $InstallInto;

        Move-Item -Force -LiteralPath (Join-Path -Path $script:TempDirectory -ChildPath "betterdiscord.asar") -Destination $InstallLocation;
      }
    } Catch {
      Write-Error -Exception $_.Exception -Message "❌ $($_.Exception.Message)";
    }
  }

  $DiscordPath = (Get-DiscordPath -Branch $InstallInto);

  Try {
    $IndexFile = (Get-Item -LiteralPath (Join-Path -Path $DiscordPath -ChildPath "index.js"));
    # cSpell:disable-next-line
    "require(`"$(($InstallLocation -replace '\\', '\\') -replace '\"', '\"')`");`nmodule.exports = require(`"./core.asar`");" | Out-File -FilePath $IndexFile;
  } Catch {
    Write-Error -Exception $_.Exception -Message "❌ Unable to inject shims into $($DiscordPath)`n❌ $($_.Exception.Message)";
  }

  Start-Discord -Branch $InstallInto;

  Remove-Item -Recurse -Path $script:TempDirectory;
}
End {
  Remove-Variable "Config" -Scope Script -ErrorAction SilentlyContinue
  Remove-Variable "Development" -Scope Local -ErrorAction SilentlyContinue
  Remove-Variable "TempDirectory" -Scope Script -ErrorAction SilentlyContinue
  Remove-Variable "StoppedDiscordFilePath" -Scope Script -ErrorAction SilentlyContinue
}

