using namespace System;
using namespace System.Collections;
using namespace System.Collections.Generic;
using namespace System.IO;
using namespace System.Linq;

[CmdletBinding(DefaultParameterSetName = 'GetMod')]
Param(
  # Specfies the name of the mod to look for, accepts wildcards.
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             ParameterSetName = 'GetMod',
             HelpMessage = 'The name of the mod to look for, accepts wildcards.')]
  [Alias('Mod','Name')]
  [ValidateNotNullOrEmpty()]
  [ValidateNotNullOrWhiteSpace()]
  [SupportsWildcards()]
  [string]
  $ModName,
  # Specfies a specific account if multiple API keys are in the config, otherwise uses the first avaliable one.
  [Parameter(Mandatory = $False,
             HelpMessage = 'A specific account if multiple API keys are in the config, otherwise uses the first avaliable one.')]
  [Alias('User','Account')]
  [AllowNull()]
  [string]
  $UserAccount = $Null,
  # Specfies a regular expression to search in code for.
  [Parameter(Mandatory = $True,
             ValueFromPipeline = $True,
             ParameterSetName = 'Search',
             HelpMessage = 'The name of the mod to look for, accepts wildcards.')]
  [switch]
  $Search,
  # Specfies a regular expression to search in code for.
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             ParameterSetName = 'Search',
             HelpMessage = 'A regular expression to search in code for.')]
  [ValidateNotNullOrEmpty()]
  [string]
  $Pattern,
  # Specfies a set of file extensions to filter for when searching for code, accepts wildcards.
  [Parameter(Mandatory = $False,
             ParameterSetName = 'Search',
             HelpMessage = 'A set of file extensions to filter for when searching for code, accepts wildcards.')]
  [ValidateNotNullOrEmpty()]
  [SupportsWildcards()]
  [string[]]
  $Filter = @('.cs')
)

