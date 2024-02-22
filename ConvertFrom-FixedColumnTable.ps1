# Note:
#  * Accepts input only via the pipeline, either line by line,
#    or as a single, multi-line string.
#  * The input is assumed to have a header line whose column names
#    mark the start of each field
#    * Column names are assumed to be *single words* (must not contain spaces).
#  * The header line is assumed to be followed by a separator line
#    (its format doesn't matter).
#function ConvertFrom-FixedColumnTable {
[CmdletBinding()]
[OutputType([Object[]])]
Param(
  # Specifies the input object to convert into a powershell table.
  [Parameter(ValueFromPipeline = $True,
    HelpMessage = "The input object to convert into a powershell table.`n" +
    "Note:`n" +
    " * Accepts input only via the pipeline, either line by line,`n" +
    "   or as a single, multi-line string.`n" +
    " * The input is assumed to have a header line whose column names`n" +
    "   mark the start of each field`n" +
    "   * Column names are assumed to be *single words* (must not contain spaces).`n" +
    " * The header line is assumed to be followed by a separator line`n" +
    "   (its format doesn't matter).")]
  [String[]]
  $InputObject
)

Begin {
  If ($Null -eq $InputObject -or $InputObject.Length -eq 0) {
    Write-Error -Message "Argument InputObject must not be null or an empty array.";
    Exit 1;
  }

  #region Process InputObject from object or string or object array or object string;

  $Lines = @();

  If ($InputObject.GetType() -eq [string[]] -or $InputObject.GetType() -eq [object[]]) {
    If ($InputObject.Length -eq 1 -and $InputObject[0].Contains("`n")) {
      $Lines = [Regex]::Split($InputObject[0].TrimEnd("`r", "`n"), '\r?\n');
    } Else {
      $Lines = $InputObject;
    }
  } ElseIf ($InputObject.GetType() -eq [string]) {
    $Lines = [Regex]::Split($InputObject.TrimEnd("`r", "`n"), '\r?\n');
  } Else {
    $Lines = @("$($InputObject)");
  }

  #endregion

  #region Initialize fields

  Set-StrictMode -Version 1;
  $LineNdx = 0;
  $FieldStartIndices = 0;
  # [PSCustomObject[]] $Output = @();


  #endregion

  #region Turnicate lines above table header

  $FoundHeader = 0;
  $FoundHeaderIndex = 0;
  $Null = ($Lines | Where-Object {
      $FoundHeaderOutput = $False;
      $Temp = ($_ -Split "");
      $Temp2 = ($Temp | Where-Object { $_ -eq "-" });
      If ($Temp2.Length -eq $_.Length) {
        $FoundHeader = $FoundHeaderIndex;
        $FoundHeaderOutput = $True;
      }
      $FoundHeaderIndex++;
      Return $FoundHeaderOutput;
    });
  $FoundHeader = $FoundHeader - 1;

  $FoundHeaderIndex = 0;
  $Lines = ($Lines | Where-Object {
    If ($FoundHeaderIndex -ge $FoundHeader) {
      Return $True;
    }
    $FoundHeaderIndex++;
    Return $False;
  });

  #endregion
}
Process {
  #region Process lines

  $Output = (($Lines -Join "`n") | ConvertFrom-SourceTable)

  <#ForEach ($Line in $Lines) {
    $LineNdx++;
    If ($LineNdx -eq 1) {
      # header line
      $HeaderLine = $Line
    } ElseIf ($LineNdx -eq 2) {
      # separator line
      # Get the indices where the fields start.
      $HeaderLineMatches = [regex]::Matches($HeaderLine, '\b\S');
      If ($HeaderLineMatches.Length -gt 0) {
        $FieldStartIndices = $HeaderLineMatches.Index;
      }
      # Calculate the field lengths.
      $FieldLengths = ForEach ($Index in 1..($FieldStartIndices.Count - 1)) {
        $FieldStartIndices[$Index] - $FieldStartIndices[$Index - 1] - 1;
      }
      # Get the column names
      $ColNames = ForEach ($Index in 0..($FieldStartIndices.Count - 1)) {
        If ($Index -eq $FieldStartIndices.Count - 1) {
          $HeaderLine.Substring($FieldStartIndices[$Index]).Trim()
        } Else {
          $HeaderLine.Substring($FieldStartIndices[$Index], $FieldLengths[$Index]).Trim()
        }
      }
    } Else {
      # data line
      $OrderedHashTable = [Ordered] @{} # ordered helper hashtable for object constructions.
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

        If (($NoteProperties | Where-Object {
          If ([string]::IsNullOrEmpty($ToTest.Value)) {
            Return $True;
          }
          Return $False;
        }).Length -gt 0) {
          $LocalOutput = $False;
        }

        Return $LocalOutput;
      }

      If (-not (Test-AllColumnsFilled -InputObject $OrderedHashTable)) {
        Write-Output $OrderedHashTable | Out-Host;
        Continue;
      }
      # Convert the ordered helper hashtable to an object and output it.
      $Output += @([PSCustomObject] $OrderedHashTable);
    }
  }#>

  #end region
}
End {
  #region finish

  # Clean up strict mode
  Set-StrictMode -Off;
  $Output | Format-Table | Write-Output;

  #endregion
}
#}