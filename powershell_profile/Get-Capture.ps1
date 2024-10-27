[CmdletBinding()]
Param()

Begin {
  Function Expand-BatchVariables() {
    [CmdletBinding()]
    Param(
      # Specifies a string to expand the variables of.
      [Parameter(Mandatory = $True)]
      [System.String]
      $String
    )

    Begin {
      $Regex = [System.Text.RegularExpressions.Regex]::new('%([^%\s]+)%');
    } Process {
      Function Get-EnvironemntVariable() {
        [CmdletBinding()]
        Param(
          # Specifies a name of an environment variable to get.
          [Parameter(Mandatory = $True)]
          [System.String]
          $Name
        )

        Begin {
          $EnvironemntVariables = (Get-ChildItem -Path "env:")
          $Output = $Null;
        } Process {
          If ($Name -eq "HOME" -and $IsWindows) {
            $Name = "USERPROFILE"
          }
          $Output = ($EnvironemntVariables | Where-Object { $_.Name -eq $Name }).Value;
        } End {
          Write-Output -NoEnumerate -InputObject $Output;
        }
      }

      If ($Regex.IsMatch($String)) {
        ForEach ($Capture in $Regex.Match($String).Captures) {
          $String.Replace($Capture, (Get-EnvironemntVariable -Name $Capture.Group[1]))
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $String;
    }
  }

  . "$(Join-Path -Path $env:ProfileDirectory -ChildPath "Config.ps1")";
  $script:Config = (Get-ProfileConfigJson);
  $script:CapturesLocation = (Expand-BatchVariables -String $script:Config.captures.location);
} Process {
  $Now = [DateTime]::Now;

  If ($Now.Hour -lt 6 -and $Now.Hour -gt 21) {
    If ($Now.Hour -ge 0) {
      $YesterdayNight = [System.DateTime]::new($Now.Year, $Now.Month, $Now.Day - 1, 21, 0, 0);
    } ElseIf ($Now.Hour -le 23) {
      $YesterdayNight = [System.DateTime]::new($Now.Year, $Now.Month, $Now.Day, 21, 0, 0);
    }
    If ($Now.Hour -ge 0) {
      $TodayMorning = [System.DateTime]::new($Now.Year, $Now.Month, $Now.Day, 6, 0, 0);
    } ElseIf ($Now.Hour -le 23) {
      $TodayMorning = [System.DateTime]::new($Now.Year, $Now.Month, $Now.Day + 1, 6, 0, 0);
    }

    $BackupItems = (Get-ChildItem -Path (Join-Path -Path $HOME -ChildPath "Downloads" -AdditionalChildPath "u", "soup") -File -Filter "*.txt" | Where-Object { $_ -match "s\d\.txt" })

    $BackupItems |
  }

  $OldFilesCount = 0;
} End {

} Clean {
  Remove-Variable -Name "Config" -Scope Script -ErrorAction SilentlyContinue;
}