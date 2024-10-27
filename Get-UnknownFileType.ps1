#function Get-UnknownFileType {
  <#
    .SYNOPSIS
      Try to get the file type based on it's file signature.
    .DESCRIPTION
      This function uses Get-FileSignature by Boe Prox and a list of
      known file signatures to try to find the file type of a given file.
    .EXAMPLE
      Get-FileType c:\path\to\file.pdf
    .LINK
      https://gallery.technet.microsoft.com/scriptcenter/Get-FileSignature-f5ae19f5
    .NOTES
      Author: Øyvind Kallstad
      Date: 15.12.2014
      Version: 1.0
  #>
  [CmdletBinding()]
  param (
    # Path to file.
    [Parameter(Mandatory = $True,
               Position = 0,
               ValueFromPipeline = $True,
               ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $Path
  )

  Begin {
    . "$($PSScriptRoot)\classFileSignatures.ps1";
  } Process {
    ForEach ($FilePath in $Path) {
      If (Test-Path -LiteralPath $Path -FileType Leaf) {
        ForEach ($Signature in $FileSignatures) {
          If ($ThisSig = Get-FileSignature -Path $FilePath -HexFilter $Signature[1] -ByteOffset $Signature[2] -ByteLimit $Signature[3]) {
            Write-Output -InputObject ([PSCustomObject] [Ordered] @{
              Path = $FilePath
              FileType = ($Signature[0])
              HexSignature = $ThisSig.HexSignature
              ASCIISignature = $ThisSig.ASCIISignature
              Extension = $ThisSig.Extension
            })
          }
        }
      } Else {
        Write-Warning -Message "$filePath not found!"
      }
    }
  }
#}