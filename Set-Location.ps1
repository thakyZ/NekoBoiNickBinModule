[CmdletBinding(DefaultParameterSetName = 'Path', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=2097049')]
param(
  [Parameter(ParameterSetName = 'Path', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string]
  ${Path},

  [Parameter(ParameterSetName = 'LiteralPath', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
  [Alias('PSPath', 'LP')]
  [string]
  ${LiteralPath},

  [switch]
  ${PassThru},

  [Parameter(ParameterSetName = 'Stack', ValueFromPipelineByPropertyName = $true)]
  [string]
  ${StackName})


dynamicparam {
  try {
    $targetCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Set-Location', [System.Management.Automation.CommandTypes]::Cmdlet, $PSBoundParameters)
    $dynamicParams = @($targetCmd.Parameters.GetEnumerator() | Microsoft.PowerShell.Core\Where-Object { $_.Value.IsDynamic })
    if ($dynamicParams.Length -gt 0) {
      $paramDictionary = [Management.Automation.RuntimeDefinedParameterDictionary]::new()
      foreach ($param in $dynamicParams) {
        $param = $param.Value
        Write-Host $param;
        Write-Host $param.Value;

        if (-not $MyInvocation.MyCommand.Parameters.ContainsKey($param.Name)) {
          $dynParam = [Management.Automation.RuntimeDefinedParameter]::new($param.Name, $param.ParameterType, $param.Attributes)
          $paramDictionary.Add($param.Name, $dynParam)
        }
      }

      return $paramDictionary
    }
  }
  catch {
    throw
  }
}

begin {
  if ($null -eq $env:PathsToCheckFor) {
    [System.Environment]::SetEnvironmentVariable('PathsToCheckFor', '')
  }
  $env:PathsToCheckFor = [System.Environment]::GetEnvironmentVariable('PathsToCheckFor')

  Function Add-ToPath {
    param(
      # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
      # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
      # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
      # characters as escape sequences.
      [Parameter(Mandatory = $true,
        Position = 0,
        ParameterSetName = "LiteralPath",
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Literal path to one or more locations.")]
      [Alias("PSPath", "LP")]
      [ValidateNotNullOrEmpty()]
      [string[]]
      $LiteralPath
    )

    foreach ($element in $LiteralPath) {
      $env:PATH = "$($env:PATH);$($element)";
      $env:PathsToCheckFor = [System.Environment]::GetEnvironmentVariable('PathsToCheckFor');
      [System.Environment]::SetEnvironmentVariable('PathsToCheckFor', "$($env:PathsToCheckFor);$($element)")
      if ($env:PathsToCheckFor -match '^;') {
        [System.Environment]::SetEnvironmentVariable('PathsToCheckFor', ($env:PathsToCheckFor -replace '^;', ''))
      }
      Write-Debug -Message "Added $($element) to Path";
    }
    Write-Debug $env:PathsToCheckFor;
    Write-Debug $env:PathsToCheckFor.Split(';').Length;
  }
  Function Clear-AddedPaths {
    param()
    [System.Collections.ArrayList]$PathArray = @();
    foreach ($element in $env:PathsToCheckFor.Split(';')) {
      if ("$($env:PATH)".Split(';') -contains $element) {
        $PathsToCheckFor = [System.Environment]::GetEnvironmentVariable('PathsToCheckFor');
        Write-Debug $env:PathsToCheckFor;
        Write-Debug $PathsToCheckFor;
        $PathsToCheckFor = [System.Collections.ArrayList]("$($env:PathsToCheckFor)".Split(';'));
        Write-Debug $PathsToCheckFor[0];
        Write-Debug $env:PathsToCheckFor;
        $PathArray = [System.Collections.ArrayList]("$($env:PATH)".Split(';'));
        Write-Debug $env:PathsToCheckFor;
        $PathArray.Remove($element);
        Write-Debug $env:PathsToCheckFor;
        $PathsToCheckFor.Remove($element);
        Write-Debug $env:PathsToCheckFor;
        Write-Debug $PathsToCheckFor[0];
        [System.Environment]::SetEnvironmentVariable('PathsToCheckFor', [String]::Join(';', $PathsToCheckFor));
        Write-Debug $env:PathsToCheckFor;
        Write-Debug -Message "Removed $($element) from Path";
      }
    }
    #Write-Debug $PathArray;
    Write-Debug $env:PathsToCheckFor;
    Write-Debug $env:PathsToCheckFor.Split(';').Length;
    $env:PATH = [String]::Join(';', $PathArray);
  }

  Function Resolve-DictionaryPath {
    param(
      # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
      # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
      # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
      # characters as escape sequences.
      [Parameter(ParameterSetName = 'LiteralPath',
        Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        Position = 0,
        HelpMessage = "Literal path to one or more locations.")]
      [Alias('PSPath', 'LP')]
      [ValidateNotNullOrEmpty()]
      [string]
      ${LiteralPath}
    )

    $PathDirectories = $LiteralPath.Split('\');
    if ($PathDirectories -contains "TexTools" -and $PathDirectories -contains "ModPacks") {
      Add-ToPath -LiteralPath @("$($env:FFXIV)\TexTools");
    }
    else {
      Clear-AddedPaths;
    }
  }

  try {
    $outBuffer = $null
    if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
      $PSBoundParameters['OutBuffer'] = 1
    }

    $getPath = $null;
    if ($PSBoundParameters.TryGetValue('Path', [ref]$getPath)) {
      $path = (Get-Item -LiteralPath (Resolve-Path -LiteralPath $getPath));
      Write-Debug $path
      Resolve-DictionaryPath -LiteralPath $path;
    }
    $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Set-Location', [System.Management.Automation.CommandTypes]::Cmdlet)
    $scriptCmd = { & $wrappedCmd @PSBoundParameters }

    $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
    $steppablePipeline.Begin($PSCmdlet)
  }
  catch {
    throw
  }
}

process {
  try {
    $steppablePipeline.Process($_)
  }
  catch {
    throw
  }
}

end {
  try {
    $steppablePipeline.End()
  }
  catch {
    throw
  }
}

clean {
  if ($null -ne $steppablePipeline) {
    $steppablePipeline.Clean()
  }
}
<#

.ForwardHelpTargetName Microsoft.PowerShell.Management\Set-Location
.ForwardHelpCategory Cmdlet

#>