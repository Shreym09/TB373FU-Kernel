# PowerShell Script to Repack OneUI 9 boot.img with New Kernel (Image.gz)
param (
    [string]$OriginalBoot = "C:\Users\Shrey\Downloads\OneUI 9 port RC2.1 for TB373FU\image\boot.img",
    [string]$NewKernel = "Image.gz",
    [string]$OutputFile = "boot_custom.img"
)

if (-not (Test-Path $OriginalBoot)) {
    Write-Error "Original boot.img not found at: $OriginalBoot"
    exit 1
}

if (-not (Test-Path $NewKernel)) {
    Write-Error "New kernel file not found at: $NewKernel (Please place the compiled Image.gz here)"
    exit 1
}

Write-Host "=== Repacking boot.img with New Kernel ===" -ForegroundColor Cyan

# Read original header (4096 bytes)
$origBytes = [System.IO.File]::ReadAllBytes($OriginalBoot)
$header = New-Object byte[] 4096
[Array]::Copy($origBytes, 0, $header, 0, 4096)

# Read new kernel bytes
$kernelBytes = [System.IO.File]::ReadAllBytes($NewKernel)
$newKernelSize = [uint32]$kernelBytes.Length

# Update kernel_size at offset 8 in header (little-endian 32-bit uint)
$sizeBytes = [System.BitConverter]::GetBytes($newKernelSize)
[Array]::Copy($sizeBytes, 0, $header, 8, 4)

Write-Host "Original kernel size: $([System.BitConverter]::ToUInt32($origBytes, 8)) bytes"
Write-Host "New kernel size:      $newKernelSize bytes"

# Write out new boot_custom.img
$outStream = [System.IO.File]::Create($OutputFile)
$outStream.Write($header, 0, 4096)
$outStream.Write($kernelBytes, 0, $kernelBytes.Length)

# Pad to page_size (4096)
$remainder = $newKernelSize % 4096
if ($remainder -ne 0) {
    $padSize = 4096 - $remainder
    $padding = New-Object byte[] $padSize
    $outStream.Write($padding, 0, $padSize)
}

$outStream.Close()

Write-Host "Successfully generated: $OutputFile" -ForegroundColor Green
Write-Host "Flash with: fastboot flash boot $OutputFile" -ForegroundColor Yellow
