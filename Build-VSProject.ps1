[CmdletBinding(DefaultParameterSetName = "Default")]
Param(
    [Parameter(Mandatory = $False,
               Position = 0,
               ValueFromPipeline = $True,
               ParameterSetName = "Default",
               HelpMessage = "The path to the default parameter set name.")]
    [Alias("PSPath", "LiteralPath")]
    [System.String[]]
    $Path = @($PWD),
    [Parameter(Mandatory = $False,
               ParameterSetName = "Default",
               HelpMessage = "The Visual Studio configuration property.")]
    [System.String]
    $Configuration = "None",
    [Parameter(Mandatory = $False,
               ParameterSetName = "Default",
               HelpMessage = "The Visual Studio platform property.")]
    [System.String]
    $Platform = "None",
    [Parameter(Mandatory = $False,
               ParameterSetName = "Default",
               HelpMessage = "A list of Visual Studio properties and their values.")]
    [Hashtable]
    $Property = @{}
)

DynamicParam {
    Class SolutionTree {
        [Systemm.IO.FileSystemInfo]
    }

    [System.IO.FileSystemInfo[]]`
    $Solutions = (Get-ChildItem -LiteralPath $Path -Recurse -Depth 2 -File -Filter '*.sln' | Where-Object {Test-ArrayContainsValue -Array ($_.FullName -split [System.IO.Path]::VolumeSeparatorChar) -Values @('.vs','.git','node_modules','obj','bin','release')})
    [Hashtable]`
    $OutputTypes = @{};
    ForEach ($Solution in $Solutions) {
        $SolutionProps = @{};
        $SolutionFileContent = (Get-Content -LiteralPath $Solution);
        $SolutionConfigurationPlatformsBlock = ($SolutionFileContent | Select-String -Pattern 'GlobalSection\(SolutionConfigurationPlatforms\) = preSolution');
        For ($i = $SolutionConfigurationPlatformsBlock.LineNumber; $i -lt $SolutionFileContent.Count; $i++) {
            If ($SolutionFileContent[$i] -match '^\s+EndGlobalSection$') {
                break;
            } Else {
                $Props = ((($SolutionFileContent[$i] -split ' = ')[0] -replace '\s+', '') -split '|');
                $SolutionProps[$Props[0]] = $Props[1];
            }
        }
        $OutputTypes[$Solution] = $SolutionProps;
    }
    If ($Configuration -ne "None") {
        ForEach ($OutputItem in (Get-HashtableIterator -Hashtable $OutputTypes)) {
            ForEach ($Property in (Get-HashtableIterator -Hashtable $OutputItem)) {
                If ($Property.Key -ne $Configuration) {
                    Read-Host -Prompt "Solution at path  does not contain "
                }
            }
        }
    }
    If ($Platform -ne "None") {

    }
    If (Test-HashtableContainsKey -HashTable $Property -Keys @('Configuration')) {

    }
    If (Test-HashtableContainsKey -HashTable $Property -Keys @('Platform')) {

    }
} Begin {

} Process {

} End {

} Clean {

}
