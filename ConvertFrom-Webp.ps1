[CmdletBinding()]
Param(
  # Specifies a path to one or more locations.
  [Parameter(Mandatory = $True,
             Position = 0,
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Path to one or more locations.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $Path,
  # Specifies to recursively look for webp files.
  [Parameter(Mandatory = $False,
             Position = 1,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage = "Recursively look for webp files.")]
  [Alias("R")]
  [switch]
  $Recurse
)

Class FileMetaData {
  [System.DateTime]$CreationTime;
  [System.DateTime]$CreationTimeUtc;
  [System.DateTime]$LastWriteTime;
  [System.DateTime]$LastWriteTimeUtc;
  [System.DateTime]$LastAccessTime;
  [System.DateTime]$LastAccessTimeUtc;
  [System.IO.FileAttributes]$Attributes;
  [System.Security.AccessControl.FileSystemSecurity]$Acl;
}

Function Get-FileMetaData {
  [CmdletBinding(DefaultParameterSetName = "PSPath")]
  Param(
    # Specifies a path to one or more locations.
    [Parameter(Mandatory = $True,
               Position = 0,
               ParameterSetName = "PSPath",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage = "Path to one or more locations.")]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath")]
    [string]
    $Path
  )

  $Output = (New-Object -TypeName FileMetaData)
  Try {
    $Item = (Get-Item -Path $Path);
    $Output.CreationTime = $Item.CreationTime;
    $Output.CreationTimeUtc = $Item.CreationTimeUtc;
    $Output.LastWriteTime = $Item.LastWriteTime;
    $Output.LastWriteTimeUtc = $Item.LastWriteTimeUtc;
    $Output.LastAccessTime = $Item.LastAccessTime;
    $Output.LastAccessTimeUtc = $Item.LastAccessTimeUtc;
    $Output.Attributes = $Item.Attributes;
    $Output.Acl = (Get-Acl -Path $Path);
    Return $Output;
  } Catch {
    Throw $_;
  }
}

Function Set-FileMetaData {
  [CmdletBinding(DefaultParameterSetName = "PSPath")]
  Param(
    # Specifies a path to one or more locations.
    [Parameter(Mandatory = $True,
               Position = 0,
               ParameterSetName = "PSPath",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage = "Path to one or more locations.")]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath")]
    [string]
    $Path,
    # Specifies the metadata to apply to the file.
    [Parameter(Mandatory = $True,
               Position = 1,
               ParameterSetName = "PSPath",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage = "The metadata to apply to the file.")]
    [ValidateNotNullOrEmpty()]
    [FileMetaData]
    $FileMetaData
  )

  Try {
    Set-ItemProperty -LiteralPath $Path -Name CreationTime -Value $FileMetaData.CreationTime;
    Set-ItemProperty -LiteralPath $Path -Name CreationTimeUtc -Value $FileMetaData.CreationTimeUtc;
    Set-ItemProperty -LiteralPath $Path -Name LastWriteTime -Value $FileMetaData.LastWriteTime;
    Set-ItemProperty -LiteralPath $Path -Name LastWriteTimeUtc -Value $FileMetaData.LastWriteTimeUtc;
    Set-ItemProperty -LiteralPath $Path -Name LastAccessTime -Value $FileMetaData.LastAccessTime;
    Set-ItemProperty -LiteralPath $Path -Name LastAccessTimeUtc -Value $FileMetaData.LastAccessTimeUtc;
    Set-ItemProperty -LiteralPath $Path -Name Attributes -Value $FileMetaData.Attributes;
    Set-Acl -LiteralPath $Path -AclObject $FileMetaData.Acl;
  } Catch {
    Throw $_;
  }
}

Function Test-OutputFileExists {
  [CmdletBinding(DefaultParameterSetName = "PSPath")]
  Param(
    # Specifies a path to one or more locations.
    [Parameter(Mandatory = $True,
               Position = 0,
               ParameterSetName = "PSPath",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage = "Path to one or more locations.")]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath")]
    [string]
    $Path,
    # Specifies a path to one or more locations. Wildcards are permitted.
    [Parameter(Mandatory = $True,
               Position = 0,
               ParameterSetName = "PSPathWildcards",
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage="Path to one or more locations. Wildcards are permitted.")]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [Alias("PathWildcard", "PSPathWildcards", "PSPathWildcard")]
    [string]
    $PathWildcards
  )

  If ($PSCmdlet.ParameterSetName -eq "PSPath") {
    If (Test-Path -LiteralPath $Path -PathType Leaf) {
      Return $True;
    } ElseIf (Test-Path -LiteralPath $Path -PathType Container) {
      Return $True;
    }
  } Else {
    If (Test-Path -LiteralPath $Path -PathType Leaf) {
      Return $True;
    } ElseIf (Test-Path -LiteralPath $Path -PathType Container) {
      Return $True;
    }
  }

  Return $False;
}

Function Get-LastDuplicateNameFiles {
  Param(
    # Specifies the output file path
    [Parameter(Mandatory = $True,
      Position = 0,
      HelpMessage = "Path to one or more locations.")]
    [string]
    $Path
  )

  $OutputDirectory = (Get-Item -LiteralPath $Path);
  $OutputBaseName = (Get-Item -LiteralPath $Path).BaseName;
  $OutputExtension = (Get-Item -LiteralPath $Path).Extension;

  If (Test-Path -LiteralPath $Path -PathType Leaf) {
    $OutputDirectory = $OutputDirectory.Directory.FullName;
  } ELseIf (Test-Path -LiteralPath $Path -PathType Container) {
    Write-Warning -Message "Supplied path was a type of Container."
    $OutputDirectory = $OutputDirectory.Patent.FullName;
  }

  $RegexString = [System.Text.RegularExpressions.Regex]::Escape("$($OutputBaseName) (\d+)($OutputExtension)")
  $Items = (Get-ChildItem -LiteralPath $OutputDirectory -File | Where-Object { $_.Name -match "$($OutputBaseName) (\d+)$($OutputExtension)" })

  [Int32[]]$IntCount = @();

  ForEach ($Item in $Items) {
    $RegexString = [System.Text.RegularExpressions.Regex]::Escape("$($Item.BaseName) (\d+)$($Item.Extension)");
    $Match = [System.Text.RegularExpressions.Regex]::Match("$($Item.Name)", $RegexString, "IgnoreCase");
    If ($Null -ne $Match -and $Match.Groups.Count -eq 2) {
      [Int32]$Int = [Int32]::Parse($Match.Groups[1].Value);
      $IntCount += @($Int);
    } ElseIf ($Null -eq $Match) {
      Write-Warning -Message "`$Match returned null.`n`$Item.Name = `"$($Item.Name)`"`n`$RegexString = `"$($RegexString)`"";
    } ElseIf ($Match.Groups.Count -ne 2) {
      Write-Warning -Message "`$Match.Groups.Count returned not equal to 2.`n`$Item.Name = `"$($Item.Name)`"`n`$RegexString = `"$($RegexString)`"";
      Write-Output $Match | Out-Host;
    }
  }

  [Int32]$FoundInt = -1;

  For ($Index = 0; $Index -lt ($IntCount | Measure-Object -Maximum); $Index++) {
    If ($IntCount -notcontains $Index) {
      Write-Host -ForegroundColor White -Object "Found missing index: " -NoNewLine;
      Write-Host -ForegroundColor Green -Object "$($Index)" -NoNewLine;
      Write-Host -ForegroundColor White -Object ".";
      $FoundInt = $Index;
      Break;
    }
  }

  $OutputPath = (Join-Path -Path $OutputDirectory -ChildPath "$($OutputBaseName) ($($FoundInt))$($OutputExtension)");

  Return $OutputPath;
}

Function Get-OutputPath {
  Param(
    # Specifies the output file path
    [Parameter(Mandatory = $True,
      Position = 0,
      HelpMessage = "Path to one or more locations.")]
    [string]
    $Path
  )

  $OutputPath = $Path;

  If (Test-OutputFileExists -Path $OutputPath) {

  }

  Return $OutputPath;
}

$Items = @();

$Dwebp = (Get-Command -Name "dwebp" -ErrorAction SilentlyContinue);

If ($Null -eq $Dwebp) {
  Write-Error -Message "Could not find program `"dwebp`" on system environment path.";
  Exit 1;
}

If ($Recurse) {
  $Items = (Get-ChildItem -LiteralPath $Path -File -Recurse -Filter "*.webp");
} Else {
  $Items = (Get-ChildItem -LiteralPath $Path -File -Filter "*.webp");
}

ForEach ($Item in $Items) {
  Try {
    $MetaData = (Get-FileMetaData -Path $Item.FullName);
    $OutputPath = (Get-OutputPath -Path(Join-Path -Path $Item.Directory.FullName -ChildPath "$($Item.BaseName).png"));
    & "$($Dwebp)" "$($Item.Fullname)" "-o" $OutputPath;
    Start-Sleep -Milliseconds 500;
    Remove-Item $Item.FullName;
    Set-FileMetaData -Path $OutputPath -FileMetaData $MetaData;
    Start-Sleep -Seconds 1;
  } Catch {
    Write-Error -Exception $_.Exception -Message $_.Exception.Message;
    Break;
  }
}
