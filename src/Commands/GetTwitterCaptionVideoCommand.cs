using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "TwitterCaptionVideo")]
public class GetTwitterCaptionVideoCommand : Cmdlet {
}
/*
param(
  # Parameter help description
  [Parameter(Mandatory = $true, Position = 0)]
  [Alias("i")]
  [string]
  $Path,
  # Parameter help description
  [Parameter(Mandatory = $true, Position = 1)]
  [Alias("t", "c", "Caption")]
  [string[]]
  $Text,
  # Parameter help description
  [Parameter(Mandatory = $true, Position = 1)]
  [Alias("o", "OutFile")]
  [string]
  $Output
)

$TempDir = (Join-Path -Path $env:TEMP -ChildPath "TwitterCaptionVideoPS1")
$FFMPEG = (Get-Command -Name "ffmpeg");

if ((Test-Path -LiteralPath $TempDir -PathType Container)) {
  Remove-Item -Path $TempDir -Recurse
}

if (-not (Test-Path -LiteralPath $TempDir -PathType Container)) {
  New-Item -Path $TempDir -ItemType Directory
}

If ($Null -eq $FFMPEG) {
  Write-Error -Message "FFMpeg not found on path";
  Exit 1;
}

$VideoWidth = (ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 $Path);

$CaptionHeight = (($Text.Length * 18) + (($Text.Length - 1 ) * 2));

Write-Host "& `"$FFMPEG`" -f lavfi -i color=size=$($VideoWidth)x$($CaptionHeight):duration=10:rate=25:color=#15202b -vf drawtext=fontfile=./chirp-regular-web.ttf:fontsize=15:fontcolor=#F7F9F9:x=`(w-text_w`)/2:y=`(h-text_h`)/2:text='$($Text)' $(Join-Path -Path $TempDir -ChildPath "output_caption.png")";
*/
