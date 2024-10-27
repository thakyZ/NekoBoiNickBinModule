using namespace System;
using namespace System.Management;
using namespace System.Management.Automation;
using namespace Microsoft.PowerShell.Commands;

Class FileSignature {
  [string] $Description;
  [string] $HexSignature;
  [int] $ByteOffset;
  [int] $ByteLimit;
  [string[]] $Extensions;

  FileSignature([string] $Description, [string] $HexSignature, [int] $ByteOffset, [int] $ByteLimit, [string[]] $Extensions) {
    $this.Description = $Description;
    $this.HexSignature = $HexSignature;
    $this.ByteOffset = $ByteOffset;
    $this.ByteLimit = $ByteLimit;
    $this.Extensions = $Extensions;
  }
  FileSignature([string] $Description, [string] $HexSignature, [string] $ByteOffset, [int] $ByteLimit, [string[]] $Extensions) {
    $this.Description = $Description;
    $this.HexSignature = $HexSignature;
    $this.ByteOffset = (ConvertTo-Int -Hex $ByteOffset);
    $this.ByteLimit = $ByteLimit;
    $this.Extensions = $Extensions;
  }
  FileSignature([string] $Description, [string] $HexSignature, [int] $ByteOffset, [string] $ByteLimit, [string[]] $Extensions) {
    $this.Description = $Description;
    $this.HexSignature = $HexSignature;
    $this.ByteOffset = $ByteOffset;
    $this.ByteLimit = (ConvertTo-Int -Hex $ByteLimit);
    $this.Extensions = $Extensions;

  }
  FileSignature([string] $Description, [string] $HexSignature, [string] $ByteOffset, [string] $ByteLimit, [string[]] $Extensions) {
    $this.Description = $Description;
    $this.HexSignature = $HexSignature;
    $this.ByteOffset = (ConvertTo-Int -Hex $ByteOffset);
    $this.ByteLimit = (ConvertTo-Int -Hex $ByteLimit);
    $this.Extensions = $Extensions;
  }
}

# Description, hex signature, byte offset, byte limit
[FileSignature[]] $FileSignatures = @(
  [FileSignature]::new('JPG/JPEG', 'FFD8FF', 0, 3, @('JPG', 'JPEG')),
  [FileSignature]::new('Portable Network Graphics (PNG)', '89504E470D0A1A0A', 0, 8, @("PNG")),
  [FileSignature]::new('Graphics Interchange Format - GIF87a (GIF)', '474946383761', 0, 6, @("GIF")),
  [FileSignature]::new('Graphics Interchange Format - GIF89a (GIF)', '474946383961', 0, 6, @("GIF")),
  [FileSignature]::new('Icon (ICO)', '00000100', 0, 4, @("ICO")),
  [FileSignature]::new('MPEG-4 (MP4)', '000000*66747970', 0, 8, @("MP4")),
  [FileSignature]::new('MPEG-4 (MP4)', '336770', 0, 3, @("MP4")),
  [FileSignature]::new('Windows/DOS executable file (EXE/COM/DLL/DRV/PIF/OCX/OLB/SCR/CPL ++)', '4D5A', 0, 2, @("EXE", "COM", "DLL", "DRV", "PIF", "OCX", "OLB", "SCR", "CPL")),
  [FileSignature]::new('Archive (RAR)', '526172211A0700', 0, 7, @("RAR")),
  [FileSignature]::new('Archive (RAR)', '526172211A070100', 0, 8, @("RAR")),
  [FileSignature]::new('Adobe Portable Document Format (PDF) / Forms Document file (FDF)', '25504446', 0, 4, @("PDF", "FDF")),
  [FileSignature]::new('MPEG-1 Audio Layer 3 (MP3)', 'FFFB', 0, 2, @("MP3")),
  [FileSignature]::new('MPEG-1 Audio Layer 3 (MP3)', '494433', 0, 3, @("MP3")),
  [FileSignature]::new('ISO9660 CD/DVD image (ISO)', '4344303031', '0x8001', 5, @("ISO")),
  [FileSignature]::new('ISO9660 CD/DVD image (ISO)', '4344303031', '0x8801', 5, @("ISO")),
  [FileSignature]::new('ISO9660 CD/DVD image (ISO)', '4344303031', '0x9001', 5, @("ISO")),
  [FileSignature]::new('Install Shield compressed file (CAB/HDR)', '49536328', 0, 4, @("CAB", "HDR")),
  [FileSignature]::new('Microsoft cabinet file (CAB) / Powerpoint Packaged Presentation (PPZ) / Microsoft Access Snapshot Viewer file (SNP)', '4D534346', 0, 4, @("CAB", "PPZ", "SNP")),
  [FileSignature]::new('Microsoft Windows Imaging Format file (WIM)', '4D5357494D', 0, 5, @("WIM")),
  [FileSignature]::new('Rich text format (RTF)', '7B5C72746631', 0, 6, @("RTF")),
  [FileSignature]::new('TrueType font file (TTF)', '0001000000', 0, 5, @("TTF")),
  [FileSignature]::new('Windows shell link (shortcut) file (LNK)', '4C00000001140200', 0, 8, @("LINK", "shortcut")),
  [FileSignature]::new('Windows Help (HLP/GID)', '4C4E0200', 0, 4, @("HLP", "GID")),
  [FileSignature]::new('Windows Help (HLP/GID)', '3F5F0300', 0, 4, @("HLP", "GID")),
  [FileSignature]::new('Windows Help (HLP)', '0000FFFFFFFF', 0, 6, @("HLP")),
  [FileSignature]::new('Windows Registry (REG/SUD)', '52454745444954', 0, 7, @("REG", "SUD")),
  [FileSignature]::new('Windows Registry (REG)', 'FFFE', 0, 2, @("REG")),
  [FileSignature]::new('Archive (ZIP/JAR)', '504B0304', 0, 4, @("ZIP","JAR")),
  [FileSignature]::new('Microsoft security catalog file (CAT)', '30', 0, 1, @("CAT")),
  [FileSignature]::new('Windows memory dump (DMP)', '5041474544554D50', 0, 8, @("DMP")),
  [FileSignature]::new('Windows 64-bit memory dump (DMP)', '5041474544553634', 0, 8, @("DMP")),
  [FileSignature]::new('Windows minidump (DMP) / Windows heap dump (HDMP)', '4D444D5093A7', 0, 6, @("DMP", "HDMP")),
  [FileSignature]::new('Microsoft Compiled HTML Help (CHM/CHI)', '49545346', 0, 4, @("CHM", "CHI")),
  [FileSignature]::new('Waveform Audio (WAV)', '52494646*57415645', 0, 12, @("WAV"))
)