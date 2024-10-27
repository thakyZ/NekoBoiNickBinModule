using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Export, "VideoToGif")]
public class ExportVideoToGifCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "AutoFps")]
Param(
  # Specifies a path to one location of a video file.
  [Parameter(Mandatory = $True,
    Position = 0,
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Path to one location of a video file.")]
  [Alias("PSPath", "I", "Input")]
  [ValidateNotNullOrEmpty()]
  [string]
  $Path,
  # Specifies a path to one location to output the gif to.
  [Parameter(Mandatory = $False,
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False,
    HelpMessage = "Path to one location to output the gif to.")]
  [Alias("PSOutput", "OutFile", "O")]
  [string]
  $Output = $Null,
  # Specifies the FPS to output as.
  [Parameter(Mandatory = $False,
    ParameterSetName = "ManualFps",
    HelpMessage = "The FPS to output to.")]
  [int]
  $Fps = -1,
  # Specifies to auto choose fps based on the input video.
  [Parameter(Mandatory = $False,
    ParameterSetName = "AutoFps",
    HelpMessage = "Auto choose fps based on the input video.")]
  [switch]
  $AutoFps = $False,
  # Specifies the width to output as.
  [Parameter(Mandatory = $False,
    HelpMessage = "The width to output to.")]
  [int]
  $Width = -1,
  # Specifies the quality to output as.
  [Parameter(Mandatory = $False,
    HelpMessage = "The quality to output to.")]
  [int]
  $Quality = -1,
  # Specifies the motion quality to output as.
  [Parameter(Mandatory = $False,
    HelpMessage = "The motion quality to output to.")]
  [int]
  $MotionQuality = -1,
  # Specifies the lossy quality to output as.
  [Parameter(Mandatory = $False,
    HelpMessage = "The lossy quality to output to.")]
  [int]
  $LossyQuality = -1,
  # Specifies to overwrite the output file.
  [Parameter(Mandatory = $False,
    HelpMessage = "Overwrite the output file.")]
  [switch]
  $Force = $False
)

If ($Null -ne $Output -and $Output -ne "" -and (Test-Path -Path $Output -PathType Leaf) -and (Get-Item -LiteralPath $Path).FullName -eq (Get-Item -LiteralPath $Output).FullName) {
  Write-Error -Message "Input `$Path and `$Output path are the extact same.";
  Exit 1;
}

If (Test-Path -LiteralPath $Path -PathType Container) {
  Write-Error -Message "Input path, `"$($Path)`", is a folder.";
  Exit 1;
} ElseIf (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
  Write-Error -Message "Input path, `"$($Path)`", does not exist on the drive.";
  Exit 1;
}

If ($Null -eq $Output -or $Output -eq "") {
  $TestRegex = [Regex]::new("^(.*)([^\d\w]{1})gif(.)\.[\w\d]{2,4}$");

  If ($TestRegex.IsMatch($Path)) {
    $TestMatch = $TestRegex.Match($Path);
    $OutputTemp = $TestMatch.Result('$1$2$3.gif');
  } Else {
    $OutputTemp = (Join-Path -Path (Get-Item -LiteralPath $Path).Directory.FullName -ChildPath "$((Get-Item -LiteralPath $Path).BaseName).gif");
  }

  $Output = $OutputTemp;
}

If ((Test-Path -LiteralPath $Output -PathType Container)) {
  Write-Error -Message "The output path, `"$($Output)`", is a folder.";
  Exit 1;
} ElseIf ((Test-Path -LiteralPath $Output -PathType Leaf) -and -not $Force) {
  Write-Error -Message "The output path, `"$($Output -Replace "^\.\\", '')`", exists on the drive. Use -Force to overwrite.";
  Exit 1;
}

Function Invoke-StringBuilder() {
  Param(
    # Specifies the path to one or more frame paths. Supports wildcards.
    [Parameter(Mandatory = $True,
      Position = 0,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "The path to one or more frame paths. Supports wildcards.")]
      [ValidateNotNullOrEmpty()]
    [string[]]
    $FramePaths,
    # Specifies the path to output the file to.
    [Parameter(Mandatory = $True,
      Position = 1,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "The path to output the file to.")]
      [ValidateNotNullOrEmpty()]
    [string]
    $Output
  )
  $Temp = @();

  ForEach ($FramePath in $FramePaths) {
    $Temp +=  $FramePath;
  }

  If ($Fps -ne -1) {
    $Temp += "--fps $($Fps)";
  }
  If ($Width -ne -1) {
    $Temp += "--width $($Width)";
  }
  If ($Quality -ne -1) {
    $Temp += "--quality $($Quality)";
  }
  If ($MotionQuality -ne -1) {
    $Temp += "--motion-quality $($MotionQuality)";
  }
  If ($LossyQuality -ne -1) {
    $Temp += "--lossy-quality $($LossyQuality)";
  }
  $Temp += "-o $($Output)"
  Return $Temp;
}

$FFmpeg = (Get-Command -Name "ffmpeg");
$FFprobe = (Get-Command -Name "ffprobe");
$GifSki = (Get-Command -Name "gifski");

If (-not (Test-Path -Path $FFmpeg.Source -PathType Leaf)) {
  Write-Error -Message "FFmpeg was not found on path.";
  Exit 1;
}
If ($AutoFps -and -not (Test-Path -Path $FFprobe.Source -PathType Leaf)) {
  Write-Error -Message "FFprobe was not found on path while -AutoFps specified.";
  Exit 1;
}
If (-not (Test-Path -Path $GifSki.Source -PathType Leaf)) {
  Write-Error -Message "GifSki was not found on path.";
  Exit 1;
}

$script:LastPercent = 0;
$script:ProgressId = $PID;

Function Write-LocalProgress() {
  Param(
    # Specifies the path to one or more frame paths. Supports wildcards.
    [Parameter(Mandatory = $True,
      Position = 0,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "The path to one or more frame paths. Supports wildcards.")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Activity,
    # Specifies the path to output the file to.
    [Parameter(Mandatory = $True,
      Position = 1,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "The path to output the file to.")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Status,
    # Specifies the path to output the file to.
    [Parameter(Mandatory = $False,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "The path to output the file to.")]
    [string]
    $CurrentOperation = "",
    # Specifies the path to output the file to.
    [Parameter(Mandatory = $False,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "The path to output the file to.")]
    [int]
    $PercentComplete = 0,
    # Specifies the path to output the file to.
    [Parameter(Mandatory = $False,
      HelpMessage = "The path to output the file to.")]
    [switch]
    $Errored = $False,
    # Specifies the path to output the file to.
    [Parameter(Mandatory = $False,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "The path to output the file to.")]
    [switch]
    $Completed = $False
  )

  If (-not $Errored) {
    $script:LastPercent = $PercentComplete;
  } Else {
    $PercentComplete = $script:LastPercent;
  }

  If ($Completed) {
    Write-Progress -Id $script:ProgressId -Activity $Activity -Status $Status -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation -Completed;
    Return;
  }

  Write-Progress -Id $script:ProgressId -Activity $Activity -Status "$($Status) - $($PercentComplete)%" -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation;
}

Function Get-StepProgress() {
  Param(
    # Specifies the current step the script is at.
    [Parameter(Mandatory = $True,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "The current step the script is at.")]
    [int]
    $CurrentStep
  )

  $TotalSteps = 6;

  If ($PSCmdlet.ParameterSetName -eq "AutoFps" -or $AutoFps) {
    $TotalSteps = 8;
  } ElseIf ($CurrentStep -gt 3) {
    $CurrentStep = $CurrentStep - 2;
  }

  $Temp = ($CurrentStep / $TotalSteps) * 100;

  Return [Math]::Ceiling($Temp);
}



Try {
  Write-LocalProgress -Activity "Converting Video to Gif" -Status "Creating temporary directory." -PercentComplete (Get-StepProgress -CurrentStep 1) -CurrentOperation "";

  If (Test-Path -LiteralPath (Join-Path -Path $env:TEMP -ChildPath "gifski.tmp")) {
    Remove-Item -Recurse -LiteralPath (Join-Path -Path $env:TEMP -ChildPath "gifski.tmp");
  }

  $TempDirectory = (New-Item -ItemType Directory -Path (Join-Path -Path $env:TEMP -ChildPath "gifski.tmp")).FullName

  $ProcessFFmpeg_StandardOutput = (Join-Path -Path  $TempDirectory -ChildPath "ProcessFFmpeg_StandardOutput.log");
  $ProcessFFmpeg_StandardError = (Join-Path -Path  $TempDirectory -ChildPath "ProcessFFmpeg_StandardError.log");

  Write-LocalProgress -Activity "Converting Video to Gif" -Status "Extracting frames..." -PercentComplete (Get-StepProgress -CurrentStep 2) -CurrentOperation "";

  $ProcessFFmpeg = (Start-Process -NoNewWindow -FilePath $FFmpeg -ArgumentList @("-i", "$($Path)", "$((Join-Path -Path $TempDirectory -ChildPath "frame%04d.png"))") -PassThru -RedirectStandardOutput $ProcessFFmpeg_StandardOutput -RedirectStandardError $ProcessFFmpeg_StandardError);
  Wait-Process -Id $ProcessFFmpeg.Id;

  Write-LocalProgress -Activity "Converting Video to Gif" -Status "Finished extracting frames." -PercentComplete (Get-StepProgress -CurrentStep 3) -CurrentOperation "";

  If ($PSCmdlet.ParameterSetName -eq "AutoFps" -or $AutoFps) {
    Write-LocalProgress -Activity "Converting Video to Gif" -Status "Running FFprobe" -PercentComplete (Get-StepProgress -CurrentStep 4) -CurrentOperation "";

    $ProcessFFprobe_StandardOutput = (Join-Path -Path  $TempDirectory -ChildPath "ProcessFFprobe_StandardOutput.log");

    $ProcessFFprobe = (Start-Process -NoNewWindow -FilePath $FFprobe -ArgumentList @("-v error", "-select_streams v", "-of default=noprint_wrappers=1:nokey=1", "-show_entries stream=r_frame_rate", "$($Path)") -PassThru -RedirectStandardOutput $ProcessFFprobe_StandardOutput);
    Wait-Process -Id $ProcessFFprobe.Id;

    $FpsFraction = ((Get-Content -Path $ProcessFFprobe_StandardOutput) -Split "/");
    Write-Debug -Message "($($FpsFraction[0]) / $($FpsFraction[1])) = $(($FpsFraction[0] / $FpsFraction[1]))"
    $Fps = ($FpsFraction[0] / $FpsFraction[1]);

    Write-LocalProgress -Activity "Converting Video to Gif" -Status "Finished running FFprobe" -PercentComplete (Get-StepProgress -CurrentStep 5) -CurrentOperation "";
  }

  $TempArguments = Invoke-StringBuilder -FramePaths (Join-Path -Path $TempDirectory -ChildPath "frame*.png") -Output $Output;

  Write-Debug -Message "Start-Process -NoNewWindow -FilePath `"$($GifSki)`" -ArgumentList @($TempArguments)";

  $ProcessGifSki_StandardOutput = (Join-Path -Path  $TempDirectory -ChildPath "ProcessGifSki_StandardOutput.log");

  Write-LocalProgress -Activity "Converting Video to Gif" -Status "Running GifSki" -PercentComplete (Get-StepProgress -CurrentStep 6) -CurrentOperation "";

  $ProcessGifSki = (Start-Process -NoNewWindow -FilePath $GifSki -ArgumentList $TempArguments -PassThru -RedirectStandardOutput $ProcessGifSki_StandardOutput);
  Wait-Process -Id $ProcessGifSki.Id;

  Write-LocalProgress -Activity "Converting Video to Gif" -Status "Finished running GifSki." -PercentComplete (Get-StepProgress -CurrentStep 7) -CurrentOperation "";
} Catch {
  Write-LocalProgress -Activity "Converting Video to Gif" -Status "Failed..." -CurrentOperation "$($_.Message)" -Errored;

  Remove-Item -Recurse -Force -Path $TempDirectory;

  Throw $_.Exception;
  Exit 1;
}

Write-LocalProgress -Activity "Converting Video to Gif" -Status "Cleaning up." -PercentComplete (Get-StepProgress -CurrentStep 8) -CurrentOperation "";

Remove-Item -Recurse -Force -Path $TempDirectory;

*/
