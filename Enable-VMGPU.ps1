$vm = $args[0]
Remove-VMGpuPartitionAdapter -VMName $vm
Add-VMGpuPartitionAdapter -VMName $vm -MaxPartitionCompute 1000000000 -MaxPartitionDecode 1000000000 -MaxPartitionEncode 18446744073709551615 -MaxPartitionVRAM 1000000000 -MinPartitionCompute 0 -MinPartitionDecode 0 -MinPartitionEncode 0 -MinPartitionVRAM 0 -OptimalPartitionCompute 1000000000 -OptimalPartitionDecode 1000000000 -OptimalPartitionEncode 18446744073709551614 -OptimalPartitionVRAM 1000000000 -Verbose
Set-VM -GuestControlledCacheTypes $true -VMName $vm
Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $vm
Set-VM -HighMemoryMappedIoSpace 32GB -VMName $vm
Start-VM -Name $vm

Start-Sleep 15 # Wait for the VM to start

# Dlls that need to be copied

$GpuDllPaths = (Get-CimInstance Win32_VideoController -Filter "Name like 'N%'").InstalledDisplayDrivers.split(',') | Get-Unique
# Extract directories
$GpuInfDirs = $GpuDllPaths | ForEach-Object {[System.IO.Path]::GetDirectoryName($_)} | Get-Unique

# Hack, leaving only NVidia drivers (solving issue with notebooks with multiple GPUs)
$GpuInfDirs = $GpuInfDirs | Where-Object {(Split-Path $_ -Leaf ).StartsWith("nv")}

# Start session to copy on quest machine
$s = New-PSSession -VMName $vm -Credential (Get-Credential)

# Copy (folders for file from $GpuDllPaths) nv_dispi.inf_amd64 folder from host to quest system
$GpuInfDirs | ForEach-Object { Copy-Item -ToSession $s -Path $_ -Destination C:\Windows\System32\HostDriverStore\FileRepository\ -Recurse -Force }

# Copy nvapi64.dll into quest system
Copy-Item -ToSession $s -Path C:\Windows\System32\nv*.dll -Destination C:\Windows\System32\

# Cleaning up session
Remove-PSSession $s

# Restarting the VM
Restart-VM $vm -Force