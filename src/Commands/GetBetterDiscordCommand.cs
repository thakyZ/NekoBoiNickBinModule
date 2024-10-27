using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "BetterDiscord")]
public class GetBetterDiscordCommand : Cmdlet {
}
/*
Param(
  # Specifies a path to output the binary to.
  [Parameter(Mandatory = $False,
    Position = 0,
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Specifies a path to output the binary to.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [string]
  $Output,
  # Specifies a custom url to download the file from.
  [Parameter(Mandatory = $False,
    Position = 1,
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Specifies a custom url to download the file from.")]
  [string]
  $UrlOverride = ""
)

$DefaultExecutable = "BetterDiscord-Windows.exe";
$DefaultUrl = "https://github.com/BetterDiscord/Installer/releases/latest/download/$($DefaultExecutable)";

$DefaultOutput = (Join-Path -Path $env:TEMP -ChildPath $DefaultExecutable);
$ExitCode = 0;

If (-not [string]::IsNullOrEmpty($UrlOverride) -and (-not [Uri]::new($UrlOverride).IsFile -or [System.IO.Path]::GetFileName([Uri]::new($UrlOverride).LocalPath) -ne $DefaultExecutable)) {
  Write-Error -Message "Uri is not a file or the download file does not match the original `"$($DefaultExecutable)`" scheme.`nPlease edit this file if the changes are different officially at: $(Join-Path -Path $PSScriptRoot -Path $MyInvocation.MyCommand.Name)"
  Exit 1;
} ElseIf (-not [string]::IsNullOrEmpty($UrlOverride)) {
  $DefaultUrl = $UrlOverride;
}

If (-not [string]::IsNullOrEmpty($Output)) {
  If ([System.IO.Path]::GetFileName([Uri]::new($Output).LocalPath) -match ".*\.(exe|asar)" -and [System.IO.Path]::GetDirectoryName([Uri]::new($Output).LocalPath)) {
    $DefaultOutput = $Output;
  }
}

If (-not (Test-Path -Path $DefaultOutput -PathType Leaf)) {
  Write-Host "Invoking WebRequest...";
  try {
    Invoke-WebRequest -Uri $DefaultUrl -OutFile $DefaultOutput -TimeoutSec 30;
  } catch {
    Write-Host -ForegroundColor Red -Object "Failed..."
    Throw $_
    Exit 1;
  }
  Write-Host -ForegroundColor Green -Object "Done...";
}

If ([string]::IsNullOrEmpty($Output) -and [string]::IsNullOrEmpty($UrlOverride) -and (Test-Path -Path $DefaultOutput -PathType Leaf)) {
  Write-Host "Starting Installer...";
  $Process = $Null;
  try {
    $Process = (Start-Process -FilePath $DefaultOutput -PassThru);
    Wait-Process -Id $Process.Id;
    $ExitCode = $Process.ExitCode;
  } catch {
    Write-Host -ForegroundColor Red -Object "Failed..."
    Throw $_
    Exit 1;
  }
  Write-Host -ForegroundColor Green -Object "Done...";
}


If (Test-Path -Path $DefaultOutput -PathType Leaf) {
  Remove-Item -Path $DefaultOutput -Force;
}

Exit $ExitCode;
*/
