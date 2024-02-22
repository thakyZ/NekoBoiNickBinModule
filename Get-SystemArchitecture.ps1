Param()

If ($IsWindows) {
  $OsType = (Get-WmiObject -Class Win32_ComputerSystem).SystemType;
  Return ($OsType -Replace "-based PC", "");
} ElseIf ($IsLinux) {
  Try {
    If ([System.Environment]::Is64BitProcess) {
      Return "x64";
    } ElseIf ([System.Environment]::Is32BitProcess) {
      Return "x86";
    } ElseIf ([System.Environment]::IsArmProcess) {
      Return "arm86";
    }
  } Catch {
    Throw;
  }
} ElseIf ($IsMacOS) {
  Try {
    If ([System.Environment]::Is64BitProcess) {
      Return "x64";
    } ElseIf ([System.Environment]::Is32BitProcess) {
      Return "x86";
    } ElseIf ([System.Environment]::IsArmProcess) {
      Return "arm86";
    }
  } Catch {
    Throw;
  }
}