using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "BackupDirectory")]
public class GetBackupDirectoryCommand : Cmdlet {
}
/*
using namespace System;
using namespace System.IO;
using namespace System.Management.Automation;
using namespace System.ServiceProcess;

[CmdletBinding(DefaultParameterSetName = "PartialPath")]
[OutputType([DirectoryInfo])]
Param(
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "PartialPath",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "A partial path to the backup location.")]
  [Alias("PSPath","Path")]
  [ValidateNotNullOrEmpty()]
  [string]
  $PartialPath
)

Begin {
  [ActionPreference] $OriginalErrorActionPreference = $ErrorActionPreference;
  [DirectoryInfo] $Output;
} Process {

} End {
  Write-Output -InputObject $Output;
} Clean {
  $ErrorActionPreference = $OriginalErrorActionPreference;
}
*/
