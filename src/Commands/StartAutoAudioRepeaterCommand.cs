using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Start, "AutoAudioRepeater")]
public class StartAutoAudioRepeaterCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "Start")]
Param(
  # Specifies ...
  # TODO: Add help message.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Start",
             HelpMessage = "...")]
  [Switch]
  $Start,
  # Specifies ...
  # TODO: Add help message.
  [Parameter(Mandatory = $False,
             Position = 0,
             ParameterSetName = "Set",
             HelpMessage = "...")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Set,
  # Specifies ...
  # TODO: Add help message.
  [Parameter(Mandatory = $False,
             Position = 0,
             ParameterSetName = "List",
             HelpMessage = "...")]
  [Switch]
  $List,
  # Specifies ...
  # TODO: Add help message.
  [Parameter(Mandatory = $False,
             Position = 1,
             ParameterSetName = "List",
             HelpMessage = "...")]
  [System.Management.Automation.HiddenAttribute()]
  [System.String]
  $Grep
)

Begin {
  Function Invoke-CutString([int]$Length, [string]$Value) {
    If ($Value.Length -gt $Length) {
      Return $Value.SubString(0, $Length);
    }
    Return $Value;
  }

  class Config {
    [string] $_Input = "High Definition Audio";
    [string] $Output = "High Definition Audio";
    [int]    $SamplingRate = 32000;
    [int]    $BitsPerSample = 16;
    [int]    $Channels = 2;
    [string] $ChannelCfg = "Stereo";
    [int]    $BufferMs = 100;
    [int]    $BufferParts = 12;
    [int]    $Prefill = 70;
    [int]    $ResyncAt = 20;
    [string] $Priority = "Normal";

    Config([psCustomObject]$Config) {
      ForEach ($Item in $Config.PSObject.Properties) {
        $Split = ($Item -Split "=");
        $Name = ($Split[0] -Split " ");
        $Value = $Split[1];

        Switch ($Name.ToLower()) {
          "input" { If ($Null -ne $Value -and $Value -ne "null") { $this._Input = (Invoke-CutString -Length 31 -Value $Value) } }
          "output" { If ($Null -ne $Value -and $Value -ne "null") { $this.Output = (Invoke-CutString -Length 31 -Value $Value) } }
          "samplingrate" { If ($Null -ne $Value -and $Value -ne "null") { $this.SamplingRate = $Value } }
          "bitspersample" { If ($Null -ne $Value -and $Value -ne "null") { $this.BitsPerSample = $Value } }
          "channels" { If ($Null -ne $Value -and $Value -ne "null") { $this.Channels = $Value } }
          "channelcfg" { If ($Null -ne $Value -and $Value -ne "null") { $this.ChannelCfg = (Invoke-CutString -Length 31 -Value $Value) } }
          "bufferms" { If ($Null -ne $Value -and $Value -ne "null") { $this.BufferMs = $Value } }
          "bufferparts" { If ($Null -ne $Value -and $Value -ne "null") { $this.BufferParts = $Value } }
          "prefill" { If ($Null -ne $Value -and $Value -ne "null") { $this.Prefill = $Value } }
          "resyncat" { If ($Null -ne $Value -and $Value -ne "null") { $this.ResyncAt = $Value } }
          "priority" { If ($Null -ne $Value -and $Value -ne "null") { $this.Priority = (Invoke-CutString -Length 31 -Value $Value) } }
        }
      }
    }

    static [Config]FromString([System.String]$ConfigString) {
      $_Config = @{}

      ForEach ($Line in $ConfigString) {
        $_Line = (($Line -Replace "/", "") -Replace "`"", "");
        $Item = ($_Line -Split (":"))
        $_Config[$Item[0]] = $Item[1];
      }

      Return [Config]::new($_Config);
    }

    [string[]]ToArray() {
      Return @(
        "/Input:`"$($this._Input)`"",
        "/Output:`"$($this.Output)`"",
        "/SamplingRate:$($this.SamplingRate)",
        "/BitsPerSample:$($this.BitsPerSample)",
        "/BitsPerSample:$($this.BitsPerSample)",
        "/Channels:$($this.Channels)",
        "/ChanCfg:`"$($this.ChannelCfg)`"",
        "/BufferMs:$($this.BufferMs)",
        "/BufferParts:$($this.BufferParts)",
        "/Prefill:$($this.Prefill)",
        "/ResyncAt:$($this.ResyncAt)",
        "/Priority:`"$($this.Priority)`""
      );
    }

    [string]ToCfgString() {
      Return "$($this.ToArray() -join "`n")"
    }
  }

  [System.String]$_Grep;

  If ($PSCmdlet.ParameterSetName -eq "List") {
    $_Grep = $Grep.ToString();
  }

  $ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath "config.json");
  $VAC_ConfigPathDir = (Join-Path -Path $env:APROG_DIR -ChildPath "bin");
  If ($Null -eq $env:APROG_DIR) {
    $VAC_ConfigPathDir = $PSScriptRoot;
  }
  $UsingJson = $True;
  $Json = $Null;
  [Config]$Config = $Null;
  $VirtualAudioCable = "audiorepeater.exe";
  $VAC_BackupPath = (Join-Path -Path $env:ProgramFiles -ChildPath "Virtual Audio Cable" -AdditionalChildPath $VirtualAudioCable);
}
Process {
  Try {
    $Json = (Get-Content -LiteralPath $ConfigPath | ConvertFrom-Json);

    If (-not [string]::IsNullOrEmpty($Set)) {
      $Config = ($Json.AudioRepeaterSettings.Presets | Where-Object { $_.Name.ToLower() -eq $Set.ToLower() } -ErrorAction SilentlyContinue);
      If ($Config.Length -eq 0) {
        $Config = ($Json.AudioRepeaterSettings.Presets.PSObject.Properties | Where-Object { $_.Name.ToLower() -eq $Set.ToLower() } -ErrorAction SilentlyContinue);
      }
      $Fetched = $Config.Settings

      If ($Null -eq $Fetched) {
        Throw "Specified preset `"$($Set)`" does not exist in the config.";
      } Else {
        $Json.AudioRepeaterSettings.Current = $Fetched;
      }
    }

    $Config = $Json.AudioRepeaterSettings.Current;
  } Catch {
    Write-Error -ErrorRecord $_;
    Write-Warning -Message "Failed to read Audio Repeater Settings from `"$($ConfigPath)`". Trying `"$($VAC_ConfigPath)`" instead.";
    Try {
      [System.String]$ConfigFile;
      If (-not [string]::IsNullOrEmpty($Set)) {
        $ConfigFile = (Join-Path -Path $VAC_ConfigPathDir -ChildPath "AutoAudioRepeater.$($Set).cfg");
      } Else {
        $ConfigFile = (Join-Path -Path $VAC_ConfigPathDir -ChildPath "AutoAudioRepeater.cfg");
      }
      $UsingJson = $False;
    } Catch {
      Write-Error -Message "Failed to read all config types.";
      Throw
    }
  }
  $UsingJson = $False;

  If ($PSCmdlet.ParameterSetName -eq "Set") {
    If ($UsingJson -eq $True) {
      (Set-Content -LiteralPath $ConfigPath -Value ($Json | ConvertTo-Json));
    } Else {
      (Set-Content -LiteralPath (Join-Path -Path $VAC_ConfigPathDir -ChildPath "AutoAudioRepeater.cfg") -Value $Config.ToCfgString());
    }
  } ElseIf ($PSCmdlet.ParameterSetName -eq "List") {
    If ($UsingJson -eq $True) {
      If ([string]::IsNullOrEmpty($_Grep)) {
        If ($Null -ne $Json.AudioRepeaterSettings.Current) {
          Write-Host -Object "1: Current";
        }

        [System.Int32]$Index = 2;

        If ($Null -ne $Json.AudioRepeaterSettings.Presets) {
          $Presets = ($Json.AudioRepeaterSettings.Presets);
          If ($Presets.Length -eq 0) {
            $Presets = ($Json.AudioRepeaterSettings.Presets.PSObject.Properties);
          }
          ForEach ($Preset in $Presets) {
            Write-Host -Object "$($Index): $($Preset.Name)"
            $Index++;
          }
        }
      } Else {
        [Config]$_tempConfig = $Null;

        If ($_Grep -eq "1" -or $_Grep.ToLower() -eq "current") {
          $_tempConfig = $Json.AudioRepeaterSettings.Current;
          Write-Host -Object $_tempConfig.ToCfgString();
        } Else {
          If ($Null -ne $Json.AudioRepeaterSettings.Presets) {
            $Presets = ($Json.AudioRepeaterSettings.Presets);
            If ($Presets.Length -eq 0) {
              $Presets = ($Json.AudioRepeaterSettings.Presets.PSObject.Properties);
            }
            [System.Int32]$Index = 2;
            $_temp = ($Presets | Where-Object {
              If ("$($_Grep)" -match "^\d+$") {
                $Output = "$($Index)" -eq "$($_Grep)";
                $Index++;
                Return $Output;
              } Else {
                Return $_.Name.ToLower() -eq $_Grep.ToLower()
              }
            });

            If ($_temp.Count -gt 1) {
              Throw "Failed to find a single preset named `"$($_Grep)`", found $($_temp.Count) too many.";
            } ElseIf ($_temp.Count -lt 1) {
              Throw "Failed to find a single preset named `"$($_Grep)`", found none.";
            }

            $_tempConfig = $Json.AudioRepeaterSettings.Presets[$_Grep];
            Write-Host -Object $_tempConfig.ToCfgString();
          }
        }
      }
    } Else {
      $Default = (Get-Item -Path (Join-Path -Path $VAC_ConfigPathDir -ChildPath "AutoAudioRepeater.cfg") -ErrorAction SilentlyContinue);
      $OtherConfigs = (Get-ChildItem -Path (Join-Path -Path $VAC_ConfigPathDir -ChildPath "AutoAudioRepeater.*.cfg") -ErrorAction SilentlyContinue);

      If ([string]::IsNullOrEmpty($_Grep)) {
        If ($Null -ne $Default) {
          Write-Host -Object "1: Current";
        }

        [System.Int32]$Index = 2;

        If ($Null -ne $OtherConfigs) {
          ForEach ($OtherConfig in $OtherConfigs) {
            Write-Host -Object "$($Index): $($OtherConfig.BaseName.Split(".")[1])"
            $Index++;
          }
        }
      } Else {
        If ($_Grep -eq "1" -or $_Grep.ToLower() -eq "current") {
          Write-Host -Object ([Config]::FromString((Get-Content -Path $Default))).ToCfgString() | Out-Host;
        } Else {
          [System.Int32]$Index = 2;
          $_temp = ($OtherConfigs | Where-Object {
            If ("$($_Grep)" -match "^\d+$") {
              $Output = "$($Index)" -eq "$($_Grep)";
              $Index++;
              Return $Output;
            } Else {
              Return $_.BaseName.ToLower().EndsWith($_Grep.ToLower());
            }
          });

          If ($_temp.Count -gt 1) {
            Throw "Failed to find a single preset named `"$($_Grep)`", found $($_temp.Count) too many.";
          } ElseIf ($_temp.Count -lt 1) {
            Throw "Failed to find a single preset named `"$($_Grep)`", found none.";
          }

          Write-Host -Object ([Config]::FromString((Get-Content -Path $_temp[0]))).ToCfgString() | Out-Host;
        }
      }
    }
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Start") {
    If ($Null -eq (Get-Command -Name $VirtualAudioCable -ErrorAction SilentlyContinue)) {
      If (Test-Path -Path $VAC_BackupPath) {
        $VirtualAudioCable = $VAC_BackupPath;
      } Else {
        Throw "Virtual Audio Cable not found on path or default directory $($VAC_BackupPath)";
        Exit 1;
      }
    }

    If ($Null -ne (Get-Process -Name "audiorepeater" -ErrorAction SilentlyContinue)) {
      Exit 0;
    }

    $Arguments = @($Config.ToArray());
    $Arguments += @("/AutoStart");

    Start-Process -WindowStyle Minimized -FilePath "$($VirtualAudioCable)" -ArgumentList $Arguments;
  }
}
End {

} Clean {

}
*/
