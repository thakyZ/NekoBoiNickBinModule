#[CmdletBinding(DefaultParameterSetName = "Path")]
#param (
#  [Parameter(Mandatory=$true,ParameterSetName="Path",HelpMessage="",Position=1)]
#  [string]
#  $FontsFolder=$pwd,
#  [Parameter(Mandatory=$true,ParameterSetName="Files",ValueFromPipeline=$true,HelpMessage="",Position=1)]
#  [System.Object[]]
#  $Fonts=$null,
#  [Parameter(Position=0,ParameterSetName="Path",Mandatory=$false,HelpMessage="")]
#  [Parameter(Position=0,ParameterSetName="Files",Mandatory=$false,HelpMessage="")]
#  [switch]
#  $Administrator
#)

$FontsFolder = "$($pwd)"
$FONTS = 0x14
$CopyOptions = 4 + 16;
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($FONTS)
(Get-ChildItem -Path $FontsFolder | Where-Object { $_.Extension -eq ".ttf" -and $_.BaseName -NotLike "RobotoSerif_*pt*" -and $_.BaseName -NotLike "*VariableFont*" }) | ForEach-Object {
    $dest = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\$($_.Name)"
    If (Test-Path -Path $dest)
    {
        Write-Warning -Message "Font $($_.Name) already installed"
    }
    Else
    {
        Write-Host -Object "Installing $($_.Name)"
        $CopyFlag = [String]::Format("{0:x}", $CopyOptions);
        $objFolder.CopyHere($_.FullName, $CopyFlag)
    }
}
Import-Module PSWinGlue
(Get-ChildItem -Path $FontsFolder | Where-Object { $_.Extension -eq ".ttf" -and $_.BaseName -Like "RobotoSerif_*pt*" }) | ForEach-Object {
  $dest = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\$($_.Name)"
  If (Test-Path -Path $dest)
  {
      Write-Warning -Message "Font $($_.Name) already installed"
      Uninstall-Font -Name "$($_.Name)" -Scope "User" -ErrorAction Continue
  }
  Else
  {
  }
}