using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsDiagnostic.Resolve, "LiteralPath")]
public class ResolveLiteralPathCommand : Cmdlet {
}
/*
[CmdletBinding()]
[OutputType([System.String])]
Param(
    # TODO: Parameter help description
    [Parameter(Mandatory = $False,
               Position = 0,
               HelpMessage = "TBA")]
    [System.Management.Automation.PSCredential]
    $Credential,
    # TODO: Parameter help description
    [Parameter(Mandatory = $True,
               Position = 1,
               HelpMessage = "TBA")]
    [Alias("Path","PSPath")]
    [ValidateNotNullOrEmpty()]
    [System.String[]]
    $LiteralPath,
    # TODO: Parameter help description
    [Parameter(Mandatory = $False,
               Position = 2,
               HelpMessage = "TBA")]
    [Switch]
    $Relative,
    # TODO: Parameter help description
    [Parameter(Mandatory = $False,
               Position = 3,
               HelpMessage = "TBA")]
    [Alias("RelativeBasePath","BasePath")]
    [System.String]
    $RelativeBaseLiteralPath
)

Begin {
    $EscapedBasePath = ($RelativeBaseLiteralPath -replace '([[\]])','`$1');
} Process {
    [System.IO.Path]::GetRelativePath("$($Compile[0].ProviderPath1)","$($Compile[0].FullName)")
} End {

}
*/
