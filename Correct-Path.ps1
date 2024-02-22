Param(
  # Specifies a switch to enable debug logging.
  [Parameter(Mandatory = $False,
             HelpMessage = "A switch to enable debug logging.")]
  [switch]
  $Debug_ = $False
)

If ($Debug -eq $True) {
  $DebugPreference = "Continue";
}


[System.Collections.Generic.List[System.String]]$Paths = (New-Object -TypeName System.Collections.Generic.List[System.String]);
[System.Collections.Generic.List[System.String]]$APROG_LIST = (New-Object -TypeName System.Collections.Generic.List[System.String]);

[Microsoft.Win32.RegistryKey]$Key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment");

$Reg_Paths = $Null;

If ($Null -ne $Key) {
  [System.Object]$Reg_Paths = $Key.GetValue("Path", $Null, "DoNotExpandEnvironmentNames");
  If ($Null -eq $Reg_Paths) {
    Write-Host -ForegroundColor Red -Object "Registry Key Value is `$Null";
  }
} Else {
  Write-Host -ForegroundColor Red -Object "Registry Key is `$Null";
}

ForEach ($Path in @($Reg_Paths -Split ";")) {
  $Paths.Add($Path);
}

ForEach ($Path in @((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment").APROG_LIST -Split ";")) {
  $APROG_LIST.Add($Path);
}

$ToRemove = @{};

$Index = 0;

ForEach ($Path in $Paths) {
  If (($Paths | Where-Object { $_ -eq $Path }).Count -gt 1) {
    Write-Debug -Message "Duplicate:                $($Path)";

    If ($ToRemove.Keys -notcontains $Path) {
      $_Temp = @{};
      $_Temp[$Path] = $Index;
      $ToRemove += $_Temp;
    }
  }

  If (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Debug -Message "Non-Existant:             $($Path)";

    If ($ToRemove.Keys -notcontains $Path) {
      $_Temp = @{};
      $_Temp[$Path] = $Index;
      $ToRemove += $_Temp;
    }
  }

  If ($APROG_LIST -contains $Path) {
    Write-Debug -Message "Duplicate in APROG_LIST: $($Path)";

    If ($ToRemove.Keys -notcontains $Path) {
      $_Temp = @{};
      $_Temp[$Path] = $Index;
      $ToRemove += $_Temp;
    }
  }
  $Index++;
}

$_ToRemove = ($ToRemove.GetEnumerator() | Sort-Object -Property Value);

[System.Int32]$_OffsetIndex = 0;

If ($_OffsetIndex -lt 0) {
  Write-Error -Message "Variable `$_OffsetIndex didn't get properly set, is at: $($_OffsetIndex)";
  Return;
}

$Limit = ($_ToRemove.Count * -1);

ForEach ($Path in $_ToRemove) {
  If ($_OffsetIndex -lt $Limit) {
    Write-Error -Message "Variable `$_OffsetIndex didn't get properly set outside loop, is at: $($_OffsetIndex)";
    Return;
  }

  Write-Verbose -Message "$($Path.Name) $($Path.Value) $($_OffsetIndex)"
  $_OffsetIndex = $_OffsetIndex - 1;
}

[System.Int32]$OffsetIndex = 0;

If ($OffsetIndex -lt 0) {
  Write-Error -Message "Variable `$OffsetIndex didn't get properly set, is at: $($OffsetIndex)";
  Return;
}

ForEach ($Path in $_ToRemove) {
  If ($OffsetIndex -lt $Limit) {
    Write-Error -Message "Variable `$OffsetIndex didn't get properly set outside loop, is at: $($OffsetIndex)";
    Return;
  }

  $Offset = $Path.Value + $OffsetIndex;
  Write-Host -ForegroundColor Green -Object "Removing at index $($Offset)/$($Paths.Count) (Offset by $($OffsetIndex))";
  $Paths.RemoveAt($Offset);
  $OffsetIndex = $OffsetIndex - 1;
}

Remove-Variable ToRemove;
Remove-Variable Index;
Remove-Variable _ToRemove;
Remove-Variable _OffsetIndex;
Remove-Variable OffsetIndex;

$OutboundValue = [System.String]::Join(";", $Paths);

$ExitCode = 0;

Write-Output ($Paths -Join ";") | Out-Host;
Read-Host;

Try {
  # Old way, disabled due to expanding values.
  #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name Path -Value "$($OutboundValue)" -ErrorAction Stop;

  [Microsoft.Win32.RegistryKey]$Key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment");

  If ($Null -ne $Key) {
    [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", "Path", "$($OutboundValue)", "ExpandString");
  } Else {
    Write-Host -ForegroundColor Red -Object "Registry Key is `$Null";
  }

  $ExitCode = $LASTEXITCODE;
} Catch {
  If ($_.Exception.Message -match ".*Access to the registry key '.+' is denied.") {
    Try {
      Start-Process -Verb RunAs -FilePath "$([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)" -ArgumentList @("-Command `"[Microsoft.Win32.RegistryKey]`$Key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment');If (`$Null -ne `$Key) {[Microsoft.Win32.Registry]::SetValue('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", "Path', '$($OutboundValue)', 'ExpandString');} Else {Write-Host -ForegroundColor Red -Object 'Registry Key is `$Null';Exit 1;};Exit `$LASTEXITCODE;`"") -Wait;
      $ExitCode = $LASTEXITCODE;
    } Catch {
      Write-Error -Message "Failed to run command as admin.";
      Throw;
    }
  } Else {
    Throw;
  }
}

Exit $ExitCode;