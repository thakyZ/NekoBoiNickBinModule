using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsDiagnostic.Repair, "EpicGamesGame")]
public class RepairEpicGamesGameCommand : Cmdlet {
}
/*
Param(
  # Specifies a path to one or more locations where Epic Games' games are installed. Wildcards are permitted.
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations where Epic Games' games are installed. Wildcards are permitted.")]
  [ValidateNotNullOrEmpty()]
  [SupportsWildcards()]
  [string[]]
  $InstallPath,
  # Specifies a path to one location where the Epic Games launcher is installed.
  [Parameter(Mandatory = $False,
             Position = 1,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Path to one one location where the Epic Games launcher is installed.")]
  [Alias("Path", "PSPath")]
  [ValidateNotNullOrEmpty()]
  [string]
  $EpicGamesPath = $Null
)

Function Wait-UserTask() {
  Param(
    # Specifies a task for the user to do.
    [Parameter(Mandatory = $True,
      Position = 0,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage="A task for the user to do.")]
    [string]
    $Task,
    # Specifies a test script block to check if user completed the task.
    [Parameter(Mandatory = $False,
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    ValueFromRemainingArguments = $True,
    HelpMessage="A test script block to check if user completed the task.")]
    [string]
    $TestIfCompleted = $Null
  )

  $local:FinishedSimple = $Null;

  If ($Null -eq $TestIfCompleted -or $TestIfCompleted -eq "") {
    $local:FinishedSimple = $False;
    $TestIfCompleted = "Return `$local:FinishedSimple;";
  }

  # Invoke-Expression -Command $TestIfCompleted;
  $Test = (Invoke-Expression -Command $TestIfCompleted);

  # Write-Host -Object "`$TestIfCompleted = `"$TestIfCompleted`"";

  # Write-Host -Object "`$Test = `"$Test`"";

  While ($Test -eq $False) {
    Write-Host -NoNewline -ForegroundColor DarkGray -Object "["
    Write-Host -NoNewline -ForegroundColor Green -Object "TASK"
    Write-Host -NoNewline -ForegroundColor DarkGray -Object "] "
    Write-Host            -ForegroundColor White -Object "$Task"
    Write-Host -NoNewline -ForegroundColor DarkGray -Object "["
    Write-Host -NoNewline -ForegroundColor Yellow -Object "READ"
    Write-Host -NoNewline -ForegroundColor DarkGray -Object "] "
    Write-Host -NoNewline -ForegroundColor White -Object "Press any key when done..."
    $Returned = (Read-Host -MaskInput);

    $Test = (Invoke-Expression -Command $TestIfCompleted);
    # Write-Host -Object "`$Test = `"$Test`"";
    # Write-Host -Object "`$Returned = `"$Returned`"";
    If ($Null -ne $Returned) {
      If ($Null -ne $local:FinishedSimple -and $vFinishedSimple -ne "") {
        # Write-Host -Object "<local:FinishedSimple>";
        # Write-Host -Object "  `$Test = `"$Test`"";
        $local:FinishedSimple = $True;
        $Test = (Invoke-Expression -Command $TestIfCompleted);
        # Write-Host -Object "  `$Test = `"$Test`"";
        # Write-Host -Object "</local:FinishedSimple>";
        Return;
      } ElseIf ($Test -eq $False) {
        # Write-Host -Object "<TestIfCompleted>";
        # Write-Host -Object "  `$Test = `"$Test`"";
        $CurrentLine = $Host.UI.RawUI.CursorPosition.Y;
        # Write-Host -Object "  `$CurrentLine = `"$CurrentLine`"";
        $ConsoleWidth = $Host.UI.RawUI.BufferSize.Width;
        # Write-Host -Object "  `$ConsoleWidth = `"$ConsoleWidth`"";
        [Console]::SetCursorPosition(0, ($CurrentLine - 2))
        # Write-Host -Object "</TestIfCompleted>";
      } ElseIf ($Test -eq $True) {
        Return;
      }
    }
  }

  Throw "Hah gay! (You failed to input anything...)";
}

Function Write-ConsoleOutput() {
  Param(
    # Specifies a task for the user to do.
    [Parameter(Mandatory = $True,
      Position = 0,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage="A task for the user to do.")]
    [string]
    $Message
  )

  Write-Host -NoNewline -ForegroundColor DarkGray -Object "["
  Write-Host -NoNewline -ForegroundColor Blue -Object "INFO"
  Write-Host -NoNewline -ForegroundColor DarkGray -Object "] "
  Write-Host            -ForegroundColor White -Object "$Message"
}

If ($EpicGamesPath -eq "" -or $Null -eq $EpicGamesPath) {
  $EpicGamesPath = (Get-Item -LiteralPath (Join-Path -Path "C:\Program Files (x86)" -ChildPath "Epic Games" -AdditionalChildPath @("Launcher", "Portal", "Binaries", "Win32", "EpicGamesLauncher.exe")));
  $script:EpicGamesWorkingDir = (Get-item -LiteralPath (Join-Path -Path "C:\Program Files (x86)" -ChildPath "Epic Games"));
}

$InstalledGames = (Get-Item -Path $InstallPath);

If ($InstallPath -Match "\*$") {
  $InstalledGames = (Get-ChildItem -Path $InstallPath);
}

ForEach ($GameFolder in $InstalledGames) {
  If (Test-Path -LiteralPath $GameFolder -PathType Leaf) {
    Write-Error -Message "Game Folder at $($GameFolder.FullName) is a file and not a folder. Skipping...";
    Continue;
  }

  If ($Null -ne (Get-Process -Name "EpicGamesLauncher" -ErrorAction SilentlyContinue)) {
    Wait-UserTask -Task "Please close the Epic Games Launcher" -TestIfCompleted "Return `$Null -eq (Get-Process -Name `"EpicGamesLauncher`" -ErrorAction SilentlyContinue);";
  }

  Write-ConsoleOutput -Message "Renaming `"$($GameFolder.Name)`" to `"$($GameFolder.BaseName).bak`"";
  Try {
    Rename-Item -Path $GameFolder -NewName "$($GameFolder.BaseName).bak";
    # Write-ConsoleOutput "Rename-Item -Path $GameFolder -NewName `"$($GameFolder.BaseName).bak`";"
  } Catch {
    Write-Error -Message "Failed to rename the installed game folder at $($GameFolder.FullName)";
    Write-Error -Message $_.Exception.Message -Exception $_.Exception;
    Exit 1;
  }

  Write-ConsoleOutput -Message "Launching the Epic Games Launcher...";
  Try {
    Start-Process -FilePath $EpicGamesPath -WorkingDirectory $script:EpicGamesWorkingDir;
    # Write-ConsoleOutput "Start-Process -FilePath $EpicGamesPath -WorkingDirectory $script:EpicGamesWorkingDir;"
  } Catch {
    Write-Error -Message "Failed to run the Epic Games Launcher.";
    Write-Error -Message $_.Exception.Message -Exception $_.Exception;
    Exit 1;
  }

  Wait-UserTask -Task "Please begin to install the game `"$($GameFolder.Name)`"`n       Then pause after it begins downloading and then close the Epic Games Launcher.";
  If ($Null -ne (Get-Process -Name "EpicGamesLauncher" -ErrorAction SilentlyContinue)) {
    Wait-UserTask -Task "Please close the Epic Games Launcher" -TestIfCompleted "Return `$Null -eq (Get-Process -Name `"EpicGamesLauncher`" -ErrorAction SilentlyContinue);";
  }

  Write-ConsoleOutput -Message "Outputing backup to the new install directory.";
  Try {
    $VisibleFiles = Get-ChildItem -Path (Join-Path -Path $GameFolder.Parent.FullName -ChildPath "$($GameFolder.BaseName).bak");
    $HiddenFiles = Get-ChildItem -Path (Join-Path -Path $GameFolder.Parent.FullName -ChildPath "$($GameFolder.BaseName).bak") -Hidden;

    ForEach ($VisibleFile in $VisibleFiles) {
      Copy-item -Recurse -Path $VisibleFile -Destination (Join-Path -Path $GameFolder.FullName -ChildPath $VisibleFile.Name) -Force;
      # Write-ConsoleOutput "Copy-item -Recurse -Path $VisibleFile -Destination `"$($GameFolder.FullName)$($VisibleFile.Name)`" -Force;"
    }
    ForEach ($HiddenFile in $HiddenFiles) {
      Copy-item -Recurse -Path $HiddenFile -Destination (Join-Path -Path $GameFolder.FullName -ChildPath $HiddenFile.Name) -Force;
      # Write-ConsoleOutput "Copy-item -Recurse -Path $HiddenFile -Destination `"$($GameFolder.FullName)$($HiddenFile.Name)`" -Force;"
    }
  } Catch {
    Write-Error -Message "Failed to copy items from backup to new folder.";
    Write-Error -Message $_.Exception.Message -Exception $_.Exception;
    Exit 1;
  }

  Write-ConsoleOutput -Message "Launching the Epic Games Launcher. Please finish the download of the new install.";
  Try {
    Start-Process -FilePath $EpicGamesPath -WorkingDirectory $script:EpicGamesWorkingDir;
    # Write-ConsoleOutput "Start-Process -FilePath $EpicGamesPath -WorkingDirectory $script:EpicGamesWorkingDir;"
  } Catch {
    Write-Error -Message "Failed to run the Epic Games Launcher.";
    Write-Error -Message $_.Exception.Message -Exception $_.Exception;
    Exit 1;
  }

  Wait-UserTask -Task "Done? Continue?";

  Write-ConsoleOutput -Message "Cleaning Up...";
  Try {
    Remove-Item -Path (Get-Item -LiteralPath (Join-Path -Path $GameFolder.Parent.FullName -ChildPath "$($GameFolder.BaseName).bak")) -Recurse -Force;
    # Write-ConsoleOutput "Remove-Item -Path `"$((Get-Item -LiteralPath (Join-Path -Path $GameFolder.Parent.FullName -ChildPath "$($GameFolder.BaseName).bak")))`" -Recurse -Force;"
  } Catch {
    Write-Error -Message "Failed to remvoe backup direcory";
    Write-Error -Message $_.Exception.Message -Exception $_.Exception;
    Exit 1;
  }
}
*/
