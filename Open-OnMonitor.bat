set args=%*
call set args=%%args:%1 %2=%%
set "exe=%~2"
set "monitor=%~1"
set "scriptname=%~nx0"
powershell -noprofile "iex (${%~f0} | out-string)"
exit /b %ERRORLEVEL%

: end batch / begin powershell #>

function usage() {
  write-host -nonewline "Usage: "
  write-host -f white "$env:scriptname monitor# filename [arguments]`n"
  write-host -nonewline "* "
  write-host -f white -nonewline "monitor# "
  write-host "is a 1-indexed integer.  Monitor 1 = 1, monitor 2 = 2, etc."
  write-host -nonewline "* "
  write-host -f white -nonewline "filename "
  write-host "is an executable or a document or media file.`n"
  write-host -nonewline "$env:scriptname mimics "
  write-host -f white -nonewline "start"
  write-host ", searching for filename both in %PATH% and"
  write-host "in Windows' app paths (web browsers, media players, etc).`n"
  write-host "Examples:"
  write-host "To display YouTube in Firefox on your second monitor, do"
  write-host -f white "   $env:scriptname 2 firefox `"www.youtube.com`"`n"
  write-host "To play an mp3 file using the default player on monitor 1:"
  write-host -f white "   $env:scriptname 1 mp3file.mp3"
  exit 1
}

add-type user32_dll @'
  [DllImport("user32.dll")]
  public static extern void SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
    int x, int y, int cx, int cy, uint uFlags);
'@ -namespace System

add-type -as System.Windows.Forms
if ($env:monitor -gt [windows.forms.systeminformation]::MonitorCount) {
  [int]$monitor = [windows.forms.systeminformation]::MonitorCount
} else {
  [int]$monitor = $env:monitor
}
try {
  if ($env:args) {
    $p = start $env:exe $env:args -passthru
  } else {
    $p = start $env:exe -passthru
  }
}
catch { usage }

$shell = new-object -COM Wscript.Shell
while (-not $shell.AppActivate($p.Id) -and ++$i -lt 100) { sleep -m 50 }

try {
  $x = [Windows.Forms.Screen]::AllScreens[--$monitor].Bounds.X
  $hwnd = (Get-Process -id $p.Id)[0].MainWindowHandle
  [user32_dll]::SetWindowPos($hwnd, [intptr]::Zero, $x, 0, 0, 0, 0x41);
}
finally { exit 0 }