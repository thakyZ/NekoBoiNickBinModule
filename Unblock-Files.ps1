[CmdletBinding()]
Param (
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $False,
    Position = 0,
    ParameterSetName = "Recursive",
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Path to one or more locations.")]
  [Parameter(Mandatory = $False,
    Position = 0,
    ParameterSetName = "NonRecursive",
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath", "LiteralPath")]
  [System.String[]]
  $Path = @($PWD),
  # Recurse directory path.
  [Parameter(Mandatory = $True,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [switch]
  $Recurse,
  # Recurse directory path.
  [Parameter(Mandatory = $False,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [System.UInt32]
  $Depth = [System.UInt32]::MaxValue,
  # Recurse directory path.
  [Parameter(Mandatory = $False,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [Parameter(Mandatory = $False,
    ParameterSetName = "NonRecursive",
    HelpMessage = "Recurse directory path.")]
  [System.String]
  $Filter = $Null,
  # Recurse directory path.
  [Parameter(Mandatory = $False,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [Parameter(Mandatory = $False,
    ParameterSetName = "NonRecursive",
    HelpMessage = "Recurse directory path.")]
  [System.String[]]
  $Include = @(),
  # Recurse directory path.
  [Parameter(Mandatory = $False,
    ParameterSetName = "Recursive",
    HelpMessage = "Recurse directory path.")]
  [Parameter(Mandatory = $False,
    ParameterSetName = "NonRecursive",
    HelpMessage = "Recurse directory path.")]
  [System.String[]]
  $Exclude = @()
)

Begin {
  [System.IO.FileSystemInfo[]] $Files = (Get-ChildItem -LiteralPath $Path -File -Recurse:($Recurse -eq $True) -Filter:($Filter) -Include:($Include) -Exclude:($Exclude) -Depth:($Depth));
} Process {
  Function Set-FileReadable {
    [CmdletBinding()]
    Param(
      [ValidateNotNull()]
      [System.IO.FileSystemInfo]
      $File,
      [ValidateNotNull()]
      [System.Boolean]
      $Read
    )
    Try {
      Get-Item -LiteralPath $File -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True) | Set-ItemProperty -Name IsReadOnly -Value $Read -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True)
    } Catch {
      Write-Error -ErrorRecord $_;
      Exit 1;
    }
  }

  Function Set-UnblockFile {
    [CmdletBinding()]
    Param(
      [ValidateNotNull()]
      [System.IO.FileSystemInfo[]]
      $Files
    )
    ForEach ($File in $Files) {
      Try {
        Unblock-File -LiteralPath $File -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True);
      } Catch {
        If ($_.Exception.Message.EndsWith(":Zone.Identifier' is denied.")) {
          Try {
            Set-FileReadable -File $File -Read $True -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True);
            Unblock-File -LiteralPath $File -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True);
            Set-FileReadable -File $File -Read $False -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True);
          } Catch {
            Write-Error -ErrorRecord $_;
            Exit 1;
          }
        } Else {
          Write-Error -ErrorRecord $_;
          Exit 1;
        }
      }
    }
  }

  Set-UnblockFile -Files $Files;

  Exit 0;
}
