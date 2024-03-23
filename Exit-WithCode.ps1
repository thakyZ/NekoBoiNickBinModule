Function Exit-WithCode {
  [CmdletBinding(DefaultParameterSetName = "Message")]
  Param(
      # Specifies a message to print before exiting.
      [Parameter(Mandatory = $False,
                 Position = 0,
                 ParameterSetName = "Message",
                 HelpMessage = "A message to print before exiting.")]
      [System.String]
      $Message = "",
      # Specifies a message either as a single object or an array of objects.
      [Parameter(Mandatory = $False,
                 Position = 0,
                 ParameterSetName = "InputObject",
                 HelpMessage = "A message either as a single object or an array of objects.")]
      [ValidateNotNull()]
      [System.Object]
      $InputObject = @(),
      # Specifies an exit code to exit the script with.
      [Parameter(Mandatory = $False,
                 ValueFromRemainingArguments = $True,
                 ParameterSetName = "Message",
                 HelpMessage = "An exit code to exit the script with.")]
      [Parameter(Mandatory = $False,
                 ValueFromRemainingArguments = $True,
                 ParameterSetName = "InputObject",
                 HelpMessage = "An exit code to exit the script with.")]
      [System.Int32]
      $Code = 0,
      # Specifies a switch to throw an error message.
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Message",
                 HelpMessage = "A switch to throw an error message.")]
      [Switch]
      $Throw = $False,
      # Specifies the stack name of a pushed location to pop location before exiting.
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Message",
                 HelpMessage = "The stack name of a pushed location to pop location before exiting.")]
      [Parameter(Mandatory = $False,
                 ParameterSetName = "InputObject",
                 HelpMessage = "The stack name of a pushed location to pop location before exiting.")]
      [String]
      $PopLocation = $Null,
      # Specifies a list of variable names and their scopes to remove.
      # * Required Parameters:
      #   [Parameter(Mandatory = $True)]
      #   [ValidateSet("Global","Script","Local","0","1")]
      #   [System.String]
      #   $Scope
      #   [Parameter(Mandatory = $True)]
      #   [ValidateNotNullOrEmpty()]
      #   [System.String[]]
      #   $Name
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Message",
                 HelpMessage = "A list of variable names and their scopes to remove.`n" +
                               "* Required Parameters:`n" +
                               "  [Parameter(Mandatory = `$True)]`n" +
                               "  [ValidateSet(`"Global`",`"Script`",`"Local`",`"0`",`"1`")]`n" +
                               "  [System.String]`n" +
                               "  `$Scope`n" +
                               "  [Parameter(Mandatory = `$True)]`n" +
                               "  [ValidateNotNullOrEmpty()]`n" +
                               "  [System.String[]]`n" +
                               "  `$Name")]
      [Parameter(Mandatory = $False,
                 ParameterSetName = "InputObject",
                 HelpMessage = "A list of variable names and their scopes to remove.`n" +
                               "* Required Parameters:`n" +
                               "  [Parameter(Mandatory = `$True)]`n" +
                               "  [ValidateSet(`"Global`",`"Script`",`"Local`",`"0`",`"1`")]`n" +
                               "  [System.String]`n" +
                               "  `$Scope`n" +
                               "  [Parameter(Mandatory = `$True)]`n" +
                               "  [ValidateNotNullOrEmpty()]`n" +
                               "  [System.String[]]`n" +
                               "  `$Name")]
      [PSCustomObject[]]
      $RemoveVariableList = @(),
      # Specifies a switch to clean all variables that weren't in at host startup time.
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Message",
                 HelpMessage = "A switch to clean all variables that weren't in at host startup time.")]
      [Parameter(Mandatory = $False,
                 ParameterSetName = "InputObject",
                 HelpMessage = "A switch to clean all variables that weren't in at host startup time.")]
      [Switch]
      $CleanAllVariables = $False
  )

  Begin {
    [System.Int32]$Index = 0;
    [System.Int32]$script:ExitCode = $Code;
  }
  Process {
    Function Invoke-LogObject {
      Param(
        [System.Object]
        $Item
      )
      If ($Null -eq $Item) {
        Throw "Item object is null.";
      }
      If ($Item.GetType() -eq [System.String]) {
        $Message += $Item;
      } ElseIf ($Item.GetType() -eq [System.Exception] -or $Item.GetType().BaseType -eq [System.Exception] -or $Item.GetType() -eq [System.Management.Automation.RuntimeException] -or $Item.GetType().BaseType -eq [System.Management.Automation.RuntimeException]) {
        Write-Error -Exception $Item.Exception -Message $Item.Message | Out-Host;
        If ($script:ExitCode -eq 0) {
          $script:ExitCode = 1;
        }
      } ElseIf ($Item.GetType() -eq [System.Management.Automation.ErrorRecord] -or $Item.GetType().BaseType -eq [System.Management.Automation.ErrorRecord]) {
        $PSCmdlet.WriteError($Item);
        If ($script:ExitCode -eq 0) {
          $script:ExitCode = 1;
        }
      } Else {
        Write-Output -InputObject $Item | Out-Host;
      }
    }

    If ($PSCmdlet.ParameterSetName -eq "InputObject") {
      If ($Null -eq $InputObject) {
        Throw "Input object is null.";
      }
      If ($InputObject.GetType().BaseType -eq [System.Array]) {
        ForEach ($Item in $InputObject) {
          Invoke-LogObject -Item $Item | Out-Host;
        }
      } Else {
        Invoke-LogObject -Item $InputObject | Out-Host;
      }
    } ElseIf ($PSCmdlet.ParameterSetName -eq "Message") {
      If ($Throw) {
        Write-Error -Message $Message | Out-Host;
        If ($script:ExitCode -eq 0) {
          $script:ExitCode = 1;
        }
      } Else {
        Write-Host -Message $Message | Out-Host;
      }
    }

    ForEach ($RemoveVariable in $RemoveVariableList) {
      If (($RemoveVariable | Get-Member).Name.Contains("Scope") -and ($RemoveVariable | Get-Member).Name.Contains("Name")) {
        Remove-Variable -Scope $RemoveVariable.Scope -Name $RemoveVariable.Name -ErrorAction SilentlyContinue;
      } Else {
        If (-not ($RemoveVariable | Get-Member).Name.Contains("Scope")) {
          Write-Error -Message "Value of argument -RemoveVariableList at index $($Index), does not contain member `"Scope`"."
        }

        If (-not ($RemoveVariable | Get-Member).Name.Contains("Name")) {
          Write-Error -Message "Value of argument -RemoveVariableList at index $($Index), does not contain member `"Name`"."
        }
      }

      $Index++;
    }

    If ($CleanAllVariables) {
      [System.String[]]$Scopes = @("Local", "Global", "Script");
      ForEach ($Scope in $Scopes) {
        $NewVariables = (Get-Variable -Scope $Scope | Where-Object {
          ForEach ($Variable in $global:BaseVariables[$Scope]) {
            If ($Variable.Name -eq $_.Name -and $Null -ne $Variable.Value) {
              Return $False;
            }
          }
          Return $True;
        });
        ForEach ($Variable in $NewVariables) {
          If (($Scope -eq "Global" -and $Variable.Name -eq "BaseVariables") -or ($Scope -eq "Script" -and $Variable.Name -eq "ExitCode")) {
            Continue;
          }
          Remove-Variable -Scope $Scope -Name $Variable.Name -ErrorAction SilentlyContinue;
        }
      }
    }

    If ($script:UseToken) {
      Remove-Variable -Scope Script -Name "Token" -ErrorAction SilentlyContinue;
    }

    If ($Null -ne $PopLocation) {
      Pop-Location -StackName $PopLocation -ErrorAction SilentlyContinue;
    }
  }
  End {
    $Code = $script:ExitCode;
    Remove-Variable -Scope Script -Name "ExitCode" -ErrorAction SilentlyContinue;
    Exit $Code;
    [System.Environment]::Exit($Code);
  }
}