function Rename-FilesInFolder {
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
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Extension renaming", ParameterSetName = "Extension")]
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Extension renaming", ParameterSetName = "Path")]
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Extension renaming", ParameterSetName = "LiteralPath")]
    [switch]
    $Extention,
    # Enable Name renaming
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Name renaming", ParameterSetName = "Name")]
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Name renaming", ParameterSetName = "Path")]
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Name renaming", ParameterSetName = "LiteralPath")]
    [switch]
    $Name,
    # Enable Name and Extension renaming
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Name and Extension renaming", ParameterSetName = "NameAndExtension")]
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Name and Extension renaming", ParameterSetName = "Path")]
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Enable Name and Extension renaming", ParameterSetName = "LiteralPath")]
    [switch]
    $NameExtension,
    # The string to replace, the string to replace with
    [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "Extension")]
    [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "Name")]
    [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "NameAndExtension")]
    [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "Path")]
    [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The string to replace, the string to replace with", ParameterSetName = "LiteralPath")]
    [string[]]
    $Replace,
    # Recurse the path provided
    [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Recurse the path provided", ParameterSetName = "Path")]
    [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Recurse the path provided", ParameterSetName = "PathAll")]
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
    Elseif ($Extention) {
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
    If ($Replace.Lengh -ne 2) {
      Write-Error -Message "Replace variable should be the string you want to replace comma sepreated by the string you want to replace it with."
    }
  }
  Process {
    ForEach ($File in $Files) {
      If ($Name) {
        Rename-Item -LiteralPath $File.FullName -NewName "$($Replace[1]).$($File.Extension)"
      }
      Elseif ($Extention) {
        Rename-Item -LiteralPath $File.FullName -NewName "$($File.BaseName).$($Replace[1])"
      }
      Elseif ($NameExtension) {
        Rename-Item -LiteralPath $File.FullName -NewName "$($Replace[1])"
      }
    }
  }
}

Export-ModuleMember -Function Rename-FilesInFolder