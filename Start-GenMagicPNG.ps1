param (
  [parameter(Mandatory = $True, Position = 0)]
  [Alias("Hidden")]
  [string]
  $ImageOne,
  [parameter(Mandatory = $True, Position = 1)]
  [Alias("Visible")]
  [string]
  $ImageTwo,
  [parameter(Mandatory = $False, Position = 2)]
  [string]
  $OutFile
);

$DoubleVision = $Null;
$PngCrush = $Null;
$Ruby = $Null;

function checkPath($ProgramEnum) {
  $TestConfig = $False;
  $Config = $Null;

  if (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "config.json") -PathType Leaf) {
    $TestConfig = $True;
    $Config = (Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "config.json") | ConvertFrom-Json);
  }

  if ($ProgramEnum -eq 0) {
    if ($env:PATH.Contains("doubleVision.bat")) {
      return 1;
    } else {
      if ($TestConfig && Test-Path -Path $Config.Installs.DoubleVision -PathType Leaf) {
        return $Config.Installs.DoubleVision;
      } else {
        return 2;
      }
    }
  } ElseIf ($ProgramEnum -eq 1) {
    if ($env:PATH.Contains("pngCrush.exe")) {
      return 1;
    } else {
      if ($TestConfig && Test-Path -Path $Config.Installs.pngCrush -PathType Leaf) {
        return $Config.Installs.pngCrush;
      } else {
        return 2;
      }
    }
  } ElseIf ($ProgramEnum -eq 2) {
    if ($env:PATH.Contains("ruby.exe")) {
      return 1;
    } else {
      if ($TestConfig && Test-Path -Path $Config.Installs.Ruby -PathType Leaf) {
        return $Config.Installs.Ruby;
      } else {
        return 2;
      }
    }
  }
}

function checkImages() {
  if (Test-Path -Path $TempImageOne -PathType Leaf && Test-Path -Path $img2 -PathType Leaf) {
    return $True;
  } else {
    return $False;
  }
}

function runpngCrush($file, $outfile, $remove) {
  if (Test-Path -Path "$($file)" -PathType Leaf) {
    Start-Process -FilePath "$($PngCrush)" "-g 0.002 $($file) $($outfile)" -NoNewWindow -Wait;

    if ($remove -eq $True) {
      if (Test-Path -Path $file -PathType Leaf) {
        Remove-Item -Path "$($file)";
      }
    }
  }
}

if (checkImages) {
  $check0 = checkPath 0;
  $check1 = checkPath 1;
  $check2 = checkPath 2;

  if ($check0 -eq 1) {
    $DoubleVision = "doubleVision.exe";
  } ElseIf ($check0 -eq 2) {
    Write-Error -Message "DoubleVision is not installed or could not be found from path or config.";
  } else {
    $DoubleVision = $check0;
  }

  if ($check1 -eq 1) {
    $PngCrush = "pngcrush.exe";
  } ElseIf ($check1 -eq 2) {
    Write-Error -Message "PNG Crush is not installed or could not be found from path or config.";
  } else {
    $PngCrush = $check1;
  }

  if ($check2 -eq 1) {
    $Ruby = "Gem";
  } ElseIf ($check2 -eq 2) {
    Write-Error -Message "Ruby Gem is not installed or could not be found from path or config.";
  } else {
    $Ruby = $check2;
  }
}

if ($Null -ne $DoubleVision) {
  #runpngCrush $TempImageOne "$($TempImageOne)-temp" $False;

  #Start-Process -FilePath "$($DoubleVision)" "$($TempImageOne)-temp $($img2) $($out)-temp" -NoNewWindow -Wait;
  Start-Process -FilePath "$($DoubleVision)" "$($TempImageOne) $($img2) $($out)-temp" -NoNewWindow -Wait;

  if (Test-Path -Path "$($TempImageOne)-temp" -PathType Leaf) {
    Remove-Item -Path "$($TempImageOne)-temp";
  }

  #runpngCrush "$($out)-temp" "$($out)" $True;
}
