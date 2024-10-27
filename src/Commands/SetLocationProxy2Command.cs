using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Set, "LocationProxy2")]
public class SetLocationProxy2Command : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "Path", HelpUri = "https://go.microsoft.com/fwlink/?LinkID=2097049")]
Param(
  [Parameter(ParameterSetName = "Path",
             Position = 0,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True)]
  [System.String]
  $Path,

  [Parameter(ParameterSetName = "LiteralPath",
             Mandatory = $True,
             ValueFromPipelineByPropertyName = $True)]
  [Alias("PSPath", "LP")]
  [System.String]
  $LiteralPath,

  [switch]
  $PassThru,

  [Parameter(ParameterSetName = "Stack",
             ValueFromPipelineByPropertyName = $True)]
  [string]
  $StackName
)

Function Invoke-ForFive {
  Write-Host "Soup0"
  If ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
    Write-Host "Soup1"
    Set-Location -LiteralPath $LiteralPath;
    Write-Host "Soup2"
    Exit $LastExitCode;
  }
  ElseIf ($PSCmdlet.ParameterSetName -eq "Path") {
    Write-Host "Soup1"
    Set-Location -Path $Path;
    Write-Host "Soup2"
    Exit $LastExitCode;
  }
  Write-Host "Soup3"
}

Function Invoke-ForSeven {
  Param()
  DynamicParam {
    Try {
      $TargetCmd = $ExecutionContext.InvokeCommand.GetCommand("Microsoft.PowerShell.Management\Set-Location", [System.Management.Automation.CommandTypes]::Cmdlet, $PSBoundParameters)
      $DynamicParams = @($TargetCmd.Parameters.GetEnumerator() | Microsoft.PowerShell.Core\Where-Object { $_.Value.IsDynamic })
      if ($DynamicParams.Length -gt 0) {
        $ParamDictionary = [Management.Automation.RuntimeDefinedParameterDictionary]::new()
        foreach ($Param in $DynamicParams) {
          $Param = $Param.Value
          Write-Host $Param;
          Write-Host $Param.Value;

          If (-not $MyInvocation.MyCommand.Parameters.ContainsKey($Param.Name)) {
            $DynParam = [Management.Automation.RuntimeDefinedParameter]::new($Param.Name, $Param.ParameterType, $Param.Attributes)
            $paramDictionary.Add($Param.Name, $DynParam)
          }
        }

        Return $paramDictionary
      }
    }
    Catch {
      Throw
    }
  }

  Begin {
    If ($Null -eq $env:PathsToCheckFor) {
      [System.Environment]::SetEnvironmentVariable("PathsToCheckFor", "")
    }
    $env:PathsToCheckFor = [System.Environment]::GetEnvironmentVariable("PathsToCheckFor")

    Function Add-ToPath {
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
        [Alias("PSPath", "LP")]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $LiteralPath
      )

      ForEach ($Element in $LiteralPath) {
        $env:PATH = "$($env:PATH);$($Element)";
        $env:PathsToCheckFor = [System.Environment]::GetEnvironmentVariable("PathsToCheckFor");
        [System.Environment]::SetEnvironmentVariable("PathsToCheckFor", "$($env:PathsToCheckFor);$($Element)")
        if ($env:PathsToCheckFor -match "^;") {
          [System.Environment]::SetEnvironmentVariable("PathsToCheckFor", ($env:PathsToCheckFor -replace "^;", ""))
        }
        Write-Debug -Message "Added $($Element) to Path";
      }
      Write-Debug $env:PathsToCheckFor;
      Write-Debug $env:PathsToCheckFor.Split(";").Length;
    }
    Function Clear-AddedPaths {
      Param()
      [System.Collections.ArrayList]$PathArray = @();
      foreach ($element in $env:PathsToCheckFor.Split(";")) {
        if ("$($env:PATH)".Split(";") -contains $element) {
          $PathsToCheckFor = [System.Environment]::GetEnvironmentVariable("PathsToCheckFor");
          Write-Debug $env:PathsToCheckFor;
          Write-Debug $PathsToCheckFor;
          $PathsToCheckFor = [System.Collections.ArrayList]("$($env:PathsToCheckFor)".Split(";"));
          Write-Debug $PathsToCheckFor[0];
          Write-Debug $env:PathsToCheckFor;
          $PathArray = [System.Collections.ArrayList]("$($env:PATH)".Split(";"));
          Write-Debug $env:PathsToCheckFor;
          $PathArray.Remove($element);
          Write-Debug $env:PathsToCheckFor;
          $PathsToCheckFor.Remove($element);
          Write-Debug $env:PathsToCheckFor;
          Write-Debug $PathsToCheckFor[0];
          [System.Environment]::SetEnvironmentVariable("PathsToCheckFor", [String]::Join(";", $PathsToCheckFor));
          Write-Debug $env:PathsToCheckFor;
          Write-Debug -Message "Removed $($element) from Path";
        }
      }
      #Write-Debug $PathArray;
      Write-Debug $env:PathsToCheckFor;
      Write-Debug $env:PathsToCheckFor.Split(";").Length;
      $env:PATH = [String]::Join(";", $PathArray);
    }

    Function Resolve-DictionaryPath {
      Param(
        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        [Parameter(ParameterSetName = "LiteralPath",
                   Mandatory = $True,
                   ValueFromPipelineByPropertyName = $True,
                   Position = 0,
                   HelpMessage = "Literal path to one or more locations.")]
        [Alias("PSPath", "LP")]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LiteralPath
      )

      $PathDirectories = $LiteralPath.Split("\");
      If ($PathDirectories -contains "TexTools" -and $PathDirectories -contains "ModPacks") {
        Add-ToPath -LiteralPath @("$($env:FFXIV)\TexTools");
      }
      Else {
        Clear-AddedPaths;
      }
    }

    Try {
      $OutBuffer = $Null
      if ($PSBoundParameters.TryGetValue("OutBuffer", [ref]$OutBuffer)) {
        $PSBoundParameters["OutBuffer"] = 1
      }

      $GetPath = $Null;
      if ($PSBoundParameters.TryGetValue("Path", [ref]$GetPath)) {
        $Temp_Path = (Get-Item -LiteralPath (Resolve-Path -LiteralPath $GetPath));
        Write-Debug $Temp_Path
        Resolve-DictionaryPath -LiteralPath $Temp_Path;
      }
      $WrappedCmd = $ExecutionContext.InvokeCommand.GetCommand("Microsoft.PowerShell.Management\Set-Location", [System.Management.Automation.CommandTypes]::Cmdlet)
      $ScriptCmd = { & $WrappedCmd @PSBoundParameters }

      $SteppablePipeline = $ScriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
      $SteppablePipeline.Begin($PSCmdlet)
    }
    Catch {
      Throw;
    }
  }
  Process {
    Try {
      $SteppablePipeline.Process($_);
    }
    Catch {
      Throw;
    }
  }
  End {
    Try {
      $SteppablePipeline.End();
      If ($Null -ne $SteppablePipeline) {
        $SteppablePipeline.Clean();
      }
    }
    Catch {
      throw;
    }
  }
  <#
  Clean {
    If ($Null -ne $SteppablePipeline) {
      $SteppablePipeline.Clean();
    }
  }
  #>
}

If ($PSVersionTable.PSVersion.Major -le 5) {
  Invoke-ForFive
} Else {
  Invoke-ForSeven
}
<#

.ForwardHelpTargetName Microsoft.PowerShell.Management\Set-Location
.ForwardHelpCategory Cmdlet

#>
*/
