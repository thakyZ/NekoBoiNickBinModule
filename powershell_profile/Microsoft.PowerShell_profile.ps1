using namespace System;
using namespace System.IO;
using namespace System.Linq;
using namespace System.Collections;
using namespace System.Collections.Generic;
using namespace System.Collections.ObjectModel;
using namespace System.Net;
using namespace System.Management.Automation;
using namespace System.Text;

# cSpell:word UGit, SlimFat, LinuxBrew, KeyGrip, KeyGrips, KeyInfo, Unhashed, Chocolatey, Choco, Adoptium, hotspot, IntelliJ, Millennias
# cSpell:ignore gpgconf, libexecdir, refreshenv, VsAppIdName, SBIE, tzst, vhdx, HKCR, squashfs
# cSpell:enableCompoundWords

Begin {
  Function Get-AllJavaVersions {
    [CmdletBinding()]
    [OutputType([Dictionary[[string],[FileSystemInfo]]])]
    Param()

    Begin {
      [Dictionary[[string],[FileSystemInfo]]] $Output = [Dictionary[[string],[FileSystemInfo]]]::new();
      [string[]] $PathsToCheck = @(
        (Join-Path -Path $env:ProgramFiles -ChildPath "Eclipse Adoptium"),
        (Join-Path -Path $env:ProgramFiles -ChildPath "Eclipse Foundation"),
        (Join-Path -Path $env:ProgramFiles -ChildPath "Java"),
        (Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Eclipse Adoptium"),
        (Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Eclipse Foundation"),
        (Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Java")
      );
    } Process {
      ForEach ($Path in $PathsToCheck) {
        If (-not (Test-Path -LiteralPath $Path)) {
          Continue;
        }

        ForEach ($Item in (Get-ChildItem -LiteralPath $Path -Directory)) {
          $JdkJre = ("$($Item.Name)" | Select-string -Pattern '^(jdk|jre)').Matches[0].Value;
          $Version = ("$($Item.Name)" -replace '^.{3}-?|(-hotspot)$','' -replace '_', '.');
          If ($Path.EndsWith("Java")) {
            $Output.Add("$($JdkJre)_$($Version)", $Item);
          } Else {
            $Output.Add("open_$($JdkJre)_$($Version)", $Item);
          }
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Update-PathVariable {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    Param(
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Default",
                 DontShow = $True)]
      [bool]
      $Default = $True
    )

    DynamicParam {
      [Dictionary[[string],[FileSystemInfo]]] $script:JavaVersions = (Get-AllJavaVersions);
      [ParameterAttribute] $ParameterAttribute = [ParameterAttribute]::new();
      $ParameterAttribute.ParameterSetName = "JavaVersion";
      $ParameterAttribute.Mandatory = $False;
      $ParameterAttribute.HelpMessage = "Provide a Java version to use and we'll try to find it."

      [ValidateSetAttribute] $ValidateSetAttribute = [ValidateSetAttribute]::new($script:JavaVersions.Keys);

      [Collection[Attribute]] $AttributeCollection = [Collection[Attribute]]::new();
      $AttributeCollection.Add($ParameterAttribute);
      $AttributeCollection.Add($ValidateSetAttribute);

      $DynamicParameter = [RuntimeDefinedParameter]::new("JavaVersion", [string], $AttributeCollection);
      $ParameterDictionary = [RuntimeDefinedParameterDictionary]::new();
      $ParameterDictionary.Add("JavaVersion", $DynamicParameter);
      Write-Output -NoEnumerate -InputObject $ParameterDictionary;
    } Begin {
      If ($PSCmdlet.ParameterSetName -eq "JavaVersion" -or $PSBoundParameters.ContainsKey("JavaVersion")) {
        $Default = $False;
      }

      [bool] $Errored = $False;
      [string]$_BasePath = $env:PATH;

      Try {
        [string[]]$PathsToPatch = @();

        [string]$MSBuildPath = ((Get-ChildItem -Path (Join-Path -Path $env:ProgramFiles -ChildPath "Microsoft Visual Studio") -Recurse -File -Filter "*.exe" | Where-Object { $_.BaseName.ToLower() -eq "msbuild" -and $_.FullName -match '[\\/]amd64[\\/]' }).Directory.FullName)

        [string[]]$PyEnvPaths = @(
          (Join-Path -Path $env:PYENV -ChildPath "versions" -AdditionalChildPath @($env:PYENV_VERSION)),
          (Join-Path -Path $env:PYENV -ChildPath "versions" -AdditionalChildPath @($env:PYENV_VERSION, "Scripts")),
          (Join-Path -Path $env:PYENV -ChildPath "bin"), (Join-Path -Path $env:PYENV -ChildPath "shims")
        );

        [string[]]$LocalPyEnvs = @();

        If (Test-Path -Path (Join-Path -Path $PWD -ChildPath ".env") -PathType Container) {
          $LocalPyEnvs = @(
            (Join-Path -Path $PWD -ChildPath ".env" -AdditionalChildPath @("Scripts")),
            (Join-Path -Path $PWD -ChildPath ".env" -AdditionalChildPath @("Lib")),
            (Join-Path -Path $PWD -ChildPath ".env" -AdditionalChildPath @("Include"))
          );
        }

        [string[]]$NvmPaths = @(
          $env:NVM_HOME,
          (Join-Path -Path $env:NVM_HOME -ChildPath "node")
        );

        [string[]]$JavaPaths = @(
          (Join-Path -Path $env:ProgramFiles -ChildPath "JetBrains" -AdditionalChildPath @("IntelliJ IDEA Community Edition", "bin"))
        );

        If ($PSCmdlet.ParameterSetName -eq "JavaVersion") {
          $JavaPaths += (Join-Path -Path $script:JavaVersions[$PSBoundParameters.JavaVersion] -ChildPath "bin");
        }

        $PathsToPatch += $MSBuildPath;
        $PathsToPatch += $PyEnvPaths;
        $PathsToPatch += $LocalPyEnvs;
        $PathsToPatch += $NvmPaths;
        $PathsToPatch += $JavaPaths;

        If ($Null -eq (Get-Variable -Scope Global -Name "BasePath" -ErrorAction SilentlyContinue)) {
          Set-Variable -Scope Global -Name "BasePath" -ErrorAction Continue -Value $_BasePath
        } Else {
          If ($global:BasePath -ne $_BasePath) {
            Set-Variable -Scope Global -Name "BasePath" -ErrorAction Continue -Value $_BasePath
          }
        }
      } Catch {
        Write-Error -ErrorRecord $_ | Out-Host;
        $Errored = $True;
      }
    } Process {
      Try {
        [string[]]$OutputPaths = @();
        [string[]]$Paths = @($_BasePath -split ':');
        ForEach ($PathToPatch in $PathsToPatch) {
          If ($Paths -notcontains $PathToPatch) {
            $OutputPaths += $PathToPatch
          }
        }
      } Catch {
        Write-Error -ErrorRecord $_ | Out-Host;
        $Errored = $True;
      }
    } End {
      Try {
        $OutputPaths += "$global:BasePath";
        $env:PATH = ($OutputPaths -join ';');
      } Catch {
        Write-Error -ErrorRecord $_ | Out-Host;
        $Errored = $True;
      }
    } Clean {
      If ($Errored) {
        $env:PATH = $_BasePath;
      }
      Clear-Variable -Scope "Script" -Name "JavaVersions";
      Remove-Variable -Scope "Script" -Name "JavaVersions";
    }
  }

  Function Expand-string {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True)]
      [string]
      $String
    )

    Begin {
      [string] $Output = $Null;
    } Process {
      $Output = $ExecutionContext.InvokeCommand.Expandstring($String);
      Try {
        $Output = (Get-Item -LiteralPath $Output);
      } Catch {
        Write-Error -ErrorRecord $_;
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Expand-ZipFile {
    [CmdletBinding(DefaultParameterSetName = "PSPath")]
    Param(
      [Parameter(Mandatory = $False,
                 Position = 0,
                 ValueFromPipeline = $True,
                 ParameterSetName = "PSPath",
                 HelpMessage = "One or more paths to compressed file(s). Supports ")]
      [SupportsWildcards()]
      [AllowNull()]
      [Alias("PSPath")]
      [string[]]
      $Path = @(),
      [Parameter(Mandatory = $False,
                 Position = 0,
                 ValueFromPipeline = $True,
                 ParameterSetName = "PSLiteralPath",
                 HelpMessage = "One or more paths to compressed file(s).")]
      [AllowNull()]
      [Alias("PSLiteralPath")]
      [string[]]
      $LiteralPath = @(),
      [Parameter(Mandatory = $false,
                 HelpMessage = "Password for the zip file to decompress it.")]
      [AllowNull()]
      [Alias("Password","Pin")]
      [string]
      $Pass = $Null,
      [Parameter(Mandatory = $False,
                 HelpMessage = "Opens a 7zip window for decompression instead of cli.")]
      [Alias("GUI")]
      [switch]
      $CreateWindow = $False,
      [Parameter(Mandatory = $False,
                 HelpMessage = "Use native decompression instead of 7zip")]
      [Alias("Native")]
      [switch]
      $UseNative = $False,
      [Parameter(Mandatory = $False,
                 HelpMessage = "Move the created folder from decompression to the current working directory.")]
      [Alias("MoveRecurse","MVR","MoveRecurseOutput")]
      [switch]
      $MoveRecurseAfter = $False
    )

    Begin {
      [string[]] $Supported7ZipExtensions = @('7z','zip','rar','001','cab','iso','xz','txz','lzma','tar','cpio','bz2','bzip2','tbz2','tbz','gz','gzip','tgz','tpz','zst','tzst','z','taz','lzh','rpm','deb','arj','vhd','vhdx','wim','swm','esd','fat','ntfs','dmg','nfs','xar','squashfs','apfs');
      [Regex] $Supported7ZipFileMatch = [Regex]::new("\.($([string]::Join("|",$Supported7ZipExtensions)))$", [RegularExpressions.RegexOptions]::OrdinalIgnoreCase);
      [string[]] $Arguments = @();
      [ApplicationInfo] $7Zip = $Null;
      If (-not $UseNative) {
        If ($CreateWindow) {
          $7zip = (Get-Command -Name "7zfm" -ErrorAction SilentlyContinue);
          If ($Null -ne $7zip) {
            Throw "7-zip not found on system path.";
          }
          $Arguments = @("x");
        } Else {
          $7zip = (Get-Command -Name "7z" -ErrorAction SilentlyContinue);
          If ($Null -ne $7zip) {
            Throw "7-zip not found on system path.";
          }
          $Arguments = @("x");
        }
      }
      [string[]] $ParsedPaths = @();
      If ($PSCmdlet.ParameterSetName -eq "PSPath") {
        If (($Path -is [string] -and (Test-NullOrEmptyOrWhiteSpace -string $Path)) -or ($Path -is [string[]] -and $Path.Count -eq 0)) {
          ForEach ($PathItem in (Get-ChildItem -LiteralPath $PWD -File | Where-Object { $Supported7ZipFileMatch.IsMatch($_.Extension) })) {
            $ParsedPaths += [WildcardPattern]::Escape($PathItem);
          }
        } Else {
          ForEach ($PathItem in $Path) {
            Write-Host "`$PathItem.GetType().FullName = `"$($PathItem.GetType().FullName)`"";
            ForEach ($Item in (Get-ChildItem -Path $PathItem)) {
              $ParsedPaths += $Item;
            }
          }
        }
      } Else {
        ForEach ($PathItem in $LiteralPath) {
          $ParsedPaths += [WildcardPattern]::Escape($PathItem);
        }
      }
      [FileSystemInfo[]] $OutputFile = @();
    } Process {
      ForEach ($PathItem in $ParsedPaths) {
        If (-not $UseNative) {
          If (-not (Test-NullOrEmptyOrWhiteSpace -string $Pass)) {
            $Arguments += "-p`"$Pass`"";
          } ElseIf ($PSBoundParameters.ContainsKey("Pass") -or $PSBoundParameters.ContainsKey("Password")) {
            $Arguments += "-p`"$(ConvertFrom-Base64 -string "a2ltb2NoaS5pbmZv")`"";
          }

          # Double-check that we got a file.
          If (Test-NullOrEmptyOrWhiteSpace -string $PathItem) {
            Throw "Failed to find file at $PWD that matches zip|tar|tar.gz|tar.bz|tar.xz|rar|7z";
          }

          $Arguments += $PathItem;
          $Process = (Start-Process -FilePath $7Zip -Wait -NoNewWindow -ArgumentList $Arguments -PassThru);

          If ($Process.ExitCode -ne 0) {
            Throw "Failed to run 7-zip, got exit code $($Process.ExitCode)";
          } Else {
            Write-Debug -Object "[DBG] 7z Exit Code: $($Process.ExitCode)";
          }
        } Else {
          $OutputFile += (Expand-Archive -Path $PathItem -ErrorAction Stop);
        }
      }
    } End {
      If ($MoveRecurseAfter) {
        Move-ItemRecurse -LiteralPath (Get-ChildItem -Path $PWD -Directory)[0].FullName $PWD -RemoveFolder
      }
    }
  }

  Function Get-HashtableIterator {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([KeyPairValue[[object],[object]][]])]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "The hashtable to get the iterator of.")]
      [Hashtable]
      $Hashtable
    )

    Begin {
      [KeyPairValue[[object],[object]][]]`
      $Output = @();
    } Process {
      ForEach ($Key in $Hashtable.Keys) {
        $Value = $Hashtable.Item($Key);
        $Output += [KeyPairValue[[object],[object]]]::new($Key, $Value);
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Test-HashtableContainsKey {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([bool])]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "The hashtable to test against.")]
      [Hashtable]
      $Hashtable,
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "The keys to test if are in hashtable.")]
      [Object[]]
      $Keys
    )

    Begin {
      [bool] $Output = $False;
    } Process {
      ForEach ($Key in $Keys) {
        If ($Hashtable.ContainsKey($Key)) {
          $Output = $True;
          Break;
        } Else {
          ForEach ($Item in (Get-HashtableIterator -Hashtable $Hashtable)) {
            If ($Item.Key.Equals($Key)) {
              $Output = $True;
              Break;
            }
          }
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Test-ArrayContainsValue {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([bool])]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "The array to test against.")]
      [Object[]]
      $Array,
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "The values to test if are in array.")]
      [Object[]]
      $Values
    )

    Begin {
      [bool] $Output = $False;
    } Process {
      ForEach ($Value in $Values) {
        If ($Array -contains $Value) {
          $Output = $True;
          Break;
        } Else {
          ForEach ($Item in $Array) {
            If ($Item.Equals($Value)) {
              $Output = $True;
              Break;
            }
          }
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Import-ExitWithCode {
    [CmdletBinding()]
    Param()

    Begin {
      [bool] $DoNothing = $False;
      If ($Null -ne (Get-Command -Name "Exit-WithCode" -ErrorAction SilentlyContinue)) {
        $DoNothing = $True;
      }
      [string]   $ExitWithCode = "";
      [string[]] $PathSplit = @();
      If ($IsWindows) {
        $PathSplit = ($env:Path -split ";");
      } Else {
        $PathSplit = ($env:Path -split ":");
      }
    }
    Process {
      If ($DoNothing -eq $False) {
        ForEach ($Item in $PathSplit) {
          $ToFind = (Get-ChildItem -LiteralPath $Item -File -ErrorAction SilentlyContinue | Select-Object -Property BaseName | Where-Object { $_ -eq "Exit-WithCode" });
          If ($Null -ne $ToFind) {
            $ExitWithCode = $ToFind.FullName;
          }
        }
      }
    } End {
      If ($DoNothing -eq $False) {
        If ($ExitWithCode -ne "" -and $Null -ne $ExitWithCode) {
          . "$($ExitWithCode)";
        } Else {
          Write-Warning -Message "PowerShell cmdlet Exit-WithCode was not found on the system path.";
        }
      }
    }
  }

  Function Get-ProfileConfig() {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param(
      [Parameter(Mandatory = $False,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "Specifies a custom profile directory. (Is Optional)")]
      [AllowNull()]
      [string]
      $ProfileDirectory = $Null
    )

    Begin {
      If ([string]::IsNullOrEmpty($ProfileDirectory)) {
        $ProfileDirectory = $global:ProfileDirectory;
      }

      $Returned = $Null;
      $ConfigPath = (Join-Path -Path $ProfileDirectory -ChildPath "config.json");
    } Process {
      Try {
        $ConfigText = (Get-Content -LiteralPath $ConfigPath -ErrorAction SilentlyContinue);
        $Returned = ($ConfigText | ConvertFrom-Json -AsHashtable);
      } Catch {
        If ($_.Exception.Message -match ".*Access to the path '.*' is denied\.") {
          Write-Output -NoEnumerate -InputObject ([Hashtable]::new());
        } Else {
          Write-Error -Exception $_.Exception -Message "Failed to load the PowerShell profile config at, $($ConfigPath)"
          Exit 1;
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Returned;
    }
  }

  Function Test-ScoopOnPath() {
    [CmdletBinding()]
    [OutputType([bool])]
    Param()

    Begin {
      [bool] $Output = $False;
    } Process {
      If ($Null -ne (Get-Command -Name "scoop" -ErrorAction SilentlyContinue)) {
        $Output = $True
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Test-HomebrewOnPath() {
    [CmdletBinding()]
    [OutputType([bool])]
    Param()

    Begin {
      [bool] $Output = $False;
    } Process {
      If ($Null -ne (Get-Command -Name "brew" -ErrorAction SilentlyContinue)) {
        $Output = $True
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Import-Ugit() {
    [CmdletBinding()]
    Param()

    Process {
      $UgitModule = (Get-Module -Name "ugit" -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1);
      If ($UgitModule) {
        $UgitModule | Import-Module;
      } Else {
        Throw "Failed to import ugit.";
      }
    }
  }

  Function Import-PSProfile {
    [CmdletBinding()]
    Param()

    Process {
      $PSProfileModule = (Get-Module -Name "PSProfile" -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1);
      If ($PSProfileModule) {
        $PSProfileModule | Import-Module;
      } Else {
        Throw "Failed to import PSProfile.";
      }
    }
  }

  Function Import-PoshGit() {
    [CmdletBinding()]
    Param()

    Process {
      $PoshGitModule = Get-Module posh-git -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1;

      If ($PoshGitModule) {
        $PoshGitModule | Import-Module;
      } ElseIf (Test-HomebrewOnPath) {
        If (Test-Path -LiteralPath "$HOME/.local/share/powershell/Modules/posh-git/1.1.0/posh-git.psd1") {
          Import-Module $ModulePath;
        }
      } ElseIf (Test-ScoopOnPath) {
        If (Test-Path -LiteralPath ($ModulePath = (Join-Path -Path (Split-Path -Path "$(scoop prefix posh-git)") -ChildPath (Join-Path -Path "current" -ChildPath "posh-git.psd1")))) {
          Import-Module $ModulePath;
        }
      } Else {
        Throw "Failed to import posh-git.";
      }
    }
  }

  Function Import-OhMyPosh() {
    [CmdletBinding()]
    Param()

    Process {
      $ModulePath = (Get-Command -Name "oh-my-posh" -ErrorAction SilentlyContinue);
      $OhMyPoshTheme = "slimfat";

      If ($Null -eq $ModulePath) {
        Throw "Oh My Posh does not exist on path!"
      } ElseIf ((Test-HomebrewOnPath) -and $IsLinux) {
        If ((Test-Path -LiteralPath "/home/linuxbrew/.linuxbrew/bin/oh-my-posh") -and (Test-Path -LiteralPath "/home/linuxbrew/.linuxbrew/opt/oh-my-posh/themes/$($OhMyPoshTheme).omp.json")) {
          & "$($ModulePath.Source)" init pwsh --config "/home/linuxbrew/.linuxbrew/opt/oh-my-posh/themes/$($OhMyPoshTheme).omp.json" | Invoke-Expression;
        }
      } ElseIf (Test-ScoopOnPath) {
        If ((Test-Path -LiteralPath (Join-Path -Path "$(scoop prefix oh-my-posh)" -ChildPath "oh-my-posh.exe")) -and (Test-Path -LiteralPath (Join-Path -Path "$(scoop prefix oh-my-posh)" -ChildPath "themes" -AdditionalChildPath "$($OhMyPoshTheme).omp.json"))) {
          (& "$($ModulePath.Source)" init pwsh --config "$(scoop prefix oh-my-posh)\themes\$($OhMyPoshTheme).omp.json") | Invoke-Expression;
        }
      } Else {
        Throw "Failed to import oh-my-posh.";
      }
    }
  }

  Function Write-DebugObject() {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "Object(s)")]
      [object]
      $Object
    )

    Begin {
      [string[]] $_sb = @();
    } Process {
      If ($Object -is [Object[]]) {
        ForEach ($Item in $Object) {
          $_sb += $Item.Tostring();
        }
      } Else {
        $_sb += $Object.Tostring();
      }
    } End {
      Write-Debug -Message ($_sb -join "`n");
    }
  }

  Function Start-GnuPGAgent() {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
      # Path to the GnuPG Connect Agent
      [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Path to the GnuPG Connect Agent")]
      [string[]]
      $GpgConnectAgent,
      # Path to the GnuPG Agent
      [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Path to the GnuPG Agent")]
      [string[]]
      $GpgAgent
    )

    Begin {
      [bool] $Output = $False;
    } Process {
      If ($Null -ne (Get-Process -Name "$((Get-Item -LiteralPath $GpgAgent).BaseName)" -ErrorAction SilentlyContinue)) {
        $Output = $True;
      } Else {
        $Array = (& "$($GpgConnectAgent)" "/bye" 2>&1);

        Write-Host -Object "Start-GnuPGAgent:`n[$($Array.GetType().FulleName)] `$Array = " | Out-Host;
        Write-Output -InputObject $Array | Out-Host;

        If ($Array.Length -ge 3 -and $Array[-1] -match ".*connection to the agent established$") {
          Write-Debug -Message "The GPG Agent has been started.";

          $Output = $True;
        } Else {
          Write-Error -Message "Failed to start the GPG Agent.";
          Write-DebugObject -Object $Array;

          $Output = $False;
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Test-KeyCached() {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param(
      # Path to the GnuPG Connect Agent
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "Path to the GnuPG Connect Agent")]
      [Alias("Path", "LiteralPath")]
      [string]
      $GpgConnectAgent,
      # Path to the GnuPG Connect Agent
      [Parameter(Mandatory = $True,
                 Position = 1,
                 HelpMessage = "Path to the GnuPG Connect Agent")]
      [string]
      $Gpg,
      [Parameter(Mandatory = $False,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "Specifies a custom config element. (Is Optional)")]
      [AllowNull()]
      [Hashtable]
      $Config
    )

    Begin {
      [Hashtable] $Output = @{
        Items = @();
        Item1 = $True;
        Item2 = $True;
      };

      If ($Null -eq $Config) {
        $Config = (Get-ProfileConfig);
      }
    } Process {
      Try {
        [string]   $FingerPrint = [string]::Join(" ", @("&",(Get-Quoted -string $Gpg),"--fingerprint",'--with-keygrip',(Get-Quoted -string $Config.gnupg.email)));
        [string[]] $KeyGrips = ((Invoke-Expression -Command $FingerPrint) | Select-string "Keygrip" | ForEach-Object { Return ($_ -split "\s+")[3]; });

        Invoke-ThrowIfEmptyNullOrInvalid -Value $KeyGrips -Name "KeyGrips";

        [string]   $KeyInfoCmd = [string]::Join(" ", @("&",(Get-Quoted -string $GpgConnectAgent),"-q",'"KeyInfo --list"','"/bye"','2>&1'));
        [string[]] $KeyInfo = ((Invoke-Expression -Command $KeyInfoCmd) | Select-string "KEYINFO" | ForEach-Object { Return ($_ -split "\s+")[6]; });

        Invoke-ThrowIfEmptyNullOrInvalid -Value $KeyInfo -Name "KeyInfo" -OtherValue $KeyGrips -OtherName "KeyGrips";

        [PSCustomObject] $Iterator = ($KeyGrips | Select-Object -Property @(
          @{
            Name = "Value";
            Expression = {
              Return $_.Tostring();
            }
          },
          @{
            Name = "Index";
            Expression = {
              Return $KeyGrips.IndexOf($_) + 1;
            }
          }
        ));

        ForEach ($KeyGrip in $Iterator) {
          $KeyInfo = $KeyInfo[$KeyGrip.Index];
          $Output.Items += $KeyGrip.Value;
          If ($KeyInfo -eq "-") {
            If ($KeyGrip.Index -eq 1) {
              $Output.Item1 = $False;
            } ElseIf ($KeyGrip.Index -eq 2) {
              $Output.Item2 = $False;
            } ElseIf ($KeyGrip.Index -gt 2) {
              $Output["Item$($KeyGrip.Index)"] = $False;
            }
          } Else {
            If ($KeyGrip.Index -gt 2) {
              $Output["Item$($KeyGrip.Index)"] = $True;
            }
          }
        }
      } Catch {
        Write-Error -ErrorRecord $_ | Out-Host;
        Throw;
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Get-UnhashedPassword() {
    [CmdletBinding(DefaultParameterSetName = "Password")]
    [OutputType([string])]
    Param(
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Set",
                 HelpMessage = "Set the user config's password.")]
      [Switch]
      $Set,
      [Parameter(Mandatory = $False,
                 Position = 0,
                 ParameterSetName = "Password",
                 ValueFromPipeline = $True,
                 HelpMessage = "A secure string to get the unhashed password of.")]
      [AllowNull()]
      [Securestring]
      $Password = $Null
    )

    Begin {
      [string] $Output = [string]::Empty;
      If ($Null -ne $script:Config -and ($Set -or ($script:Config.gnupg.password_hashed -eq "" -and $Null -ne $Password)) -and ($Null -ne (Get-Variable -Scope Script -Name 'Config' -ErrorAction SilentlyContinue))) {
        $Secure = (Read-Host -AsSecurestring -Prompt "Insert Password");
        $Encrypted = (ConvertFrom-SecureString -Securestring $Secure);
        $script:Config.gnupg.password_hashed = $Encrypted;

        Set-Content -LiteralPath (Join-Path -Path (Get-Item -LiteralPath $Profile).Directory.FullName -ChildPath "config.json") -InputObject ($script:Config | ConvertTo-Json -Depth 100);
      }
    } Process {
      If (-not $Set) {
        If ($Null -ne $script:Config -and $Null -ne $script:Config.gnupg -and $Null -ne $script:Config.gnupg.password_hashed -and $Null -eq $Password) {
          $Password = (ConvertTo-SecureString -string $script:Config.gnupg.password_hashed);
        }
        $Output = ([System.Net.NetworkCredential]::new([string]::Empty, $Password)).Password;
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Invoke-CacheKey() {
    [CmdletBinding()]
    Param(
      # Path to the GnuPG Preset Pass Command
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "Path to the GnuPG Preset Pass Command")]
      [Alias("Path", "LiteralPath")]
      [string]
      $GpgPresetPass,
      # The keygrips to cache.
      [Parameter(Mandatory = $True,
                 Position = 1,
                 HelpMessage = "The keygrips to cache.")]
      [Alias("Item", "KeyGrip", "KeyGrips")]
      [string[]]
      $Items
    )

    Process {
      ForEach ($Item in $Items) {
        [object] $Output
        Try {
          $Test = "-P `"$(Get-UnhashedPassword)`"";
          $Output = (Invoke-Expression -Command "& `"$($GpgPresetPass)`" --preset $Test `"$($Item)`"");
        } Catch {
          Write-Error -Message "Failed to preset passphrase.";
          Write-Debug -Message "$($Output)";
          Write-Error -ErrorRecord $_;
          Throw;
        }
      }
    }
  }

  Function Get-GnupgPath() {
    [CmdletBinding()]
    [OutputType([Hashtable[]])]
    Param(
      [Parameter(Mandatory = $False,
                 Position = 0,
                 HelpMessage = "CurrentPath")]
      [string]
      $Path = ""
    )

    Begin {
      If (-not (Test-NullOrEmptyOrWhiteSpace -String $Path)) {
        If ($IsWindows) {
          $env:PATH = "$($Path);$($env:PATH)";
        } Else {
          $env:PATH = "$($env:PATH):$($Path)";
        }
      }
    } Process {
      [System.Management.Automation.ApplicationInfo]`
      $GpgConnectAgent = (Get-Command -Name "gpg-connect-agent" -ErrorAction SilentlyContinue);
      [System.Management.Automation.ApplicationInfo]`
      $Gpg = (Get-Command -Name "gpg" -ErrorAction SilentlyContinue);
      [System.Management.Automation.ApplicationInfo]`
      $GpgConf = (Get-Command -Name "gpgconf" -ErrorAction SilentlyContinue);
      [System.Management.Automation.ApplicationInfo]`
      $GpgAgent = (Get-Command -Name "gpg-agent" -ErrorAction SilentlyContinue);
      [System.Management.Automation.ApplicationInfo]`
      $GpgPresetPass = (Get-Command -Name "gpg-preset-passphrase" -ErrorAction SilentlyContinue);

      If ($Null -eq $GpgConnectAgent) {
        $GpgConnectAgent = @{ Source = $False };
      }

      If ($Null -eq $Gpg) {
        $Gpg = @{ Source = $False };
      }

      If ($Null -eq $GpgConf) {
        $GpgConf = @{ Source = $False };
      }

      If ($Null -eq $GpgAgent) {
        $GpgAgent = @{ Source = $False };
      }

      If ($Null -eq $GpgPresetPass) {
        $GpgPresetPass = @{ Source = $False };
      }
    } End {
      Write-Output -NoEnumerate -InputObject @($GpgConnectAgent, $Gpg, $GpgConf, $GpgAgent, $GpgPresetPass);
    }
  }

  Function Test-GnupgOnPath() {
    [CmdletBinding()]
    [OutputType([Hashtable[]])]
    Param(
      [Parameter(Mandatory = $False,
                 Position = 0,
                 HelpMessage = "CurrentPath")] # TODO: Better help message.
      [string]
      $Path = "",
      [Parameter(Mandatory = $False,
                 Position = 0,
                 HelpMessage = "Current Iteration Step")]
      [int]
      $Step = 0
    )

    Begin {
      [int] $MaxSteps = 2;

      If ($Step -gt $MaxSteps) {
        Throw "Failed to find GnuPG tools."
      }

      If ($Path -ne "" -and $Null -ne $Path) {
        $env:PATH = $Path;
      }
    } Process {
      $Gnupg = (Get-GnupgPath -Path $Path);

      $GpgConnectAgent = $Gnupg[0];
      $Gpg = $Gnupg[1];
      $GpgConf = $Gnupg[2];
      $GpgAgent = $Gnupg[3];
      $GpgPresetPass = $Gnupg[4];

      If (-not (Test-Path -LiteralPath $GpgConnectAgent.Source -PathType Leaf) -or
        -not (Test-Path -LiteralPath $GpgAgent.Source -PathType Leaf) -or
        -not (Test-Path -LiteralPath $GpgPresetPass.Source -PathType Leaf) -or
        -not (Test-Path -LiteralPath $Gpg.Source -PathType Leaf)) {
        If (Test-ScoopOnPath -and $Step -eq 0) {
          $Path = "$($env:PATH)$([System.IO.Path]::PathSeparator)$(scoop prefix gnupg)";
          Test-GnupgOnPath -Path $Path -Step ($Step + 1);
        } ElseIf ((Test-Path -Path (Join-Path -Path $HOME -ChildPath "scoop" -AdditionalChildPath @("apps", "gnupg", "current", "bin"))) -and $Step -eq 1) {
          $Path = "$($env:PATH)$([System.IO.Path]::PathSeparator)$(Join-Path -Path "$HOME" -ChildPath "scoop" -AdditionalChildPath @("apps", "gnupg", "current", "bin"))";
          Test-GnupgOnPath -Path $Path -Step ($Step + 1);
        } ElseIf ($GpgConf -ne $False -and (Test-Path -Path "$(& "$GpgConf" --list-dirs "libexecdir")") -and $Step -ge 0) {
          $Path = "$($env:PATH)$([System.IO.Path]::PathSeparator)$(& "$GpgConf" --list-dirs "libexecdir")";
          Test-GnupgOnPath -Path $Path -Step ($Step + 1);
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Gnupg;
    }
  }

  Function Import-GnuPGKey() {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $False,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "Specifies a custom config element. (Is Optional)")]
      [AllowNull()]
      [Hashtable]
      $Config
    )

    Begin {
      [string] $ScriptRoot = $PSScriptRoot;

      If ([string]::IsNullOrEmpty($ScriptRoot)) {
        $ScriptRoot = (Get-Location);
      }

      If ($Null -eq $Config) {
        $Config = (Get-ProfileConfig);
      }
    } Process {
      $Gnupg = (Test-GnupgOnPath);
      $GpgConnectAgent = $Gnupg[0];
      $Gpg = $Gnupg[1];
      $GpgAgent = $Gnupg[3];
      $GpgPresetPass = $Gnupg[4];
    } End {
      Try {
        If (Start-GnuPGAgent -GpgConnectAgent $GpgConnectAgent.Source -GpgAgent $GpgAgent.Source) {
          [Hashtable] $CacheKeyInfo = (Test-KeyCached -GpgConnectAgent $GpgConnectAgent.Source -Gpg $Gpg.Source)
          If (-not $CacheKeyInfo.Item1 -or -not $CacheKeyInfo.Item2) {
            Invoke-CacheKey -Path $GpgPresetPass -Items $CacheKeyInfo.Items;
          }
        }
      } Catch {
        Write-Error -ErrorRecord $_ | Out-Host;
        Throw;
      }
    }
  }

  Function Get-BaseVariables {
    [CmdletBinding()]
    Param()

    Begin {
      $Scopes = @("Script", "Local", "Global");
      $Output = @{};
    } Process {
      ForEach ($Scope in $Scopes) {
        $Output += @{ "$($Scope)" = (Get-Variable -Scope "$($Scope)"); };
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Add-PSDrives {
    [CmdletBinding()]
    Param()

    Begin {
      $Drives = @(
        @{ PSProvider = "registry"; Root = "HKEY_CLASSES_ROOT"; Name = "HKCR" }
      )
    } Process {
      ForEach ($Drive in $Drives) {
        Try {
          New-PSDrive -PSProvider $Drive.PSProvider -Root $Drive.Root -Name $Drive.Name | Out-Null;
        } Catch {
          Write-Host -ForegroundColor Red -Object "Failed to add PSDrive with name $($Drive.Name), root $($Drive.Root), and provider $($Drive.PSProvider)"
          Throw;
        }
      }
    }
  }

  Function Get-Quoted() {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "string input value to wrap in quotes")]
      [AllowNull()]
      [string]
      $String,
      [Parameter(Mandatory = $False,
                 HelpMessage = "Use single quotes instead of double.")]
      [Switch]
      $Single = $False
    )

    Begin {
      [string] $Output = $Null;
    } Process {
      If ($Single) {
        $Output = "'$($String)'";
      } Else {
        $Output = "`"$($String)`"";
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Test-NullOrEmptyOrWhiteSpace() {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "string input value to test against")]
      [AllowEmptystring()]
      [string[]]
      $String
    )

    Begin {
      [bool] $Output = $False;
    } Process {
      $Output = ([string]::IsNullOrEmpty($String) -or [string]::IsNullOrWhiteSpace($String));
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Invoke-ThrowIfEmptyNullOrInvalid {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 ParameterSetName = "Default",
                 HelpMessage = "An array to test if is null or empty.")]
      [Parameter(Mandatory = $True,
                 ValueFromPipeline = $True,
                 ParameterSetName = "Other",
                 HelpMessage = "An array to test if is null or empty.")]
      [AllowNull()]
      [object[]]
      $Value,
      [Parameter(Mandatory = $True,
                 Position = 1,
                 ParameterSetName = "Default",
                 HelpMessage = "Name of the array variable.")]
      [Parameter(Mandatory = $True,
                 ParameterSetName = "Other",
                 HelpMessage = "Name of the array variable.")]
      [ValidateNotNullOrEmpty()]
      [ValidateNotNullOrWhiteSpace()]
      [string]
      $Name,
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Default",
                 HelpMessage = "Length to check against.")]
      [int]
      $Length = 0,
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Other",
                 HelpMessage = "Test the length of this array variable with another.")]
      [ValidateNotNull()]
      [object[]]
      $OtherValue,
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Other",
                 HelpMessage = "Name of the other array variable.")]
      [ValidateNotNullOrEmpty()]
      [ValidateNotNullOrWhiteSpace()]
      [string]
      $OtherName
    )

    Process {
      If ($Null -eq $Value) {
        Throw "$($Name) is a null value.";
      }
      If ($PSCmdlet.ParameterSetName -eq "Default" -and $Value.Length -eq $Length) {
        Throw "$($Name) has a length of 0";
      }
      If ($PSCmdlet.ParameterSetName -eq "Other" -and $Value.Length -eq $OtherValue.Length) {
        Throw "$($Name) does not have an equal length to that of the array $($OtherName)";
      }
    }
  }

  Function Invoke-ParseValue {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
      [Parameter(Mandatory = $True,
                 HelpMessage = "Value to parse into full command.")]
      [string]
      $Value
    )

    Begin {
      [string] $Output = $Null;
    } Process {
      # TODO: Add more methods later as it is needed.
      If ($Value -notmatch '[\\/]' -and $Value -match '\.(?:ps1|bat|sh|bash|zsh|cmd)$') {
        [CommandInfo] $Command = (Get-Command -Name $Value -ErrorAction SilentlyContinue);
        If ($Null -eq $Command -or $Null -eq $Command) {
          $Output = $Value;
        } ElseIf ($Null -ne $Command.Source) {
          $Output = $Output.Source;
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  Function Add-Aliases {
    [CmdletBinding()]
    Param()

    Process {
      Try {
        If ($Null -ne $script:Config.Aliases) {
          [PSCustomObject] $Iterator = ($script:Config.Aliases | Select-Object -Property @(
            @{
              Name = "Key";
              Expression = {
                Return ($_ | Get-Member | Where-Object {
                  Return $_.MemberType -eq "NoteProperty";
                } | Select-Object -First 1).Name;
              };
            },
            @{
              Name = "Value";
              Expression = {
                Return ($_.PSObject.Properties | Where-Object { Return $_.MemberType -eq "NoteProperty"; } | Select-Object -First 1).Value;
              };
            }
          ));
          ForEach ($KeyValuePair in $Iterator) {
            If ($Null -ne (Get-Alias -Name $KeyValuePair.Key -ErrorAction "SilentlyContinue") -and -not (Get-Alias -Name $KeyValuePair.Key -ErrorAction "SilentlyContinue").Definition.Contains($KeyValuePair.Value)) {
              Remove-PSProfileCommandAlias -Alias $KeyValuePair.Key -Save -Verbose -Debug;
              Remove-Alias -Name $KeyValuePair.Key -Verbose -Debug;
            }
            If ($Null -eq (Get-Alias -Name $KeyValuePair.Key -ErrorAction "SilentlyContinue")) {
              Add-PSProfileCommandAlias -Alias $KeyValuePair.Key -Command (Invoke-ParseValue -Value $KeyValuePair.Value);
            }
          }
        }
      } Catch {
        Write-Error -ErrorRecord $_;
      }
    }
  }

  Function Get-TimeStampDifference {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ValueFromPipeline = $True,
                 HelpMessage = "The first timestamp to compare to.")]
      [ValidateNotNull()]
      [DateTimeOffset]
      $First,
      [Parameter(Mandatory = $False,
                 Position = 1,
                 HelpMessage = "The second timestamp to compare to. Defaults to now.")]
      [ValidateNotNull()]
      [DateTimeOffset]
      $Second = [DateTimeOffset]::Now
    )

    Begin {
      [long] $Difference = ($Second.ToUnixTimeMilliseconds() - $First.ToUnixTimeMilliseconds());
      If ($Difference -lt $global:TimeLengths["Seconds"]) {
        Return "$($Difference)ms"
      } ElseIf ($Difference -ge $global:TimeLengths["Seconds"]  -and $Difference -lt $global:TimeLengths["Minutes"]) {
        Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Seconds"]))s"
      } ElseIf ($Difference -ge $global:TimeLengths["Minutes"]  -and $Difference -lt $global:TimeLengths["Hours"]) {
        Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Minutes"]))m"
      } ElseIf ($Difference -ge $global:TimeLengths["Hours"]    -and $Difference -lt $global:TimeLengths["Days"]) {
          Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Hours"]))h";
      } ElseIf ($Difference -ge $global:TimeLengths["Days"]     -and $Difference -lt $global:TimeLengths["Weeks"]) {
          Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Days"])) days";
      } ElseIf ($Difference -ge $global:TimeLengths["Weeks"]    -and $Difference -lt $global:TimeLengths["Months"]) {
          Return "$([Math]::Ceiling($Difference /  $global:TimeLengths["Weeks"])) weeks";
      } ElseIf ($Difference -ge $global:TimeLengths["Months"]   -and $Difference -lt $global:TimeLengths["Years"]) {
          Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Months"])) months";
      } ElseIf ($Difference -ge $global:TimeLengths["Years"]    -and $Difference -lt $global:TimeLengths["Decades"]) {
          Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Years"])) months";
      } ElseIf ($Difference -ge $global:TimeLengths["Decades"]   -and $Difference -lt $global:TimeLengths["Centuries"]) {
          Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Decades"])) decades";
      } ElseIf ($Difference -ge $global:TimeLengths["Centuries"] -and $Difference -lt $global:TimeLengths["Millennias"]) {
          Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Centuries"])) centuries";
      } ElseIf ($Difference -ge $global:TimeLengths["Millennias"]) {
          Return "$([Math]::Ceiling($Difference / $global:TimeLengths["Millennias"])) millenias";
      }
    }
  }

  Function Get-TimeLengths {
    [CmdletBinding()]
    [OutputType([Dictionary[string, Long]])]
    Param()

    Begin {
      [Dictionary[string, Long]] $TimeLengths = [Dictionary[string, Long]]::new();
    } Process {
      $TimeLengths.Add("Milliseconds", 1);
      $TimeLengths.Add("Seconds"     , 1000 * $TimeLengths["Milliseconds"]);
      $TimeLengths.Add("Minutes"     , 60   * $TimeLengths["Seconds"]);
      $TimeLengths.Add("Hours"       , 60   * $TimeLengths["Minutes"]);
      $TimeLengths.Add("Days"        , 24   * $TimeLengths["Hours"]);
      $TimeLengths.Add("Weeks"       , 7    * $TimeLengths["Days"]);
      $TimeLengths.Add("Months"      , 30   * $TimeLengths["Days"]);
      $TimeLengths.Add("Years"       , 12   * $TimeLengths["Months"]);
      $TimeLengths.Add("Decades"     , 10   * $TimeLengths["Years"]);
      $TimeLengths.Add("Centuries"   , 100  * $TimeLengths["Years"]);
      $TimeLengths.Add("Millennias"  , 1000 * $TimeLengths["Years"]);
    } End {
      Write-Output -NoEnumerate -InputObject $TimeLengths
    }
  }

  Function Remove-BadDirectory {
    [CmdletBinding()]
    Param()

    Begin {
      $BadUserProfileDirectory = (Join-Path -Path $HOME -ChildPath '%UserProfile%');
    } Process {
      If ((Test-Path -LiteralPath $BadUserProfileDirectory -PathType Container) -or [Directory]::Exists($BadUserProfileDirectory)) {
        Remove-Item -LiteralPath $BadUserProfileDirectory -Recurse -Force;
        Write-Host -ForegroundColor Yellow -Object "Found Directory in `$HOME called '%UserProfile%' and has been removed. $([DateTime]::Now)" | Out-Host;
      }
    }
  }

  Set-Variable -Scope Global -Name "ProfileDirectory" -Value (Get-Item -LiteralPath $Profile).Directory;

  Set-Variable -Scope Global -Name "TimeLengths" -Value (Get-TimeLengths);

  Set-Variable -Scope Script -Name "Config" -Value (Get-ProfileConfig);

  Import-PSProfile
  Import-ExitWithCode
} Process {
  # Import the Chocolatey Profile that contains the necessary code to enable
  # tab-completions to function for `choco`.
  # Be aware that if you are missing these lines from your profile, tab completion
  # for `choco` will not function.
  # See https://ch0.co/tab-completion for details.
  $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1";
  If (Test-Path -LiteralPath $ChocolateyProfile) {
    Import-Module "$ChocolateyProfile"
    # ./Refresh-Environment.ps1
    refreshenv | Out-Null
  }
  If ($Null -eq $env:SBIE -or "$env:SBIE".Equals("True", [stringComparer]::OrdinalIgnoreCase)) {
    # Import the key Asynchronously will prevent long loading times but won't print to console.
    [bool]           $RunAsynchronously = $False;
    [string]         $JobName = "Import-GnuPGKey";
    [DateTimeOffset] $StartTimeStamp = [DateTimeOffset]::Now;
    # Lockfile unneeded continue to try import once again.
    [string]         $LockFilePath = (Join-Path -Path $global:ProfileDirectory -ChildPath ".import-gnupg-key.lock");
    #If (Test-Path -LiteralPath $LockFile -PathType Leaf) {
    #  Remove-Item -LiteralPath (Join-Path -Path $LockFile -ChildPath ".import-gnupg-key.lock") -Force;
    #}
    [string] $UsingStatements = ((Get-Content -LiteralPath $PSCommandPath | Select-String '^using namespace .+$') -join "`n");

    If (-not (Test-Path -LiteralPath $LockFilePath -PathType Leaf)) {
      $ImportGnuPGKeyJob = (Start-Job -Name $JobName -WorkingDirectory (Get-Item -LiteralPath $PWD) -ScriptBlock {
        . ([ScriptBlock]::Create($using:UsingStatements))
        Try {
          $Output = [Dictionary[[String],[Object]]]::new();
          $Output.Add("Status", $Null);
          $Output.Add("Error", $Null);
          $Output.Add("LockFile", $Null);
          Try {
            Push-Location -LiteralPath ($using:PWD).ProviderPath;
            ${function:Import-GnuPGKey}                  = "${using:function:Import-GnuPGKey}";
            ${function:Get-ProfileConfig}                = "${using:function:Get-ProfileConfig}";
            ${function:Test-GnupgOnPath}                 = "${using:function:Test-GnupgOnPath}";
            ${function:Get-GnupgPath}                    = "${using:function:Get-GnupgPath}";
            ${function:Test-NullOrEmptyOrWhiteSpace}     = "${using:function:Test-NullOrEmptyOrWhiteSpace}";
            ${function:Start-GnuPGAgent}                 = "${using:function:Start-GnuPGAgent}";
            ${function:Get-Quoted}                       = "${using:function:Get-Quoted}";
            ${function:Test-KeyCached}                   = "${using:function:Test-KeyCached}";
            ${function:Invoke-CacheKey}                  = "${using:function:Invoke-CacheKey}";
            ${function:Get-UnhashedPassword}             = "${using:function:Get-UnhashedPassword}";
            ${function:Invoke-ThrowIfEmptyNullOrInvalid} = "${using:function:Invoke-ThrowIfEmptyNullOrInvalid}";
            $script:Config                               = $Args[1];
            $global:ProfileDirectory                     = "${using:global:ProfileDirectory}";
            [String] $local:LockFilePath                 = $Args[0];
            [FileInfo] $LockFile                         = (New-Item -Path (Join-Path -Path $local:LockFilePath -ChildPath ".import-gnupg-key.lock"));
            Import-GnuPGKey;
            $Output["Status"]   = "Finished";
            $Output["LockFile"] = $LockFile;
            Write-Output -NoEnumerate -InputObject $Output;
          } Catch {
            $Output["Status"]   = "Errored";
            $Output["Error"]    = $_;
            $Output["LockFile"] = $LockFile;
            Write-Output -NoEnumerate -InputObject $Output;
            Throw;
          } Finally {
            Pop-Location;
          }
        } Catch {
          Write-Output -NoEnumerate -InputObject $_;
          Throw;
        }
      } -ArgumentList @($LockFilePath, $script:Config));
      Register-ObjectEvent -InputObject $ImportGnuPGKeyJob -EventName StateChanged -Action {
        [DateTimeOffset] $EndTimeStamp = [DateTimeOffset]::Now;
        Switch ($EventArgs.JobStateInfo.State) {
          Completed {
            $JobOutput = (Receive-Job -Id $Sender.Id);
            If (-not $RunAsynchronously) {
              If ($JobOutput.Status -eq "Finished") {
                Write-Host -Object "Importing GnuPG key took $(Get-TimeStampDifference -First $StartTimeStamp -Second $EndTimeStamp)" | Out-Host;
              } Else {
                Write-Output -InputObject $JobOutput | Out-Host;
              }
            }

            Remove-Item -LiteralPath $JobOutput.LockFile -Force;
          }
          Failed {
            $JobOutput = (Receive-Job -Id $Sender.Id);
            If (-not $RunAsynchronously) {
              If ($JobOutput.Status -ne "Finished") {
                Write-Host -ForegroundColor Red -Object "Importing GnuPG key failed took $(Get-TimeStampDifference -First $StartTimeStamp -Second $EndTimeStamp)" | Out-Host;
                If ($JobOutput.Error -is [ErrorRecord]) {
                  Write-Error -ErrorRecord $JobOutput.Error | Out-Host;
                } Else {
                  Write-Output -InputObject $JobOutput | Out-Host;
                }
              } Else {
                Write-Output -InputObject $JobOutput | Out-Host;
              }
            }
            Remove-Item -LiteralPath $JobOutput.LockFile -Force;
          }
          Default {
            $JobOutput = (Receive-Job -Id $Sender.Id);
            Write-Error -Message "Got Unknown JobDStateInfo `"$($EventArgs.JobStateInfo.State)`"" -ErrorId "Unknown Enum" -TargetObject $EventArgs.JobStateInfo.State -RecommendedAction "Contact the author of this script. Or handle it yourself." -Category [ErrorCategory]::NotImplemented | Out-Host;
            # Something else here, enum has many possible states
            Remove-Item -LiteralPath $JobOutput.LockFile -Force;
          }
        }
      } | Out-Null;

      If (-not $RunAsynchronously) {
        If (-not $ImportGnuPGKeyJob.Finished.WaitOne()) {
          Write-Error -Message "Job `"$($JobName)`" Finished handle WaitOne() method returned `$False. Please look into this!" | Out-Host;
          Remove-Item -LiteralPath $JobOutput["LockFile"] -Force -ErrorAction SilentlyContinue;
        }
      }
      # Lockfile unneeded continue to try import once again.
      #New-Item -Path $LockFile -ItemType File -Value "$($ImportGnuPGKeyJob.Id)`n$($ImportGnuPGKeyJob.InstanceId)" | Out-Null;
    }
  }

  Add-Aliases;
  Add-PSDrives;

  $DisableOnVSShell = $False;

  If ($Null -ne $env:VSAPPIDNAME -or ($Null -eq $env:VSAPPIDNAME -and $DisableOnVSShell -eq $False)) {
    Import-PoshGit;
    Import-OhMyPosh;
  }

  Remove-BadDirectory;
} End {
  $global:BaseVariables = (Get-BaseVariables);
} Clean {
  Clear-Variable -Name "Config" -Scope Script;
  Remove-Variable -Name "Config" -Scope Script;
}