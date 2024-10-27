using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Set, "HyperVStaticIp")]
public class SetHyperVStaticIpCommand : Cmdlet {
}
/*
$Default = "192.168.48.1"
$WSL = "172.22.32.1"
Start-Process -Path "C:\Windows\System32\netsh.exe" -ArgumentList "interface ip set address name=`"vEthernet (Default Switch)`" source=static addr=$($Default) 255.255.240.0 none"
Start-Process -Path "C:\Windows\System32\netsh.exe" -ArgumentList "interface ip set address name=`"vEthernet (WSL)`" source=static addr=$($WSL) 255.255.240.0 none"
*/
