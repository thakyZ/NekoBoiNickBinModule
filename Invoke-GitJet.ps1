Param()

$script:SSHAgent = "$($env:WinDir)\System32\OpenSSH\ssh-agent.exe"
$script:SSH = "$($env:WinDir)\System32\OpenSSH\ssh.exe"
$script:GIT = "$($env:APROG_DIR)\Git\bin\git.exe"
$script:PATH = "$($env:APROG_DIR)\Git\bin;$($env:WinDir)\System32\OpenSSH\;$($env:PATH)"
$script:KEY = "$($env:UserProfile)\.ssh\id_rsa"

$script:GIT_SSH_COMMAND = "$($script:SSH) -i $($script:KEY)"
& "$($script:GIT)" $PSBoundParameters.Values