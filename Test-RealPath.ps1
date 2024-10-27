[CmdletBinding()]
[OutputType([System.Boolean])]
Param(
  [Parameter(Position = 0,
             ParameterSetName = "Path",
             Mandatory = $True,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True
             HelpMessage = "Gets or sets the path parameter to the command.")]
  [AllowNull()]
  [AllowEmptyString()]
  [AllowEmptyCollection()]
  [System.String[]]
  $Path,
  [Parameter(HelpMessage = "Gets or sets the filter property.")]
  [System.String]
  $Filter,
  [Parameter(HelpMessage = "Gets or sets the include property.")]
  [System.String[]]
  $Include,
  [Parameter(HelpMessage = "Gets or sets the exclude property.")]
  [System.String[]]
  $Exclude,
  [Parameter(HelpMessage = "Gets or sets the isContainer property.")]
  [Alias("Type")]
  [Microsoft.PowerShell.Commands.TestPathType]
  $PathType = [Microsoft.PowerShell.Commands.TestPathType]::Any,
  [Parameter(HelpMessage = "Gets or sets the IsValid parameter.")]
  [Switch]
  $IsValid
)
DynamicParam {
  [System.Object] $Result = $Null;
  If (-not $IsValid) {
      If ($Null -ne $Path -and $Path.Length -gt 0 -and $Null -ne $Path[0]) {
          $Result = $InvokeProvider.Item.ItemExistsDynamicParameters($Path[0], $Context);
      } Else {
          $Result = $InvokeProvider.Item.ItemExistsDynamicParameters(".", $Context);
      }
  }

  Write-Output -NoEnumerate -InputObject Result;
} Begin {
  [System.Boolean] $Output = $False;
  [System.String[]] $_paths = @();
} Process {
  If ($Null -eq $_paths -or $_paths.Length -eq 0) {
    Write-Error -ErrorRecord [ErrorRecord]::new([ArgumentNullException]::new(TestPathResources.PathIsNullOrEmptyCollection), "NullPathNotPermitted", [ErrorCategory]::InvalidArgument, $Path));
    return;
  }

  [CmdletProviderContext] $CurrentContext = $CmdletProviderContext;

  ForEach ($_path in $_paths) {
    [System.Boolean] $Result = $False;
    If ([System.String]::IsNullOrWhiteSpace($_path)) {
      If ($_path -is null) {
          Write-Error -ErrorRecord [ErrorRecord]::new([ArgumentNullException]::new(TestPathResources.PathIsNullOrEmptyCollection), "NullPathNotPermitted", [ErrorCategory]::InvalidArgument, $_path));
      } Else {
        Write-Output -NoEnumerate -InputObject $Result;
      }
      Continue;
    }
    Try {
      If ($IsValid) {
        $Result = [SessionState]::Path.IsValid($_path, $_currentContext);
      } Else {
        $Result = [InvokeProvider]::Item.Exists($_path, $_currentContext);

        if ($PathType == [Microsoft.PowerShell.Commands.TestPathType]::Container)
        {
          $Result = $Result -band [InvokeProvider]::Item.IsContainer($_path, $_currentContext);
        }
        else if ($PathType == [Microsoft.PowerShell.Commands.TestPathType]::Leaf)
        {
          $Result = $Result -band -not [InvokeProvider]::Item.IsContainer($_path, $_currentContext);
        }
      }
    }

    // Any of the known exceptions means the path does not exist.
    catch (PSNotSupportedException)
    {
    }
    catch (DriveNotFoundException)
    {
    }
    catch (ProviderNotFoundException)
    {
    }
    catch (ItemNotFoundException)
    {
    }

    WriteObject(result);
  }
} End {
  Write-Output -NoEnumerate -InputObject $Output;
}