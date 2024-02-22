Param(
  # Specifies a switch to disable plugins recursively.
  [Parameter(Mandatory = $False,
             HelpMessage = "Disable plugins recursively.")]
  [switch]
  $Recurse,
  # Specifies a switch to interactively disable plugins.
  [Parameter(Mandatory = $False,
             HelpMessage = "Interactively disable plugins.")]
  [switch]
  $Interactive,
  # Specifies a switch to automatically confirm to disable all plugins.
  [Parameter(Mandatory = $False,
             HelpMessage = "Automatically confirm to disable all plugins.")]
  [switch]
  $Confirm,
  # Specifies which plugins to exclude from disabling.
  [Parameter(Mandatory = $False,
             HelpMessage = "List of plugins to exclude from disabling.")]
  [System.String[]]
  $Exclude,
  # Specifies a path to Notepad++
  [Parameter(Mandatory = $False,
             HelpMessage="Path to Notepad++ installation directory.")]
  [Alias("PSPath")]
  [string]
  $NppPath = $Null
)

DynamicParam {
  Function Test-NppPath {
    Param(
      # Specifies the path to test.
      [Parameter(Mandatory = $False)]
      [System.String]
      $PathToTest = $Null
    )

    If ($Null -eq $PathToTest) {
      $PathToTest = $NppPath
    }

    If (Test-Path -LiteralPath $PathToTest -PathType Leaf) {
      $TestPath = (Get-Item -LiteralPath $PathToTest).Directory.FullName;
      If (Test-NppPath -PathToTest $TestPath) {
        $NppPath = $TestPath;
        Return $True;
      } Else {
        Return $False;
      }
    } ElseIf (Test-Path -LiteralPath $NppPath -PathType Container) {
      If (Test-Path -LiteralPath (Join-Path -Path $PathToTest -ChildPath "notepad++.exe") -PathType Leaf) {
        Return $True;
      } Else {
        Return $False;
      }
    } Else {
      Return $False;
    }
  }

  If ($Null -eq $NppPath) {
    $Drives = (Get-PSDrive | Where-Object { $_.Provider.Name -eq "FileSystem" -and $_.Name.Length -eq 1 });
    ForEach ($Drive in $Drives) {
      ForEach ($ProgramDirectory in @("Program Files", "Program Files (x86)")) {
        $NppPath = ((Get-ChildItem -LiteralPath (Join-Path -Path $Drive.Root -ChildPath $ProgramDirectory) -Directory) | Where-Object { $_.Name -match "Notepad\+\+" }).FullName;
      }
    }

    If ($Null -eq $NppPath) {
      Throw "Notepad++ install location was not found, please provide a custom location with the -NppPath argument.";
    }
  } Else {
    If (-not (Test-NppPath -PathToTest $NppPath)) {
      Throw "Notepad++ install location was not found, please provide a custom location with the -NppPath argument.";
    }
  }

  [System.String[]]$NotFoundPlugins = @();
  [System.String[]]$ValidPlugins = @();

  If ($Exclude.Count -gt 0) {
    $PluginsDirectory = (Get-ChildItem -LiteralPath (Join-Path -Path $NppPath -ChildPath "plugins") -Directory).Name;
    ForEach ($Item in $Exclude) {
      If ($PluginsDirectory -notcontains $Item) {
        $NotFoundPlugins += $Item;
      } Else {
        $ValidPlugins += $Item;
      }
    }
  }

  Write-Host -ForegroundColor DarkYellow -Object "Could not find the following plugins: " -NoNewline;
  [System.Int32]$Index1 = 0;
  ForEach ($NotFoundPlugin in $NotFoundPlugins) {
    Write-Host -ForegroundColor White -Object "$($NotFoundPlugin)" -NoNewline;
    If ($Index1 -lt $NotFoundPlugins.Length) {
      Write-Host -ForegroundColor DarkYellow -Object "," -NoNewline;
    }
    $Index1++;
  }

  Write-Host -ForegroundColor White -Object "Disabling the following plugins: " -NoNewline;
  [System.Int32]$Index2 = 0;
  ForEach ($ValidPlugin in $ValidPlugins) {
    Write-Host -ForegroundColor Green -Object "$($ValidPlugin)" -NoNewline;
    If ($Index2 -lt $ValidPlugins.Length) {
      Write-Host -ForegroundColor White -Object "," -NoNewline;
    }
    $Index2++;
  }
}