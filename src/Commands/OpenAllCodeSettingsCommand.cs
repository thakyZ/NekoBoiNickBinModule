using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Open, "AllCodeSettings")]
public class OpenAllCodeSettingsCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "Both")]
Param(
    [Parameter(Mandatory = $True,
               ParameterSetName = "Codium",
               HelpMessage = "Open all Codium settings files.")]
    [Parameter(Mandatory = $True,
               ParameterSetName = "Both",
               HelpMessage = "Open all Codium settings files.")]
    [Alias("VSCodium")]
    [Switch]
    $Codium,
    [Parameter(Mandatory = $False,
               ParameterSetName = "Codium",
               HelpMessage = "Override the path to the Codium profile directory.")]
    [Parameter(Mandatory = $False,
               ParameterSetName = "Both",
               HelpMessage = "Override the path to the Codium profile directory.")]
    [System.String]
    $CodiumPath = $Null,
    [Parameter(Mandatory = $True,
               ParameterSetName = "VSCode",
               HelpMessage = "Open all Codium settings files.")]
    [Parameter(Mandatory = $True,
               ParameterSetName = "Both",
               HelpMessage = "Open all Codium settings files.")]
    [Alias("Code")]
    [Switch]
    $VSCode,
    [Parameter(Mandatory = $False,
               ParameterSetName = "VSCode",
               HelpMessage = "Override the path to the VSCode profile directory.")]
    [Parameter(Mandatory = $False,
               ParameterSetName = "Both",
               HelpMessage = "Override the path to the VSCode profile directory.")]
    [System.String]
    $VSCodePath = $Null,
    [Parameter(Mandatory = $False,
               ParameterSetName = "Both",
               HelpMessage = "Try open each profile next to their equivalent in the other application.")]
    [Switch]
    $Sorted
)

Begin {
    Function Get-ValueFromNameInHashtableArray {
        [CmdletBinding()]
        [OutputType([System.Collections.Hashtable])]
        Param(
            [Parameter(Mandatory = $True,
                       Position = 0,
                       ValueFromPipeline = $True,
                       HelpMessage = "The array of hashtables to test against.")]
            [ValidateNotNullOrEmpty()]
            [Alias("Array","Hashtables")]
            [System.Collections.Hashtable[]]
            $ArrayOfHashtables,
            [Parameter(Mandatory = $True,
                       ValueFromPipeline = $True,
                       HelpMessage = "The key in the hashtable to test for.")]
            [ValidateNotNullOrEmpty()]
            [Alias("Key")]
            [System.String]
            $HashtableKeyToSearch,
            [Parameter(Mandatory = $True,
                       ValueFromPipeline = $True,
                       HelpMessage = "The key's value to test against")]
            [Alias("Value")]
            [System.String]
            $HashtableKeyTest
        )

        Begin {
            [System.Collections.Hashtable]`
            $Output = $Null;
        } Process {
            ForEach ($Item in $ArrayOfHashtables) {
                If ($Item.ContainsKey($HashtableKeyToSearch) -and $Item.Item($HashtableKeyToSearch) -eq $HashtableKeyTest) {
                    $Output = $Item;
                }
            }
        } End {
            Return $Output;
        }
    }

    If (($PSCmdlet.ParameterSetName -eq "Codium" -or $PSCmdlet.ParameterSetName -eq "Both") -and ($Null -eq $CodiumPath -or [System.String]::NotNullOrEmpty($CodiumPath) -or [System.String]::NotNullOrWhiteSpace($CodiumPath))) {
        $CodiumPath = (Get-Item -LiteralPath (Join-Path -Path $env:AppData -ChildPath "VSCodium" -AdditionalChildPath @("User")));
    }
    If (($PSCmdlet.ParameterSetName -eq "VSCode" -or $PSCmdlet.ParameterSetName -eq "Both") -and ($Null -eq $VSCodePath -or [System.String]::NotNullOrEmpty($VSCodePath) -or [System.String]::NotNullOrWhiteSpace($VSCodePath))) {
        $VSCodePath = (Get-Item -LiteralPath (Join-Path -Path $env:AppData -ChildPath "Code" -AdditionalChildPath @("User")));
    }
    $CodiumFiles = @{};
    If ($PSCmdlet.ParameterSetName -eq "Codium" -or $PSCmdlet.ParameterSetName -eq "Both") {
        $CodiumGlobalStorage = ((Get-Item -LiteralPath (Join-Path -Path $CodiumPath -ChildPath "globalStorage" -AdditionalChildPath @("storage.json"))) | Get-Content | ConvertFrom-Json -AsHashTable);
        $UserDataProfiles = $CodiumGlobalStorage.userDataProfiles
        ForEach ($File in (Get-ChildItem -LiteralPath $CodiumPath -Recurse -File -Filter "settings.json" | Where-Object { $_.Directory.Name -eq "User" -or $_.Directory.Parent.Name -eq "profiles" })) {
            If ($File.Directory.Name -eq "User") {
                $CodiumFiles["global"] = $File;
            } ElseIf ($File.Directory.Parent.Name -eq "profiles") {
                $Key = (Get-ValueFromNameInHashtableArray -Array $UserDataProfiles -Key "Name" -Value $File.Directory.Name);
                $CodiumFiles[$Key] = $File;
            }
        }
    }
    $VSCodeFiles = @{};
    If ($PSCmdlet.ParameterSetName -eq "VSCode" -or $PSCmdlet.ParameterSetName -eq "Both") {
        $VSCodeGlobalStorage = ((Get-Item -LiteralPath (Join-Path -Path $VSCodePath -ChildPath "globalStorage" -AdditionalChildPath @("storage.json"))) | Get-Content | ConvertFrom-Json -AsHashTable);
        $UserDataProfiles = $VSCodeGlobalStorage.userDataProfiles
        ForEach ($File in (Get-ChildItem -LiteralPath $VSCodePath -Recurse -File -Filter "settings.json" | Where-Object { $_.Directory.Name -eq "User" -or $_.Directory.Parent.Name -eq "profiles" })) {
            If ($File.Directory.Name -eq "User") {
                $VSCodeFiles["global"] = $File;
            } ElseIf ($File.Directory.Parent.Name -eq "profiles") {
                $Key = (Get-ValueFromNameInHashtableArray -Array $UserDataProfiles -Key "Name" -Value $File.Directory.Name);
                $VSCodeFiles[$Key] = $File;
            }
        }
    }
} Process {

} End {

}
*/
