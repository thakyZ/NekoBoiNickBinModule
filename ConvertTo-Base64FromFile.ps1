[CmdletBinding()]
Param(
  [System.String]
  $Path,
  [Switch]
  $Compress
)

Begin {
  [IO.FileStream]  $FileStream   = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read);
  [IO.MemoryStream]$MemoryStream = [IO.MemoryStream]::new();
  $Output = $Null;
} Process {
  $FileStream.CopyTo($MemoryStream);
  $Output = (ConvertTo-Base64 -MemoryStream $MemoryStream -Compress:($Compress -eq $True));
} End {
  Write-Output -NoEnumerate -InputObject $Output;
} Clean {
  $FileStream.Close();
  $MemoryStream.Close();
}