[CmdletBinding(DefaultParameterSetName = "LiteralPath")]
Param(
  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $False,
             Position = 0,
             ParameterSetName = "LiteralPath",
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath","LiteralPath")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path = $Null
)

DynamicParam {
  Function Get-AllDirectories {
    [CmdletBinding(DefaultParameterSetName = "LiteralPath")]
    Param(
      # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
      # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
      # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
      # characters as escape sequences.
      [Parameter(Mandatory = $True,
                Position = 0,
                ParameterSetName = "LiteralPath",
                ValueFromPipelineByPropertyName = $True,
                HelpMessage = "Path to one or more locations.")]
      [Alias("PSPath","LiteralPath")]
      [ValidateNotNullOrEmpty()]
      [System.String]
      $Path
    )

    Begin {
      $Output = @();
    }
    Process {
      # Check if there are loose files in the root directory.
      $LooseFiles = (Get-ChildItem -LiteralPath $Path -File);
      If (($Null -ne $LooseFiles -and $LooseFiles.Length -gt 0) -or ($LooseFiles.Length -eq 1 -and -not $LooseFiles[0].Name -eq ".tmp_exclusion.lst")) {
        $Output += (Get-Item -LiteralPath $Path).BaseName
      }
      $Directories = (Get-ChildItem -LiteralPath $Path -Directory -Recurse);
      ForEach ($Directory in $Directories) {
        $ChildDirectories = (Get-ChildItem -LiteralPath $Directory.Fullname -Directory);
        If ($Null -eq $ChildDirectories -or $ChildDirectories.Length -eq 0) {
          $RelativePath = (Resolve-Path -LiteralPath $Directory.FullName -Relative -RelativeBasePath $Path);
          $RelativePath = ($RelativePath -replace "^\.\\", "")
          $RelativePath = ($RelativePath -replace "\\", ".")
          Write-Host -Object "RelativePath = `"$($RelativePath)`"" | Out-Host;
          $Output += $RelativePath
        }
      }
    }
    End {
      Return $Output;
    }
  }

  If ($Null -eq $Path) {
    $Path = (Get-Item -LiteralPath $PWD).FullName
  }
  $AllDirectories = (Get-AllDirectories -Path $Path);
  $ZippedDirectory = (Join-Path -Path $Path -ChildPath "Zipped");
}
Begin {
  If (-not (Test-Path -LiteralPath $ZippedDirectory -PathType Container)) {
    New-Item -Path $ZippedDirectory -ItemType Directory;
  }
  $7zip = (Get-Command -Name "7z" -ErrorAction SilentlyContinue);
  If ($Null -eq $7zip) {
    Throw "Unable to find command ``7z' on the path."
  }
}
Process {
  Function Get-AllDirectoriesInverse {
    [CmdletBinding(DefaultParameterSetName = "LiteralPath")]
    Param(
      # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
      # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
      # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
      # characters as escape sequences.
      [Parameter(Mandatory = $True,
                Position = 0,
                ParameterSetName = "LiteralPath",
                ValueFromPipelineByPropertyName = $True,
                HelpMessage = "Path to one or more locations.")]
      [Alias("PSPath","LiteralPath")]
      [ValidateNotNullOrEmpty()]
      [System.String]
      $Path
    )

    Begin {
      $Output = @();
    }
    Process {
      # Check if there are loose files in the root directory.
      $LooseFiles = (Get-ChildItem -LiteralPath $Path -File);
      If ($Null -ne $LooseFiles -and $LooseFiles.Length -gt 0) {
        $Output += (Get-Item -LiteralPath $Path).BaseName
      }
      $Directories = (Get-ChildItem -LiteralPath $Path -Directory -Recurse);
      ForEach ($Directory in $Directories) {
        $ChildDirectories = (Get-ChildItem -LiteralPath $Directory.Fullname -Directory);
        If ($Null -eq $ChildDirectories -or $ChildDirectories.Length -eq 0) {
          $RelativePath = (Resolve-Path -LiteralPath $Directory.FullName -Relative -RelativeBasePath $Path);
          $RelativePath = ($RelativePath -replace "^\.\\", "")
          $RelativePath = ($RelativePath -replace "\\", ".")
          Write-Host -Object "RelativePath = `"$($RelativePath)`"" | Out-Host;
          $Output += $RelativePath
        }
      }
    }
    End {
      Return $Output;
    }
  }

  ForEach ($Item in $AllDirectories) {
    $ZipFile = (Join-Path -Path $ZippedDirectory -ChildPath "$($Item).7z");
    If (Test-Path -LiteralPath $ZipFile -PathType Leaf) {
      Remove-Item -LiteralPath $ZipFile;
    }
    $ItemPath = (Get-Item -LiteralPath "$($Path)/$($Item -Replace "\.", "/")");
    $ExclusionList = (Join-Path -Path $Path -ChildPath ".tmp_exclusion.lst");
    $ExcludeOnTheWay = (Get-AllDirectoriesInverse -Path $ItemPath);
    If (Test-Path -LiteralPath $ExclusionList -PathType Leaf) {
      Remove-Item -LiteralPath $ExclusionList;
    }
    ($ExcludeOnTheWay -join "`r`n") | Out-File -FilePath $ExclusionList;
    Write-Host -Object "ItemPath = `"$($ItemPath)`"" | Out-Host;
    $ArgumentList = @(
      "a",
      "-t7z",
      "-m0=lzma2",
      "-mx=9",
      "-aoa",
      "-mfb=64",
      "-md=32m",
      "-ms=on",
      "-mhe",
      "-r",
      "-sse",
      "-ssp",
      "-w`"$($Path)`"",
      "-x@.tmp_exclusion.lst"
      "$($Item).7z",
      "$($ItemPath)"
    );
    Start-Process -FilePath $7zip.Source -Wait -NoNewWindow -WorkingDirectory $Path -ArgumentList $ArgumentList;
  }
}
End {
}
