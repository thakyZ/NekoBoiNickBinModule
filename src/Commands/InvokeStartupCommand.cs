using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Invoke, "Startup")]
public class InvokeStartupCommand : Cmdlet {
}
/*
param()

if ($env:Path.Contains("C:\Windows\System32\OpenSSH")) {
  # Do nothing
}
else {
  $env:Path = "C:\Windows\System32\OpenSSH;$env:Path"
}


function Get-SshAgent() {
  $agentPid = [Environment]::GetEnvironmentVariable("SSH_AGENT_PID", "User")
  if ([int]$agentPid -eq 0) {
    $agentPid = [Environment]::GetEnvironmentVariable("SSH_AGENT_PID", "Process")
  }

  if ([int]$agentPid -eq 0) {
    0
  }
  else {
    # Make sure the process is actually running
    $process = Get-Process -Id $agentPid -ErrorAction SilentlyContinue

    if (($null -eq $process) -or ($process.ProcessName -ne "ssh-agent")) {
      # It is not running (this is an error). Remove env vars and return 0 for no agent.
      [Environment]::SetEnvironmentVariable("SSH_AGENT_PID", $null, "Process")
      [Environment]::SetEnvironmentVariable("SSH_AGENT_PID", $null, "User")
      [Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", $null, "Process")
      [Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", $null, "User")
      0
    }
    else {
      # It is running. Return the PID.
      $agentPid
    }
  }
}

function Invoke-SshAgentStart() {
  $status = Get-SshAgent
  Write-Host $status
  if ($status -ne 0) {
    . (Resolve-Path D:/Files/System/Programs/bin/ssh-agent-utils.ps1)
  }
}

Invoke-SshAgentStart
*/
