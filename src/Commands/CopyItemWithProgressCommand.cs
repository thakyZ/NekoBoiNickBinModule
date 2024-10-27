using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Copy, "ItemWithProgress")]
public class CopyItemWithProgressCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "StringPaths")]
Param(
  # Specifies a set of file system paths as an array of [System.String]s to copy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "StringPaths",
             ValueFromPipeline = $True,
             HelpMessage = "A set of file system paths as an array of [System.String]s to copy.")]
  [ValidateNotNullOrEmpty()]
  [System.String[]]
  $Paths,
  # Specifies a set of file system paths as an array of [System.IO.FileSystemInfo]s to copy.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "FileSystemPaths",
             ValueFromPipeline = $True,
             HelpMessage = "A set of file system paths as an array of [System.IO.FileSystemInfo]s to copy.")]
  [ValidateNotNullOrEmpty()]
  [System.IO.FileSystemInfo[]]
  $FilePaths,
  # Specifies a path to specify as the destination of the copied paths.
  [Parameter(Mandatory = $True,
             Position = 1,
             ParameterSetName = "StringPaths",
             ValueFromPipeline = $True,
             HelpMessage = "A path to specify as the destination of the copied paths")]
  [Parameter(Mandatory = $True,
             Position = 1,
             ParameterSetName = "FileSystemPaths",
             ValueFromPipeline = $True,
             HelpMessage = "A path to specify as the destination of the copied paths")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Destination
)

Begin {
  [System.IO.FileSystemInfo[]]`
  $Items = @();
  If ($PSCmdlet.ParameterSetName -eq "StringPaths") {
    ForEach ($Path in $Paths) {
      $Item = (Get-Item -LiteralPath $Path -ErrorAction Stop);
      If (Test-Path -LiteralPath $Item -PathType Leaf) {
        $Items += @($Item);
      }
    }
  } ElseIf ($PSCmdlet.ParameterSetName -eq "FileSystemPaths") {
    $Items = $FilePaths;
  }
  [System.IO.FileSystemInfo]`
  $_Destination = (Get-Item -LiteralPath $Destination -ErrorAction Stop);
  If (Test-Path -LiteralPath $_Destination -PathType Leaf) {
    Throw "Destination path type is a file not a folder.";
  }
  [System.Int32]`
  $Index = 0;
  [System.Int32]`
  $Progress = 0;
  [System.Int32]`
  $Total = $Items.Length;
}
Process {
  Function Get-Progress {
    [CmdletBinding()]
    [OutputType([System.Int32])]
    Param(
      [Parameter(Mandatory = $True)]
      [ValidateNotNull()]
      [System.Int32]
      $Index,
      [Parameter(Mandatory = $True)]
      [ValidateNotNull()]
      [System.Int32]
      $Total
    )
    Return [System.Math]::Ceiling(($Index / $Total) * 100);
  }
  ForEach ($Item in $Items) {
    Copy-Item -LiteralPath $Item -Destination $_Destination -ErrorAction Stop;
    $Index++;
    $Progress = (Get-Progress -Index $Index -Total $Total);
    Write-Progress -Id 0 -Activity "Copied $($Item.FullName) to $(Join-Path -Path $_Destination.FullName -ChildPath $Item.Name)" -Status "$($Index)/$($Total) $($Progress)% Complete:" -PercentComplete $Progress;
  }
}
End {
  Write-Progress -Id 0 -Complete;
}
*/
