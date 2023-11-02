Param()

$script:APROG_DIR = ""
$InvokeProcessCmdlet = (Get-Command -Name "Invoke-Process" -ErrorAction SilentlyContinue);

If ($Null -eq $InvokeProcessCmdlet) {
  Write-Error -Message "The cmdlet ``Invoke-Process`` was not found on the path.";
  Exit 1;
}

If ([string]::IsNullOrEmpty($env:APROG_DIR)) {
  Write-Warning "`$env:APROG_DIR is null";
  $script:APROG_DIR = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath ".."));
} Else {
  $script:APROG_DIR = $env:APROG_DIR;
}

$PixivUtilDir = (Join-Path -Path $script:APROG_DIR -ChildPath "PixivUtil")
$PixivUtil = (Join-Path -Path $PixivUtilDir -ChildPath "PixivUtil2.exe")

If (-not (Test-Path -LiteralPath $PixivUtilDir -PathType Container)) {
  Write-Error -Message "The PixivUtil directory does not exist on path: $($PixivUtilDir)";
  Exit 1;
} ElseIf (-not (Test-Path -LiteralPath $PixivUtil -PathType Leaf)) {
  Write-Error -Message "The PixivUtil2 executable does not exist on path: $($PixivUtil)";
  Exit 1;
}

Function Invoke-TestJob() {
  Try {
    $Job = (Start-Job -ScriptBlock {
        $ReturnOuput = (Invoke-Expression -Command "& `"$($args[0])`" -FileName `"$($args[1])`" -Arguments `"$($args[2])`" -WorkingDirectory `"$($args[3])`" -Timeout 1")
        Write-Output @{ReturnOutput = $ReturnOuput; CmdLine = "& `"$($args[0])`" -FileName `"$($args[1])`" -Arguments `"$($args[2])`" -WorkingDirectory `"$($args[3])`" -Timeout 1" }
      } -ArgumentList @($InvokeProcessCmdlet.Source, $PixivUtil, @("-x"), $PixivUtilDir));
    #$JobOutput = (Receive-Job -Job $Job);
    $RunningJobs = (Get-Job -Id $Job.Id | Where-Object { $_.State -eq "Running" })
    While ($RunningJobs) {
      Write-Host -Object "." -NoNewline
      $RunningJobs = (Get-Job -Id $Job.Id | Where-Object { $_.State -eq "Running" })
      Start-Sleep -Seconds 3;
    }
    Write-Host -Object "";
    $JobOutput = (Receive-Job -Job $Job);
    Write-Output $JobOutput
  } Catch {
    Throw $_
    Write-Error -Exception $_.Exception -Message "Failed to run the job."
  }
}

Invoke-TestJob