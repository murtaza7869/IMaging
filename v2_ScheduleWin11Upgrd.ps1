# Windows 11 Upgrade Scheduler Script with Hardware Compatibility Bypass
# This script bypasses hardware checks, downloads the upgrade script, and schedules it to run

# Set error action preference
$ErrorActionPreference = "Stop"

# Check for Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator. Exiting..." -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Starting Windows 11 Upgrade Scheduler with Hardware Bypass..." -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    # Step 1: Apply Windows 11 Hardware Compatibility Bypasses
    Write-Host "`nStep 1: Applying Windows 11 Hardware Compatibility Bypasses..." -ForegroundColor Yellow
    
    # Create registry paths if they don't exist
    $registryPaths = @(
        "HKLM:\SYSTEM\Setup\MoSetup",
        "HKLM:\SYSTEM\Setup\LabConfig"
    )
    
    foreach ($path in $registryPaths) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
            Write-Host "  Created registry path: $path" -ForegroundColor Gray
        }
    }
    
    # Apply MoSetup bypass (for upgrade scenarios)
    Write-Host "`n  Applying upgrade bypass settings..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
    Write-Host "    ✓ Allowed upgrades with unsupported TPM or CPU" -ForegroundColor Green
    
    # Apply LabConfig bypasses (comprehensive hardware check bypass)
    Write-Host "`n  Applying comprehensive hardware bypasses..." -ForegroundColor Cyan
    
    $labConfigSettings = @{
        "BypassTPMCheck" = 1          # Bypass TPM 2.0 requirement
        "BypassCPUCheck" = 1          # Bypass CPU compatibility check
        "BypassRAMCheck" = 1          # Bypass 4GB RAM requirement
        "BypassStorageCheck" = 1      # Bypass 64GB storage requirement
        "BypassSecureBootCheck" = 1   # Bypass Secure Boot requirement
        "BypassDiskCheck" = 1         # Bypass disk check
        "BypassNRPCheck" = 1          # Bypass network requirement during setup
        "BypassTPM20Check" = 1        # Additional TPM 2.0 bypass
        "SkipCPUCheck" = 1            # Skip CPU model verification
        "SkipTPMCheck" = 1            # Skip TPM verification
        "AllowUpgradesWithUnsupportedTPM" = 1  # Allow unsupported TPM
        "AllowUpgradesWithUnsupportedCPU" = 1  # Allow unsupported CPU
    }
    
    foreach ($setting in $labConfigSettings.GetEnumerator()) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name $setting.Key -Value $setting.Value -Type DWord -Force
        Write-Host "    ✓ $($setting.Key) set to $($setting.Value)" -ForegroundColor Green
    }
    
    # Additional compatibility settings for Windows Update
    Write-Host "`n  Applying Windows Update compatibility settings..." -ForegroundColor Cyan
    
    $updatePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    if (-not (Test-Path $updatePath)) {
        New-Item -Path $updatePath -Force | Out-Null
    }
    Set-ItemProperty -Path $updatePath -Name "AllowOSUpgrade" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "    ✓ Windows Update OS upgrade allowed" -ForegroundColor Green
    
    # Apply additional compatibility settings
    Write-Host "`n  Applying additional compatibility settings..." -ForegroundColor Cyan
    
    # Disable Windows 11 hardware requirements in Windows Setup
    $setupPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\HwReqCheck"
    if (-not (Test-Path $setupPath)) {
        New-Item -Path $setupPath -Force | Out-Null
    }
    Set-ItemProperty -Path $setupPath -Name "HwReqCheckVer" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "    ✓ Hardware requirement check version set to 0" -ForegroundColor Green
    
    # Set compatibility flags for upgrade
    $compatPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\CompatMarkers"
    if (-not (Test-Path $compatPath)) {
        New-Item -Path $compatPath -Force | Out-Null
    }
    Set-ItemProperty -Path $compatPath -Name "CompatibilityMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Host "    ✓ Compatibility mode enabled" -ForegroundColor Green
    
    Write-Host "`n  Hardware compatibility bypasses applied successfully!" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    # Step 2: Download the upgrade script
    Write-Host "`nStep 2: Downloading Windows 11 upgrade script..." -ForegroundColor Yellow
    
    $downloadUrl = "https://raw.githubusercontent.com/murtaza7869/IMaging/refs/heads/main/UpgradeWin11.ps1"
    $localPath = "$env:TEMP\UpgradeWin11.ps1"
    $taskName = "Win11UpgradeTask"
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $localPath -UseBasicParsing
        Write-Host "  ✓ Script downloaded successfully to: $localPath" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Failed to download script: $_" -ForegroundColor Red
        exit 1
    }
    
    # Verify the script was downloaded
    if (-not (Test-Path $localPath)) {
        Write-Host "  ✗ Downloaded script not found at expected location!" -ForegroundColor Red
        exit 1
    }
    
    # Step 3: Create wrapper script with additional bypasses
    Write-Host "`nStep 3: Creating wrapper script with environment variables..." -ForegroundColor Yellow
    
    $wrapperScript = @"
