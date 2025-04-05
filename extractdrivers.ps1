# Extract-Drivers.ps1
# Script to extract Ethernet and Storage Controller driver INF files from a running system

# Ensure script is running with admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrative privileges. Please run as administrator."
    exit
}

# Create output directory
$outputDir = "$env:USERPROFILE\Desktop\ExtractedDrivers"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
Write-Host "Output directory: $outputDir"

# Function to extract driver details from a device
function Extract-DriverInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceClass,
        
        [Parameter(Mandatory=$true)]
        [string]$DeviceType,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFolder
    )
    
    Write-Host "`nExtracting $DeviceType drivers..."
    
    # Get devices matching the class
    $devices = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq $DeviceClass }
    
    if (-not $devices) {
        Write-Warning "No $DeviceType devices found."
        return
    }
    
    foreach ($device in $devices) {
        Write-Host "`nDevice: $($device.DeviceName)"
        Write-Host "Driver: $($device.DriverName)"
        Write-Host "Provider: $($device.DriverProviderName)"
        Write-Host "Version: $($device.DriverVersion)"
        
        # Extract INF file
        $infFile = $device.InfName
        if ($infFile) {
            $infPath = "$env:windir\INF\$infFile"
            if (Test-Path $infPath) {
                $deviceFolder = "$OutputFolder\$($DeviceType)_$($device.DeviceName -replace '[\\\/\:\*\?\"\<\>\|]', '_')"
                New-Item -ItemType Directory -Path $deviceFolder -Force | Out-Null
                
                # Copy INF file to destination
                Copy-Item -Path $infPath -Destination $deviceFolder
                Write-Host "INF file copied to: $deviceFolder\$infFile"
                
                # Extract driver files
                try {
                    # Find associated driver files by parsing the INF file
                    $infContent = Get-Content -Path $infPath -Raw
                    
                    # Create folder for driver files
                    $driverFilesFolder = "$deviceFolder\DriverFiles"
                    New-Item -ItemType Directory -Path $driverFilesFolder -Force | Out-Null
                    
                    # Export the device driver to a folder (this captures all necessary files)
                    $exportCmd = "pnputil /export-driver $infFile $driverFilesFolder"
                    Write-Host "Executing: $exportCmd"
                    Invoke-Expression $exportCmd
                    
                    Write-Host "Driver files exported to: $driverFilesFolder"
                } catch {
                    Write-Warning "Error extracting driver files: $_"
                }
                
                # Create metadata file with driver details
                $metadataFile = "$deviceFolder\driver_info.txt"
                @"
Device Name: $($device.DeviceName)
Driver Name: $($device.DriverName)
Provider: $($device.DriverProviderName)
Version: $($device.DriverVersion)
INF File: $infFile
Device ID: $($device.DeviceID)
Extracted Date: $(Get-Date)
"@ | Out-File -FilePath $metadataFile
                Write-Host "Driver metadata saved to: $metadataFile"
            } else {
                Write-Warning "INF file not found: $infPath"
            }
        } else {
            Write-Warning "No INF file associated with this device."
        }
    }
}

# Extract Ethernet card network drivers
Extract-DriverInfo -DeviceClass "Net" -DeviceType "NetworkAdapter" -OutputFolder $outputDir

# Extract Storage controller drivers
Extract-DriverInfo -DeviceClass "SCSIAdapter" -DeviceType "StorageController" -OutputFolder $outputDir

# Create a summary file
$summaryFile = "$outputDir\extraction_summary.txt"
@"
Driver Extraction Summary
========================
Computer Name: $env:COMPUTERNAME
Extraction Date: $(Get-Date)
System Info: $((Get-WmiObject Win32_OperatingSystem).Caption) $((Get-WmiObject Win32_OperatingSystem).Version)
Processor: $((Get-WmiObject Win32_Processor).Name)
"@ | Out-File -FilePath $summaryFile

Write-Host "`n========================================================"
Write-Host "Driver extraction complete!"
Write-Host "All drivers have been saved to: $outputDir"
Write-Host "You can now use these drivers with DISM to add to a WIM file"
Write-Host "Example DISM command:"
Write-Host "dism /image:C:\mount\windows /add-driver /driver:$outputDir /recurse"
Write-Host "========================================================`n"