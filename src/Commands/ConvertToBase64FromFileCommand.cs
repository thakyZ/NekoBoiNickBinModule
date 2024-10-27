using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.ConvertTo, "Base64FromFile")]
public class ConvertToBase64FromFileCommand : Cmdlet {
}
/*
[CmdletBinding()]
Param(
  [System.String]
  $Path,
  [Switch]
  $Compress
)

Begin {
  [IO.FileStream]  $FileStream   = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read);
  [IO.MemoryStream]$MemoryStream = [IO.MemoryStream]::new();
  $Output = $Null;
} Process {
  $FileStream.CopyTo($MemoryStream);
  $Output = (ConvertTo-Base64 -MemoryStream $MemoryStream -Compress:($Compress -eq $True));
} End {
  Write-Output $Output;
} Clean {
  $FileStream.Close();
  $MemoryStream.Close();
}
*/
