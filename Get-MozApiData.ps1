param(
  # The passphrase for signing.
  [Parameter(Mandatory=$true,Position=0,HelpMessage="The new passphrase for signing.",ParameterSetName="CreateNew")]
  [Switch]
  $Create,
  # Set the current passphrase.
  [Parameter(Mandatory=$true,Position=1,HelpMessage="Set the current passphrase.",ParameterSetName="SetNew")]
  [Switch]
  $Set,
  # The passphrase for signing.
  [Parameter(Mandatory=$false,Position=0,HelpMessage="The passphrase for signing.",ParameterSetName="GetData")]
  [Switch]
  $Get
)
$Hash = $null

if ($Create) {
  if (Test-Path "${HOME}\Pictures\.Security\MozSigningKey" -PathType Leaf) {
    Write-Error -Message "Please set password instead of creating a new one."
    Exit 1
  }
  Write-Host -Object "Please enter new passphrase"
  (ConvertFrom-SecureString (Read-Host -AsSecureString)) | Out-File "${HOME}\Pictures\.Security\MozSigningKey"
  Write-Host -Object "Wrote hash to file."
  Exit 0
}

if ($Set) {
  if (-not (Test-Path "${HOME}\Pictures\.Security\MozSigningKey" -PathType Leaf)) {
    Write-Error -Message "Please create password instead of setting a new one."
    Exit 1
  }
  Write-Host -Object "Please enter current passphrase"
  $CurrentPassphrase = (Read-Host -AsSecureString)
  if ((Test-Path "${HOME}\Pictures\.Security\MozSigningKey" -PathType Leaf)) {
    if ([string]::IsNullOrEmpty($CurrentPassphrase)) {
      Write-Error -Message "Current Passphrase is null or empty."
      Exit 1
    }
    $Hash = (ConvertTo-SecureString (Get-Content -Path "${HOME}\Pictures\.Security\MozSigningKey" -Force));
  }
  if (([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($CurrentPassphrase))).compareTo([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Hash))) -eq 0) {
    Write-Host "Please enter new passphrase"
    $NewPassphrase = (Read-Host -AsSecureString);
    if ([string]::IsNullOrEmpty($NewPassphrase)) {
      Write-Error -Message "New Passphrase is null or empty."
      Exit 1
    }
    (ConvertFrom-SecureString $NewPassphrase) | Out-File "${HOME}\Pictures\.Security\MozSigningKey"
    Write-Host -Object "Wrote new hash to file."
    Exit 0
  } else {
    Write-Error -Message "Passphrase does not match."
    Exit 1
  }
}

if ($Get) {
  if (-not (Test-Path "${HOME}\Pictures\.Security\MozSigningKey" -PathType Leaf)) {
    Write-Error -Message "Please create password instead of getting data."
    Exit 1
  }
  Write-Host -Object "Please enter current passphrase"
  $CurrentPassphrase = (Read-Host -AsSecureString)
  if ((Test-Path "${HOME}\Pictures\.Security\MozSigningKey" -PathType Leaf)) {
    if ([string]::IsNullOrEmpty($CurrentPassphrase)) {
      Write-Error -Message "Current Passphrase is null or empty."
      Exit 1
    }
    $Hash = (ConvertTo-SecureString (Get-Content -Path "${HOME}\Pictures\.Security\MozSigningKey" -Force));
  }
  if (([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($CurrentPassphrase))).compareTo([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Hash))) -eq 0) {
    $Json = ((Get-Content -Path "${HOME}\Pictures\.Security\Moz_Api_Keys.txt") | ConvertFrom-Json)
    Write-Output -NoEnumerate -InputObject @($Json.JWT.issuer
             $Json.JWT.secret)
    Exit 0
  } else {
    Write-Error -Message "Passphrase does not match."
    Exit 1
  }
}