using namespace System;
using namespace System.Text.RegularExpressions;
using namespace System.IO;

[CmdletBinding(DefaultParameterSetName = "Install")]
Param(
  # Specifies a string indicating which Discord build to install into.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Install",
             HelpMessage = "Which Discord build to install into.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Uninstall",
             HelpMessage = "Which Discord build to uninstall into.")]
  [Alias("Discord")]
  [ValidateSet("Stable", "PTB", "Canary")]
  [string]
  $InstallInto = "Stable",
  # Specifies a switch whether to build from source or download for GitHub.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Install",
             HelpMessage = "Whether to build from source or download for GitHub.")]
  [Alias("Source")]
  [switch]
  $FromSource = $False,
  # Specifies a switch to install Better Discord from Discord.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Uninstall",
             HelpMessage = "Uninstalls Better Discord from Discord.")]
  [Alias("Remove")]
  [switch]
  $Uninstall = $False
)

Begin {
  If ($PSCmdLet.ParameterSetName -eq "Install") {
    [string] $local:UtilsPath = (Join-Path -Path (Get-Item -Path $Profile).Directory -ChildPath "Utils.ps1");
    [bool]   $local:ImportedUtils = $False;
    [object] $script:Config = $Null;
    If (Test-Path -LiteralPath $local:UtilsPath -PathType Leaf) {
      . "$($local:UtilsPath)";
      $local:ImportedUtils = $True;
      $script:Config = (Get-Config -Path (Join-Path -Path $PSScriptRoot -ChildPath "config.json"));
    }

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

      [string] $local:Development = $Null;

      If ($local:ImportedUtils -eq $True) {
        If ($Null -ne $script:Config.Installs.DevelopmentDirectory) {
          $local:Development = (Join-Path -Path $script:Config.Installs.DevelopmentDirectory -ChildPath "Discord" -AdditionalChildPaths @("BetterDiscord"));
        } Else {
          Throw "Key ``DevelopmentDirectory`` not set or is blank in Config > Installs";
        }
      }
    }
  }
}
Process {
  $script:StoppedDiscordFilePath = $Null;

  Function Get-DiscordProcesses {
    [CmdletBinding()]
    [OutputType([PSObject])]
    Param(
      # Specifies which discord build to stop the process of.
      [Parameter(Mandatory = $True,
                 HelpMessage = "Which discord build to stop the process of.")]
      [Alias("Discord")]
      [ValidateSet("Stable", "PTB", "Canary")]
      [string]
      $Branch
    )

    Begin {
      [PSObject] $Output = $Null;
      $Processes = (Get-Process "discord" -ErrorAction SilentlyContinue);
    } Process {
      If ($Null -ne $Processes) {
        $Output = ($Processes | Select-Object -Property @(@{
          Name="Id";
          Expression={$_.Id};
        }; @{
          Name="FilePath";
          Expression={
            $Split = ($_.CommandLine -Split " ");
            $FilePath = ($Split[0] -Replace "\`"([^`"]+)\`"", '$1');
            Write-Output -NoEnumerate -InputObject $FilePath;
          }
        }) | Select-Object -Property @(@{
          Name="Id";
          Expression={$_.Id};
        }; @{
          Name="FilePath";
          Expression={$_.FilePath};
        }; @{
          Name="Build";
          Expression={
            $EscapedLocalAppData = $([Regex]::Escape($env:LocalAppData));
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
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }
  Function Stop-Discord {
    [CmdletBinding()]
    Param(
      # Specifies which discord build to stop the process of.
      [Parameter(Mandatory = $True,
                 HelpMessage = "Which discord build to stop the process of.")]
      [Alias("Discord")]
      [ValidateSet("Stable", "PTB", "Canary")]
      [string]
      $Branch,
      # Specifies a switch that determins to wait for discord process to have actually stopped before continuing the script.
      [Parameter(Mandatory = $False,
                 HelpMessage = 'Waits for discord to have actually stopped then continues the script.')]
      [switch]
      $Wait
    )

    Begin {
      $ProcessesFiltered = (Get-DiscordProcesses -Branch $Branch);
    } Process {
      If ($Null -eq $ProcessesFiltered) {
        Throw "Failed to find running process amongst discord processes for build type $($Branch)"
      }

      If ($Output.Length -eq 1) {
        Write-Warning -Message "Only found one Discord process after filtered, normally there are multiple, you may have to close discord before running this script";
      }

      Try {
        $script:StoppedDiscordFilePath = $ProcessesFiltered[0].FilePath;
        ForEach ($Process in $ProcessesFiltered) {
          Stop-Process -Id $Process.Id -ErrorAction SilentlyContinue;
        }
      } Catch {
        Throw;
      }
    } End {
      If ($Wait -eq $True) {
        While ($Null -ne (Get-DiscordProcesses -Branch $Branch)) {
          Start-Sleep -Seconds 5;
        }
      }
    }
  }

  Function Start-Discord {
    [CmdletBinding()]
    Param(
      # Specifies which discord build to start the process of.
      [Parameter(Mandatory = $True,
                 HelpMessage = "Which discord build to start the process of.")]
      [Alias("Discord")]
      [ValidateSet("Stable", "PTB", "Canary")]
      [string]
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
      [string]
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

  If ($PSCmdLet.ParameterSetName -eq "Install") {
    If ($FromSource -and -not [string]::IsNullOrEmpty($local:Development) -and -not [string]::IsNullOrWhiteSpace($local:Development)) {
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

      Stop-Discord -Branch $InstallInto -Wait;

      # Install betterdiscord.asar
      Move-Item -Force -LiteralPath (Join-Path -Path $DistDirectory -ChildPath "betterdiscord.asar") -Destination $InstallLocation;
    } Else {
      Try {
        $Headers = @{
          Accept = "application/octet-stream";
        };

        $Token = @();

        If ($Null -ne $script:Config) {
          $Token = $script:Config.Tokens.Where({ $_.Addresses -contains "github.com" });
        }

        If ($Token.Count -ne 0) {
          $Headers["Authorization"] = "Bearer $($Token[0].Token)";
        }

        $WebRequest = (Invoke-WebRequest -Uri "https://github.com/BetterDiscord/BetterDiscord/releases/latest/download/betterdiscord.asar" -Headers $Headers -SkipHttpErrorCheck -ErrorAction SilentlyContinue -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome));

        If ($WebRequest.StatusCode -ne 200) {
          Throw "❌ The web request returned with status code $($WebRequest.StatusCode)";
        } Else {
          New-Item -Path $script:TempDirectory -ItemType Directory -ErrorAction SilentlyContinue | Out-Null;

          [File]::WriteAllBytes("$(Join-Path -Path $script:TempDirectory -ChildPath "betterdiscord.asar")", $WebRequest.Content);

          Stop-Discord -Branch $InstallInto -Wait;

          If (Test-Path -LiteralPath $InstallLocation -PathType Leaf) {
            Remove-Item -LiteralPath $InstallLocation
          }

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
      "require('$(($InstallLocation -replace '\\', '\\') -replace '\"', '\"')');`nmodule.exports = require('./core.asar');" | Out-File -FilePath $IndexFile;
    } Catch {
      Write-Error -Exception $_.Exception -Message "❌ Unable to inject shims into $($DiscordPath)`n❌ $($_.Exception.Message)";
    }

    Start-Discord -Branch $InstallInto;

    Remove-Item -Recurse -Path $script:TempDirectory;
  } Else {
    Stop-Discord -Branch $InstallInto -Wait;
    $DiscordPath = (Get-DiscordPath -Branch $InstallInto);

    Try {
      $IndexFile = (Get-Item -LiteralPath (Join-Path -Path $DiscordPath -ChildPath "index.js"));
      # cSpell:disable-next-line
      "module.exports = require('./core.asar');" | Out-File -FilePath $IndexFile;
    } Catch {
      # cSpell:ignore uninject
      Write-Error -Exception $_.Exception -Message "❌ Unable to uninject shims from $($DiscordPath)`n❌ $($_.Exception.Message)";
    }

    Start-Discord -Branch $InstallInto;
  }
}
End {
  Remove-Variable "Config" -Scope Script -ErrorAction SilentlyContinue
  Remove-Variable "Development" -Scope Local -ErrorAction SilentlyContinue
  Remove-Variable "TempDirectory" -Scope Script -ErrorAction SilentlyContinue
  Remove-Variable "StoppedDiscordFilePath" -Scope Script -ErrorAction SilentlyContinue
}

