Param(
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $False,
    Position = 0,
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Path to one or more solutions.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [System.IO.DirectoryInfo[]]
  [object[]]
  [string[]]
  $Path = @($PWD)
)

If ($Path.Length -le 0) {
  Throw "Length of argument 'Path' is 0.";
}

$Index = 0;

ForEach ($Item in $Path) {
  If (-not (Test-Path -LiteralPath $Item -PathType Container)) {
    $Path[$Index] = (Get-Item -LiteralPath $Item).Directory.FullName;
  }

  $Index++;
}

ForEach ($Item1 in $Path) {
  [System.IO.DirectoryInfo]$InputPath;

  If ($Item1.GetType().ToString() -eq "string") {
    $InputPath = (Get-Item -LiteralPath $Item1);
  } ElseIf ($Item1.GetType().ToString() -eq "object") {
    Try {
      $InputPath = (Get-Item -LiteralPath $Item1);
    } Catch {
      Write-Warning -Message "Failed to get supplied path with value of `"$($Item1)`"";
      Continue;
    }
  } ElseIf ($Item1.GetType().ToString() -eq "System.IO.DirectoryInfo") {
    $InputPath = $Item1;
  } Else {
    Write-Warning -Message "Failed to get supplied path type with value of `"$($Item1.GetType())`"";
    Continue;
  }

  [System.Collections.Generic.List[System.IO.DirectoryInfo]]$VisibleItems = (Get-ChildItem -LiteralPath $InputPath.FullName -Recurse -Directory | Where-Object { $_.Name -eq "bin" -or $_.Name -eq "obj" -or $_.Name -eq ".vs" });
  [System.Collections.Generic.List[System.IO.DirectoryInfo]]$HiddenItems = (Get-ChildItem -LiteralPath $InputPath.FullName -Hidden -Recurse -Directory | Where-Object { $_.Name -eq "bin" -or $_.Name -eq "obj" -or $_.Name -eq ".vs" });

  If ($Null -eq $VisibleItems) {
    $VisibleItems = (New-Object -TypeName System.Collections.Generic.List[System.IO.DirectoryInfo]);
  }
  If ($Null -eq $HiddenItems) {
    $HiddenItems = (New-Object -TypeName System.Collections.Generic.List[System.IO.DirectoryInfo]);
  }

  [System.Collections.Generic.List[System.IO.DirectoryInfo]]$AllItems = (New-Object -TypeName System.Collections.Generic.List[System.IO.DirectoryInfo]);
  $AllItems.AddRange($VisibleItems);
  $AllItems.AddRange($HiddenItems);

  ForEach ($Item2 in $AllItems) {
    [System.IO.DirectoryInfo]$ParsedPath = $Item2;

    Try {
      Remove-Item -Force -LiteralPath $ParsedPath.FullName -Recurse;
    } Catch {
      Write-Warning -Message "Failed to delete item at `"$(Resolve-Path -Relative $ParsedPath.FullName -RelativeBasePath $InputPath.FullName)`"";
    }
  }
}

