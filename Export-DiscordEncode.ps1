param(
  [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The input file.")]
  [string]
  $FilePath,
  [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The output file.")]
  [string]
  $Value,
  [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Toggle the use of audio off.")]
  [switch]
  $NoAudio,
  [Parameter(Mandatory = $false, Position = 3, HelpMessage = "The audio bitrate")]
  [string]
  $AudioBits,
  [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Video encoding preset.")]
  [string]
  [ValidateSet("ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow", "placebo")]
  $VideoPreset = "veryslow"
)

if (-not $(Test-Path -Path "${FilePath}" -PathType Leaf)) {
  Write-Error -Message "${FilePath} does not exist."
  Exit 2
}

if ($null -ne $AudioBits) {
  $NoAudio = false;
}

function DurationSeconds() {
  param(
    [string]
    $1 = ""
  )

  Write-Output -NoEnumerate -InputObject [Math]::Round($(ffprobe.exe -i "${1}" -show_entries format=duration -v quiet -of csv="p=0"), 2)
}

function SubtractAndTurncate() {
  param(
    [int]
    $1 = 1,
    [int]
    $2 = 1
  )
  $_temp = ${1} / 1 - ${2}
  Write-Output -NoEnumerate -InputObject [Math]::Round($_temp, 2);
}

function DivideFloats() {
  param(
    [int]
    $1 = 1,
    [int]
    $2 = 1
  )
  $_temp = ${1} / ${2}
  Write-Output -NoEnumerate -InputObject [Math]::Round($_temp, 2);
}

$audioargs = "-an"
$audiobits = 0

if ($null -ne $AudioBits) {
  $audiobits = $AudioBits
}
else {
  $audiobits = 96
}

if (-not $NoAudio) {
  $audioargs = "-c:a aac -b:a ${audiobits}k"
  Write-Host -Object "Using ${audiobits}k aac audio."
}

$duration = $(DurationSeconds "${FilePath}")
Write-Host -Object "${FilePath}"
Write-Host -Object "Duration is ${duration}"
$kbits = $(SubtractAndTurncate (DivideFloats 60630.8 $duration) $audiobits)
Write-Host -Object "Video bitrate is ${kbits} kb/s"
$TMPDIR = (mktemp -d)
$PASSLOGFILE = "${TMPDIR}/ffmpeg2pass"
Invoke-Expression -Command "ffmpeg.exe -y -i `"${FilePath}`" -c:v libx264 -passlogfile ${PASSLOGFILE} -preset ${VideoPreset} -threads 0 -b:v ${kbits}k -pass 1 -an -f mp4 NUL &&
ffmpeg.exe -i `"${FilePath}`" -c:v libx264 -passlogfile ${PASSLOGFILE} -preset ${VideoPreset} -threads 0 -b:v ${kbits}k -pass 2 ${audioargs} `"${Value}`""
Remove-Item -Recurse -Force "$TMPDIR"