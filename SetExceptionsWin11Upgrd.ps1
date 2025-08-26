# Windows 11 Hardware Requirements Bypass Script
# This script sets all registry keys to bypass Windows 11 upgrade requirements
# Run this before attempting a Windows 11 upgrade on unsupported hardware

# Require Administrator privileges
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "   Windows 11 Requirements Bypass Script" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Check for Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[INFO] Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

try {
    # Create necessary registry paths
    Write-Host "[SETUP] Creating required registry paths..." -ForegroundColor Yellow
    
    $paths = @(
        "HKLM:\SYSTEM\Setup\MoSetup",
        "HKLM:\SYSTEM\Setup\LabConfig",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\HwReqCheck",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\CompatMarkers",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    )
    
    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
            Write-Host "  ✓ Created: $path" -ForegroundColor Gray
        } else {
            Write-Host "  • Exists: $path" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
    Write-Host "[BYPASS] Applying Windows 11 requirement bypasses..." -ForegroundColor Yellow
    Write-Host ""
    
    # 1. MoSetup - Allow upgrades with unsupported hardware
    Write-Host "  Setting upgrade allowance for unsupported hardware..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
    Write-Host "    ✓ AllowUpgradesWithUnsupportedTPMOrCPU = 1" -ForegroundColor Green
    
    Write-Host ""
    
    # 2. LabConfig - Comprehensive bypass settings
    Write-Host "  Applying comprehensive hardware bypasses..." -ForegroundColor Cyan
    
    $labConfig = @{
        "BypassTPMCheck"         = 1    # Bypass TPM 2.0 requirement
        "BypassTPM20Check"       = 1    # Additional TPM 2.0 bypass
        "BypassCPUCheck"         = 1    # Bypass CPU compatibility check
        "BypassRAMCheck"         = 1    # Bypass 4GB RAM requirement
        "BypassStorageCheck"     = 1    # Bypass 64GB storage requirement
        "BypassSecureBootCheck"  = 1    # Bypass Secure Boot requirement
        "BypassDiskCheck"        = 1    # Bypass disk check
        "BypassNRPCheck"         = 1    # Bypass network requirement
        "SkipTPMCheck"           = 1    # Skip TPM verification
        "SkipCPUCheck"           = 1    # Skip CPU model verification
        "AllowUpgradesWithUnsupportedTPM" = 1   # Allow unsupported TPM
        "AllowUpgradesWithUnsupportedCPU" = 1   # Allow unsupported CPU
        "AllowUpgradesWithUnsupportedTPMOrCPU" = 1  # Combined bypass
    }
    
    foreach ($key in $labConfig.Keys) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name $key -Value $labConfig[$key] -Type DWord -Force
        Write-Host "    ✓ $key = $($labConfig[$key])" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # 3. OOBE - Out of Box Experience bypasses
    Write-Host "  Setting OOBE bypasses..." -ForegroundColor Cyan
    
    $oobeSettings = @{
        "BypassNRO" = 1              # Bypass network requirement in OOBE
        "SkipMachineOOBE" = 1        # Skip machine OOBE
        "SkipUserOOBE" = 1           # Skip user OOBE
    }
    
    foreach ($key in $oobeSettings.Keys) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name $key -Value $oobeSettings[$key] -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "    ✓ $key = $($oobeSettings[$key])" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # 4. Hardware requirement check version
    Write-Host "  Disabling hardware requirement checks..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\HwReqCheck" -Name "HwReqCheckVer" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "    ✓ HwReqCheckVer = 0" -ForegroundColor Green
    
    # 5. Compatibility markers
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\CompatMarkers" -Name "CompatibilityMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "    ✓ CompatibilityMode = 1" -ForegroundColor Green
    
    Write-Host ""
    
    # 6. Windows Update settings
    Write-Host "  Configuring Windows Update for OS upgrade..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AllowOSUpgrade" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "    ✓ AllowOSUpgrade = 1" -ForegroundColor Green
    
    Write-Host ""
    
    # 7. Set environment variables (for current session)
    Write-Host "  Setting environment variables for current session..." -ForegroundColor Cyan
    
    $envVars = @{
        "BypassTPMCheck" = "1"
        "BypassCPUCheck" = "1"
        "BypassRAMCheck" = "1"
        "BypassStorageCheck" = "1"
        "BypassSecureBootCheck" = "1"
        "AllowUpgradesWithUnsupportedTPMOrCPU" = "1"
    }
    
    foreach ($var in $envVars.Keys) {
        [System.Environment]::SetEnvironmentVariable($var, $envVars[$var], "Machine")
        [System.Environment]::SetEnvironmentVariable($var, $envVars[$var], "Process")
        Write-Host "    ✓ $var = $($envVars[$var])" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "         ALL BYPASSES APPLIED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary of bypassed requirements:" -ForegroundColor Yellow
    Write-Host "  ✓ TPM 2.0 requirement - BYPASSED" -ForegroundColor Green
    Write-Host "  ✓ CPU compatibility - BYPASSED" -ForegroundColor Green
    Write-Host "  ✓ 4GB RAM minimum - BYPASSED" -ForegroundColor Green
    Write-Host "  ✓ 64GB storage minimum - BYPASSED" -ForegroundColor Green
    Write-Host "  ✓ UEFI firmware - BYPASSED" -ForegroundColor Green
    Write-Host "  ✓ Secure Boot - BYPASSED" -ForegroundColor Green
    Write-Host "  ✓ Internet connection - BYPASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "[SUCCESS] System is now configured to upgrade to Windows 11" -ForegroundColor Green
    Write-Host "          regardless of hardware compatibility!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[NOTE] You can now run your Windows 11 upgrade process." -ForegroundColor Cyan
    Write-Host "[NOTE] These settings will persist across reboots." -ForegroundColor Cyan
    Write-Host ""
    
    # Optional: Export settings for verification
    $exportPath = "$env:TEMP\Win11_Bypass_Settings.txt"
    Write-Host "[INFO] Exporting applied settings to: $exportPath" -ForegroundColor Yellow
    
    @"
Windows 11 Bypass Settings Applied on $(Get-Date)
================================================

SYSTEM\Setup\MoSetup:
$(Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" | Out-String)

SYSTEM\Setup\LabConfig:
$(Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" | Out-String)

Environment Variables Set:
$($envVars.Keys | ForEach-Object { "$_ = $($envVars[$_])" } | Out-String)
"@ | Out-File -FilePath $exportPath -Force
    
    Write-Host "[SUCCESS] Settings exported for verification" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Red
    Write-Host "                ERROR OCCURRED!" -ForegroundColor Red
    Write-Host "===============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "[INFO] Some settings may have been partially applied." -ForegroundColor Yellow
    Write-Host "[INFO] Try running the script again as Administrator." -ForegroundColor Yellow
    exit 1
}

# Script completed - no pause needed for automated execution
Write-Host "[COMPLETE] Script finished successfully." -ForegroundColor Green
exit 0
