[CmdletBinding(DefaultParameterSetName = "NonRelative")]
[OutputType([System.String])]
Param(
  # Specifies a string that resembles a path on the system.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "NonRelative",
             HelpMessage = "A string that resembles a path on the system.")]
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Relative",
             HelpMessage = "A string that resembles a path on the system.`n" +
                           "⚠️ the argument must exist on the system")]
  [System.String]
  $Path,
  # Specifies a string that is a parent or relative to the argument -Path.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "NonRelative",
             HelpMessage = "A string that is a parent to the argument -Path.")]
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Relative",
             HelpMessage = "A string that is relative to the argument -Path.`n" +
                           "⚠️ the argument must exist on the system")]
  [Alias("RelativeTo")]
  [System.String]
  $RelativeBasePath,
  # Specifies a switch to match a relative path that isn't a direct parent.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Relative",
             HelpMessage = "A switch to match a relative path that isn't a direct parent.")]
  [switch]
  $Relative,
  # Specifies a string to replace the argument -RelativeTo with on output.
  [Parameter(Mandatory = $False,
             ParameterSetName = "NonRelative",
             HelpMessage = "A string to replace the argument -RelativeTo with on output.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "Relative",
             HelpMessage = "A string to replace the argument -RelativeTo with on output.")]
  [System.String]
  $ReplaceWith
)

Begin {
  [System.String]$Output = $Null;

  If ($Relative) {
    If (-not (Test-Path -Path $Path -PathType Any)) {
      Throw "Value of argument `"-Path`", `"$($Path)`" does not exist on the file system path."
    }

    If (-not (Test-Path -Path $RelativeTo -PathType Any)) {
      Throw "Value of argument `"-RelativeTo`", `"$($RelativeTo)`" does not exist on the file system path."
    }
  }

  If ($Null -eq $ReplaceWith) {
    $EnvironmentVariables = (Get-ChildItem -Path "env:" | Where-Object { [System.Text.RegularExpressions.Regex]::IsMatch($_.Value, "\w:\\") })
    ForEach ($EnvironmentVariable in $EnvironmentVariables) {
      If ($RelativeBasePath.StartsWith($EnvironmentVariable.Value)) {
        $ReplaceWith = "%$($EnvironmentVariable.Name)%";
        Break;
      }
    }
  }
  If ($Null -eq $ReplaceWith) {
    Throw "Valid value of argument -ReplaceWith could not be determined, please specify.";
  }
}
Process {
  If ($Relative) {
    [System.String]$RelativePath = (Resolve-Path -Path $Path -Relative -RelativeBasePath $RelativeBasePath);
    $Output = ($RelativePath -replace "$([System.Text.RegularExpressions.Regex]::Escape($RelativeBasePath))", "$ReplaceWith");
  } Else {
    [System.String]$RelativeBasePathEscaped = $([System.Text.RegularExpressions.Regex]::Escape($RelativeBasePath));
    $Output = ($Path -replace "$RelativeBasePathEscaped", "$ReplaceWith");
  }
}
End {
  $Output | Write-Output;
}