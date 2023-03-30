Param (
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $true,
    Position = 0,
    ParameterSetName = "Recursive",
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true,
    HelpMessage = "Path to one or more locations.")]
  [Parameter(Mandatory = $true,
    Position = 0,
    ParameterSetName = "NonRecursive",
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true,
    HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath", "LiteralPath")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $Path,
  # Recurse directory path.
  [Parameter(Mandatory = $true,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [switch]
  $Recurse,
  # Recurse directory path.
  [Parameter(Mandatory = $false,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [int]
  $Depth = -1,
  # Recurse directory path.
  [Parameter(Mandatory = $false,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [Parameter(Mandatory = $false,
    ParameterSetName = "NonRecursive",
    HelpMessage = "Recurse directory path.")]
  [string]
  $Filter = "",
  # Recurse directory path.
  [Parameter(Mandatory = $false,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [Parameter(Mandatory = $false,
    ParameterSetName = "NonRecursive",
    HelpMessage = "Recurse directory path.")]
  [string[]]
  $Include = @(),
  # Recurse directory path.
  [Parameter(Mandatory = $false,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [Parameter(Mandatory = $false,
    ParameterSetName = "NonRecursive",
    HelpMessage = "Recurse directory path.")]
  [string[]]
  $Exclude = @()
)

Begin {
  $CommandBuilt = "Get-ChildItem -LiteralPath `$Path";

  $PathType = $null;

  if (Test-Path -LiteralPath $Path -PathType Container) {
    $PathType = "Directory";
  }
  elseif (Test-Path -LiteralPath $Path -PathType Leaf) {
    $PathType = "File";
  }

  if ($null -eq $PathType) {
    Write-Error "Path specified is not valid";
  }

  if ($PathType -eq "File" -and $Recurse -eq $true) {
    Write-Warning "Path specified is not a directory Recursive switch does nothing.";
  }
  elseif ($PathType -eq "Directory" -and $Recurse -eq $true) {
    $CommandBuilt += " -Recurse";

    if ($Filter -ne "") {
      $CommandBuilt += " -Filter `$Filter";
    }
    if ($Include.Length -gt 0) {
      $CommandBuilt += " -Include `$Include";
    }
    if ($Include.Length -gt 0) {
      $CommandBuilt += " -Exclude `$Exclude";
    }
    if ($Depth -ge 0) {
      $CommandBuilt += " -Depth `$Depth";
    }
  }
  elseif ($PathType -eq "Directory" -and $Recurse -eq $false) {
    if ($Filter -ne "") {
      $CommandBuilt += " -Filter `$Filter";
    }
    if ($Include.Length -gt 0) {
      $CommandBuilt += " -Include `$Include";
    }
    if ($Include.Length -gt 0) {
      $CommandBuilt += " -Exclude `$Exclude";
    }
  }

  $Files = Invoke-Expression -Command $CommandBuilt;
}
Process {
  ForEach ($File in $Files) {
    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
      Write-Host "Unblocking File $($File.FullName)";
    }

    try {
      Get-Item -LiteralPath "$($File.FullName)" | Unblock-File;
    }
    catch {
      Write-Error -Exception $_.Exception;
      Exit 1;
    }
  }
  Exit 0;
}
