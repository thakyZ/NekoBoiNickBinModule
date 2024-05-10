Param()

$Verbose = $False;

$ErrorPath = (Join-Path -Path $PSScriptRoot -ChildPath "error.log");

If ($Null -eq (Get-Command -Name "git")) {
  "Cannot find git on path" | Out-File -Append -FilePath $ErrorPath
  Exit 1;
}

If ($Null -eq (Get-Command -Name "gpgconf") -or $Null -eq (Get-Command -Name "gpg")) {
  "Cannot find gnupg tools on path" | Out-File -Append -FilePath $ErrorPath
  Exit 1;
}

$Errors = 0;

$GpgCmd = "";

Try {
  $GpgCmd=(& "git" "config" "--global" "gpg.cmd")
} Catch {
  $_ | Out-File -Append -FilePath $ErrorPath
  $Errors++;
}

Try {
  & "$($GpgCmd)" "--pinentry-mode" "loopback" $args
}
Catch {
  $_ | Out-File -Append -FilePath $ErrorPath

  Try {
    & "$($GpgCmd)" "--pinentry-mode" "loopback" $args
  }
  Catch {
    $_ | Out-File -Append -FilePath $ErrorPath
    $Errors++;
  }
}

If ($Errors -gt 0) {
  Exit 1;
}

Exit 0;