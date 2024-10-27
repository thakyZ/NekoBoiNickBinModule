using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Update, "MariaDB")]
public class UpdateMariaDBCommand : Cmdlet {
}
/*
using namespace System; using namespace System.IO; using namespace System.Management.Automation; using namespace System.ServiceProcess;  [CmdletBinding()] Param()  Begin {   [ActionPreference]  $OriginalErrorActionPreference = $ErrorActionPreference;   [ServiceController] $Service = (Get-Service -Name "MariaDB" -ErrorAction SilentlyContinue);   [ApplicationInfo]   $WinGet  = (Get-Command -Name "winget.exe" -ErrorAction SilentlyContinue);   [FileSystemInfo]    $BackupDirectory = (Get-BackupDirectory -PartialPath "MariaDB");   [bool] $FreshInstall = ($Null -eq $Service); } Process {   If (-not $FreshInstall) {     If ($Service.Status -ne "Stopped") {       Stop-Service -InputObject $Service;     }   } } End {   Start-Service -InputObject $Service; } Clean {   $ErrorActionPreference = $OriginalErrorActionPreference; }
*/
