using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsLifecycle.Enable, "VMGPU")]
public class EnableVMGPUCommand : Cmdlet {
}
/*
[CmdletBinding()]
Param(
  # Specifies the name of a virtual machine.
  [Parameter(Mandatory = $True,
             Position = 0,
             HelpMessage = "Name of a virtual machine.")]
  [Alias("VM", "Name")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $VirtualMachine,
  # Specifies the percentage of the GPU to allocate to the virtual machine. 0.0000000001 by default.
  [Parameter(Mandatory = $False,
             HelpMessage = "Percentage of the GPU to allocate to the virtual machine. 0.0000000001 by default.")]
  [System.Double]
  $PercentageAllocation = 0.0000000001
)

Begin {
  $ErrorActionPreference = "Stop";
  If ($PSBoundParameters.ContainsKey("Verbose")) {
    $VerbosePreference = "Continue";
  }
  If ($PSBoundParameters.ContainsKey("Debug")) {
    $DebugPreference = "Break";
  }
  $GPUs = (Get-VMHostPartitionableGpu);
  If ($Null -eq $GPUs) {
    Throw "No Partitionable GPU found on the machine.";
  }
  If ($Null -eq (Get-VM -Name $VirtualMachine -ErrorAction SilentlyContinue)) {
    Throw "No Virtual Machine with name $VirtualMachine";
  }
} Process {
  If ($Null -ne (Get-VMGpuPartitionAdapter -VMName $VirtualMachine)) {
    Remove-VMGpuPartitionAdapter -VMName $VirtualMachine
  }
  $MaxPartitionCompute     = [Math]::Ceiling($GPUs.MaxPartitionCompute      * $PercentageAllocation);
  $MaxPartitionDecode      = [Math]::Ceiling($GPUs.MaxPartitionDecode       * $PercentageAllocation);
  $MaxPartitionEncode      = [Math]::Ceiling($GPUs.MaxPartitionEncode       * $PercentageAllocation);
  $MaxPartitionVRAM        = [Math]::Ceiling($GPUs.MaxPartitionVRAM         * $PercentageAllocation);
  $OptimalPartitionCompute = [Math]::Ceiling($GPUs.OptimalPartitionCompute  * $PercentageAllocation);
  $OptimalPartitionDecode  = [Math]::Ceiling($GPUs.OptimalPartitionDecode   * $PercentageAllocation);
  $OptimalPartitionEncode  = [Math]::Ceiling($GPUs.OptimalPartitionEncode   * $PercentageAllocation);
  $OptimalPartitionVRAM    = [Math]::Ceiling($GPUs.OptimalPartitionVRAM     * $PercentageAllocation);
  Add-VMGpuPartitionAdapter -VMName $VirtualMachine -MaxPartitionCompute $MaxPartitionCompute -MaxPartitionDecode $MaxPartitionDecode -MaxPartitionEncode $MaxPartitionEncode -MaxPartitionVRAM $MaxPartitionVRAM -MinPartitionCompute 0 -MinPartitionDecode 0 -MinPartitionEncode 0 -MinPartitionVRAM 0 -OptimalPartitionCompute $OptimalPartitionCompute -OptimalPartitionDecode $OptimalPartitionDecode -OptimalPartitionEncode $OptimalPartitionEncode -OptimalPartitionVRAM $OptimalPartitionVRAM -Verbose:($VerbosePreference);
  Set-VM -GuestControlledCacheTypes $True -VMName $VirtualMachine;
  Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $VirtualMachine;
  Set-VM -HighMemoryMappedIoSpace 32GB -VMName $VirtualMachine;
  Start-VM -Name $VirtualMachine;

  Start-Sleep 15 # Wait for the VM to start

  # Dlls that need to be copied

  $GpuDllPaths = ((Get-CimInstance Win32_VideoController -Filter "Name like 'N%'").InstalledDisplayDrivers -Split ',' | Get-Unique);
  # Extract directories
  $GpuInfDirs = ($GpuDllPaths | ForEach-Object { [System.IO.Path]::GetDirectoryName($_) } | Get-Unique);

  # Hack, leaving only NVidia drivers (solving issue with notebooks with multiple GPUs)
  $GpuInfDirs = ($GpuInfDirs | Where-Object { (Split-Path $_ -Leaf ).StartsWith("nv") })

  # Start session to copy on quest machine
  $PSSession = (New-PSSession -VMName $VirtualMachine -Credential (Get-Credential));

  # Copy (folders for file from $GpuDllPaths) nv_dispi.inf_amd64 folder from host to quest system
  $GpuInfDirs | ForEach-Object { Copy-Item -ToSession $PSSession -Path $_ -Destination "C:\Windows\System32\HostDriverStore\FileRepository\" -Recurse -Force -ErrorAction Continue }

  # Copy nvapi64.dll into quest system
  Copy-Item -ToSession $PSSession -Path "C:\Windows\System32\nv*.dll" -Destination "C:\Windows\System32\" -ErrorAction Continue
} End {
  # Cleaning up session
  Remove-PSSession $PSSession -ErrorAction Continue

  # Restarting the VM
  Restart-VM $VirtualMachine -Force -ErrorAction Continue
}
*/
