using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Switch, "HyperVGpuPartitionAdapter")]
public class SwitchHyperVGpuPartitionAdapterCommand : Cmdlet {
}
/*
param(
  [Parameter(Mandatory)][string]$vmName
)
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"
try {

  $vmPartitionAdapter = Get-VMGpuPartitionAdapter -VMName $vmName
  if ($vmPartitionAdapter) {
    Write-Information "Removing Partition Adapter. Checkpoints work."
    $vmPartitionAdapter | Remove-VMGpuPartitionAdapter
  }
  else {
    Write-Information "Adding Partition Adapter. Checkpoints no longer work."
    Add-VMGpuPartitionAdapter -VMName $vmName #-InstancePath (Get-VMHostPartitionableGpu).Name
    $vmPartitionAdapter = Get-VMGpuPartitionAdapter -VMName $vmName
    [uint64]$two = 200000000;
    [uint64]$three =  3689348814741910323;
    $adapterConfig = @{
      # 100% of values from my system's Get-VMPartitionableGpu
      # Not sure why PartitionEncode uses 2^64 or if this is a good idea to set...
      MaxPartitionEncode = (Get-VMHostPartitionableGpu).MaxPartitionEncode
      OptimalPartitionEncode = (Get-VMHostPartitionableGpu).OptimalPartitionEncode
      MaxPartitionDecode = (Get-VMHostPartitionableGpu).MaxPartitionDecode
      OptimalPartitionDecode = (Get-VMHostPartitionableGpu).OptimalPartitionDecode
      MaxPartitionCompute = (Get-VMHostPartitionableGpu).MaxPartitionCompute
      OptimalPartitionCompute = (Get-VMHostPartitionableGpu).OptimalPartitionCompute
      MaxPartitionVRAM = (Get-VMHostPartitionableGpu).MaxPartitionVRAM
      OptimalPartitionVRAM = (Get-VMHostPartitionableGpu).OptimalPartitionVRAM
      # 80% of values
      MinPartitionEncode = [uint64]((Get-VMHostPartitionableGpu).MaxPartitionEncode-$three)
      MinPartitionDecode = [uint64]((Get-VMHostPartitionableGpu).MaxPartitionDecode-$two)
      MinPartitionCompute = [uint64]((Get-VMHostPartitionableGpu).MaxPartitionCompute-$two)
      MinPartitionVRAM = [uint64]((Get-VMHostPartitionableGpu).MaxPartitionVRAM-$two)
    }
    $vmPartitionAdapter | Set-VMGpuPartitionAdapter @adapterConfig
    $vmPartitionAdapter
  }
}
catch {
  Write-Error $_
}
*/
