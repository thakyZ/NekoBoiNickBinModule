@echo off
set SSHAgent="%WINDIR%\System32\OpenSSH\ssh-agent.exe"
set SSH="%WINDIR%\System32\OpenSSH\ssh.exe"
set GIT="%APROG_DIR%\Git\bin\git.exe"
set PATH="%APROG_DIR%\Git\bin;%WINDIR%\System32\OpenSSH\;%PATH%"
set KEY="%USERPROFILE%\.ssh\id_rsa"

set GIT_SSH_COMMAND="%SSH% -i %KEY%"
%GIT% %*