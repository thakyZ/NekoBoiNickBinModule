using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "StellarisModHash")]
public class GetStellarisModHashCommand : Cmdlet {
}
/*
$python = (Get-Command python)  & "$python" "$env:APROG_DIR\bin\stellaris_hasher.py" "--rootdir" "E:\\SteamLibrary\\SteamApps\\workshop\\content\\281990"
*/
