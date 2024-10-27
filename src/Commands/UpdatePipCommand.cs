using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Update, "Pip")]
public class UpdatePipCommand : Cmdlet {
}
/*
(((pip list -o | Select-String -NotMatch "Package", "----------") -Replace '(?<name>[\w\d_]+).+', '${name}') -Split '\n') | ForEach-Object { pip install --upgrade $_ }
*/
