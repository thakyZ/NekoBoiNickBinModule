using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Invoke, "GitJet")]
public class InvokeGitJetCommand : Cmdlet {
}
/*
Param()  $script:SSHAgent = "$($env:WinDir)\System32\OpenSSH\ssh-agent.exe" $script:SSH = "$($env:WinDir)\System32\OpenSSH\ssh.exe" $script:GIT = "$($env:APROG_DIR)\Git\bin\git.exe" $script:PATH = "$($env:APROG_DIR)\Git\bin;$($env:WinDir)\System32\OpenSSH\;$($env:PATH)" $script:KEY = "$($env:UserProfile)\.ssh\id_rsa"  $script:GIT_SSH_COMMAND = "$($script:SSH) -i $($script:KEY)" & "$($script:GIT)" $PSBoundParameters.Values
*/
