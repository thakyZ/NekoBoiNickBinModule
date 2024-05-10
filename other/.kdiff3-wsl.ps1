Param()

$Verbose = $False;

$ArgsProcessed = @{};

$ArgsProcessed = @{};
$SkipNext = $False;
For ($Index = 0; $Index -lt $args.Length; $Index++) {
  If ($SkipNext -eq $True) {
    $SkipNext = $False;
  } Else {
    If (($args[$Index].StartsWith("-") -and $args[$Index].Length -eq 2)) {
      $SkipNext = $True;
      If ($args[$Index] -eq "-o") {
        $ArgsProcessed += @{ "Output" = "$($args[$Index + 1])" };
      } Else {
        Write-Warning -Message "Unsupported option `"$($args[$Index])`"";
      }
    } Else {
      If ($Index -eq 0) {
        $ArgsProcessed += @{ "Local" = "$($args[$Index])" };
      } ElseIf ($Index -eq 1) {
        $ArgsProcessed += @{ "Remote" = "$($args[$Index])" };
      } ElseIf ($Index -eq 2) {
        $ArgsProcessed += @{ "Base" = "$($args[$Index - 2])" };
        $ArgsProcessed["Local"] = "$($args[$Index - 1])";
        $ArgsProcessed["Remote"] = "$($args[$Index])";
      }
    }
  }
}

$WSL_PWD=("C:\Users\thaky\Development\Git\Games\zOther\degrees-of-lewdity-foster" | Select-Object -Property @(@{Name="PWD";Expression={[System.Text.RegularExpressions.Regex]::Replace("$($_ -Replace '\\', '/')", '^([A-Z]):', {param($m) "/mnt/$("$($m.Groups[1].Value)".ToLower())"})}})).PWD

# \"$BASE\" \"$LOCAL\" \"$REMOTE\" -o \"$MERGED\"
$DebugPath = (Join-Path -Path $PSScriptRoot -ChildPath "debug.log");
#$ArgsProcessed | Out-File -Append -FilePath $DebugPath


$ErrorPath = (Join-Path -Path $PSScriptRoot -ChildPath "error.log");

If ($Null -eq (Get-Command -Name "wsl")) {
  "Cannot find wsl on path" | Out-File -Append -FilePath $ErrorPath
  Exit 1;
}

$Errors = 0;

# "C:\Program Files\WSL\wslg.exe" -d Ubuntu --cd "~" -- kdiff3
# C:\WINDOWS\system32\wsl.exe ~ -d Ubuntu

$WSL_Installs = (((& "wsl" "--list" "--verbose") | Select-Object -Property @(@{Name="Line";Expression={$_ -Replace '[\u0000-\u0019]+', ''}})).Line | Where-Object { ($_ -Replace '[\u0000-\u0020]+', '') -ne "NAMESTATEVERSION" -and -not [System.String]::IsNullOrEmpty($_) -and -not [System.String]::IsNullOrWhiteSpace($_) } | Select-Object -Property @(@{Name="Name";Expression={$_ -Replace '^([* ])\s([^\s]+)\s+([^\s]+)\s+(\d)', '$2'}},@{Name="State";Expression={$_ -Replace '^([* ])\s([^\s]+)\s+([^\s]+)\s+(\d)', '$3'}},@{Name="Version";Expression={$_ -Replace '^([* ])\s([^\s]+)\s+([^\s]+)\s+(\d)', '$4'}},@{Name="IsDefault";Expression={($_ -Replace '^([* ])\s([^\s]+)\s+([^\s]+)\s+(\d)', '$1') -eq '*'}}))

$Install_To_Use = ($WSL_Installs | Where-Object { $_.IsDefault });

If ($Install_To_Use.State -ne "Running") {
  Try {
    & "wsl" "~" "-u" "root" "-d" "$($Install_To_Use.Name)" "-e" "initwsl 2"
  } Catch {
    $_ | Out-File -Append -FilePath $ErrorPath
    $Errors++;
  }
}

Try {
  If ($Null -ne $ArgsProcessed.Base -and $Null -ne $ArgsProcessed.Output) {
    & "wsl" "-d" "$($Install_To_Use.Name)" "--cd" "$PWD" "--" "kdiff3" "$($ArgsProcessed.Base)" "$($ArgsProcessed.Local)" "$($ArgsProcessed.Remote)" "-o" "$($ArgsProcessed.Output)"
  } ElseIf ($Null -ne $ArgsProcessed.Base -and $Null -eq $ArgsProcessed.Output) {
    & "wsl" "-d" "$($Install_To_Use.Name)" "--cd" "$PWD" "--" "kdiff3" "$($ArgsProcessed.Base)" "$($ArgsProcessed.Local)" "$($ArgsProcessed.Remote)"
  } ElseIf ($Null -eq $ArgsProcessed.Base -and $Null -ne $ArgsProcessed.Output) {
    & "wsl" "-d" "$($Install_To_Use.Name)" "--cd" "$PWD" "--" "kdiff3" "$($ArgsProcessed.Local)" "$($ArgsProcessed.Remote)" "-o" "$($ArgsProcessed.Output)"
  } Else {
    & "wsl" "-d" "$($Install_To_Use.Name)" "--cd" "$PWD" "--" "kdiff3" "$($ArgsProcessed.Local)" "$($ArgsProcessed.Remote)"
  }
} Catch {
  $_ | Out-File -Append -FilePath $ErrorPath
  $Errors++;
}

If ($Errors -gt 0) {
  Exit 1;
}

Exit 0;