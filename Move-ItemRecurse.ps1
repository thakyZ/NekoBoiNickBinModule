[CmdletBinding()]
Param(
  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "LiteralPath",
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Literal path to one or more locations.")]
  [Alias("PSLiteralPath")]
  [ValidateNotNullOrEmpty()]
  [System.String[]]
  $LiteralPath,
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Path",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $Path,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 5,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 4,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [switch]
  $Force,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 4,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 3,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [System.String]
  $Filter,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 3,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 2,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [System.String[]]
  $Exclude,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 6,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 5,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [System.String[]]
  $Include,
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $False,
             Position = 1,
             ParameterSetName = "Path",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Parameter(Mandatory = $False,
             Position = 0,
             ParameterSetName = "LiteralPath",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSDestination")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Destination,
  # Specifies ...
  # TODO: Add Help Message
  [Parameter(Mandatory = $False,
             Position = 2,
             ParameterSetName = "Path",
             HelpMessage = "TODO: Add Help Message")]
  [Parameter(Mandatory = $False,
             Position = 1,
             ParameterSetName = "LiteralPath",
             HelpMessage = "TODO: Add Help Message")]
  [System.Management.Automation.PSCredential]
  $Credential
)

Begin {
  $EnableDebug = $False;
  $EnableVerbose = $False;
  If ($DebugPreference -ne "SilentlyContinue") {
    $EnableDebug = $True;
  }
  If ($VerbosePreference -ne "SilentlyContinue") {
    $EnableVerbose = $True;
  }
  [System.String]$EscapedPath = "";
  [System.IO.FileSystemInfo]$SourcePath
  [System.IO.FileSystemInfo[]]$SourceItems = @();

  Write-Host -Object "Querying items of source path...";
  If ($PSCmdlet.ParameterSetName -eq "Path") {
    $EscapedPath = (ConvertTo-Escaped -LiteralPath (Resolve-Path -Path $Path -Debug:$EnableDebug -Verbose:$EnableVerbose) -Debug:$EnableDebug -Verbose:$EnableVerbose);
  } Else {
    $EscapedPath = (ConvertTo-Escaped -LiteralPath (Resolve-Path -Path $LiteralPath -Debug:$EnableDebug -Verbose:$EnableVerbose) -Debug:$EnableDebug -Verbose:$EnableVerbose);
  }
  $SourceItems = (Get-ChildItem -Path $EscapedPath -Recurse -Debug:$EnableDebug -Verbose:$EnableVerbose);
  Write-Host -Object "Done.";

  [System.IO.FileSystemInfo]$DestinationPath = (ConvertTo-Escaped (Resolve-Path -Path $Destination -Debug:$EnableDebug -Verbose:$EnableVerbose) -Debug:$EnableDebug -Verbose:$EnableVerbose);
  [System.IO.FileSystemInfo[]]$DestinationItems = @();
  Write-Host -Object "Querying items of destination path...";
  $DestinationItems = (Get-ChildItem -Path $Destination -Recurse -Debug:$EnableDebug -Verbose:$EnableVerbose);
  Write-Host -Object "Done.";
}
Process {
  Function Get-RelativeForDestination {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $True,
                 ParameterSetName = "Path")]
      [System.IO.FileSystemInfo]
      $Path,
      [Parameter(Mandatory = $True,
                 ParameterSetName = "Path")]
      [Parameter(Mandatory = $True,
                 ParameterSetName = "LiteralPath")]
      [System.IO.FileSystemInfo]
      $ParentPath,
      [Parameter(Mandatory = $True,
                 ParameterSetName = "Path")]
      [Parameter(Mandatory = $True,
                 ParameterSetName = "LiteralPath")]
      [System.IO.FileSystemInfo]
      $Destination
    )

    Begin {
      [System.String]$Output = "undefined";
      [System.String]$BasePathFromSource = "";
      [System.String[]]$PathSplit = ($Path.FullName -split $ParentPath.FullName);
      $BasePathFromSource = $PathSplit[$PathSplit.Count - 1];
    }
    Process {
      $Output = (Join-Path -Path $Destination.FullName -ChildPath $BasePathFromSource);
    }
    End {
      If ($EnableDebug) {
        Write-Host -Object "Get-RelativeForDestination(`"$($Path)`", `"$($ParentPath)`", `"$($Destination)`") => `"$Output`"" | Out-Host;
      }
      Write-Output -InputObject $Output;
    }
  }

  ForEach ($SourceItem in $SourceItems) {
    [System.String]$PotentialDestinationPath = (Get-RelativeForDestination -Path $SourceItem -ParentPath $Path -Destination $DestinationPath);
    If (Test-Path -Path $SourceItem.FullName -PathType Container -Verbose:$EnableVerbose -Debug:$EnableDebug) {
      If (Test-Path -Path $PotentialDestinationPath -PathType Container -Verbose:$EnableVerbose -Debug:$EnableDebug) {
        If ($EnableVerbose -or $EnableDebug) {
          Write-Verbose -Verbose -Message "Passing over container at '$($SourceItem.FullName)'"
        }
      } Else {
        If (Test-Path -Path $PotentialDestinationPath -PathType Leaf -Verbose:$EnableVerbose -Debug:$EnableDebug) {
          Write-Warning -Message "Path at '$PotentialDestinationPath' does not match type of '$($SourceItem.FullName)' (Expected Container got Leaf).";
        } Else {
          Move-Item -Path $SourceItem -Destination $PotentialDestinationPath -Force:$Force -Verbose:$EnableVerbose -Debug:$EnableDebug;
        }
      }
    } ElseIf (Test-Path -Path $SourceItem.FullName -PathType Leaf -Verbose:$EnableVerbose -Debug:$EnableDebug) {
      If (Test-Path -Path $PotentialDestinationPath -PathType Leaf -Verbose:$EnableVerbose -Debug:$EnableDebug) {
        Move-Item -Path $SourceItem -Destination $PotentialDestinationPath -Force:$Force -Verbose:$EnableVerbose -Debug:$EnableDebug;
      } Else {
        If (Test-Path -Path $PotentialDestinationPath -PathType Container -Verbose:$EnableVerbose -Debug:$EnableDebug) {
          Write-Warning -Message "Path at '$PotentialDestinationPath' does not match type of '$($SourceItem.FullName)' (Expected Leaf got Container).";
        } Else {
          Move-Item -Path $SourceItem -Destination $PotentialDestinationPath -Verbose:$EnableVerbose -Debug:$EnableDebug;
        }
      }
    }
  }
}
End {
  Write-Host -Object "Cleaning up...";
  $AfterSourceItems = (Get-ChildItem -Path $EscapedPath -Recurse -Verbose:$EnableVerbose -Debug:$EnableDebug);
  If ($AfterSourceItems.Length -gt 0) {
    Remove-Item -Recurse -Force -Path $EscapedPath -Verbose:$EnableVerbose -Debug:$EnableDebug;
  }
  Write-Host -Object "Done...";
}