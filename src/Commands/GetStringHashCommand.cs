using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "StringHash")]
public class GetStringHashCommand : Cmdlet {
}
/*
[CmdletBinding()] [OutputType([System.Collections.Hashtable])] Param(   # Specifies a string to convert.   [Parameter(Mandatory = $False,              ValueFromPipelineByPropertyName = $True,              ValueFromRemainingArguments = $True,              HelpMessage = "A string to convert.")]   [ValidateNotNullOrEmpty()]   [System.String]   $String,   # Specifies the hashing algorithm to use. Defaults to 'SHA256'.   [Parameter(Mandatory = $False,              HelpMessage = "The hashing algorithm to use. Defaults to 'SHA256'.")]   [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]   [System.String]   $Algorithm = "SHA256" )  Begin {   [System.Byte[]]$Bytes = [System.Text.Encoding]::UTF8.GetBytes($String)   $AlgorithmObj = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)   $StringBuilder = (New-Object -TypeName System.Text.StringBuilder); } Process {   [System.Byte[]]$ByteString = $AlgorithmObj.ComputeHash($Bytes);   ForEach ($Byte in $ByteString) {     $Null = $StringBuilder.Append($Byte.ToString("x2"));   } } End {   $Output = @{     Algorithm = $Algorithm;     Hash = $StringBuilder.ToString().ToUpper();     String = $String;   };   Write-Output -InputObject $Output; }
*/
