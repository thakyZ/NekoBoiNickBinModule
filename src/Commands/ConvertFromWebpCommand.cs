using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.ConvertFrom, "Webp")]
public class ConvertFromWebpCommand : Cmdlet {
}
/*
[CmdletBinding()]
Param(
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [System.String[]]
  $Path,
  # Specifies to recursively look for webp files.
  [Parameter(Mandatory = $False,
             HelpMessage = "Recursively look for webp files.")]
  [Alias("R")]
  [System.Management.Automation.SwitchParameter]
  $Recurse,
  # Specifies a path to a custom dwebp.exe file.
  [Parameter(Mandatory = $False,
             HelpMessage = "A path to a custom dwebp.exe file.")]
  [System.String]
  $Dwebp = $Null
)

Class FileMetaData {
  [System.DateTime]$CreationTime;
  [System.DateTime]$CreationTimeUtc;
  [System.DateTime]$LastWriteTime;
  [System.DateTime]$LastWriteTimeUtc;
  [System.DateTime]$LastAccessTime;
  [System.DateTime]$LastAccessTimeUtc;
  [System.IO.FileAttributes]$Attributes;
  [System.Security.AccessControl.FileSystemSecurity]$Acl;
}

Function Get-FileMetaData {
  [CmdletBinding(DefaultParameterSetName = "PSPath")]
  Param(
    # Specifies a path to one or more locations.
    [Parameter(Mandatory = $True,
               Position = 0,
               ParameterSetName = "PSPath",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage = "Path to one or more locations.")]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath")]
    [System.String]
    $Path
  )

  $Output = (New-Object -TypeName FileMetaData)
  Try {
    $Item = (Get-Item -Path $Path);
    $Output.CreationTime = $Item.CreationTime;
    $Output.CreationTimeUtc = $Item.CreationTimeUtc;
    $Output.LastWriteTime = $Item.LastWriteTime;
    $Output.LastWriteTimeUtc = $Item.LastWriteTimeUtc;
    $Output.LastAccessTime = $Item.LastAccessTime;
    $Output.LastAccessTimeUtc = $Item.LastAccessTimeUtc;
    $Output.Attributes = $Item.Attributes;
    $Output.Acl = (Get-Acl -Path $Path);
    Return $Output;
  } Catch {
    Throw $_;
  }
}

Function Set-FileMetaData {
  [CmdletBinding(DefaultParameterSetName = "PSPath")]
  Param(
    # Specifies a path to one or more locations.
    [Parameter(Mandatory = $True,
               Position = 0,
               ParameterSetName = "PSPath",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage = "Path to one or more locations.")]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath")]
    [System.String]
    $Path,
    # Specifies the metadata to apply to the file.
    [Parameter(Mandatory = $True,
               Position = 1,
               ParameterSetName = "PSPath",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage = "The metadata to apply to the file.")]
    [ValidateNotNullOrEmpty()]
    [FileMetaData]
    $FileMetaData
  )

  Try {
    Set-ItemProperty -LiteralPath $Path -Name CreationTime -Value $FileMetaData.CreationTime;
    Set-ItemProperty -LiteralPath $Path -Name CreationTimeUtc -Value $FileMetaData.CreationTimeUtc;
    Set-ItemProperty -LiteralPath $Path -Name LastWriteTime -Value $FileMetaData.LastWriteTime;
    Set-ItemProperty -LiteralPath $Path -Name LastWriteTimeUtc -Value $FileMetaData.LastWriteTimeUtc;
    Set-ItemProperty -LiteralPath $Path -Name LastAccessTime -Value $FileMetaData.LastAccessTime;
    Set-ItemProperty -LiteralPath $Path -Name LastAccessTimeUtc -Value $FileMetaData.LastAccessTimeUtc;
    # Set-ItemProperty -LiteralPath $Path -Name Attributes -Value $FileMetaData.Attributes;
    Set-Acl -LiteralPath $Path -AclObject $FileMetaData.Acl;
  } Catch {
    Throw $_;
  }
}

Function Test-OutputFileExists {
  [CmdletBinding(DefaultParameterSetName = "PSPath")]
  Param(
    # Specifies a path to one or more locations.
    [Parameter(Mandatory = $True,
               Position = 0,
               ParameterSetName = "PSPath",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage = "Path to one or more locations.")]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath")]
    [System.String]
    $Path,
    # Specifies a path to one or more locations. Wildcards are permitted.
    [Parameter(Mandatory = $True,
               Position = 0,
               ParameterSetName = "PSPathWildcards",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage="Path to one or more locations. Wildcards are permitted.")]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [Alias("PathWildcard", "PSPathWildcards", "PSPathWildcard")]
    [System.String]
    $PathWildcards
  )

  If ($PSCmdlet.ParameterSetName -eq "PSPath") {
    If (Test-Path -LiteralPath $Path -PathType Leaf) {
      Return $True;
    } ElseIf (Test-Path -LiteralPath $Path -PathType Container) {
      Return $True;
    }
  } Else {
    If (Test-Path -LiteralPath $Path -PathType Leaf) {
      Return $True;
    } ElseIf (Test-Path -LiteralPath $Path -PathType Container) {
      Return $True;
    }
  }

  Return $False;
}

Function Get-LastDuplicateNameFiles {
  Param(
    # Specifies the output file path
    [Parameter(Mandatory = $True,
               Position = 0,
               HelpMessage = "Path to one or more locations.")]
    [System.String]
    $Path
  )

  $OutputDirectory = (Get-Item -LiteralPath $Path);
  $OutputBaseName = (Get-Item -LiteralPath $Path).BaseName;
  $OutputExtension = (Get-Item -LiteralPath $Path).Extension;

  If (Test-Path -LiteralPath $Path -PathType Leaf) {
    $OutputDirectory = $OutputDirectory.Directory.FullName;
  } ELseIf (Test-Path -LiteralPath $Path -PathType Container) {
    Write-Warning -Message "Supplied path was a type of Container."
    $OutputDirectory = $OutputDirectory.Patent.FullName;
  }

  $RegexString = [System.Text.RegularExpressions.Regex]::Escape("$($OutputBaseName) (\d+)($OutputExtension)")
  $Items = (Get-ChildItem -LiteralPath $OutputDirectory -File | Where-Object { $_.Name -match "$($OutputBaseName) (\d+)$($OutputExtension)" })

  [Int32[]]$IntCount = @();

  ForEach ($Item in $Items) {
    $RegexString = [System.Text.RegularExpressions.Regex]::Escape("$($Item.BaseName) (\d+)$($Item.Extension)");
    $Match = [System.Text.RegularExpressions.Regex]::Match("$($Item.Name)", $RegexString, "IgnoreCase");
    If ($Null -ne $Match -and $Match.Groups.Count -eq 2) {
      [Int32]$Int = [Int32]::Parse($Match.Groups[1].Value);
      $IntCount += @($Int);
    } ElseIf ($Null -eq $Match) {
      Write-Warning -Message "`$Match returned null.`n`$Item.Name = `"$($Item.Name)`"`n`$RegexString = `"$($RegexString)`"";
    } ElseIf ($Match.Groups.Count -ne 2) {
      Write-Warning -Message "`$Match.Groups.Count returned not equal to 2.`n`$Item.Name = `"$($Item.Name)`"`n`$RegexString = `"$($RegexString)`"";
      Write-Output $Match | Out-Host;
    }
  }

  [Int32]$FoundInt = -1;

  For ($Index = 0; $Index -lt ($IntCount | Measure-Object -Maximum); $Index++) {
    If ($IntCount -notcontains $Index) {
      Write-Host -ForegroundColor White -Object "Found missing index: " -NoNewLine;
      Write-Host -ForegroundColor Green -Object "$($Index)" -NoNewLine;
      Write-Host -ForegroundColor White -Object ".";
      $FoundInt = $Index;
      Break;
    }
  }

  $OutputPath = (Join-Path -Path $OutputDirectory -ChildPath "$($OutputBaseName) ($($FoundInt))$($OutputExtension)");

  Return $OutputPath;
}

Function Get-SimplifyName {
  [CmdletBinding()]
  [OutputType([System.String])]
  Param(
    # Specifies the output file path
    [Parameter(Mandatory = $True,
      Position = 0,
      HelpMessage = "Path to one or more locations.")]
    [System.String]
    $BaseName
  )

  If ($BaseName -match '(.+) \(\d+\)') {
    Return ($BaseName -replace '(.+) \(\d+\)$', '$1');
  }

  Return $BaseName;
}

Function Get-OutputPath {
  [CmdletBinding()]
  # [OutputType([System.String])]
  Param(
    # Specifies the output file path
    [Parameter(Mandatory = $True,
      Position = 0,
      HelpMessage = "Path to one or more locations.")]
    [System.String]
    $Path
  )

  Begin {
    $OutputPath = $Path;
  }
  Process {
    Try {
      If (Test-OutputFileExists -Path $OutputPath) {
        [System.String]$Script = (Get-Content -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "Get-MissingNewItem.cs") -Raw -Encoding UTF8);
        $Job = (Start-Job -ScriptBlock {
          [System.String]$_Script = $args[0];
          If ($Null -eq $_Script || $_Script -eq "") {
            Throw "`$_Script is null";
          }
          [System.String]$_OutputPath = $args[1];
          If ($Null -eq $_OutputPath || $_OutputPath -eq "") {
            Throw "`$_OutputPath is null";
          }
          Add-Type -Language CSharp $_Script;
          Write-Output -InputObject ([NekoBoiNick.CSharp.PowerShell.Cmdlets.Get_MissingNewItem]::Main($_OutputPath));
        } -ArgumentList @($Script, $OutputPath));
        [System.String]$LastState = (Get-Job -Id $Job.Id).State;
        While ($LastState -eq "Running") {
          Start-Sleep -Seconds 5;
          $LastState = (Get-Job -Id $Job.Id).State;
        }
        $Result = (Receive-Job -Id $Job.Id);
        If ($LastState -ne "Completed") {
          Remove-Job -Id $Job.Id;
          Throw $Result;
        }
        $OutputPath = $Result;
        Remove-Job -Id $Job.Id;
      }
    } Catch {
      Write-Error -ErrorRecord $_ | Out-Host;
      Throw;
    }
  }
  End {
    Return $OutputPath;
  }
}

$Items = @();

[System.Object]$_Dwebp;

If ($Null -eq $Dwebp -or $Dwebp -eq "") {
  $Json = (Get-Content -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "config.json") | ConvertFrom-Json);
  $Config = ($Json.Installs | Where-Object { $_.Name.ToLower() -eq "dwebp" } -ErrorAction SilentlyContinue);
  If ($Config.Length -eq 0) {
    $Config = ($Json.Installs.PSObject.Properties | Where-Object { $_.Name.ToLower() -eq "dwebp" } -ErrorAction SilentlyContinue);
  }
  $_Dwebp = (Get-Command -Name "dwebp" -ErrorAction SilentlyContinue);

  If ($Config.Length -eq 0 -and $Null -eq $_Dwebp) {
    Write-Error -Message "Could not find program `"dwebp`" on system environment path.";
    Exit 1;
  } ElseIf ($Config.Length -eq 1 -and $Null -eq $_Dwebp) {
    $_Dwebp = @{ Source = (Resolve-Path -Path $Config.Value) };
  } Elseif ($Config.Length -gt 1 -and $Null -eq $_Dwebp) {
    Write-Error -Message "Too many entires for dwebp in the config.";
    Exit 1;
  }
} Else {
  If (Test-Path -LiteralPath $Dwebp -PathType Leaf) {
    $_Dwebp = @{ Source = (Resolve-Path -Path $Dwebp) };
  } Else {
    Write-Error -Message "Could not find program `"$($Dwebp)`" as a executable.";
  }
}

If ($Recurse) {
  $Items = (Get-ChildItem -LiteralPath $Path -File -Recurse -Filter "*.webp");
} Else {
  $Items = (Get-ChildItem -LiteralPath $Path -File -Filter "*.webp");
}

ForEach ($Item in $Items) {
  Try {
    $MetaData = (Get-FileMetaData -Path $Item.FullName);
    $OutputPath = (Get-OutputPath -Path (Join-Path -Path $Item.Directory.FullName -ChildPath "$($Item.BaseName).png"));
    & "$($_Dwebp.Source)" "$($Item.Fullname)" "-o" $OutputPath;
    Start-Sleep -Milliseconds 500;
    Remove-Item $Item.FullName;
    Set-FileMetaData -Path $OutputPath -FileMetaData $MetaData;
    Start-Sleep -Seconds 1;
  } Catch {
    Throw $_;
    Break;
  }
}
*/
