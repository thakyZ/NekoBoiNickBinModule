using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Invoke, "Pixel5")]
public class InvokePixel5Command : Cmdlet {
}
/*
$env:PATH = "$($env:APROG_DIR)\Android\Sdk\emulator;$env:PATH"
Start-Process -NoNewWindow -FilePath "emulator.exe" -ArgumentList "-avd", "Pixel_4_API_30", "-netdelay", "none", "-netspeed", "full" -WorkingDirectory "$($env:APROG_DIR)\Android\Sdk\emulator"
*/