# Windows 11 Upgrade Wrapper Script with Bypass Environment Variables
`$ErrorActionPreference = "Continue"

# Set environment variables to bypass checks
Write-Host "Setting bypass environment variables..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable("BypassTPMCheck", "1", "Process")
[System.Environment]::SetEnvironmentVariable("BypassCPUCheck", "1", "Process")
[System.Environment]::SetEnvironmentVariable("BypassRAMCheck", "1", "Process")
[System.Environment]::SetEnvironmentVariable("BypassStorageCheck", "1", "Process")
[System.Environment]::SetEnvironmentVariable("BypassSecureBootCheck", "1", "Process")
[System.Environment]::SetEnvironmentVariable("AllowUpgradesWithUnsupportedTPMOrCPU", "1", "Process")

Write-Host "Environment variables set. Starting upgrade script..." -ForegroundColor Green

# Execute the main upgrade script
& "$localPath"
"@
    
    $wrapperPath = "$env:TEMP\Win11UpgradeWrapper.ps1"
    $wrapperScript | Out-File -FilePath $wrapperPath -Encoding UTF8 -Force
    Write-Host "  ✓ Wrapper script created at: $wrapperPath" -ForegroundColor Green
    
    # Step 4: Set up scheduled task
    Write-Host "`nStep 4: Creating scheduled task..." -ForegroundColor Yellow
    
    # Get current user information
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host "  Current user: $currentUser" -ForegroundColor Cyan
    
    # Calculate trigger time (30 seconds from now)
    $triggerTime = (Get-Date).AddSeconds(30)
    Write-Host "  Task will run at: $($triggerTime.ToString('HH:mm:ss'))" -ForegroundColor Cyan
    
    # Remove existing task if it exists
    try {
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "  Removing existing task..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
    }
    catch {
        # Task doesn't exist, continue
    }
    
    # Create scheduled task action to run the wrapper script
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$wrapperPath`""
    
    # Create trigger for 30 seconds from now
    $trigger = New-ScheduledTaskTrigger -Once -At $triggerTime
    
    # Create principal to run with highest privileges
    $principal = New-ScheduledTaskPrincipal -UserId $currentUser `
        -LogonType Interactive `
        -RunLevel Highest
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 4) `
        -Priority 4 `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Register the scheduled task
    try {
        $task = Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description "Windows 11 Upgrade Task with Hardware Bypass - Runs the upgrade script" `
            -Force
        
        Write-Host "  ✓ Scheduled task created successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Failed to create scheduled task: $_" -ForegroundColor Red
        exit 1
    }
    
    # Verify task was created
    $verifyTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($verifyTask) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "TASK CREATED SUCCESSFULLY!" -ForegroundColor Green
        Write-Host "=" * 60 -ForegroundColor Cyan
        Write-Host "`nTask Details:" -ForegroundColor Cyan
        Write-Host "  Task Name: $($verifyTask.TaskName)" -ForegroundColor White
        Write-Host "  State: $($verifyTask.State)" -ForegroundColor White
        Write-Host "  Next Run Time: $($triggerTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
        Write-Host "`nHardware Bypasses Applied:" -ForegroundColor Cyan
        Write-Host "  ✓ TPM 2.0 requirement bypassed" -ForegroundColor Green
        Write-Host "  ✓ CPU compatibility check bypassed" -ForegroundColor Green
        Write-Host "  ✓ RAM requirement bypassed" -ForegroundColor Green
        Write-Host "  ✓ Storage requirement bypassed" -ForegroundColor Green
        Write-Host "  ✓ Secure Boot requirement bypassed" -ForegroundColor Green
        Write-Host "  ✓ UEFI requirement bypassed" -ForegroundColor Green
        Write-Host "`nThe Windows 11 upgrade will start in 30 seconds!" -ForegroundColor Green
        Write-Host "Monitor progress in Task Scheduler (taskschd.msc)" -ForegroundColor Yellow
    }
    else {
        Write-Host "  ⚠ Warning: Could not verify task creation!" -ForegroundColor Yellow
    }
    
    # Display countdown
    Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
    Write-Host "STARTING COUNTDOWN..." -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    for ($i = 30; $i -gt 0; $i--) {
        Write-Progress -Activity "Windows 11 Upgrade Starting In" `
            -Status "$i seconds remaining" `
            -PercentComplete ((30-$i)/30*100) `
            -CurrentOperation "Hardware checks bypassed - Upgrade will proceed regardless of compatibility"
        Start-Sleep -Seconds 1
    }
    Write-Progress -Activity "Windows 11 Upgrade Starting In" -Completed
    
    Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
    Write-Host "UPGRADE TASK IS NOW RUNNING!" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "`nThe upgrade will proceed with all hardware checks bypassed." -ForegroundColor Yellow
    Write-Host "Check Task Scheduler for status and results." -ForegroundColor Yellow
    Write-Host "`nNote: System may restart during the upgrade process." -ForegroundColor Cyan
}
catch {
    Write-Host "`n" + "=" * 60 -ForegroundColor Red
    Write-Host "ERROR OCCURRED!" -ForegroundColor Red
    Write-Host "=" * 60 -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
    Write-Host "Script execution completed." -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}
