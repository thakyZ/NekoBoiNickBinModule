using namespace System;
using namespace System.Collections;
using namespace System.Collections.Generic;
using namespace System.IO;
using namespace System.Linq;
using namespace System.Management;
using namespace System.Management.Automation;
using namespace System.Security.Cryptography;
using namespace Microsoft.Automation;
using namespace Microsoft.PowerShell.Commands;

[CmdletBinding()]
Param(
  # Specifies the password manager service to use.
  [Parameter(Mandatory = $True,
             Position = 0,
             HelpMessage = 'The password manager to use.')]
  [AllowNull()]
  [ValidateSet('Bitwarden')]
  [Alias('PasswordManager')]
  [string]
  $Service = 'Bitwarden',
  # Specifies the list of recovery codes to save to a profile.
  [Parameter(Mandatory = $False,
             ValueFromPipeline = $True,
             HelpMessage = 'The list of recovery codes to save to a profile')]
  [AllowNull()]
  [Alias('Passwords','BackupPasswords','Codes')]
  [SecureString[]]
  $RecoveryCodes,
  # Specifies the password manager site entry to apply to recovery codes too.
  [Parameter(Mandatory = $False,
             ValueFromPipeline = $True,
             HelpMessage = 'The password manager site entry to apply to recovery codes too.')]
  [AllowNull()]
  [Alias('Entry','Profile')]
  [string]
  $SiteEntry,
  # Specifies the password manager site entry's containing folder.
  [Parameter(Mandatory = $False,
             ValueFromPipeline = $True,
             HelpMessage = "The password manager site entry's containing folder")]
  [AllowNull()]
  [Alias('Folder')]
  [string]
  $EntryFolder,
  # Specifies the master password to login to your password manager with.
  [Parameter(Mandatory = $False,
             HelpMessage = 'The master password to login to your password manager with.')]
  [AllowNull()]
  [Alias('Password','Master')]
  [SecureString]
  $MasterPassword
)

Begin {
  Class ItemEntry {
    [guid] $ID;
    [string] $Name;

    FolderEntry([string] $ID, [string] $Name) {
      $this.ID = $ID;
      $this.Name = $Name;
    }
  }

  Class FolderEntry {
    [guid] $ID;
    [string] $Name;
    [ItemCollection] $Items;

    FolderEntry([string] $ID, [string] $Name, [ItemCollection] $Items = [ItemCollection]::new()) {
      $this.ID = $ID;
      $this.Name = $Name;
      $this.Items = $Items;
    }
  }

  Class ItemCollection : List[ItemEntry] {}

  Class FolderCollection : List[FolderEntry] {}

  Function Get-CommandOutput {
    [CmdletBinding()]
    [OutputType([string[]])]
    Param(
      [Parameter(Mandatory = $True)]
      [ValidateNotNull()]
      [ApplicationInfo]
      $PasswordManager,
      [Parameter(Mandatory = $False)]
      [ValidateNotNull()]
      [AllowEmptyCollection()]
      [string[]]
      $Arguments = @()
    )

    Begin {
      [string[]] $Output = @();
    } Process {
      $Output = (Start-Process -FilePath $PasswordManager.Source -ArgumentList $Arguments -Wait -PassThru -NoNewWindow);
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  [ApplicationInfo] $PasswordManager = $Null;

  If ($Service -match 'bitwarden') {
    $PasswordManager = (Get-Command -Name 'bw' -ErrorAction SilentlyContinue);

    If ($Null -eq $PasswordManager) {
      Throw [FileNotFoundException]::new('Password manager Bitwarden-CLI not found on system path.');
    } Else {
      [string[]] $ValidateIsBitwarden = (Get-CommandOutput -PasswordManager $PasswordManager -Arguments @('--help'));

      If ($Null -eq ($ValidateIsBitwarden | Select-String -Pattern 'Bitwarden')) {
        Throw [InvalidOperationException]::new('Found "bw.exe" on the system path, but it does not appear to be a Bitwarden-CLI executable.');
      }
    }
  } Else {
    Throw [NotImplementedException]::new('This service has not been implemented yet.')
  }

  If ($Null -eq (Get-Command -Name 'Get-UnhashedPassword' -ErrorAction SilentlyContinue)) {
    Throw [CommandNotFoundException]::('Unable to find the pwsh command "Get-UnhashedPassword".');
  }

  [string]   $DecryptedMasterPassword = $Null;
  [string[]] $DecryptedRecoveryCodes = @();

  Try {
    If ($Null -ne $MasterPassword) {
      $DecryptedMasterPassword = (Get-UnhashedPassword -Password $MasterPassword);
    }
    [SecureString] $RecoveryCode;

    ForEach ($RecoveryCode in $RecoveryCodes) {
      $DecryptedRecoveryCodes += (Get-UnhashedPassword -Password $RecoveryCode);
    }
  } catch {
    Write-Host -ForegroundColor Red -Object 'Failed while decrypting passwords.' | Out-Host;
    Write-Error -ErrorRecord $_ | Out-Host;
    Exit 1;
  }
} Process {
  [string[]] $OutputArray = @()
  [string] $Output = [string]::Empty;
  If ($Service -match 'bitwarden') {
    Try {
      [string[]] $Arguments = @('unlock');

      If ($Null -ne $DecryptedMasterPassword) {
        $Arguments += $DecryptedMasterPassword;
      }

      $OutputArray = (Get-CommandOutput -PasswordManager $PasswordManager -Arguments $Arguments);
      [MatchInfo] $EnvironemntMatch = ($OutputArray | Select-String -Pattern '\$env:BW_SESSION="([^"]+)"');

      If ($Null -ne $EnvironemntMatch) {
        If ($EnvironemntMatch.Matches.Groups.Count -eq 2) {
          $env:BW_SESSION = "$($EnvironemntMatch.Matches.Groups[1].Value)";
        }
      }

      If ($Null -eq $env:BW_SESSION) {
        Write-Warning -Message 'Failed to set or get environemnt variable BW_SESSION. You may have to enter your master password each time an operation occurs.';
      }

      [string] $FolderUUID;

      If ($Null -eq $EntryFolder) {
        $Arguments = @('list', 'folders')
        $Output = (Get-CommandOutput -PasswordManager $PasswordManager -Arguments $Arguments);
      } Else {

      }
    } catch {
      Write-Host -ForegroundColor Red -Object 'Failed when trying to handle Bitwarden-CLI.';
      Write-Error -ErrorRecord $_;
      Exit 1;
    }
  } Else {
    Throw [NotImplementedException]::new('This service has not been implemented yet.')
  }
} End {

} Clean {

}