using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Invoke, "PixivUtil")]
public class InvokePixivUtilCommand : Cmdlet {
}
/*
Begin {
  #region DynamicParam
  $Default = $True;
  $Arguments = @();
  $Debug = $False;
  ForEach ($Arg in $Args) {
    $ToPut = $Arg;
    If ($Arg.GetType() -ne [System.String]) {
      $ToPut = $Arg.ToString();
    }
    $Arguments += @($ToPut);
  }

  [System.String[]]$OtherArguments = @();

  If ($Default) {
    If ($Null -ne $Arguments) {
      For ($Index = 0; $Index -lt $Arguments.Count; $Index++) {
        Switch ($Arguments[$Index].ToLower()) {
          { $_ -eq "--set_cookie" -or $_ -eq "--setcookie" -or $_ -eq "--set-cookie" -or $_ -eq "-setcookie" -or $_ -eq "-set-cookie" -or $_ -eq "-set_cookie" -or $_ -eq "--sc" } {
            If (-not $Arguments[$Index + 1].StartsWith("--") -or $Arguments[$Index + 1].StartsWith("-")) {
              $CookieSupplied = $True;
              $SuppliedCookie = $Arguments[$Index + 1];
            }
            $SetCookie = $True;
            $Default = $False;
            Break;
          }
          { $_ -eq "--help" -or $_ -eq "-help" -or $_ -eq "-h", $_ -eq "-?" } {
            $Help = $True;
            $Default = $False;
            Break;
          }
          { $_ -eq "--update" -or $_ -eq "-update" -or $_ -eq "-u" } {
            $Update = $True;
            $Default = $False;
            Break;
          }
          { $_ -eq "--debug" -or $_ -eq "-debug" } {
            $Debug = $True;
            Break;
          }
          Default {
            $OtherArguments += $Arguments[$Index];
          }
        }
      }
    }
  }
  #endregion DynamicParam

  $OriginalOutputEncoding = [Console]::OutputEncoding;
  If ($Null -ne $OriginalOutputEncoding -and $OriginalOutputEncoding.GetType() -ne [System.Text.UTF8Encoding]) {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new();
  }

  Function Invoke-Exit() {
    Param(
      # Specifies the exit code to close the script with.
      [Parameter(Mandatory = $False,
        Position = 0,
        ValueFromRemainingArguments = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "The exit code to close the script with.")]
      [Alias("ExitCode")]
      [int]
      $Code = 0
    )
    Write-Debug -Message "Resetting to original output encoding.";
    [Console]::OutputEncoding = $OriginalOutputEncoding;
    Exit $Code;
  }

  Function Get-ObjectSyntax {
    Param(
      # Specifies the type of object to get the color syntax of.
      [Parameter(Mandatory = $True,
        Position = 0,
        ValueFromRemainingArguments = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "The type of object to get the color syntax of.")]
      [Alias("InputType")]
      [System.Type]
      $Type
    )

    If ($Type -match "[Int\d+]" -or $Type -match "[UInt\d+]" -or $Type -eq [System.Double] -or $Type -eq [System.Single] -or $Type -eq [System.Single] -or $Type -eq [System.Decimal]) {
      Return "DarkYellow";
    }
    If ($Type -eq [System.String] -or $Type -eq [System.Char]) {
      Return "DarkCyan";
    }
    If ($Type -eq [System.Boolean]) {
      Return "DarkGreen";
    }
    If ($Type -eq [System.Byte] -or $Type -eq [System.SByte] -or $Type -eq [System.IntPtr] -or $Type -eq [System.UIntPtr]) {
      Return "DarkMagenta";
    }
    Return "DarkMagenta";
  }
  Function Get-ObjectEnclosing {
    Param(
      # Specifies the type of object to get the color syntax of.
      [Parameter(Mandatory = $True,
        Position = 0,
        ValueFromRemainingArguments = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "The type of object to get the color syntax of.")]
      [Alias("InputObject")]
      [System.Object]
      $Object
    )

    If ($Object.GetType() -eq [System.String]) {
      Return "`"$($Object)`"";
    }
    If ($Object.GetType() -eq [System.Char]) {
      Return "'$($Object)'";
    }
    If ($Object.GetType() -eq [System.Boolean]) {
      Return "`$$($Object)";
    }
    If ($Object.GetType() -eq [System.Byte] -or $Object.GetType() -eq [System.SByte] -or $Object.GetType() -eq [System.IntPtr] -or $Object.GetType() -eq [System.UIntPtr]) {
      Return "0x$([System.BitConverter]::ToString($Object).Replace('-', ''))";
    }
    Return $Object;
  }

  Function Write-Debug {
    Param(
      # Specifies the input to write debugging information to.
      [Parameter(Mandatory = $True,
        Position = 0,
        HelpMessage = "The input to write debugging information to.")]
      [Alias("InputObject", "Message")]
      [System.Object]
      $Object
    )
    If (-not $Debug) {
      Return;
    }

    Write-Host -ForegroundColor Blue -Object "DEBUG: " -NoNewline
    If ($Object.GetType().BaseType -eq [System.ValueType]) {
      Write-Host -ForegroundColor (Get-ObjectSyntax -InputType $Object.GetType()) -Object (Get-ObjectEnclosing -InputObject $Object)
    } ElseIf ($Object.GetType().BaseType -eq [System.Array]) {
      Write-Host -ForegroundColor DarkCyan -Object "Array: [ " -NoNewline;
      For ($Index = 1; $Index -lt $Object.Length; $Index++) {
        $Item = $Object[$Index];
        Write-Host -ForegroundColor (Get-ObjectSyntax -InputType $Item.GetType()) -Object (Get-ObjectEnclosing -InputObject $Item) -NoNewline
        Write-Host -ForegroundColor White -Object ", " -NoNewline;
      }
      Write-Host -ForegroundColor White -Object "]";
    } ElseIf ($Object.GetType().BaseType -eq [System.Object]) {
      Write-Host -ForegroundColor White -Object "Object:";
      Write-Output -InputObject $Object | Out-Host;
    }
  }

  Try {
    Import-Module -Name "PsIni";
  } Catch {
    Write-Host -NoNewline -ForegroundColor Yellow -Object "Missing module PsIni would you like to install?"
    $Prompt = (Read-Host -Prompt " [y/N]")

    If ($Prompt.ToLower() -eq "n") {
      Invoke-Exit -Code 0;
    }

    Try {
      Install-Module -Scope CurrentUser -Name "PsIni";
      Import-Module -Name "PsIni";
    } Catch {
      Throw $_;
      Invoke-Exit -Code 1;
    }
  }

  $ExitCode = -1;
  $script:APROG_DIR = ""
  #$InvokeProcessCmdlet = (Get-Command -Name "Invoke-Process" -ErrorAction SilentlyContinue);

  #If ($Null -eq $InvokeProcessCmdlet) {
  #  Write-Debug -Message "The cmdlet ``Invoke-Process`` was not found on the path.`nUsing Start-Process Instead.";
  #  $InvokeProcessCmdlet = $False;
  #}

  If ([string]::IsNullOrEmpty($env:APROG_DIR)) {
    Write-Warning "`$env:APROG_DIR is null";
    $script:APROG_DIR = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath ".."));
  } Else {
    $script:APROG_DIR = $env:APROG_DIR;
  }

  $PixivUtilDir = (Join-Path -Path $script:APROG_DIR -ChildPath "PixivUtil");
  $PixivUtil = (Join-Path -Path $PixivUtilDir -ChildPath "PixivUtil2.exe");
  $PixivUtilConfig = (Join-Path -Path $PixivUtilDir -ChildPath "config.ini");

  If (-not (Test-Path -LiteralPath $PixivUtilDir -PathType Container)) {
    Write-Error -Message "The PixivUtil directory does not exist on path: $($PixivUtilDir)";
    Invoke-Exit -Code 1;
  }
  If (-not (Test-Path -LiteralPath $PixivUtil -PathType Leaf)) {
    Write-Error -Message "The PixivUtil2 executable does not exist on path: $($PixivUtil)";
    Invoke-Exit -Code 1;
  }
  If ($SetCookie -and -not (Test-Path -LiteralPath $PixivUtilConfig -PathType Leaf)) {
    Write-Error -Message "The PixivUtil2 config does not exist on path: $($PixivUtilConfig)";
    Invoke-Exit -Code 1;
  }

  $PixivUtil = (Get-Command -Name $PixivUtil -ErrorAction SilentlyContinue);
  $UpdatePixivUtil = (Get-Command -Name "Update-PixivUtil.ps1" -ErrorAction SilentlyContinue);

  If ($Null -eq $PixivUtil) {
    Write-Error -Message "The PixivUtil2 executable does not exist on path: $($PixivUtil)";
    Invoke-Exit -Code 1;
  }
  If ($Update -and $Null -eq $UpdatePixivUtil) {
    Write-Error -Message "The command `"Update-PixivUtil.ps1`" does not exist on the system environment `"`$env:Path`".";
    Invoke-Exit -Code 1;
  }
}
Process {
  If ($Help) {
    Write-Output "$((Get-Item -Path $PSCommandPath).Name) [-Update] [-SetCookie <string>] [-Help] [<PixivUtil2 Arguments>]`n" | Out-Host;
    Write-Host -ForegroundColor White -Object "PixivUtil2 Arguments`n";
    $PixivHelp = $(& "$($PixivUtil.Source)" "--help");
    $StartWriting = $False;
    ForEach ($Item in $PixivHelp) {
      If ($Item -match "Options:") {
        $StartWriting = $True;
      }
      If ($StartWriting) {
        Write-Output $Item | Out-Host;
      }
    }

    Invoke-Exit -Code 0;
  } ElseIf ($SetCookie) {
    $IniFileContents = (Get-IniContent -FilePath $PixivUtilConfig);
    If ($CookieSupplied) {
      $AskForInput = (Read-Host -Prompt "Replace supplied cookie on which of these?`n[0] Pixiv Cookie`n[1] Refresh Token`n[2] FanBox Cookie`n[0/1/2]");
      Write-Host -Object "";
      Switch ($AskForInput.ToLower()) {
        { Return ($_ -eq "0" -or $_ -eq 0 -or $_ -match "pi?x?i?v? ?c?o?o?k?i?e?"); } {
          Write-Debug -Message $SuppliedCookie;
          Write-Debug -Message $IniFileContents["Authentication"]["cookie"];
          $IniFileContents["Authentication"]["cookie"] = "$($SuppliedCookie)";
          $OneSet = $True;
          Break;
        }
        { Return ($_ -eq "1" -or $_ -eq 1 -or $_ -match "re?f?r?e?s?h? ?T?o?k?e?n?"); } {
          Write-Debug -Message $SuppliedCookie;
          Write-Debug -Message $IniFileContents["Authentication"]["refresh_token"];
          $IniFileContents["Authentication"]["cookie"] = "$($SuppliedCookie)";
          $OneSet = $True;
          Break;
        }
        { Return ($_ -eq "2" -or $_ -eq 2 -or $_ -match "f?a?n?b?o?x? ?c?o?o?k?i?e?"); } {
          Write-Debug -Message $SuppliedCookie;
          Write-Debug -Message $IniFileContents["Authentication"]["cookieFanbox"];
          $IniFileContents["Authentication"]["cookie"] = "$($SuppliedCookie)";
          $OneSet = $True;
          Break;
        }
      }
    } Else {
      $OneSet = $False;
      Write-Host -ForegroundColor Green -Object "NOTE: " -NoNewline;
      Write-Host -ForegroundColor White -Object "Leave input blank if you want to keep it the same and move onto the FanBox cookie.";
      $AskForCookie = (Read-Host -MaskInput -Prompt "Cookie for https://pixiv.net (PHPSESSID)");
      Write-Host -Object "";
      If ($AskForCookie -ne "" -and $Null -ne $AskForCookie) {
        Write-Debug -Message $AskForCookie;
        Write-Debug -Message $IniFileContents["Authentication"]["cookie"];
        $IniFileContents["Authentication"]["cookie"] = "$($AskForCookie)";
        $OneSet = $True;
      }
      $AskForRefreshToken = (Read-Host -MaskInput -Prompt "Refresh token for https://pixiv.net (PHPSESSID)");
      Write-Host -Object "";
      If ($AskForRefreshToken -ne "" -and $Null -ne $AskForRefreshToken) {
        Write-Debug -Message $AskForRefreshToken;
        Write-Debug -Message $IniFileContents["Authentication"]["refresh_token"];
        $IniFileContents["Authentication"]["refresh_token"] = "$($AskForRefreshToken)";
        $OneSet = $True;
      }
      $AskForCookie = (Read-Host -MaskInput -Prompt "Cookie for https://fanbox.cc (FANBOXSESSID)");
      Write-Host -Object "";
      If ($AskForCookie -ne "" -and $Null -ne $AskForCookie) {
        Write-Debug -Message $AskForCookie;
        Write-Debug -Message $IniFileContents["Authentication"]["cookieFanbox"];
        $IniFileContents["Authentication"]["cookieFanbox"] = "$($AskForCookie)";
        $OneSet = $True;
      }
    }

    If ($OneSet) {
      Copy-Item -LiteralPath $PixivUtilConfig -Destination "$($PixivUtilConfig).bak";
      $IniFileContents | Out-IniFile -FilePath $PixivUtilConfig -Force;
    }
    Invoke-Exit -Code 0;
  } ElseIf ($Update) {
    Invoke-Exit -Code 0;
  } Else {
    Function Invoke-TestJob() {
      If ($OtherArguments.Length -gt 0) {
        $JoinedArguments = "`"" + [string]::Join("`", `"", $OtherArguments.Split(" ")) + "`"";

        Try {
          $Command = "Start-Process -FilePath `"$($PixivUtil.Source)`" -NoNewWindow -WorkingDirectory `"$($PixivUtilDir)`""
          If ($OtherArguments.Length -gt 0) {
            $Command += " -ArgumentList `@($($JoinedArguments))"
          }
          Write-Debug -Message "Will run this command: $($Command)";
          Invoke-Expression -Command "$($Command)";
        } Catch {
          Write-Error -Exception $_.Exception -Message "Failed to run the job.";
          Throw;
        }
      }
    }

    If (-not $Default) {
      Invoke-TestJob
    }

    Try {
      Start-Process -FilePath "$($PixivUtil.Source)" -NoNewWindow -WorkingDirectory "$($PixivUtilDir)" -ArgumentList $OtherArguments -LoadUserProfile -Wait;
      $ExitCode = $LastExitCode;
    } Catch {
      Write-Error -Exception $_.Exception -Message "Failed to run the job.";
      Throw;
    }
  }
}
End {
  Write-Host "EXITCODE: $($ExitCode)";
  Invoke-Exit -Code $ExitCode;
}
*/