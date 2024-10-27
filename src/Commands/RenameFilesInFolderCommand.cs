using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Rename, "FilesInFolder")]
public class RenameFilesInFolderCommand : Cmdlet {
}
/*
#function Rename-FilesInFolder {
[CmdletBinding(DefaultParameterSetName = "Path")]
param(
  # Path of folder to rename files of
  [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path", HelpMessage = "Enter one or more filenames")]
  [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "PathAll")]
  [string[]]
  $Path,
  # Path of folder to rename files of
  [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "LiteralPathAll")]
  [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "LiteralPath", HelpMessage = "Enter a single filename", ValueFromPipeline = $true)]
  [string]
  $LiteralPath,
  # Enable Extension renaming
  [Parameter(Mandatory = $false, HelpMessage = "Enable Extension renaming", ParameterSetName = "Extension")]
  [Parameter(Mandatory = $false, HelpMessage = "Enable Extension renaming", ParameterSetName = "Path")]
  [Parameter(Mandatory = $false, HelpMessage = "Enable Extension renaming", ParameterSetName = "LiteralPath")]
  [switch]
  $Extension,
  # Enable Name renaming
  [Parameter(Mandatory = $false, HelpMessage = "Enable Name renaming", ParameterSetName = "Name")]
  [Parameter(Mandatory = $false, HelpMessage = "Enable Name renaming", ParameterSetName = "Path")]
  [Parameter(Mandatory = $false, HelpMessage = "Enable Name renaming", ParameterSetName = "LiteralPath")]
  [switch]
  $Name,
  # Enable Name and Extension renaming
  [Parameter(Mandatory = $false, HelpMessage = "Enable Name and Extension renaming", ParameterSetName = "NameAndExtension")]
  [Parameter(Mandatory = $false, HelpMessage = "Enable Name and Extension renaming", ParameterSetName = "Path")]
  [Parameter(Mandatory = $false, HelpMessage = "Enable Name and Extension renaming", ParameterSetName = "LiteralPath")]
  [switch]
  $NameExtension,
  # The string to replace, the string to replace with
  [Parameter(Mandatory = $false, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "Extension")]
  [Parameter(Mandatory = $false, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "Name")]
  [Parameter(Mandatory = $false, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "NameAndExtension")]
  [Parameter(Mandatory = $false, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "Path")]
  [Parameter(Mandatory = $false, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "LiteralPath")]
  [string[]]
  $Replace,
  # Recurse the path provided
  [Parameter(Mandatory = $false, HelpMessage = "Recurse the path provided", ParameterSetName = "Path")]
  [Parameter(Mandatory = $false, HelpMessage = "Recurse the path provided", ParameterSetName = "PathAll")]
  [switch]
  $Recurse
)

Begin {
  If ($Name) {
    If ($Path) {
      $Files = Get-ChildItem -Path $Path -Recurse:$Recurse -Filter "$($Replace[0]).*" -File;
    }
    Else {
      $Files = Get-ChildItem -LiteralPath $LiteralPath -Filter -Filter "$($Replace[0]).*" -File;
    }
  }
  Elseif ($Extension) {
    If ($Path) {
      $Files = Get-ChildItem -Path $Path -Recurse:$Recurse -Filter "*.$($Replace[0])" -File;
    }
    Else {
      $Files = Get-ChildItem -LiteralPath $LiteralPath -Filter "*.$($Replace[0])" -File;
    }
  }
  Elseif ($NameExtension) {
    If ($Path) {
      $Files = Get-ChildItem -Path $Path -Recurse:$Recurse -Filter "$($Replace[0])" -File;
    }
    Else {
      $Files = Get-ChildItem -LiteralPath $LiteralPath -Filter "$($Replace[0])" -File;
    }
  }
  If ($Replace.Length -ne 2) {
    Write-Error -Message "Replace variable should be the string you want to replace comma sepreated by the string you want to replace it with."
  }
}
Process {
  Function Test-PathExists() {
    Param(
      [string]
      $Directory,
      [String]
      $Path
    )
    $Val = $Path
    $RegEx = "(\s\((\d\)))"
    If (Test-Path -Path $Path) {
      $NewNum = 1;
      If ($Path -match $RegEx) {
        $NewNum = parseInt(($Path -replace $RegEx, "$2")) + 1;
      }
      $Val = Test-PathExists -Path "$($Directory)\$($Val.Split(".")[0] -replace $RegEx, '') ($($NewNum)).$($Val.Split(".")[1])"
    }
    Return $Val
  }

  ForEach ($File in $Files) {
    If ($Name) {
      Writ-Host (Test-PathExists -Path "$($File.Directory.FullName)\$($Replace[1]).$($File.Extension)")
      Rename-Item -LiteralPath $File.FullName -NewName (Test-PathExists -Directory "$($File.Directory.FullName)" -Path "$($Replace[1]).$($File.Extension)")
    }
    Elseif ($Extension) {
      Rename-Item -LiteralPath $File.FullName -NewName (Test-PathExists -Directory "$($File.Directory.FullName)" -Path "$($File.BaseName).$($Replace[1])")
    }
    Elseif ($NameExtension) {
      Rename-Item -LiteralPath $File.FullName -NewName (Test-PathExists -Directory "$($File.Directory.FullName)" -Path "$($Replace[1])")
    }
  }
}
#}

#Export-ModuleMember -Function Rename-FilesInFolder
*/
