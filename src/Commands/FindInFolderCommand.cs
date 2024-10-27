using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Find, "InFolder")]
public class FindInFolderCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = 'Path')]
param(
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $False,
    Position = 0,
    ParameterSetName = "Path",
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Path to one or more locations. Defaults to the current working directory.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $Path = @($PWD),
  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $False,
    Position = 0,
    ParameterSetName = "LiteralPath",
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Literal path to one or more locations. Defaults to the current working directory.")]
  [Alias("PSLiteralPath")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $LiteralPath = @($PWD),
  # Specifies a path to one or more locations. Wildcards are permitted.
  [Parameter(Mandatory = $False,
    Position = 0,
    ParameterSetName = "PathWildcard",
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Path to one or more locations. Defaults to the current working directory.")]
  [ValidateNotNullOrEmpty()]
  [SupportsWildcards()]
  [string[]]
  $PathWildcard = @($PWD),
  # Regex supported values to search for files in the path.
  [Parameter(Mandatory = $True,
    Position = 1,
    ParameterSetName = "Path",
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Regex supported values to search for files in the path.")]
  [Parameter(Mandatory = $True,
    Position = 1,
    ParameterSetName = "LiteralPath",
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Regex supported values to search for files in the path.")]
  [Parameter(Mandatory = $True,
    Position = 1,
    ParameterSetName = "PathWildcard",
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Regex supported values to search for files in the path.")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $Value,
  # Gets the items in the specified locations and in all child items of the locations.
  [Parameter(Mandatory = $False,
    Position = 2,
    ParameterSetName = "Path",
    HelpMessage = "Gets the items in the specified locations and in all child items of the locations.")]
  [Parameter(Mandatory = $False,
    Position = 2,
    ParameterSetName = "LiteralPath",
    HelpMessage = "Gets the items in the specified locations and in all child items of the locations.")]
  [Parameter(Mandatory = $False,
    Position = 2,
    ParameterSetName = "PathWildcard",
    HelpMessage = "Gets the items in the specified locations and in all child items of the locations.")]
  [switch]
  $Recurse
)

Begin {
  [hashtable]$InputPaths = [ordered]@{};

  If ($PsCmdlet.ParameterSetName -eq "Path") {
    ForEach ($_Path in $Path) {
      If (Test-Path -Path $_Path -PathType Leaf) {
        Write-Warning -Message "$($_Path) is a file not a directory.";
      }
      ElseIf (Test-Path -Path $_Path -PathType Container) {
        $InputPaths[$_Path] += $False;
      }
      Else {
        Write-Warning -Message "$($_Path) does not exist on the file system.";
      }
    }
  }
  ElseIf ($PsCmdlet.ParameterSetName -eq "LiteralPath") {
    ForEach ($_Path in $LiteralPath) {
      If (Test-Path -LiteralPath $_Path -PathType Leaf) {
        Write-Warning -Message "$($_Path) is a file not a directory.";
      }
      ElseIf (Test-Path -LiteralPath $_Path -PathType Container) {
        $InputPaths[$_Path] += $True;
      }
      Else {
        Write-Warning -Message "$($_Path) does not exist on the file system.";
      }
    }
  }
  ElseIf ($PsCmdlet.ParameterSetName -eq "PathWildcard") {
    ForEach ($_Path in $PathWildcard) {
      $_PathParent = (Split-Path -Path $_Path);
      If (Test-Path -Path $_PathParent -PathType Leaf) {
        Write-Warning -Message "$($__Path) is a file not a directory.";
      }
      ElseIf (Test-Path -Path $_PathParent -PathType Container) {
        $_PathFiles = (Split-Path -Path $_Path -Leaf)
        If ((Get-ChildItem -Path $_PathParent -Filter "$($_PathFiles)").Length -gt 0) {
          $InputPaths[$_PathParent] = $_PathFiles;
        }
        Else {
          Write-Warning -Message "Files matching pattern, $($_PathFiles), does not exist in the directory, $($_PathParent)";
        }
      }
      Else {
        Write-Warning -Message "$($_PathParent) does not exist on the file system.";
      }
    }
  }
}
Process {
  $OutputObjects = @();
  If ($Recurse) {
    ForEach ($Key in $InputPaths.Keys) {
      If ($InputPaths[$Key] -eq $True) {
        ForEach ($Item in (Get-ChildItem -LiteralPath $Key -Recurse | Where-Object { $_.Name -match $Value })) {
          $OutputObjects += [PSCustomObject]@{Name = "$($Item.BaseName)"; Path = $($Item.FullName); Item = [PSObject]$Item };
        }
      }
      ElseIf ($InputPaths[$Key] -eq $False) {
        ForEach ($Item in (Get-ChildItem -Path $Key -Recurse | Where-Object { $_.Name -match $Value })) {
          $OutputObjects += [PSCustomObject]@{Name = "$($Item.BaseName)"; Path = $($Item.FullName); Item = [PSObject]$Item };
        }
      }
      Else {
        ForEach ($Item in (Get-ChildItem -Path $Key -Recurse -Filter "$($InputPaths[$Key])" | Where-Object { $_.Name -match $Value })) {
          $OutputObjects += [PSCustomObject]@{Name = "$($Item.BaseName)"; Path = $($Item.FullName); Item = [PSObject]$Item };
        }
      }
    }
  }
  Else {
    ForEach ($Key in $InputPaths.Keys) {
      If ($InputPaths[$Key] -eq $True) {
        ForEach ($Item in (Get-ChildItem -LiteralPath $Key | Where-Object { $_.Name -match $Value })) {
          $OutputObjects += [PSCustomObject]@{Name = "$($Item.BaseName)"; Path = $($Item.FullName); Item = [PSObject]$Item };
        }
      }
      ElseIf ($InputPaths[$Key] -eq $False) {
        ForEach ($Item in (Get-ChildItem -Path $Key | Where-Object { $_.Name -match $Value })) {
          $OutputObjects += [PSCustomObject]@{Name = "$($Item.BaseName)"; Path = $($Item.FullName); Item = [PSObject]$Item };
        }
      }
      Else {
        ForEach ($Item in (Get-ChildItem -Path $Key -Filter "$($InputPaths[$Key])" | Where-Object { $_.Name -match $Value })) {
          $OutputObjects += [PSCustomObject]@{Name = "$($Item.BaseName)"; Path = $($Item.FullName); Item = [PSObject]$Item };
        }
      }
    }
  }
}
End {
  $OutputObjects | Format-Table -AutoSize
}
*/
