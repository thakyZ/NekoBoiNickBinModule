Param(
  # Specifies a path to one or more locations.
  # Set to ex. "C:\path to files\*.mp3" via the command-line.
  [Parameter(Mandatory = $True,
    Position = 0,
    ParameterSetName = "Paths",
    ValueFromPipeline = $True,
    ValueFromPipelineByPropertyName = $True,
    HelpMessage = "Path to one or more locations.`nSet to ex. `"C:\path to files\*.mp3`" via the command-line.")]
  [Alias("PSPath")]
  [SupportsWildcards()]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $PlaylistPaths
)

[string[]]$FileList = @();

ForEach ($PlaylistPath in $PlaylistPaths) {
  # Use basic wildcard notation (ex. "*.mp3") to place
  # matching file names from a directory into a VLC
  # playlist.

  # Turn ex. "C:\path to files\*.mp3" into ex. "C:\path to files\*"
  $PlaylistDirectory = Split-Path -Path $PlaylistPath
  $PlaylistDirectory = "$($PlaylistDirectory)\*"

  # -Leaf returns the last item or container in a path
  # (ex. "*.mp3")
  $FileType = Split-Path -Path $PlaylistPath -Leaf

  # Place any matching file names/paths into a $file_list
  # $file_list = Get-ChildItem C:\path to files\* -Include *.mp3
  $FileList += @((Get-ChildItem $PlaylistDirectory -Include $FileType).FullName)
}

Function Get-VLCLocation() {
  $Output = (Get-Command -Name "vlc" -ErrorAction SilentlyContinue);
  If ($Null -ne $Output) {
    Write-Output -NoEnumerate -InputObject $Output.Source;
  }
  $Drives = @(Get-PSDrive | Where-Object { $_.Provider -match "FileSystem" -and $_.Root.Length -eq 3 });
  ForEach ($Drive in $Drives) {
    ForEach ($ProgramFiles in @("Program Files", "Program Files (x86)")) {
      If (Test-Path -LiteralPath (Join-Path -Path "$($Drive.Root)" -ChildPath "$($ProgramFiles)" -AdditionalChildPath @("VideoLAN", "VLC", "vlc.exe")) -PathType Leaf) {
        Return (Get-Item -LiteralPath (Join-Path -Path "$($Drive.Root)" -ChildPath "$($ProgramFiles)" -AdditionalChildPath @("VideoLAN", "VLC", "vlc.exe"))).FullName;
      }
    }
  }

  Write-Warning -Message "Could not find VLC in normal locations...";
  $AskForPath = (Read-Host -Prompt "Path to VLC");

  While ($AskForPath -ne "" -and -not (Test-Path -LiteralPath $AskForPath -PathType Leaf)) {
    $AskForPath = (Read-Host -Prompt "Path to VLC");
    Start-Sleep -Seconds 1;
  }

  If (Test-Path -LiteralPath $AskForPath -PathType Leaf) {
    $Output = (Get-Item -LiteralPath $AskForPath).FullName;
  }

  $Output;
}

# "Pre-load" VLC for (arguably) better initial playback, etc.
# Start-Process vlc -ArgumentList @("--one-instance")
Start-Process (Get-VLCLocation) -ArgumentList @("--one-instance")

ForEach ($File in $FileList) {
  # Add quotes to $File output, since this may contain spaces.
  $QuotedFilePath = "`"$($File)`"";

  # Queue up the item in the current VLC playlist.
  # Start-Process vlc -ArgumentList @("--one-instance", "--playlist-enqueue", $QuotedFilePath)
  Start-Process (Get-VLCLocation) -ArgumentList @("--one-instance", "--playlist-enqueue", $QuotedFilePath)

  # Add a delay between loading files to help avoid playlist
  # jumbling. May not be 100% effective.
  Start-Sleep -Seconds 2
}