DynamicParam {
  [string] $GenericRecommenedAction = 'Contact author of this script to fix. Please provide any relavent information such as logs.';
  [string] $TempCacheFile = (Join-Path -Path $env:TEMP -ChildPath 'Get-ModIOMod.cache');
  [FileInfo] $CacheFile = (Get-Item -LiteralPath $TempCacheFile -ErrorAction SilentlyContinue);
  [Hashtable] $CacheData = $Null;

  [string] $TempConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath 'config.json');
  [FileInfo] $ConfigPath = (Get-Item -LiteralPath $TempConfigPath -ErrorAction SilentlyContinue);

  If ($Null -eq $ConfigPath) {
    Throw [FileNotFoundException]::new("Config path was not found at $($TempConfigPath)");
  }

  [Hashtable] $TokenToUse = $Null;

  [Hashtable] $Config = (Get-Content -LiteralPath $TempConfigPath | ConvertFrom-Json -AsHashtable -Depth 100);
  [Hashtable[]] $Tokens = $Config.Tokens;
  [Hashtable[]] $ModIOTokens = ($Tokens | Where-Object { $_.Addresses -contains '*.modapi.io' });

  If ($Null -ne $UserAccount) {
    $TokenToUse = ($ModIOTokens | Where-Object { $_.UserAccount.ToString() -match [Regex]::Escape($UserAccount) } | Select-Object -First 1);
  } Else {
    $TokenToUse = ($ModIOTokens | Select-Object -First 1);
  }

  If ($Null -ne $CacheFile) {
    $CacheData = (Get-Content -LiteralPath $CacheFile | ConvertFrom-Json -Depth 100 -AsHashtable);
  } Else {
    $global:Responses = @();
    [int] $LeftToDo = 1;
    $CacheData = @{ data = [List[PSCustomObject]]::new(); result_total = 0 };
    [int] $LastLeftToDo = -1;

    While ($LeftToDo -gt 0) {
      If ($LastLeftToDo -eq $LeftToDo) {
        Write-Error -ErrorId 'GetModIOMod.RestMethod.While.LoopBreak' -Message 'Failed to loop through getting each page in Mod.io API rest response' -Category DeadlockDetected -TargetObject $LeftToDo -RecommendedAction $GenericRecommenedAction;
        Break;
      }

      [PSCustomObject] $Response = (Invoke-RestMethod -Method Get -Uri "https://$($TokenToUse.UserAccount).modapi.io/v1/games?_offset=$(($LeftToDo - 1) * 100)&api_key=$($TokenToUse.Token)" -Headers @{ Accept = 'application/json' });

      If ($Null -eq ($Response | Get-Member -MemberType NoteProperty -Name 'data')) {
        Write-Error -ErrorId 'GetModIOMod.RestMethod.Invoke.APIError' -Message "Failed to get proper api response from Mod.io's API." -Category InvalidData -TargetObject $Response -RecommendedAction 'Review the API response and your API key.';
      } Else {
        $CacheData.result_total = $Response.result_total;
        $global:Responses += $Response;
        $CacheData.data.AddRange($Response.data.ToList())
      }

      $LastLeftToDo = $LeftToDo;

      If (($Response.result_count + $Response.result_offset) -lt $Response.result_total) {
        $LeftToDo = [Math]::Ceiling($Response.result_total / ($Response.result_count + $Response.result_offset)) - 1;
      } Else {
        $LeftToDo--;
      }
    }
    [string] $CacheDataText = (ConvertTo-Json -Depth 100 -Compress -EnumsAsStrings -InputObject $CacheData);
    Set-Content -LiteralPath $TempCacheFile -Value $CacheDataText | Out-Null;
  }
  If ($Null -eq $CacheData -or $Null -eq $CacheData.data -or $Null -eq $CacheData.result_total -or $CacheData.result_total -ne $CacheData.data.Count) {
    Write-Error -ErrorId 'GetModIOMod.Cache.Invalid' -Message 'Cached data was invalid and we cannot proceed.' -Category InvalidData -TargetObject $CacheData -RecommendedAction $GenericRecommenedAction;
  }
  [string] $TempModIOPath = (Join-Path -Path 'C:' -ChildPath 'Users' -AdditionalChildPath @('Public', 'mod.io'));
  [DirectoryInfo] $ModIOPath = (Get-Item -LiteralPath $TempModIOPath -ErrorAction SilentlyContinue);
  If ($Null -eq $ModIOPath) {
    Throw [DirectoryNotFoundException]::new("Mod.io directory was not found at $($TempModIOPath)");
  }
  [DirectoryInfo[]] $Games = (Get-ChildItem -LiteralPath $ModIOPath -Directory);
  [Hashtable] $GameNames = @{};
  ForEach ($Game in $Games) {
    [string] $GameName = ($CacheData.data | Where-Object { $Null -ne ($_ | Get-Member -MemberType NoteProperty -Name 'id') -and $_.id -eq $Game.Name } | Select-Object -First 1 -Property 'name').name;
    $GameNames.Add($Game.Name, $GameName);
  }

  # Specifies a collection of dynamic parameters.
  $ParameterDictionary = [RuntimeDefinedParameterDictionary]::new();

  # Specifies the game to query into.
  [ParameterAttribute] $GameNameParameterAttribute = [ParameterAttribute]::new();
  $GameNameParameterAttribute.Mandatory = $False;
  $GameNameParameterAttribute.HelpMessage = 'The game to query into.';
  [AliasAttribute] $GameNameAliasAttribute = [AliasAttribute]::new('Game');
  [AllowNullAttribute] $GameNameAllowNullAttribute = [AllowNullAttribute]::new();
  [ValidateSetAttribute] $GameNameValidateSetAttribute = [ValidateSetAttribute]::new($GameNames.Values);
  [Collection[Attribute]] $GameNameAttributeCollection = [Collection[Attribute]]::new();
  $GameNameAttributeCollection.Add($GameNameParameterAttribute);
  $GameNameAttributeCollection.Add($GameNameValidateSetAttribute);
  $GameNameAttributeCollection.Add($GameNameAliasAttribute);
  $GameNameAttributeCollection.Add($GameNameAllowNullAttribute);
  $GameNameDynamicParameter = [RuntimeDefinedParameter]::new('GameName', [string], $GameNameAttributeCollection);
  $GameNameDynamicParameter.Value = $Null;
  $ParameterDictionary.Add('GameName', $GameNameDynamicParameter);

  # Specifies the cache data to be used elsewhere in the script.
  [ParameterAttribute] $CacheDataParameterAttribute = [ParameterAttribute]::new();
  $CacheDataParameterAttribute.Mandatory = $False;
  $CacheDataParameterAttribute.DontShow = $True;
  [AllowNullAttribute] $CacheDataAllowNullAttribute = [AllowNullAttribute]::new();
  [Collection[Attribute]] $CacheDataAttributeCollection = [Collection[Attribute]]::new();
  $CacheDataAttributeCollection.Add($CacheDataParameterAttribute);
  $CacheDataAttributeCollection.Add($CacheDataAllowNullAttribute);
  $CacheDataDynamicParameter = [RuntimeDefinedParameter]::new('CacheData', [Hashtable], $CacheDataAttributeCollection);
  $CacheDataDynamicParameter.Value = $CacheData;
  $ParameterDictionary.Add('CacheData', $CacheDataDynamicParameter);

  # Specifies last token that was used (if applicable)
  [ParameterAttribute] $TokenToUseParameterAttribute = [ParameterAttribute]::new();
  $TokenToUseParameterAttribute.Mandatory = $False;
  $TokenToUseParameterAttribute.DontShow = $True;
  [AllowNullAttribute] $TokenToUseAllowNullAttribute = [AllowNullAttribute]::new();
  [Collection[Attribute]] $TokenToUseAttributeCollection = [Collection[Attribute]]::new();
  $TokenToUseAttributeCollection.Add($TokenToUseParameterAttribute);
  $TokenToUseAttributeCollection.Add($TokenToUseAllowNullAttribute);
  $TokenToUseDynamicParameter = [RuntimeDefinedParameter]::new('TokenToUse', [Hashtable], $TokenToUseAttributeCollection);
  $TokenToUseDynamicParameter.Value = $TokenToUse;
  $ParameterDictionary.Add('TokenToUse', $TokenToUseDynamicParameter);

  # Specifies last token that was used (if applicable)
  [ParameterAttribute] $GameNamesParameterAttribute = [ParameterAttribute]::new();
  $GameNamesParameterAttribute.Mandatory = $False;
  $GameNamesParameterAttribute.DontShow = $True;
  [Collection[Attribute]] $GameNamesAttributeCollection = [Collection[Attribute]]::new();
  $GameNamesAttributeCollection.Add($ParameterAttribute);
  $GameNamesDynamicParameter = [RuntimeDefinedParameter]::new('GameNames', [Hashtable], $GameNamesAttributeCollection);
  $GameNamesDynamicParameter.Value = $GameNames;
  $ParameterDictionary.Add('GameNames', $GameNamesDynamicParameter);

  Write-Output -NoEnumerate -InputObject $ParameterDictionary;
} Begin {
  Function Test-GameNameOrDirectoryName {
    [CmdletBinding()]
    Param(
      # Specifies the game name to specifically target.
      [Parameter(Mandatory = $True)]
      [AllowNull]
      [string]
      $ParameterName
    )

  }

  [bool] $CanUseCacheData  = ($PSBoundParameters.ContainsKey('CacheData')  -and $Null -ne $PSBoundParameters['CacheData']);
  [bool] $CanUseTokenToUse = ($PSBoundParameters.ContainsKey('TokenToUse') -and $Null -ne $PSBoundParameters['TokenToUse']);
  [bool] $CanUseGameName   = ($PSBoundParameters.ContainsKey('GameName')   -and $Null -ne $PSBoundParameters['GameName']);
  [bool] $CanUseGameNames  = ($PSBoundParameters.ContainsKey('GameNames')   -and $Null -ne $PSBoundParameters['GameNames']);
  [string] $GameName = $Null;
  If ($CanUseGameName) {
    $GameName = $PSBoundParameters['GameName'];
  }
  [Hashtable] $GameNames = $Null;
  If ($CanUseGameNames) {
    $GameNames = $PSBoundParameters['GameNames'];
  }
  [Hashtable] $CacheData = $Null;
  If ($CanUseCacheData) {
    $CacheData = $PSBoundParameters['CacheData'];
  }
  [Hashtable] $TokenToUse = $Null;
  If ($CanUseTokenToUse) {
    $TokenToUse = $PSBoundParameters['TokenToUse'];
  }
  [string] $TempModIOPath = (Join-Path -Path 'C:' -ChildPath 'Users' -AdditionalChildPath @('Public', 'mod.io'));
  [DirectoryInfo] $ModIOPath = (Get-Item -LiteralPath $TempModIOPath -ErrorAction SilentlyContinue);

  If ($Null -eq $ModIOPath) {
    Throw [DirectoryNotFoundException]::new("Mod.io directory was not found at $($TempModIOPath)");
  }
  [HashTable] $FoundMods = @{ Games = [List[Hashtable]]::new(); };
} Process {
  If ($PSCmdlet.ParameterSetName -eq 'GetMod') {
    [DirectoryInfo[]] $FoundGames = @();
    [DirectoryInfo[]] $Games = (Get-ChildItem -LiteralPath $ModIOPath -Directory);
    ForEach ($Game in $Games) {
      If ($CanUseGameName -and $CanUseGameNames) {
        If (-not $GameNames.ContainsKey($Game.Name)) {
          Write-Warning -Message "Failed to find game by id $($Game.Name) which is not specified in the cache";
        } ElseIf (-not $GameNames.ContainsValue($GameName)) {
          Write-Warning -Message "Failed to find game id in cache data by the name $($GameName)";
        } ElseIf ($GameNames[$Game.Name] -eq $GameName) {
          $FoundGames += $Game;
          Break;
        } Else {
          Write-Debug -Message "Skipping $($Game.Name)...";
        }
      } Else {
        $FoundGames += $Game;
      }
    }
    ForEach ($FoundGame in $FoundGames) {
      [string] $TempModStatePath = (Join-Path -Path $FoundGame -ChildPath 'state.json');
      [FileInfo] $ModStatePath = (Get-Item -LiteralPath $TempModStatePath -ErrorAction SilentlyContinue);
      If ($Null -eq $ModStatePath) {
        Write-Warning -Message "Mod.io game directory of $($FoundGame.Name) is not a valid directory. Skipping...";
        Continue;
      }
      [Hashtable] $ModStateData = (Get-Content -LiteralPath $ModStatePath | ConvertFrom-Json -Depth 100 -AsHashtable);
      If (-not $ModStateData.ContainsKey('mods')) {
        Write-Warning -Message "Mod.io game directory of $($FoundGame.Name)'s state data is not a valid state data file. Skipping...";
        Continue;
      }
      [int] $Index = 0;
      ForEach ($Mod in $ModStateData.mods.Values) {
        If (-not $Mod.ContainsKey('modObject') -or -not $Mod.modObject.ContainsKey('name') -or -not $Mod.modObject.ContainsKey('id')) {
          Write-Warning -Message "Mod.io game directory of $($FoundGame.Name)'s state data at index $($Index) is not a valid state data file. Skipping...";
          Continue;
        }
        [string] $CurrentModName = $Mod.modObject.name;
        [Regex] $ModNameRegex = [Regex]::new("$([Regex]::Escape($ModName).Replace('\*', '.*'))");
        # Write-Host -Object "`$CurrentModName = `"$CurrentModName`" | `$ModName = `"$ModName`" | `$ModNameRegex = `"$ModNameRegex`"";
        If ($ModNameRegex.IsMatch($CurrentModName)) {
          If (-not $Mod.ContainsKey('currentModfile') -or -not $Mod.currentModfile.ContainsKey('id') -or -not $Mod.currentModfile.ContainsKey('mod_id')) {
            Write-Warning -Message "Mod.io game directory of $($FoundGame.Name)'s state data at index $($Index) is not a valid state data file. Skipping...";
            Continue;
          }
          [DirectoryInfo] $FoundModDirectory = (Get-Item -LiteralPath (Join-Path -Path $FoundGame -ChildPath 'mods' -AdditionalChildPath @("$($Mod.currentModfile.mod_id)_$($Mod.currentModfile.id)")));
          [int] $GameIndex = 0;
          If ($Null -eq ($FoundMods.Games | Where-Object { $_.GameId -eq $FoundGame.Name })) {
            $GameIndex = $FoundMods.Length - 1;
            [Hashtable] $Data = @{
              GameId = $FoundGame.Name;
              GameName = $GameName;
              GameDirectory = $FoundGame;
              Mods = [List[Hashtable]]::new();
            };
            $FoundMods.Games.Add($Data);
          }
          If ($Null -eq ($FoundMods.Games[$GameIndex].Mods | Where-Object { $_.ModId -eq $Mod.modObject.id })) {
            [Hashtable] $Data = @{
              ModName = $CurrentModName;
              ModId = $Mod.modObject.id;
              ModDirectory = $FoundModDirectory;
              ModInfo = $Mod;
            };
            $FoundMods.Games[$GameIndex].Mods.Add($Data);
          }
        }
        $Index++;
      }
      Remove-Variable -Name 'Index';
    }
  } ElseIf ($PSCmdlet.ParameterSetName -eq 'Search') {
    [DirectoryInfo[]] $Games = (Get-ChildItem -LiteralPath $ModIOPath -Directory);
    ForEach ($Game in $Games) {

    }
  }
} End {
  Write-Output -NoEnumerate -InputObject $FoundMods;
}