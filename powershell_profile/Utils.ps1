Function Get-Config() {
  Param(
    # Specifies a path to a single location. Unlike the Path parameter, the value of the LiteralPath parameter is
    # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
    # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
    # characters as escape sequences.
    [Parameter(Mandatory = $True,
      Position = 0,
      ParameterSetName = "LiteralPath",
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "Literal path to a single location.")]
    [Alias("PSLiteralPath")]
    [ValidateNotNullOrEmpty()]
    [string]
    $LiteralPath,
    # Specifies a path to a single location.
    [Parameter(Mandatory = $True,
      Position = 0,
      ParameterSetName = "Path",
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = "Path to a single location.")]
    [Alias("PSPath")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Path
  )

  If ($PSCmdlet.ParameterSetName -eq "Path") {
    $ConfigPath = $Path;
  } Else {
    $ConfigPath = $LiteralPath;
  }

  $Returned = $Null;

  Try {
    $ConfigText = (Get-Content -LiteralPath $ConfigPath);
    $Returned = ($ConfigText | ConvertFrom-Json);
  } Catch {
    Write-Error -Exception $_.Exception -Message "Failed to load the JSON config at, $($ConfigPath)"
    Throw $_.Exception;
    Exit 1;
  }

  Return $Returned;
}

Function Get-UnhashedPassword() {
  Param()

  If ($script:Config.gnupg.password_hashed -eq "") {
    $Secure = Read-Host -AsSecureString -Prompt "Insert Password";
    $Encrypted = ConvertFrom-SecureString -SecureString $Secure;
    $script:Config.gnupg.password_hashed = $Encrypted;

    ($script:Config | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path -Path (Get-Item -LiteralPath $Profile).Directory.FullName -ChildPath "config.json");
  }

  $Test = (New-Object -TypeName System.Net.NetworkCredential -ArgumentList @([string]::Empty, (ConvertTo-SecureString -String $script:Config.gnupg.password_hashed))).Password;
  Return $Test;
}

Function Expand-Variables() {
  Param(
    # Specifies the string in which to expand the environment variables of.
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "The string in which to expand the Environment Variables of")]
    [ValidateNotNullOrEmpty]
    [string]
    $InputObject,
    # Specifies the current environmental variables if needed to do so.
    [Parameter(Mandatory = $False, Position = 1, HelpMessage = "The current environmental variables if needed to do so.")]
    [PSObject]
    $EnvironmentVariables = (Get-ChildItem -Path "env:")
  )

  $VariableMatches = [regex]::new('((%|\$)(env:|script:|global:|local:|private:)?[\w_-]+(%)?)').Match($InputObject);

  ForEach ($Match in $VariableMatches.Captures) {

  }
}