using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Update, "SEToolbox")]
public class UpdateSEToolboxCommand : Cmdlet {
}
/*
[CmdletBinding()]
Param()

. "$(Join-Path -Path (Get-Item -Path $Profile).Directory -ChildPath 'Utils.ps1')";

$script:Config = (Get-Config -Path (Join-Path -Path $PSScriptRoot -ChildPath "config.json"));

[System.String]$Repo = "mmusu3/SEToolbox"

[System.String]$Releases = "https://api.github.com/repos/$($Repo)/releases"

[System.String]$DownloadDest = (Join-Path -Path 'D:' -ChildPath 'Modding' -AdditionalChildPath @('Tools', 'SpaceEngineers', 'SEToolbox'))

If (-not (Test-Path -LiteralPath $DownloadDest -PathType Container)) {
  If (Test-Path -LiteralPath $DownloadDest -PathType Leaf) {
    Throw "Destination path at $($DownloadDest) is a file not a folder."
  }
  $Null = New-Item -Path $DownloadDest -ItemType Directory;
}

[System.String[]]$FoundTokens = ($script:Config.Tokens | Where-Object {
  $Obj1 = $_;
  Return $Null -ne ($Obj1.Addresses | Where-Object {
    $Obj2 = $_;
    Return $Releases -match $Obj2;
  });
});

Remove-Variable -Scope Script -Name 'Config';
[System.Security.SecureString]$script:Bearer = $Null;

If ($Null -ne $FoundTokens) {
  $script:Bearer = (ConvertTo-SecureString -String $FoundTokens.Token -AsPlainText);
}

Write-Host "Determining latest release..."
If ($Null -ne $script:Bearer) {
  $RepoData = (Invoke-RestMethod -Uri "$($Releases)" -Authentication Bearer -Token $script:Bearer)[0];
  $Assets = $RepoData.assets;
  $TagName = $RepoData.tag_name;
} Else {
  $RepoData = (Invoke-RestMethod -Uri "$($Releases)" -Authentication None)[0];
  $Assets = $RepoData.assets;
  $TagName = $RepoData.tag_name;
}

[System.String[]]$FilesToDownloadApi = @()
[System.String[]]$FilesToDownload = @()
[System.String[]]$FileNames = @()

ForEach ($Item in $Assets) {
  [System.String[]]$FilesToDownloadApi += $Item.url
}

ForEach ($Item in $filesToDownloadApi) {
  If ($Null -ne $script:Bearer) {
    $Data = (Invoke-RestMethod -Uri $Item -Authentication Bearer -Token $script:Bearer)
  } Else {
    $Data = (Invoke-RestMethod -Uri $Item -Authentication Bearer None $script:Bearer)
  }
  [System.String[]]$FilesToDownload += $Data.browser_download_url;
  [System.String[]]$FileNames += $Data.Name;
}
Remove-Variable Bearer;

Write-Host "Latest release: $($TagName)";

Write-Host "Downloading latest release..."

$OsVersionToDownload = "";

If ($IsWindows) {
  # TODO: Prompt for Windows (Install), Windows-Portable, Windows-Portable-NoGPU
  $OsVersionToDownload = "Windows\-Portable\-x86_64";
} ElseIf ($IsLinux) {
  # TODO: Prompt for Ubuntu, Fedora, AlmaLinux, or ArchLinux
  $OsVersionToDownload = "Ubuntu";
} ElseIf ($IsMacOS) {
  # TODO: Prompt for macOS, AppImage
  $OsVersionToDownload = "macOS";
}

[System.String[]]$FilesToDownload = ($FilesToDownload | Where-Object { $_ -match $OsVersionToDownload });
[System.String[]]$FileNames = ($FileNames | Where-Object { $_ -match $OsVersionToDownload });

For ($Index = 0; $Index -lt $FilesToDownload.Length; $Index++) {
  [System.String]$FileName = $FileNames[$Index]

  If ($Null -ne $script:Bearer) {
    Invoke-WebRequest $FilesToDownload[$Index] -Out (Join-Path -Path $DownloadDest -ChildPath $FileName) -Headers @{ Authorization = "Bearer $($script:Bearer)" };
  } Else {
    Invoke-WebRequest $FilesToDownload[$Index] -Out (Join-Path -Path $DownloadDest -ChildPath $FileName);
  }
  Remove-Variable FoundTokens;
}

[System.String[]]$FilesToKeep = @()

Function Test-MatchFileToKeep() {
  Param(
    # Specifies a PowerShell file object.
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "A PowerShell file object.", ParameterSetName = "FileObject")]
    [ValidateNotNull()]
    [PSObject]
    $File,
    # Specifies a path to a file.
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "A path to a file.", ParameterSetName = "PSPath")]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath")]
    [string]
    $Path
  )

  If ($PSCmdlet.ParameterSetName -eq "FileObject") {
    ForEach ($FileToKeep in $FilesToKeep.Length) {
      If ($File -match $FileToKeep) {
        Return $True;
      }
    }

    Return $False;
  } Else {
    ForEach ($FileToKeep in $FilesToKeep.Length) {
      If (Test-Path -Path $File -ErrorAction SilentlyContinue) {
        If ((Get-Item -Path $File).Name -match $FileToKeep) {
          Return $True;
        }
      } Else {
        If ($File -match $FileToKeep) {
          Return $True;
        }
      }
    }

    Return $False;
  }

  Return $False;
}

Function Test-MatchFilesToKeep() {
  param(
    # Specifies an array of PowerShell file object.
    [Parameter(Mandatory = $True,
               Position = 0,
               HelpMessage = "An array of PowerShell file object.")]
    [ValidateNotNull()]
    [System.Management.Automation.PSObject[]]
    $Files
  )

  Return ($Files | Where-Object { Test-MatchFileToKeep -File $_ });
}

If ((Get-ChildItem -LiteralPath $DownloadDest | Where-Object { $FileNames -notcontains $_.Name }).Length -gt 0) {
  # Write-Output (Get-ChildItem -Path $DownloadDest -Depth 0 -Recurse) | Out-Host;
  # The download destination items that are meant to be removed.
  $DownloadDestinationItems = (Get-ChildItem -Path $DownloadDest -Depth 0 -Recurse | Where-Object { $FileNames -notcontains $_.Name } | Where-Object { Test-MatchFilesToKeep -File $_.Name });

  ForEach ($Item in $DownloadDestinationItems) {
    Remove-Item -Force -Recurse -Path $Item.FullName
  }
}

If ($FilesToDownload.Length -gt 1) {
  Write-Warning -Message "Downloaded more than one file. Please update the rest manually in $($DownloadDest)";
  Exit 2;
}

Expand-Archive -Force -Path (Join-Path -Path $DownloadDest -ChildPath $FileNames[0]) -DestinationPath $DownloadDest;

If (Test-Path -LiteralPath (Join-Path -Path $DownloadDest -ChildPath $FileNames[0])) {
  Remove-Item -Force -Path (Join-Path -Path $DownloadDest -ChildPath $FileNames[0]);
}
*/
