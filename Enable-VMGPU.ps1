[CmdletBinding()]
Param(
  # Specifies the name of a virtual machine.
  [Parameter(Mandatory = $True,
             Position = 0,
             HelpMessage = "Name of a virtual machine.")]
  [Alias("VM", "Name")]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $VirtualMachine
)

Begin {
  If ($Null -eq (Get-VM -Name $VirtualMachine -ErrorAction SilentlyContinue)) {
    Throw "No Virtual Machine with name $VirtualMachine";
  }
} Process {
  If ($Null -ne (Get-VMGpuPartitionAdapter -VMName $VirtualMachine)) {
    Remove-VMGpuPartitionAdapter -VMName $VirtualMachine -ErrorAction Stop
  }
  Add-VMGpuPartitionAdapter -VMName $VirtualMachine -MaxPartitionCompute 1000000000 -MaxPartitionDecode 1000000000 -MaxPartitionEncode 18446744073709551615 -MaxPartitionVRAM 1000000000 -MinPartitionCompute 0 -MinPartitionDecode 0 -MinPartitionEncode 0 -MinPartitionVRAM 0 -OptimalPartitionCompute 1000000000 -OptimalPartitionDecode 1000000000 -OptimalPartitionEncode 18446744073709551614 -OptimalPartitionVRAM 1000000000 -Verbose -ErrorAction Stop
  Set-VM -GuestControlledCacheTypes $true -VMName $VirtualMachine -ErrorAction Stop
  Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $VirtualMachine -ErrorAction Stop
  Set-VM -HighMemoryMappedIoSpace 32GB -VMName $VirtualMachine -ErrorAction Stop
  Start-VM -Name $VirtualMachine -ErrorAction Stop

  Start-Sleep 15 # Wait for the VM to start

  # Dlls that need to be copied

  $GpuDllPaths = (Get-CimInstance Win32_VideoController -Filter "Name like 'N%'" -ErrorAction Stop).InstalledDisplayDrivers -Split ',' | Get-Unique
  # Extract directories
  $GpuInfDirs = $GpuDllPaths | ForEach-Object { [System.IO.Path]::GetDirectoryName($_) } | Get-Unique

  # Hack, leaving only NVidia drivers (solving issue with notebooks with multiple GPUs)
  $GpuInfDirs = $GpuInfDirs | Where-Object { (Split-Path $_ -Leaf ).StartsWith("nv") }

  # Start session to copy on quest machine
  $PSSession = New-PSSession -VMName $VirtualMachine -Credential (Get-Credential) -ErrorAction Stop;

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