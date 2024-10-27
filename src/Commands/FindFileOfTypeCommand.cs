using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Find, "FileOfType")]
public class FindFileOfTypeCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "Path")]
[OutputType([System.IO.FileSystemInfo[]])]
Param(
  # Specifies a path to one or more locations. Wildcards are permitted.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Path",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [SupportsWildcards()]
  [System.String[]]
  $ParameterName,
  # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "LiteralPath",
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Literal path to one or more locations.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [System.String[]]
  $LiteralPath,
  # Specifies the type of file to search for.
  [Parameter(Mandatory = $True,
             Position = 1,
             HelpMessage = "The type of file to search for.")]
  [ValidateSet("MP4","AAC","MP3","WEBM","PNG","APNG","JPEG","JPG","GIF")]
  [System.String]
  $FileType,
  # Specifies a switch to search the directory recursively.
  [Parameter(Mandatory = $False,
             HelpMessage = "Search the directory provided recursively.")]
  [System.Management.Automation.SwitchParameter]
  $Recurse,
  # Specifies the wildcard pattern to match files to test the path of.
  [Parameter(Mandatory = $False,
             HelpMessage = "The wildcard pattern to test the path of.")]
  [System.String]
  $Filter,
  # Specifies the regex pattern to match files to test the path of.
  [Parameter(Mandatory = $False,
             HelpMessage = "The regex pattern to test the path of.")]
  [System.String]
  $Pattern
)

DynamicParam {
  If (-not [System.String]::IsNullOrEmpty($Filter) -and -not [System.String]::IsNullOrEmpty($Pattern)) {
    Write-Error -Message "Please specify either Filter or Pattern parameters not both.";
    Exit 1;
  }
  [System.IO.FileSystemInfo] $LPath;
  If ($PSCmdlet.ParameterSetName -eq "Path") {
    $LPath = (Get-Item -Path $Path);
  } Else {
    $LPath = (Get-Item -LiteralPath $LiteralPath);
  }
} Begin {
  [System.IO.FileSystemInfo[]] $Output = @();
} Process {
  Function Test-FileType {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param([System.IO.FileSystemInfo]$File,[System.String]$FileType)

    Begin {
      [System.Boolean] $Output = $False;
    } Process {
      (Get-UnknownFileType -)
    } End {
      Return $Output;
    }
  }
  $Output = (Get-ChildItem -LiteralPath $LPath -Recurse:($Recurse -eq $True) -Filter:($Filter) | Where-Object {
    [System.Boolean] $PatternMatch = $True;
    If (-not [System.String]::IsNullOrEmpty($Pattern)) {
      $PatternMatch = (-not [System.Text.RegularExpressions.Regex]::IsMatch($_.Name, $Pattern, [System.Text.RegularExpressions.RegexOptions]::None, 1000));
    }
    Return ($PatternMatch -and (Test-FileType -File $_ -FileType $FileType));
  });
} End {
  Return $Output;
} Clean {

}
*/
