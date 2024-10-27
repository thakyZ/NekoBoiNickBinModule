using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "SystemArchitecture")]
public class GetSystemArchitectureCommand : Cmdlet {
}
/*
Param()  If ($IsWindows) {   $OsType = (Get-WmiObject -Class Win32_ComputerSystem).SystemType;   Return ($OsType -Split "-based")[0]; } ElseIf ($IsLinux) {   Try {     If ([System.Environment]::Is64BitProcess) {       Return "x64";     } ElseIf ([System.Environment]::Is32BitProcess) {       Return "x86";     } ElseIf ([System.Environment]::IsArmProcess) {       Return "arm86";     }   } Catch {     Throw;   } } ElseIf ($IsMacOS) {   Try {     If ([System.Environment]::Is64BitProcess) {       Return "x64";     } ElseIf ([System.Environment]::Is32BitProcess) {       Return "x86";     } ElseIf ([System.Environment]::IsArmProcess) {       Return "arm86";     }   } Catch {     Throw;   } }
*/
