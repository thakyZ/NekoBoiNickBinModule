Param(
  [Parameter(Mandatory = $False, Position = 0, HelpMessage = "a")]
	[ValidateNotNullOrEmpty()]
	[string]
	$Set
)

Function Cut-String([int]$Length, [string]$Value) {
  If ($Value.Length -gt $Length) {
		Return $Value.SubString(0, $Length);
	}
	Return $Value;
}

class Config {
	[string] $Input         = "High Definition Audio";
  [string] $Output        = "High Definition Audio";
  [int]    $SamplingRate  = 32000;
  [int]    $BitsPerSample = 16;
  [int]    $Channels      = 2;
  [string] $ChannelCfg    = "Stereo";
  [int]    $BufferMs      = 100;
  [int]    $BufferParts   = 12;
  [int]    $Prefill       = 70;
  [int]    $ResyncAt      = 20;
  [string] $Priority      = "Normal";

	Config([psCustomObject]$Config) {
	  ForEach ($Item in $Config.PSObject.Properties) {
			$Split = ($Item -Split "=");
			$Name = ($Split[0] -Split " ");
			$Value = $Split[1];

			Switch ($Name.ToLower()) {
				"input"         { If ($Null -ne $Value -and $Value -ne "null") { $this.Input         = (Cut-String -Length 31 -Value $Value) } }
				"output"        { If ($Null -ne $Value -and $Value -ne "null") { $this.Output        = (Cut-String -Length 31 -Value $Value) } }
				"samplingrate"  { If ($Null -ne $Value -and $Value -ne "null") { $this.SamplingRate  = $Value } }
				"bitspersample" { If ($Null -ne $Value -and $Value -ne "null") { $this.BitsPerSample = $Value } }
				"channels"      { If ($Null -ne $Value -and $Value -ne "null") { $this.Channels      = $Value } }
				"channelcfg"    { If ($Null -ne $Value -and $Value -ne "null") { $this.ChannelCfg    = (Cut-String -Length 31 -Value $Value) } }
				"bufferms"      { If ($Null -ne $Value -and $Value -ne "null") { $this.BufferMs      = $Value } }
				"bufferparts"   { If ($Null -ne $Value -and $Value -ne "null") { $this.BufferParts   = $Value } }
				"prefill"       { If ($Null -ne $Value -and $Value -ne "null") { $this.Prefill       = $Value } }
				"resyncat"      { If ($Null -ne $Value -and $Value -ne "null") { $this.ResyncAt      = $Value } }
				"priority"      { If ($Null -ne $Value -and $Value -ne "null") { $this.Priority      = (Cut-String -Length 31 -Value $Value) } }
			}
		}
	}

  [string[]]ToArray() {
		Return @(
		  "/Input:`"$($this.Input)`"",
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
}

$Json = $Null;
[Config]$Config = $Null;

Try {
	$Json = (Get-Content -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "Settings.json") | ConvertFrom-Json);

  If ($Set -ne "" -and $Null -ne $Set) {
		$Fetched = ($Json.AudioRepeaterSettings.Presets | Where-Object { $_.Name.ToLower() -eq $Set.ToLower() }).Settings

    If ($Null -eq $Fetched) {
			Throw "Specified preset `"$($Set)`" does not exist in the config.";
		} Else {
		  $Json.AudioRepeaterSettings.Current = $Fetched;
		}
	}

	$Config = $Json.AudioRepeaterSettings.Current;
} Catch {
	Write-Error -Exception $_.Exception
	Write-Warning -Message "Failed to read Audio Repeater Settings from `"$((Join-Path -Path $PSScriptRoot -ChildPath "Settings.json"))`". Trying `"$((Join-Path -Path $PSScriptRoot -ChildPath "AutoAudioRepeater.cfg"))`" instead.";
	Try {
    $ConfigFile = $Null;

    If ($Null -eq $env:APROG_DIR) {
			$ConfigFile = (Join-Path -Path $PSScriptRoot -ChildPath "AutoAudioRepeater.cfg");
		} Else {
			$ConfigFile = (Join-Path -Path $env:APROG_DIR -ChildPath "bin" -AdditionalChildPath "AutoAudioRepeater.cfg");
		}

		$_Config = @{}

		ForEach ($Line in (Get-Content -LiteralPath $ConfigFile)) {
		  $_Line = (($Line -Replace "/", "") -Replace "`"", "");
		  $Item = ($_Line -Split (":"))
			$_Config[$Item[0]] = $Item[1];
		}

		$Config = New-Object -ItemType Config -ArgumentList @($_Config);
	} Catch {
	  Write-Error -Exception $_.Exception
	  Throw "Failed to read all config types."
	}
}

$VirtualAudioCable = "audiorepeater.exe";
$VAC_BackupPath = (Join-Path -Path $env:ProgramFiles -ChildPath "Virtual Audio Cable" -AdditionalChildPath $VirtualAudioCable)

If ($Null -eq (Get-Command -Name $VirtualAudioCable -ErrorAction SilentlyContinue)) {
  If (Test-Path -Path $VAC_BackupPath) {
	$VirtualAudioCable = $VAC_BackupPath;
  } Else {
    Write-Error -Message "Virtual Audio Cable not found on path or default directory $($VAC_BackupPath)"
	Exit 1
  }
}

If ($Null -ne (Get-Process -Name "audiorepeater" -ErrorAction SilentlyContinue)) {
  Exit 0
}

$Arguments = $Config.ToArray();
$Arguments += "/AutoStart";

Start-Process -WindowStyle Minimized -FilePath "$($VirtualAudioCable)" -ArgumentList $Arguments