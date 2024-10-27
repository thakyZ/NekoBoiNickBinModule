using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Get, "YoutubeVideo")]
public class GetYoutubeVideoCommand : Cmdlet {
}
/*
[CmdletBinding(DefaultParameterSetName = "Path")]
Param(
  # Specifies the uri to the YouTube video to download.
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "Path",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Uri to the YouTube video to download.")]
  [Parameter(Mandatory = $True,
             Position = 0,
             ParameterSetName = "LiteralPath",
             ValueFromPipeline = $True,
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Uri to the YouTube video to download.")]
  [Alias("Url")]
  [System.String]
  $Uri,
  # Specifies a path to one location.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Path",
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Path to one location.")]
  [Alias("PSPath")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path = $PWD,
  # Specifies a path to one location. Unlike the Path parameter, the value of the LiteralPath parameter is
  # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
  # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
  # characters as escape sequences.
  [Parameter(Mandatory = $False,
             ParameterSetName = "LiteralPath",
             ValueFromPipelineByPropertyName = $True,
             HelpMessage="Literal path to one location.")]
  [Alias("PSLiteralPath")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $LiteralPath = $PWD,
  # Specifies the output file format for the downloaded video.
  [Parameter(Mandatory = $False,
             ParameterSetName = "Path",
             HelpMessage="The output file format for the downloaded video.")]
  [Parameter(Mandatory = $False,
             ParameterSetName = "LiteralPath",
             HelpMessage="The output file format for the downloaded video.")]
  [ValidateSet("3gp","aac","flv","m4a","mp3","mp4","ogg","wav","webm","avi","mkv","mov","flv")]
  [System.String]
  $Format = $Null
)

Begin {
  $script:YtDlp = (Get-Command -Name "yt-dlp" -ErrorAction SilentlyContinue);
  If ($Null -eq $script:YtDlp) {
    Throw "Unable to find command yt-dlp on system path.";
  }
  [System.Int32]$script:ExitCode = 0;
  [System.String]$script:LocationStack = "Download-YoutubeVideo_Stack"

  [System.String]$OutputPath = $PWD;
  If ($PSCmdlet.ParameterSetName -eq "Path") {
    $OutputPath = $Path;
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Path") {
    $OutputPath = $LiteralPath;
  }

  If (-not (Test-Path -LiteralPath $OutputPath -PathType Container)) {
    New-Item -Path $OutputPath -ItemType Directory | Out-Null;
  }

  Push-Location -LiteralPath $OutputPath -StackName $script:LocationStack
}
Process {
  [System.String[]]$Arguments = @();

  If ($Null -ne $Format -and $Format -ne "") {
    $Arguments += @("--format $($Format)");
  }

  $Arguments += @("-o `"%(title)s-%(id)s.%(ext)s`"");

  $Arguments += @("$($Uri)");

  $Job = Start-Job -ScriptBlock {
    [System.Object[]]$StdOut = @();
    [System.Collections.HashTable]$Errors = @{ WhileRunning=@(); FullBlock=@(); };
    $YtDlp = $Args[0];
    [System.String[]]$Arguments = $Args[1];
    [System.String]$Location = $Args[2];
    $_PSCmdlet = $Args[3];
    [System.Int32]$ExitCode = 1;
    Try {
      [System.Diagnostics.ProcessStartInfo]$ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new();
      $ProcessStartInfo.FileName = $YtDlp.Source;
      $ProcessStartInfo.Arguments = ($Arguments -join " ");
      $ProcessStartInfo.UseShellExecute = $False;
      $ProcessStartInfo.WorkingDirectory = $Location;
      $ProcessStartInfo.RedirectStandardInput = $False;
      $ProcessStartInfo.RedirectStandardOutput = $True;
      $ProcessStartInfo.RedirectStandardError = $True;
      $ProcessStartInfo.CreateNoWindow = $True;
      [System.Diagnostics.Process]$Process = [System.Diagnostics.Process]::new();
      $Process.StartInfo = $ProcessStartInfo;
      $Process.Start() | Out-Null
      [System.IO.StreamReader]$StandardOutput = $Process.StandardOutput;
      [System.IO.StreamReader]$StandardError = $Process.StandardError;
      [System.Boolean]$ProcessState = $Process.HasExited;
      While (-not $ProcessState) {
        Try {
          [System.String]$StdOutTemp = [System.Convert]::ToChar($StandardOutput.Read()).ToString();
          [System.String]$StdErrTemp = [System.Convert]::ToChar($StandardError.Read()).ToString();
          If ($Null -ne $StdOutTemp -and $StdOutTemp -ne "") {
            Write-Host -Object $StdOutTemp -NoNewLine | Out-Host;
            [System.Console]::Write($StdOutTemp);
            $_PSCmdlet.WriteInformation($StdErrTemp);
            $StdOut += @($StdOutTemp)
          }
          If ($Null -ne $StdErrTemp -and $StdErrTemp -ne "") {
            Write-Host -Object $StdErrTemp -NoNewLine | Out-Host;
            [System.Console]::Write($StdErrTemp);
            $_PSCmdlet.WriteError($StdErrTemp);
            $StdOut += @($StdErrTemp)
          }
        } Catch {
          $Errors.WhileRunning += @($_);
          Write-Warning -Message $_.Exception.Message | Out-Host;
        }
        $ProcessState = $Process.HasExited;
      }
      Write-Output -InputObject @($Errors, $Process.ExitCode, $StdOut, $Process, $ProcessStartInfo);
    } Catch {
      $Errors.FullBlock += @($_);
      Write-Output -InputObject @($Errors, $ExitCode, $StdOut, $Null, $Null);
    }
  } -ArgumentList @($script:YtDlp, $Arguments, $PWD, $PSCmdlet);
  $JobState = (Get-Job -InstanceId $Job.InstanceId).State;
  While ($JobState -eq "Running") {
    Start-Sleep -Seconds 5;
    $JobState = (Get-Job -InstanceId $Job.InstanceId).State;
  }

  $JobReceived = (Receive-Job -InstanceId $Job.InstanceId);

  If ($Job.State -eq "Completed") {
    Write-Output -InputObject $JobReceived[2] | Out-Host;
    Write-Output -InputObject $JobReceived | Out-Host;
    Write-Output -InputObject $JobReceived;
  } ElseIf ($Job.State -eq "Failed") {
    Write-Output -InputObject $JobReceived[2] | Out-Host;
    Write-Output -InputObject $JobReceived | Out-Host;
    Write-Output -InputObject $JobReceived;
  } Else {
    Write-Error -Message "Failed with unknown status code `"$($Job.State)`"." | Out-Host;
    Write-Output -InputObject $JobReceived[2] | Out-Host;
    Write-Output -InputObject $JobReceived | Out-Host;
    Write-Output -InputObject $JobReceived;
  }

  Remove-Job -Id $Job.Id;

  $script:ExitCode = $JobReceived[1];
}
End {
  Exit $script:ExitCode;
}
Clean {
  Pop-Location -StackName $script:LocationStack
  Remove-Variable -Scope Script -Name "YtDlp";
  Remove-Variable -Scope Script -Name "LocationStack";
  Remove-Variable -Scope Script -Name "ExitCode";
}
*/
