param(
  # The name of the processes to kill.
  [Parameter(Position = 0, Mandatory = $true, HelpMessage = "The name of the processes to kill.")]
  [string]
  $Name
)

if ($null -eq (Get-Process -Name $Name)) {
  Write-Error -Message "Process ${Name} doesn't exist or isn't running.";
}

$processes = Get-Process -Name $Name;

$processes | ForEach-Object {
  try {
    Stop-Process -Id $_.Id -Force;
  }
  catch [System.UnauthorizedAccessException] {
    Write-Error -Message "An Exception Occured [System.UnauthorizedAccessException] on process name ["$_.Name"] and id ["$_.Id"]";
  }
  catch {
    Write-Error -Message "Unknown Exception Occured on process name ["$_.Name"] and id ["$_.Id"]";
  }
}