using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Set, "Permission")]
public class SetPermissionCommand : Cmdlet {
}
/*
Param(
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
  [string[]]
  $Path
)

Function Test-AclContains($Acl) {
  Return ($Null -ne ($Acl.Access | Where-Object {
    $Access = $_;
    Return $Access.IdentityReference -eq "Oscar11\thaky" -and $Access.IsInherited -eq $False;
  }));
}

Function Get-AclAccessIndex($Access) {
  $Index = 0;
  For ($Index; $Index -lt $Access.Count; $Index++) {
    If ($Access[$Index].IdentityReference -eq "Oscar11\thaky" -and $Access.IsInherited -eq $False) {
      Break;
    }
  }
  Return $Index;
}

$Items = (Get-ChildItem -Path $Path -Recurse | Where-Object {
  $SubItem = $_.FullName;
  $Acl = (Get-Acl -Path $SubItem);
  Return (Test-AclContains -Acl $Acl);
});

Write-Output "Found Items Total: $($Items.Length)"

$Items | ForEach-Object {
  Try {
    $SubItem = $_.FullName;
    $Acl = (Get-Acl $SubItem);
    $BeforeCount = $Acl.Access.Count;
    $AccessIndex = Get-AclAccessIndex -Acl $Acl.Access;
    $Acl.RemoveAccessRuleSpecific($Acl.Access[$AccessIndex]);
    $AfterCount = $Acl.Access.Count;
    Write-Output "File: $($SubItem)`nBefore Count: $($BeforeCount)`nFound Index: $($AccessIndex)`nAfter Count: $($AfterCount)`n";
    # Set-Acl -Path $SubItem -AclObject $Acl;
  } Catch {
    Write-Error -Exception $_.Exception -Message $_.Message;
  }
}
*/
