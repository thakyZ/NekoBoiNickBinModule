using namespace System;
using namespace System.Collections;
using namespace System.Collections.Generic;
using namespace System.IO;

[CmdletBinding()]
Param()

# cSpell:ignore zcat
Begin {
  $ConfigDirectory = (Join-Path -Path $HOME -ChildPath ".config" -AdditionalChildPath @("saved_blacklists"))
  $ConfigFile = (Join-Path -Path $ConfigDirectory -ChildPath "saved.json")
  If (-not (Test-Path -LiteralPath $ConfigDirectory -PathType Container) -or -not [Directory]::Exists($ConfigDirectory)) {
    New-Item -Path $ConfigDirectory -ItemType Directory;
  }
  If (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf) -or -not [File]::Exists($ConfigFile)) {
    New-Item -Path $ConfigFile -ItemType File;
    Set-Content -LiteralPath $ConfigFile  -Value "{`n}`n";
  }
  [Hashtable] $Config = (Get-Content -LiteralPath $ConfigFile | ConvertFrom-Json -Depth 100 -AsHashtable)
  [DirectoryInfo[]] $DirectoriesToCheckLogsOf = @();
  If ($IsLinux) {
    $DirectoriesToCheckLogsOf = @(
      (Resolve-Path -LiteralPath (Join-Path "/" -ChildPath "var" -AdditionalChildPath @("log", "nginx")))
    );
  }
  [string[]] $WhatToLookFor = @(

  );
  [Regex] $ClientCapture = [Regex]::new('client: ([^,]+)');
} Process {
  ForEach ($Directory in $DirectoriesToCheckLogsOf) {
    ForEach ($File in @(Get-ChildItem -LiteralPath $Directory -Filter "*.log*")) {
      [string[]] $FileContents = @();

      If ($File.Extension -eq ".log" -or $File.Extension -eq ".1") {
        $FileContents = (Get-Content -LiteralPath $File);
      } ElseIf ($File.Extension -eq ".gz" -and $Null -ne (Get-Command -Name "zcat" -ErrorAction SilentlyContinue)) {
        $FileContents = (& "zcat" "$($File.FullName)" 2>&1);
      }

      ForEach ($Look in $WhatToLookFor) {
        $Match = ($FileContents | Select-String -SimpleMatch $Look);
        If ($Null -ne $Match) {
          For ($i = 0; $i -lt $Match.Matches.Count; $i++) {
            ForEach ($mLook in $ClientCapture.Matches($Match.ToString())) {
              $IpAddress = $Look.Groups[1].Value;
              If (Test-ValidIp -Address $IpAddress) {
                
              }
            }
          }
          client: 167.71.206.152
        }
      }
    }
  }
} End {
  Set-Content -LiteralPath $ConfigFile -Value ($Config | ConvertTo-Json -Depth 100)
} Clean {

}