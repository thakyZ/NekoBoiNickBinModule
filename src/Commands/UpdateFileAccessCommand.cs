using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Update, "FileAccess")]
public class UpdateFileAccessCommand : Cmdlet {
}
/*
$Root = "E:\";
$OwnerToReplace=(Get-Acl -LiteralPath $Root).Owner;
$AccessToReplace=($OwnerToReplace -Split ':')[1];
$NewOwner=((Get-Acl C:\Users\thaky\Desktop).Owner -Split '\\');
$objUser = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList @($NewOwner[0], $NewOwner[1]);
$script:objAccessRule;
$script:Output = $Null

Function Invoke-Process($Items) {
  ForEach ($Item in $Items) {
    $objFile=(Get-Acl -LiteralPath $Item.FullName);
    If ((Get-Acl -LiteralPath $Item.FullName).Owner -eq $OwnerToReplace) {
      Try {
        Write-Host "Setting owner of `"$($Item.FullName)`" from $OwnerToReplace to $($NewOwner[0])\$($NewOwner[1])";
        $objFile.SetOwner($objUser);
      } Catch [System.Management.Automation.RuntimeException] {
        Write-Error -Message $_.Exception.Message -Exception $_.Exception;
        Start-Sleep -Seconds 2;
      } Catch {
        Write-Error -Message $_.Exception.Message -Exception $_.Exception;
        Break;
      }
    }
    $objOldAccessRule = ((Get-Acl -LiteralPath $Item.FullName).Access | Where-Object { $_.IdentityReference -eq $AccessToReplace -and $_.IsInherited -eq $False });
    If ($objOldAccessRule.Length -ge 1) {
      Try {
        $script:objAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList @("$($NewOwner[0])\$($NewOwner[1])", $objOldAccessRule.FileSystemRights, $objOldAccessRule.InheritanceFlags, $objOldAccessRule.PropagationFlags, $objOldAccessRule.AccessControlType);
        Write-Host "Setting access of `"$($Item.FullName)`" from $AccessToReplace to $($NewOwner[0])\$($NewOwner[1])";

        ForEach ($Rule in $objOldAccessRule) {
          Write-Host "Removing access of $AccessToReplace from `"$($Item.FullName)`"";
          $objFile.RemoveAccessRule($Rule);
        }

        $objFile.AddAccessRule($script:objAccessRule);
        $objFile | Set-Acl -LiteralPath $Item.FullName;
      } Catch [System.Management.Automation.RuntimeException] {
        Write-Error -Message $_.Exception.Message -Exception $_.Exception;
        Start-Sleep -Seconds 2;
      } Catch {
        Write-Error -Message $_.Exception.Message -Exception $_.Exception;
        Break;
      }
    }
    Break;
  }
}

Invoke-Process -Items @((Get-Item -LiteralPath $Root) | Where-Object { (Get-Acl $_.FullName).Owner -eq $OwnerToReplace -or ((Get-Acl -LiteralPath $_.FullName).Access | Where-Object { $_.IdentityReference -eq $OwnerToReplace -and $_.IsInherited -eq $False }).Length -ge 1 });
Invoke-Process -Items @(Get-ChildItem $Root -Recurse | Where-Object { (Get-Acl $_.FullName).Owner -eq $OwnerToReplace -or ((Get-Acl -LiteralPath $_.FullName).Access | Where-Object { $_.IdentityReference -eq $OwnerToReplace -and $_.IsInherited -eq $False }).Length -ge 1 });
Write-Output $script:Output;

*/
