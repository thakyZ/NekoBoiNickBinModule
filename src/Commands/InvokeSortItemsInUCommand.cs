using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Invoke, "SortItemsInU")]
public class InvokeSortItemsInUCommand : Cmdlet {
}
/*
[CmdletBinding()]
Param(
  # Specifies a switch to use the new console method when running the script.
  [Parameter(Mandatory = $False,
             HelpMessage = "A switch to use the new console method when running the script.")]
  [Switch]
  $NewConsoleMethod = $False,
  # Specifies a switch to not dry run the script.
  [Parameter(Mandatory = $False,
             HelpMessage = "A switch to not dry run the script.")]
  [Switch]
  $NoDryRun = $False,
  # Specifies a switch to use the old script method.
  [Parameter(Mandatory = $False,
             HelpMessage = "A switch to use the old script method.")]
  [Switch]
  $Old = $False
)

Begin {
  $script:OldConsoleMethod = (-not $NewConsoleMethod);
  $script:DryRun = (-not $NoDryRun);
  $script:Debug = $PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $True;
  $script:Old = $Old;
}
Process {
  If ($script:Old -eq $False) {
    [System.String]$CodePath = (Join-Path -Path $PSScriptRoot -ChildPath "Sort_ItemsInU.cs");
    [System.String]$Code = (Get-Content -Encoding UTF8BOM -Path $CodePath -Raw);
    [System.Management.Automation.Job]$Job = Start-Job -ScriptBlock {
      Try {
        Add-Type -AssemblyName "System.Management.Automation";
      } Catch {
        Write-Error -Message "$($_.Exception.Message) Ref 0" | Out-Host;
        Throw;
      }
      [System.String]$Code = $Args[0];
      $Cmdlet = $Args[1];
      [System.Boolean]$Debug = $Args[2];
      [System.Boolean]$DryRun = $Args[3];
      [System.Boolean]$OldConsoleMethod = $Args[4];
      Try {
        Add-Type -Language CSharp -TypeDefinition $Code;
      } Catch {
        Write-Error -Message "$($_.Exception.Message) Ref 1" | Out-Host;
        Throw;
      }
      [System.Object[]]$Output;
      Try {
        $Output = [NekoBoiNick.CSharp.PowerShell.Cmdlets.SortItemsInU]::RunWrapperStatic($Cmdlet, $Debug, $DryRun, $OldConsoleMethod);
      } Catch {
        Write-Error -Message "$($_.Exception.Message) Ref 2`n$($_.Exception.StackTrace)" | Out-Host;
        Throw;
      }
      Write-Output -InputObject $Output;
    } -ArgumentList @($Code, $PSCmdlet, $script:Debug, $script:DryRun, $script:OldConsoleMethod);
    [System.Management.Automation.Job]$State = (Get-Job -InstanceId $Job.InstanceId);
    While ($State.State -eq "Running") {
      Start-Sleep -Seconds 5;
      $State = (Get-Job -InstanceId $Job.InstanceId);
    }
    [System.Object[]]$Received = (Receive-Job -InstanceId $Job.InstanceId);
    If ($State.State -eq "Completed") {
      If ($Null -ne $Received) {
        Write-Output -InputObject $Received | Out-Host;
      }
    } ElseIf ($State.State -eq "Failed") {
      If ($Null -ne $Received) {
        Write-Output -InputObject $Received | Out-Host;
      }
      Throw "Job failed with output.";
    } Else {
      If ($Null -ne $Received) {
        Write-Output -InputObject $Received | Out-Host;
      }
      Write-Warning -Message "Job ended with unexpected state: $($State.State)."
    }
    Remove-Job -Id $Job.Id
  } Else {
    $ProcessingDir = (Join-Path -Path $HOME -ChildPath "Downloads" -AdditionalChildPath @("u"));
    $Folders = (Get-ChildItem -Path $ProcessingDir -Directory)
    $Items = (Get-ChildItem -Path $ProcessingDir -File | Where-Object {$_.BaseName -match "^[^-]+-"} | Select-Object -Property @(
                @{Name="FullName";Expression={$_.FullName}},
                @{Name="Name";Expression={$_.Name}},
                @{Name="BaseName";Expression={$_.BaseName}},
                @{Name="PotentialArtistName";Expression={$Test=$_.BaseName.Split("-")[0];If($Test -ne $_.BaseName -and $Test -notmatch "[\(\)\[\]\{\} \-_\/\\]" -and $_.Extension -ne ".zip"){Return $Test;}Return $Null;}},
                @{Name="PotentialArtistNameOther";Expression = {$Test=$_.BaseName.Split("_")[0];If($Test -ne $_.BaseName -and $Test -notmatch "[\(\)\[\]\{\} \-_\/\\]" -and $_.Extension -ne ".zip"){Return $Test;};Return $Null;}}
            ));
    $ConsolePosition = @{ X = 0; Y = 0; };
    $ConsolePositionInter1 = @{ X = 0; Y = 0; };
    $ConsolePositionInter2 = @{ X = 0; Y = 0; };
    $ConsolePosition = Get-ConsolePosition
    ForEach ($Item in $Items) {
      Set-ConsolePosition $ConsolePosition;
      $HasCurrentDirectory = @($False, $Null);
      $DisableOption2 = $False;
      If ($Folders.Name -contains $Item.PotentialArtistName -and ([System.String]::IsNullOrEmpty($Item.PotentialArtistName) -or [System.String]::IsNullOrWhiteSpace($Item.PotentialArtistName))) {
        $HasCurrentDirectory = @($True, $Item.PotentialArtistName);
      } ElseIf ($Folders.Name -contains $Item.PotentialArtistNameOther -and ([System.String]::IsNullOrEmpty($Item.PotentialArtistNameOther) -or [System.String]::IsNullOrWhiteSpace($Item.PotentialArtistNameOther))) {
        $HasCurrentDirectory = @($True, $Item.PotentialArtistNameOther);
      } ElseIf (([System.String]::IsNullOrEmpty($Item.PotentialArtistName) -or [System.String]::IsNullOrWhiteSpace($Item.PotentialArtistName)) -and ([System.String]::IsNullOrEmpty($Item.PotentialArtistNameOther) -or [System.String]::IsNullOrWhiteSpace($Item.PotentialArtistNameOther)) -and $Folders.Name -notcontains $Item.PotentialArtistNameOther -and $Folders.Name -notcontains $Item.PotentialArtistName) {
        $DisableOption2 = $True;
      }
      Write-Host -Object "Info:";
      Write-Output -InputObject $Item | Out-Host;
      Write-Host -Object "Choose an option:"
      Write-Host -Object " - 0: Make New Directory";
      Write-Host -Object " - 1: Move into directory $($HasCurrentDirectory[1])";
      Write-Host -Object " - 2: Skip";
      Write-Host -Object " - 3: Other";
      $Choice = $Null;
      $ConsolePositionInter1 = Get-ConsolePosition
      While ($Choice -notmatch "[0-3]" -and ($Choice -ne "2" -and $DisableOption2 -ne $True)) {
        Set-ConsolePosition -Coordinates $ConsolePositionInter1;
        $Choice = (Read-Host -Prompt "[0/1/2/3]");
      }
      If ($Choice -eq "0") {
        $NewDirName = (Read-Host -Prompt "New Folder Name?");
        If (-not (Test-Path -Path (Join-Path -Path $ProcessingDir -ChildPath $NewDirName) -PathType Container)) {
          If ($script:DryRun) {
            Write-Host -Object "Making new directory at $(Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1])" -ForegroundColor Yellow;
          } Else {
            New-Item -ItemType Directory -Path (Join-Path -Path $ProcessingDir -ChildPath $NewDirName);
          }
        }
        $RelativePath = (Resolve-Path -Path (Join-Path -Path $ProcessingDir -ChildPath $NewDirName) -Relative -RelativeBasePath $ProcessingDir -ErrorAction SilentlyContinue);
        $ChoiceInter = $Null;
        $ConsolePositionInter2 = Get-ConsolePosition
        While ($ChoiceInter -notmatch "[yn]") {
          Set-ConsolePosition -Coordinates $ConsolePositionInter2;
          $ChoiceInter = (Read-Host -Prompt "Move item into $($RelativePath)? [y/N]").ToLower();
        }
        If ($ChoiceInter -eq "y") {
          If ($script:DryRun) {
            Write-Host -Object "Moving $($Item.Fullname) to Destination $(Join-Path -Path $ProcessingDir -ChildPath $NewDirName -AdditionalChildPath @($Item.BaseName))" -ForegroundColor Yellow;
          } Else {
            Move-Item -Path $Item.FullName -Destination (Join-Path -Path $ProcessingDir -ChildPath $NewDirName -AdditionalChildPath @($Item.BaseName))
          }
        } ElseIf ($ChoiceInter -eq "n") {
          Write-Host -Object "Skipping...";
        } Else {
          Throw "Failed with unknown choice `"$($ChoiceInter)`"";
        }
        $ChoiceInter = $Null;
      } ElseIf ($Choice -eq "1") {
        If (-not (Test-Path -Path (Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1]) -PathType Container)) {
          If ($script:DryRun) {
            Write-Host -Object "Making new directory at $(Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1])" -ForegroundColor Yellow;
          } Else {
            New-Item -ItemType Directory -Path (Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1]);
          }
        }
        $RelativePath = (Resolve-Path -Path (Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1]) -Relative -RelativeBasePath $ProcessingDir -ErrorAction SilentlyContinue);
        $ChoiceInter = $Null;
        $ConsolePositionInter2 = Get-ConsolePosition
        While ($ChoiceInter -notmatch "[yn]") {
          Set-ConsolePosition -Coordinates $ConsolePositionInter2;
          $ChoiceInter = (Read-Host -Prompt "Move item into $($RelativePath)? [y/N]").ToLower();
        }
        If ($ChoiceInter -eq "y") {
          If ($script:DryRun) {
            Write-Host -Object "Moving $($Item.Fullname) to Destination $(Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1] -AdditionalChildPath @($Item.BaseName))" -ForegroundColor Yellow;
          } Else {
            Move-Item -Path $Item.FullName -Destination (Join-Path -Path $ProcessingDir -ChildPath $HasCurrentDirectory[1] -AdditionalChildPath @($Item.BaseName))
          }
        } ElseIf ($ChoiceInter -eq "n") {
          Write-Host -Object "Skipping...";
        } Else {
          Throw "Failed with unknown choice `"$($ChoiceInter)`"";
        }
        $ChoiceInter = $Null;
      } ElseIf ($Choice -eq "2") {
        Write-Host -Object "Skipping...";
      } ElseIf ($Choice -eq "3") {
        Write-Host -Object "Not Yet Implemented";
      } Else {
        Throw "Failed with unknown choice `"$($Choice)`"";
      }
      $Choice = $Null;
      $EndConsolePosition = Get-ConsolePosition
      Clear-ConsoleInArea -CoordinatesStart $ConsolePosition -CoordinatesEnd $EndConsolePosition;
      Set-ConsolePosition $ConsolePosition;
    }
  }
}
*/
