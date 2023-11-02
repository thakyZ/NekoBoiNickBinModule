$code=@'

Public Class DiskInfo
  Private Declare Function QueryDosDevice Lib "kernel32" Alias "QueryDosDeviceA" (ByVal lpDeviceName As String, ByVal lpTargetPath As String, ByVal ucchMax As Long) As Long
  Shared Function GetDeviceName(sDisk As String) As String
    Dim sDevice As String = New String(" ",50)
    if QueryDosDevice(sDisk, sDevice, sDevice.Length) Then
      Return sDevice
    Else
      Throw New System.Exception("sDisk value not found - not a disk.")
    End If
  End Function
End Class

'@

Add-type $code -Language VisualBasic

[diskinfo]::GetDeviceName('c:')
gwmi win32_volume|
  Where-Object{$_.DriveLetter}|
  ForEach-Object{[diskinfo]::GetDeviceName($_.DriveLetter)}