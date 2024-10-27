using namespace System.Management.Automation;
using namespace System.IO;

[CmdletBinding(DefaultParameterSetName = "VSCodium")]
Param(
  # Specifies a switch to use VSCode profiles.
  [Parameter(Mandatory = $False,
             ParameterSetName = "VSCode",
             HelpMessage = "A switch to use VSCode profiles.")]
  [Alias("Code")]
  [Switch]
  $VSCode,
  # Specifies a switch to use VSCodium profiles.
  [Parameter(Mandatory = $False,
             ParameterSetName = "VSCodium",
             HelpMessage = "A switch to use VSCode profiles.")]
  [Alias("Codium")]
  [Switch]
  $VSCodium
)

Begin {
  [String] $Directory = [String]::Empty;
  If ($PSCmdlet.ParameterSetName -eq "VSCode") {
    $VSCode = $True;
    $Directory = "Code";
  } ElseIf ($PSCmdlet.ParameterSetName -eq "VSCodium") {
    $VSCodium = $True;
    $Directory = "VSCodium";
  }

  [FileSystemInfo] $UserDirectory = (Get-Item -LiteralPath (Join-Path -Path $env:AppData -ChildPath $Directory -AdditionalChildPath @("User")));
  [OrderedHashtable] $ProfileData = @{
    Main = @{
      IsNone      = $False;
      Config      = (Get-Item -LiteralPath (Join-Path -Path $UserDirectory -ChildPath "settings.json") -ErrorAction SilentlyContinue);
      Keybindings = (Get-Item -LiteralPath (Join-Path -Path $UserDirectory -ChildPath "keybindings.json") -ErrorAction SilentlyContinue);
      Snippets    = @(Get-ChildItem -LiteralPath (Join-Path -Path $UserDirectory -ChildPath "snippets") -ErrorAction SilentlyContinue);
    };
  };
  [OrderedHashtable[]] $ProfileInformation = (Get-Item -LiteralPath (Join-Path -Path $UserDirectory -ChildPath "globalStorage" -AdditionalChildPath @("storage.json")) | Get-Content | ConvertFrom-Json -Depth 100 -AsHashtable).userDataProfiles;
  [FileSystemInfo[]]   $Profiles           = @(Get-ChildItem -LiteralPath (Join-Path -Path $UserDirectory -ChildPath "profiles"));

  Function Invoke-BuildProfiles {
    [CmdletBinding()]
    [OutputType([OrderedHashtable])]
    Param(
      [OrderedHashtable[]] $Information,
      [FileSystemInfo[]]   $Profiles
    )

    Begin {
      [OrderedHashtable] $Output = @{};
    } Process {
      ForEach ($Item in $Profiles) {
        [OrderedHashtable] $ProfileInfo = ($Information | Where-Object { $_.location -eq $Item.Name });
        [String] $ProfileName = $ProfileInfo.name;
        $Output.Add($ProfileName, @{
          IsNone      = ($ProfileName.ToLower() -eq "none");
          Config      = (Get-Item -LiteralPath (Join-Path -Path $Item -ChildPath "settings.json") -ErrorAction SilentlyContinue);
          Keybindings = (Get-Item -LiteralPath (Join-Path -Path $Item -ChildPath "keybindings.json") -ErrorAction SilentlyContinue);
          Snippets    = @(Get-ChildItem -LiteralPath (Join-Path -Path $Item -ChildPath "snippets") -ErrorAction SilentlyContinue);
        });
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  $ProfileData += (Invoke-BuildProfiles -Information $ProfileInformation -Profiles $Profiles);
} Process {
  [OrderedHashtable] $MainData = ($ProfileData.GetEnumerator() | Where-Object { $_.Name -eq "Main" });

  $MainDataConfigHash      = $Null;
  If ($MainData.Item("Config"))

  $MainDataKeybindingsHash = $Null;

  $SnippetsHash            = @($MainData.Item("Snippets"))

  ForEach ($Key in @(($ProfileData.GetEnumerator() | Where-Object { $_.Name -ne "Main" }).Keys)) {
    [OrderedHashtable] $Data = ($ProfileData.GetEnumerator() | Where-Object { $_.Name -eq $Key });
    # Check If Is None
    If ($Data.Value.IsNone) {
      Continue;
    }
    # Check Config
    [FileSystemInfo] $Config = $Data.Values.Item("Config");
    If ($Null -ne $Config) {
      $ConfigHash = (Get-FileHash -LiteralPath $Config -Algorithm SHA512);
      [OrderedHashtable] $ConfigJson = (Get-Content -LiteralPath $Config | ConvertFrom-Json -Depth 100 -AsHashtable);
    }
    # Check Keybindings
    [FileSystemInfo] $Keybindings = $Data.Values.Item("Keybindings");
    If ($Null -ne $Config) {
      $KeybindingsHash = (Get-FileHash -LiteralPath $Config -Algorithm SHA512);
      [OrderedHashtable] $KeybindingsJson = (Get-Content -LiteralPath $Keybindings | ConvertFrom-Json -Depth 100 -AsHashtable);
    }
    # Check Snippets
    [FileSystemInfo] $Snippets = $Data.Values.Item("Snippets");
    If ($Null -ne $Config) {
      ForEach ($Snippet in $Snippets) {
        $SnippetHash = (Get-FileHash -LiteralPath $Snippet -Algorithm SHA512);
        [OrderedHashtable] $SnippetJson = (Get-Content -LiteralPath $Snippet | ConvertFrom-Json -Depth 100 -AsHashtable);

      }
    }
  }
} End {
  Write-Output -NoEnumerate -InputObject $MainData;
}