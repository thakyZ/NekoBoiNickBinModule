# Note:
#  * Accepts input only via the pipeline, either line by line,
#    or as a single, multi-line string.
#  * The input is assumed to have a header line whose column names
#    mark the start of each field
#    * Column names are assumed to be *single words* (must not contain spaces).
#  * The header line is assumed to be followed by a separator line
#    (its format doesn't matter).
#function ConvertFrom-FixedColumnTable {
[CmdletBinding(PositionalBinding = $True, DefaultParameterSetName = "Default")]
[OutputType([System.Object[]])]
Param(
  # Specifies the input object to convert into a powershell table.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Default",
             ValueFromPipeline = $True,
             HelpMessage = "The input object to convert into a powershell table.`n" +
             "Note:`n" +
             " * Accepts input only via the pipeline, either line by line,`n" +
             "   or as a single, multi-line string.`n" +
             " * The input is assumed to have a header line whose column names`n" +
             "   mark the start of each field`n" +
             "   * Column names are assumed to be *single words* (must not contain spaces).`n" +
             " * The header line is assumed to be followed by a separator line`n" +
             "   (its format doesn't matter).")]
  [ValidateNotNull()]
  [System.Object]
  $InputObject,
  # Specifies a switch to use an alternative package for building the table.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Default",
             HelpMessage = "A switch to use an alternative package for building the table.`n" +
             "⚠️ WARNING: The package may not be installed or may not have the expected output.")]
  [Alias("Alt", "Alternative")]
  [switch]
  $AlternativeBuilder = $False
)

Begin {
  If ($Null -eq $InputObject -or $InputObject.Length -eq 0) {
    Write-Host "IsNull: $($Null -eq $InputObject)";
    Write-Host "Length: $($InputObject.Length)";
    Write-Host "InputObject: $($InputObject)";
    Write-Error -Message "Argument InputObject must not be null or an empty array.";
    Exit 1;
  }

  # region Process InputObject from object or string or object array or object string;

  $script:Lines = @();

  If ($InputObject.GetType() -eq [System.String[]] -or $InputObject.GetType() -eq [System.Object[]]) {
    If ($InputObject.Length -eq 1 -and $InputObject[0].Contains("`n")) {
      $script:Lines = [System.Text.RegularExpressions.Regex]::Split($InputObject[0].TrimEnd("`r", "`n"), '\r?\n');
    } Else {
      $script:Lines = $InputObject;
    }
  } ElseIf ($InputObject.GetType() -eq [System.String]) {
    $script:Lines = [System.Text.RegularExpressions.Regex]::Split($InputObject.TrimEnd("`r", "`n"), '\r?\n');
  } Else {
    $script:Lines = @("$($InputObject)");
  }

  # endregion

  # region Initialize fields

  Set-StrictMode -Version 1;
  $LineNdx = 0;
  $FieldStartIndices = 0;
  # [PSCustomObject[]] $Output = @();


  # endregion

  # region Truncate lines above table header

  $script:FoundHeader = 0;
  $script:FoundHeaderIndex = 0;
  $Null = ($Lines | Where-Object {
      $FoundHeaderOutput = $False;
      $Temp = ($_ -Split "");
      $Temp2 = ($Temp | Where-Object { $_ -eq "-" });
      If ($Temp2.Length -eq $_.Length) {
        $script:FoundHeader = $script:FoundHeaderIndex;
        $FoundHeaderOutput = $True;
      }
      $script:FoundHeaderIndex++;
      Return $FoundHeaderOutput;
    });
  $script:FoundHeader = $script:FoundHeader - 1;

  $script:FoundHeaderIndex = 0;
  $Lines = ($Lines | Where-Object {
      If ($script:FoundHeaderIndex -ge $script:FoundHeader) {
        Return $True;
      }
      $script:FoundHeaderIndex++;
      Return $False;
    });

  # endregion
}
Process {
  # region Process lines
  If ($AlternativeBuilder) {
    $Output = (($script:Lines -join "`n") | ConvertFrom-SourceTable)
  } Else {
    ForEach ($Line in $script:Lines) {
      $LineNdx++;
      If ($LineNdx -eq 1) {
        # header line
        $HeaderLine = $Line
      } ElseIf ($LineNdx -eq 2) {
        # separator line
        # Get the indices where the fields start.
        $HeaderLineMatches = [System.Text.RegularExpressions.Regex]::Matches($HeaderLine, '\b\S');
        If ($HeaderLineMatches.Length -gt 0) {
          $FieldStartIndices = $HeaderLineMatches.Index;
        }
        # Calculate the field lengths.
        $FieldLengths = @();
        ForEach ($Index in 1..($FieldStartIndices.Count - 1)) {
          $FieldLengths += @($FieldStartIndices[$Index] - $FieldStartIndices[$Index - 1] - 1);
        }
        # Get the column names
        $ColNames = @();
        ForEach ($Index in 0..($FieldStartIndices.Count - 1)) {
          If ($Index -eq $FieldStartIndices.Count - 1) {
            $ColNames += @($HeaderLine.Substring($FieldStartIndices[$Index]).Trim());
          } Else {
            $ColNames += @($HeaderLine.Substring($FieldStartIndices[$Index], $FieldLengths[$Index]).Trim());
          }
        }
      } Else {
        # data line
        $OrderedHashTable = [Ordered] @{}; # ordered helper hashtable for object constructions.
        $Index = 0
        ForEach ($ColName in $ColNames) {
          $OrderedHashTable[$ColName] =
          If ($FieldStartIndices[$Index] -lt $Line.Length) {
            If ($FieldLengths[$Index] -and $FieldStartIndices[$Index] + $FieldLengths[$Index] -le $Line.Length) {
              $Line.Substring($FieldStartIndices[$Index], $FieldLengths[$Index]).Trim();
            } Else {
              $Line.Substring($FieldStartIndices[$Index]).Trim();
            }
          }
          $Index++;
        }

        Function Test-AllColumnsFilled() {
          Param(
            # Parameter help description
            [Parameter(Mandatory = $True)]
            [PSCustomObject]
            $InputObject
          )

          $LocalOutput = $True;
          [PSCustomObject[]] $NoteProperties = @(($InputObject.PSObject.Properties | Where-Object { $_.MemberType -eq "NoteProperty" }));

          If (($NoteProperties | Where-Object { [System.String]::IsNullOrEmpty($ToTest.Value) }).Length -gt 0) {
            $LocalOutput = $False;
          }

          Write-Output -NoEnumerate -InputObject $LocalOutput;
        }

        If (-not (Test-AllColumnsFilled -InputObject $OrderedHashTable)) {
          Write-Output $OrderedHashTable | Out-Host;
          Continue;
        }
        # Convert the ordered helper hashtable to an object and output it.
        $Output += @([PSCustomObject] $OrderedHashTable);
      }
    }
  }
  #end region
}
End {
  # region finish
  # Clean up strict mode
  Set-StrictMode -Off;
  $Output | Write-Output;
  # endregion
}
#}