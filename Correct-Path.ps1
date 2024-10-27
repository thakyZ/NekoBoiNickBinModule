using namespace System
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Collections.Specialized
using namespace System.Diagnostics
using namespace System.Linq
using namespace System.Management.Automation
using namespace System.Text.RegularExpressions
using namespace Microsoft.Win32

[CmdletBinding()]
Param(
  [Parameter(DontShow = $True)]
  [String]
  $AsAdmin = $Null
)

# cSpell:ignore APROG_LIST
# cSpell:ignoreRegExp /HKLM(?=:\\)/

Begin {
  Function Write-Log {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 1,
                 ValueFromPipeline = $True)]
      [Object]
      $Object,
      [Parameter(Mandatory = $True,
                 Position = 0)]
      [String]
      $Name,
      [Parameter(Mandatory = $False)]
      [ValidateSet("Black","DarkBlue","DarkGreen","DarkCyan","DarkRed","DarkMagenta","DarkYellow","Gray","DarkGray","Blue","Green","Cyan","Red","Magenta","Yellow","White")]
      [String]
      $ForegroundColor = "White"
    )
    Begin {
      [System.Int32]$MinLength = 38;
      [String]$Message = [String]::Empty;
    } Process {
      Write-Host -Object '[' -ForegroundColor Yellow -NoNewline;

      If ($Null -eq $Object) {
        Write-Host -Object 'Null' -ForegroundColor Yellow -NoNewline;
        $Message = "[Null]"
      } Else {
        $Message = "[$($Object.GetType().Name)]"
        Write-Host -Object $Object.GetType().Name -ForegroundColor DarkMagenta -NoNewline;
      }

      Write-Host -Object ']' -ForegroundColor Yellow -NoNewline;
      Write-Host -Object "$([String]::new(' ', ($MinLength - $Message.Length)))" -ForegroundColor White -NoNewline;

      If ($Null -eq $Object) {
        Write-Host -Object "`$$($Name)" -ForegroundColor Red -NoNewline;
        Write-Host -Object ' = ' -ForegroundColor Cyan -NoNewline;
        Write-Host -Object '$Null' -ForegroundColor Yellow;
      } Else {
        Write-Host -Object "`$$($Name)" -ForegroundColor Red -NoNewline;
        Write-Host -Object ' = ' -ForegroundColor Cyan -NoNewline;
        $Message = "$($Object)";
        If ($Object.GetType().Name -eq "String") {
          Write-Host -Object "`"$($Message)`"" -ForegroundColor $ForegroundColor;
        } ElseIf (($Object.GetType().Name.Contains("List") -or $Object.GetType().Name.Contains("Dictionary")) -and $Null -ne $Object.Count -or ($Null -ne $Object.Length -and [String]::IsNullOrEmpty($Message))) {
          Write-Host -Object '[]' -ForegroundColor $ForegroundColor;
        } Else {
          Write-Host -Object $Message -ForegroundColor $ForegroundColor;
        }
      }
    }
  }


  [ActionPreference]$OriginalErrorActionPreference = $ErrorActionPreference;
  $ErrorActionPreference = "Stop";
  If ($PSBoundParameters.Keys.Contains("Debug") -eq $True) {
    $DebugPreference = "Continue";
  }
  If ($PSBoundParameters.Keys.Contains("Verbose") -eq $True) {
    $VerbosePreference = "Continue";
  }
} Process {
  Function Expand-Path {
    [CmdletBinding()]
    [OutputType([String])]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "Path string to expand.")]
      [ValidateNotNullOrWhiteSpace()]
      [ValidateNotNullOrEmpty()]
      [String]
      $Path
    )

    Begin {
      If ([String]::IsNullOrEmpty($Path) -or [String]::IsNullOrWhiteSpace($Path)) {
        Throw "Variable `$Path is null or empty or white space.";
      }
      [String]$Output = $Path;
      If ($Path -notmatch '%[^%]*?%') {
        Write-Output -NoEnumerate -InputObject $Output;
      }
      [DictionaryEntry[]]$EnvironmentVariables = (Get-ChildItem -Path "env:");
    } Process {
      [Regex]$BatchVariable = [Regex]::new('(%([^%]*?)%)');
      [MatchCollection]$TempMatches = $BatchVariable.Matches($Path);
      ForEach ($Match in $TempMatches) {
        If ($Match.Groups.Count -ne 3) {
          Continue;
        }
        [String]$EnvironmentVariableName = $Match.Groups[2].Value;
        [String]$FullEnvironmentVariable = $Match.Groups[1].Value;
        [String]$EnvironmentVariableValue = ($EnvironmentVariables | WHere-Object { $_.Name -eq $EnvironmentVariableName }).Value;
        If ($EnvironmentVariables.Name.Contains($EnvironmentVariableName)) {
          $Output = $Path.Replace($FullEnvironmentVariable, $EnvironmentVariableValue, 1)
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function ConvertTo-List {
    [CmdletBinding()]
    [OutputType([List[[KeyValuePair[[String], [Object]]]]])]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "A generic dictionary to convert to list.")]
      [ValidateNotNull()]
      [IDictionary]
      $Dictionary
    )

    Begin {
      Write-Log -Object $Dictionary -Name "Dictionary"
      [List[[KeyValuePair[[String], [Object]]]]]`
      $Output = [List[[KeyValuePair[[String], [Object]]]]]::new();
    } Process {
      Write-Log -Object $Dictionary.Count -Name "Dictionary.Count"
      Write-Log -Object $Dictionary.Keys -Name "Dictionary.Keys"
      ForEach ($Key in $Dictionary.Keys) {
        Write-Log -Object $Key -Name "Key"
        [Object]$Value = $Dictionary[$Key];
        Write-Log -Object $Value -Name "Value"
        [KeyValuePair[[String], [Object]]]`
        $KeyValuePair = [KeyValuePair[[String], [Object]]]::new($Key, $Value);
        $Output.Add($KeyValuePair);
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  If ([String]::IsNullOrEmpty($AsAdmin) -or [String]::IsNullOrWhiteSpace($AsAdmin)) {
    [List[String]]$Paths = [List[String]]::new();
    [List[String]]$AdminProgramList = [List[String]]::new();

    [RegistryKey]$Key = [Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment");

    [Object]$Reg_Paths = $Null;

    If ($Null -ne $Key) {
      $Reg_Paths = $Key.GetValue("Path", $Null, "DoNotExpandEnvironmentNames");
      If ($Null -eq $Reg_Paths) {
        Write-Host -ForegroundColor Red -Object "Registry Key Value is `$Null";
      }
    } Else {
      Write-Host -ForegroundColor Red -Object "Registry Key is `$Null";
    }

    Write-Host -ForegroundColor Red -Object $Reg_Paths;

    ForEach ($Path in @($Reg_Paths -Split ";")) {
      $Paths.Add($Path);
    }

    ForEach ($Path in @((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment").APROG_LIST -Split ";")) {
      $AdminProgramList.Add($Path);
    }

    [OrderedDictionary]$ToRemove = [OrderedDictionary]::new();

    [Int32]$Index = 0;

    ForEach ($Path in $Paths) {
      $ExpandedPath = (Expand-Path -Path $Path);

      If ($ExpandedPath -is [System.Object[]]) {
        $ExpandedPath = $ExpandedPath[0]
      }

      If (($Paths | Where-Object { $_ -eq $Path }).Count -gt 1) {
        Write-Debug -Message "Duplicate:                $($Path)";

        If ($ToRemove.Keys -notcontains (Expand-Path -Path $Path)) {
          $ToRemove.Add("$($Path)", "$($Index)");
        }
      }

      If ($Path -eq "%APROG_LIST%") {
        Continue;
      }

      If (-not (Test-Path -LiteralPath $ExpandedPath -PathType Container)) {
        Write-Debug -Message "Non-Existant:             $($Path)";

        If ($ToRemove.Keys -notcontains $ExpandedPath) {
          $ToRemove.Add("$($Path)", "$($Index)");
        }
      }

      If ($AdminProgramList -contains $ExpandedPath) {
        Write-Debug -Message "Duplicate in APROG_LIST: $($Path)";

        If ($ToRemove.Keys -notcontains $ExpandedPath) {
          $ToRemove.Add("$($Path)", "$($Index)");
        }
      }
      $Index++;
    }

    Write-Log -Object $ToRemove.Count -Name "ToRemove.Count";
    Write-Log -Object $ToRemove.Keys -Name "ToRemove.Keys";
    $ToRemove = ($ToRemove | Sort-Object -Property Values);
    Write-Log -Object $ToRemove.Count -Name "ToRemove.Count";
    Write-Log -Object $ToRemove.Keys -Name "ToRemove.Keys";

    [Int32]$Limit = $ToRemove.Count;
    [Int32]$NegativeOffsetIndex = $ToRemove.Count + 1;
    Write-Host -Object "Soup1";

    $ToRemoveList = (ConvertTo-List -Dictionary $ToRemove);
    Write-Log -Object $ToRemoveList -Name "ToRemoveList";
    Write-Output -InputObject $ToRemoveList | Out-Host;
    If ($ToRemoveList -is [System.Object[]] -and $ToRemoveList[0] -is [List[[KeyValuePair[[String], [Object]]]]]) {
      $ToRemoveList = $ToRemoveList[0];
    }

    Write-Log -Object $Limit -Name "Limit";

    ForEach ($Path in $ToRemoveList) {
      Write-Log -Object $Path -Name "Path";
      Write-Log -Object $Path.Key -Name "Path Name";
      Write-Log -Object $Path.Value -Name "Path.Value";
      If ($NegativeOffsetIndex -lt 0) {
        Write-Error -Message "Variable `$NegativeOffsetIndex didn't get properly set outside loop, is at: $($NegativeOffsetIndex)";
        Return;
      }

      Write-Verbose -Message "$($Path.Name) $($Path.Value) $($NegativeOffsetIndex)"
      $NegativeOffsetIndex--;
    }

    [Int32]$OffsetIndex = 0;

    If ($OffsetIndex -lt 0) {
      Write-Error -Message "Variable `$OffsetIndex didn't get properly set, is at: $($OffsetIndex)";
      Return;
    }

    ForEach ($Path in $ToRemoveList) {
      $PathValue = [Int32]::Parse($Path.Value);

      If ($OffsetIndex -gt $Limit) {
        Write-Error -Message "Variable `$OffsetIndex didn't get properly set outside loop, is at: $($OffsetIndex)";
        Return;
      }

      [Int32]$Offset = $PathValue - 1;

      Write-Host -ForegroundColor Green -Object "Removing, `"$($Path)`", at index $($Offset)/$($Paths.Count) (Offset by $($OffsetIndex))";
      $Paths[$Offset] = "";
      $OffsetIndex++;
    }

    $Paths = ($Paths | Where-Object { -not [string]::IsNullOrEmpty($_) -and -not [string]::IsNullOrWhiteSpace($_) });

    If (-not $Paths.Contains("%APROG_LIST%")) {
      $Paths.Add("%APROG_LIST%");
    }

    Write-Host -ForegroundColor Blue -Object "$([String]::Join(";", $Paths))";

    [String]$OutboundValue = [String]::Join(";", $Paths);

    [Int32]$ExitCode = 0;
  } Else {
    [String]$OutboundValue = $AsAdmin;
  }

  Try {
    [RegistryKey]$Key = [Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment");

    If ($Null -ne $Key) {
      [Registry]::SetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", "Path", "$($OutboundValue)", "ExpandString");
    } Else {
      Write-Host -ForegroundColor Red -Object "Registry Key is `$Null";
    }

    $ExitCode = $LASTEXITCODE;
  } Catch {
    If ($_.Exception.Message -match ".*Access to the registry key '.+' is denied.") {
      Try {
        Start-Process -Verb RunAs -FilePath "$([Process]::GetCurrentProcess().MainModule.FileName)" -ArgumentList @("-Command", "& '`"$($PSCommandPath)`" -AsAdmin `"$($OutboundValue)`"'") -Wait;
        $ExitCode = $LASTEXITCODE;
      } Catch {
        Write-Error -Message "Failed to run command as admin.";
        Throw;
      }
    } Else {
      Throw;
    }
  }
} End {
  [RegistryKey]$Key = [Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment");
  [Object]$Reg_Paths = $Null;

  If ($Null -ne $Key) {
    $Reg_Paths = $Key.GetValue("Path", $Null, "DoNotExpandEnvironmentNames");
    If ($Null -eq $Reg_Paths) {
      Write-Host -ForegroundColor Red -Object "Registry Key Value is `$Null";
    } Else {
      Write-Host -ForegroundColor Green -Object $Reg_Paths;
    }
  } Else {
    Write-Host -ForegroundColor Red -Object "Registry Key is `$Null";
  }
  Exit $ExitCode;
} Clean {
  $ErrorActionPreference = $OriginalErrorActionPreference;
}

<#
## OLD

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
#>