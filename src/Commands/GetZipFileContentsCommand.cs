using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "ZipFileContents")]
public class GetZipFileContentsCommand : Cmdlet {
}
/*
[CmdletBinding()]
[OutputType([SevenZipContents[]])]
Param(
  [Parameter(Mandatory = $False,
             ValueFromPipeline = $True)]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path,
  [Parameter(Mandatory = $False)]
  [Alias("Password")]
  [System.String]
  $Pass = $Null
)

Begin {
Enum SevenZipAttributes {
  None = 0;
  Directory = 1;
  Unk2 = 2;
  Unk3 = 4;
  Unk4 = 8;
  Archive = 16;
}

Class SevenZipContents {
  [System.String]$Date
  [System.String]$Time
  [SevenZipAttributes]$Attributes = [SevenZipAttributes]::None;
  [System.Int64]$Size = 0;
  [System.Int64]$Compressed = 0;
  [System.String]$Name;

  hidden static [SevenZipAttributes]ParseAttributes($String) {
    $Split = ($String -split '');
    [SevenZipAttributes]$Output = [SevenZipAttributes]::None;
    For ($I = 0; $I -lt $Split.Length; $I++) {
      If ($Split[$I] -ne '.') {
        If ($I -eq 0) {
          $Output = $Output -bor [SevenZipAttributes]::Directory;
        } ElseIf ($I -eq 1) {
          $Output = $Output -bor [SevenZipAttributes]::Unk2;
        } ElseIf ($I -eq 2) {
          $Output = $Output -bor [SevenZipAttributes]::Unk3;
        } ElseIf ($I -eq 3) {
          $Output = $Output -bor [SevenZipAttributes]::Unk4;
        } ElseIf ($I -eq 4) {
          $Output = $Output -bor [SevenZipAttributes]::Archive;
        }
      }
    }
    Return $Output;
  }

  SevenZipContents($Date, $Time, $Attributes, $Size, $Compressed, $Name) {
    If ($Null -eq $Time -or [System.String]::IsNullOrEmpty($Time)) {
      $Split = ($Date -split '\s+', 6);
      $this.Date = $Split[0];
      $this.Time = $Split[1];
      $this.Attributes = ParseAttributes($Split[2]);
      $this.Size = [System.Int64]::Parse($Split[3]);
      $this.Compressed = [System.Int64]::Parse($Split[4]);
      $this.Name = $Split[5];
    } Else {
      $this.Date = $Date;
      $this.Time = $Time;
      If ($Attributes -is [System.String]) {
        $this.Attributes = ParseAttributes($Attributes);
      } ElseIf ($Attributes -is [SevenZipAttributes]) {
        $this.Attributes = $Attributes;
      }
      If ($Size -is [System.String]) {
        $this.Size = [System.Int64]::Parse($Size);
      } ElseIf ($Size -is [System.Int64] -or $Size -is [System.Int32]) {
        $this.Size = $Size;
      }
      If ($Compressed -is [System.String]) {
        $this.Compressed = [System.Int64]::Parse($Compressed);
      } ElseIf ($Compressed -is [System.Int64] -or $Compressed -is [System.Int32]) {
        $this.Compressed = $Compressed;
      }
      $this.Name = $Name;
    }
  }

  [System.DateTime] GetTimestamp() {
    Return [System.DateTime]::Parse("$($this.Date) $($this.Time)");
  }
}

    $7z = (Get-Command -Name "7z" -ErrorAction SilentlyContinue);

    If ($Null -ne $7z) {
      Throw "7-zip not found on system path.";
    }

    [System.String[]]`
    $Arguments = @("l");
  } Process {
    If (-not [System.String]::IsNullOrEmpty($Pass) -and -not [System.String]::IsNullOrWhiteSpace($Pass)) {
      $Arguments += "-p`"$Pass`"";
    } ElseIf ($PSBoundParameters.ContainsKey("Pass") -or $PSBoundParameters.ContainsKey("Password")) {
      $Arguments += '-p"kimochi.info"'; # TODO: Remove this code before commit!!!
    }

    If ([System.String]::IsNullOrEmpty($Path) -or [System.String]::IsNullOrWhiteSpace($Path)) {
      $Path = (Get-ChildItem -Path $PWD -File | Where-Object { $_.Extension -match '\.(?:zip|tar(?:\.(?:gz|bz|xz))?|rar|7z)' })[0].FullName
    }

    # Double-check that we got a file.
    If ([System.String]::IsNullOrEmpty($Path) -or [System.String]::IsNullOrWhiteSpace($Path)) {
      Throw "Failed to find file at $PWD that matches zip|tar|tar.gz|tar.bz|tar.xz|rar|7z";
    }

    $Arguments += $Path;
    $Process = (Invoke-Expression -Command "& $($7z.Source) $($Arguments)");
    $ExitCode = $LastExitCode;

    If ($ExitCode -ne 0) {
      Throw "Failed to run 7-zip, got exit code $($ExitCode)";
    } Else {
      Write-Host -Object "[DBG] 7z Exit Code: $($ExitCode)";
    }

    $script:Index = 0;

    $Text = ($Process | Select-Object -Property @(
      @{Name = "Index"; Expression = {$script:Index}},
      @{Name = "String"; Expression = {$script:Index++;Return $_}}
    ));

    $LineToFind = ($Text | Where-Object {$_.String -match 'Date\s+Time\s+Attr\s+Size\s+Compressed\s+Name' -and -not [System.String]::IsNullOrEmpty($_.String)}).Index;
    $Status = $False;
    $Lines = @();

    For ($I = $LineToFind; $I -lt $Text.Length; $I++) {
      If ($I -ne $LineToFind) {
        If ($Text[$I].String.StartsWith('---')) {
          $Status = (-not $Status);
          $I++;
        }

        If ($Status) {
          $Lines += $Text[$I].String;
        }
      }
    }

    [SevenZipContents[]]$Output = @();
    ForEach ($Line in $Lines) {
      $Output += @([SevenZipContents]::new($Line));
    }
  } End {
    Return $Output;
  } Clean {
    Remove-Variable -Scope Script -Name Index -ErrorAction "Continue";
  }
  */
