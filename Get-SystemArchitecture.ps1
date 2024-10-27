Param()

If ($IsWindows) {
  $OsType = (Get-WmiObject -Class Win32_ComputerSystem).SystemType;
  Write-Output -NoEnumerate -InputObject ($OsType -Split "-based")[0];
} ElseIf ($IsLinux) {
  Try {
    If ([System.Environment]::Is64BitProcess) {
      Write-Output -NoEnumerate -InputObject "x64";
    } ElseIf ([System.Environment]::Is32BitProcess) {
      Write-Output -NoEnumerate -InputObject "x86";
    } ElseIf ([System.Environment]::IsArmProcess) {
      Write-Output -NoEnumerate -InputObject "arm86";
    }
  } Catch {
    Throw;
  }
} ElseIf ($IsMacOS) {
  Try {
    If ([System.Environment]::Is64BitProcess) {
      Write-Output -NoEnumerate -InputObject "x64";
    } ElseIf ([System.Environment]::Is32BitProcess) {
      Write-Output -NoEnumerate -InputObject "x86";
    } ElseIf ([System.Environment]::IsArmProcess) {
      Write-Output -NoEnumerate -InputObject "arm86";
    }
  } Catch {
    Throw;
  }
}