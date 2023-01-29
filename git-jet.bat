@echo off
set SSHAgent="C:\Windows\System32\OpenSSH\ssh-agent.exe"
set SSH="C:\Windows\System32\OpenSSH\ssh.exe"
set GIT="D:\Files\System\Programs\Git\bin\git.exe"
set PATH="D:\Files\System\Programs\Git\bin;C:\Windows\System32\OpenSSH\;%PATH%"
set KEY="C:\Users\thaky\.ssh\id_rsa"

set GIT_SSH_COMMAND="%SSH% -i %KEY%"
%GIT% %*