# Borrowed from:
# @see https://github.com/alx9r/ToolFoundations/blob/master/Functions/classAccessor.ps1
If ($PSVersionTable.PSVersion.Major -ge "5") {
  Function Get-AccessorPropertyName {
    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
      [Parameter(ValueFromPipeline = $true)]
      [System.String]
      $String
    )
    Process {
      # check for missing underscore
      $Regex = [System.Text.RegularExpressions.Regex]::new('\$(?!_)(?<PropertyName>\w*)\s*=\s*');
      $Match = $Regex.Match($String)
      If ($Match.Success -eq $True) {
        Throw [System.FormatException]::new("Missing underscore in property name at`n$($String)");
      }

      # the main match
      $Regex = [System.Text.RegularExpressions.Regex]::new('\$_(?<PropertyName>\w*)\s*=\s*');
      $Match = $Regex.Match($String)
      Write-Output -NoEnumerate -InputObject (ConvertFrom-RegexNamedGroupCapture -Match $Match -Regex $Regex).PropertyName
    }
  }

  Function Accessor {
    [CmdletBinding()]
    Param (
      # Specifies the object to access as a parent for the property.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "The object to access as a parent for the property.")]
      [System.Object]
      $Object,
      # Specifies the script block containing the Get-Variable and Set-Variable accessors.
      [Parameter(Mandatory = $True,
                 Position = 1,
                 HelpMessage = "The script block containing the Get-Variable and Set-Variable accessors.")]
      [System.Management.Automation.ScriptBlock]
      $Scriptblock
    )
    Process {
      # Extract the property name
      $PropertyName = ($MyInvocation.Line | Get-AccessorPropertyName);


      # Prepare the get and set functions that are invoked
      # inside the scriptblock passed to Accessor.
      $Functions = @{
        GetFunction = {
          Param (
            $Scriptblock = (
              # default getter
              Invoke-Expression "{`$this._$($PropertyName)}"
            )
          )
          Return New-Object "System.Management.Automation.PSObject" -Property @{ Accessor = 'Get'; Scriptblock = $Scriptblock }
        }
        SetFunction = [System.Management.Automation.ScriptBlock]::Create({
            Param (
              $Scriptblock = (
                # default setter
                Invoke-Expression "{Param(`$p) `$this._$($PropertyName) = `$p}"
              )
            )
            Return New-Object "System.Management.Automation.PSObject" -Property @{
              Accessor = 'Set'; Scriptblock = $Scriptblock
            }
          })
      }

      # Prepare the variables that are available inside the
      # scriptblock that is passed to the accessor.
      $this = $Object; # Ignore: PSAvoidAssignmentToAutomaticVariable
      $__PropertyName = $PropertyName
      $Variables = (Get-Variable 'this', '__PropertyName');

      # Avoid a naming collision with the set and get aliases
      $Done = $False;
      [System.Management.Automation.ErrorRecord[]]$ErrorRecords = @();
      Try {
        Remove-Alias -Name "Set" -Scope "Local" -ErrorAction "Stop"
      } Catch {
        $ErrorRecords += $_;
        Try {
          Remove-Item alias:\Set -ErrorAction "Stop";
          $Done = $True;
        } Catch {
          $ErrorRecords += $_;
        }
      } Finally {
        If ($Done -eq $False) {
          ForEach ($ErrorRecord in $ErrorRecords) {
            Write-Error -ErrorRecord $ErrorRecord;
          }
          Throw "Failed to remove Set alias.";
        }
      }
      Set-Alias -Name "Set" -Value "SetFunction"
      Set-Alias -Name "Setter" -Value "SetFunction"
      Set-Alias -Name "Get" -Value "GetFunction"
      Set-Alias -Name "Getter" -Value "GetFunction"

      # Invoke the scriptblock
      $Items = $MyInvocation.MyCommand.Module.NewBoundScriptBlock(
        $Scriptblock
      ).InvokeWithContext($Functions, $Variables)

      # This empty getter is invoked when no get statement is
      # included in Accessor.
      $Getter = @{}


      $InitialValue = [System.Collections.ArrayList]::new()
      ForEach ($Item in $Items) {
        # Get the initializer values
        If (@("Get", "Set") -notcontains $Item.Accessor) {
          $InitialValue.Add($Item) | Out-Null;
        }

        # Extract the getter
        If ($Item.Accessor -eq "Get") {
          $Getter = $Item.Scriptblock;
        }

        # Extract the setter
        If ( $Item.Accessor -eq "Set" ) {
          $Setter = $Item.Scriptblock;
        }
      }

      # If there is no getter or setter don't add a ScriptProperty.
      If ((-not $Getter -and -not $Setter) -or ($Null -eq $Getter -and $Null -eq $Setter)) {
        Write-Output -NoEnumerate -InputObject $InitialValue
      }

      # Prepare to create the ScriptProperty.
      $Splat = @{
        MemberType = "ScriptProperty";
        Name       = $PropertyName;
        Value      = $Getter;
      }

      # Omit the setter parameter if it is null.
      If ($Setter -and $Null -ne $Setter) {
        $Splat.SecondValue = $Setter
      }

      # Add the accessors by creating a ScriptProperty.
      $Object | Add-Member @Splat | Out-Null;

      # Return the initializers.
      Write-Output -NoEnumerate -InputObject $InitialValue
    }
  }
}