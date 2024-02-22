[CmdletBinding()]
Param(
  # Specifies a URI who's contents are to convert.
  [Parameter(Mandatory = $False,
             ValueFromPipelineByPropertyName = $True,
             ValueFromRemainingArguments = $True,
             HelpMessage = "A URI who's contents are to convert.")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Uri,
  # Specifies the hashing algorithm to use. Defaults to 'SHA256'.
  [Parameter(Mandatory = $False,
             HelpMessage = "The hashing algorithm to use. Defaults to 'SHA256'.")]
  [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]
  [System.String]
  $Algorithm = "SHA256",
  # Specifies an authorization method to use. Defaults to 'None'.
  # Must be specified as the authorization header's value should normally be.
  [Parameter(Mandatory = $False,
             HelpMessage = ("Specifies an authorization method to use. Defaults to 'None'. `n" +
                            "Must be specified as the authorization header's value should normally be."))]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Authorization = "None"
)

Begin {
  $AlgorithmObj = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
  $StringBuilder = (New-Object -TypeName System.Text.StringBuilder);
}
Process {
  [System.Byte[]]$Bytes;
  Try {
    $WebRequest = $Null;
    If ($Authorization -eq "None") {
      $WebRequest = (Invoke-WebRequest -Uri $Uri -SkipHttpErrorCheck -ErrorAction SilentlyContinue -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome));
    } Else {
      $WebRequest = (Invoke-WebRequest -Uri $Uri -SkipHttpErrorCheck -ErrorAction SilentlyContinue -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -Headers @{ Authorization = $Authorization });
    }

    If ($WebRequest.StatusCode -eq 200) {
      $Content = $WebRequest.Content;
      If ($Content.GetType() -eq [System.String]) {
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Content);
      } ElseIf ($Content.GetType() -eq [System.String[]]) {
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes(($Content -Join "`n"));
      } ElseIf ($Content.GetType() -eq [System.Byte[]]) {
        $Bytes = $Content;
      }
    }
  } Catch {
    Write-Host -ForegroundColor Red -Object "Failed to invoke WebRequest.`n$($_.Exception.Message)"
    Throw;
  }

  [System.Byte[]]$ByteString = $AlgorithmObj.ComputeHash($Bytes);
  ForEach ($Byte in $ByteString) {
    $Null = $StringBuilder.Append($Byte.ToString("x2"))
  }
}
End {
  $Output = @{
    Algorithm = $Algorithm;
    Hash = $StringBuilder.ToString()
    Uri = $Uri
  }
  Write-Output -InputObject $Output;
}
