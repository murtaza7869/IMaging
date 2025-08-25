# Windows 11 Upgrade Scheduler Script
# This script downloads the upgrade script and schedules it to run in 30 seconds

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    Write-Host "Starting Windows 11 Upgrade Scheduler..." -ForegroundColor Green
    
    # Define paths
    $downloadUrl = "https://raw.githubusercontent.com/murtaza7869/IMaging/refs/heads/main/UpgradeWin11.ps1"
    $localPath = "$env:TEMP\UpgradeWin11.ps1"
    $taskName = "Win11UpgradeTask"
    
    # Download the upgrade script
    Write-Host "Downloading upgrade script from GitHub..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $localPath -UseBasicParsing
        Write-Host "Script downloaded successfully to: $localPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to download script: $_" -ForegroundColor Red
        exit 1
    }
    
    # Verify the script was downloaded
    if (-not (Test-Path $localPath)) {
        Write-Host "Downloaded script not found at expected location!" -ForegroundColor Red
        exit 1
    }
    
    # Get current user information
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host "Current user: $currentUser" -ForegroundColor Cyan
    
    # Calculate trigger time (30 seconds from now)
    $triggerTime = (Get-Date).AddSeconds(30)
    Write-Host "Task will run at: $($triggerTime.ToString('HH:mm:ss'))" -ForegroundColor Cyan
    
    # Remove existing task if it exists
    Write-Host "Checking for existing scheduled task..." -ForegroundColor Yellow
    try {
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "Removing existing task..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
    }
    catch {
        # Task doesn't exist, continue
    }
    
    # Create scheduled task action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$localPath`""
    
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
        -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
        -Priority 4
    
    # Register the scheduled task
    Write-Host "Creating scheduled task..." -ForegroundColor Yellow
    try {
        $task = Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description "Windows 11 Upgrade Task - Runs the upgrade script" `
            -Force
        
        Write-Host "Scheduled task created successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create scheduled task: $_" -ForegroundColor Red
        exit 1
    }
    
    # Verify task was created
    $verifyTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($verifyTask) {
        Write-Host "`nTask Details:" -ForegroundColor Cyan
        Write-Host "  Task Name: $($verifyTask.TaskName)" -ForegroundColor White
        Write-Host "  State: $($verifyTask.State)" -ForegroundColor White
        Write-Host "  Next Run Time: $($triggerTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
        Write-Host "`nThe Windows 11 upgrade script will execute in 30 seconds!" -ForegroundColor Green
        Write-Host "You can monitor the task in Task Scheduler (taskschd.msc)" -ForegroundColor Yellow
    }
    else {
        Write-Host "Warning: Could not verify task creation!" -ForegroundColor Yellow
    }
    
    # Optional: Display countdown
    Write-Host "`nStarting countdown..." -ForegroundColor Cyan
    for ($i = 30; $i -gt 0; $i--) {
        Write-Progress -Activity "Windows 11 Upgrade Starting In" -Status "$i seconds remaining" -PercentComplete ((30-$i)/30*100)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Activity "Windows 11 Upgrade Starting In" -Completed
    Write-Host "`nUpgrade task should now be running!" -ForegroundColor Green
    Write-Host "Check Task Scheduler for status and results." -ForegroundColor Yellow
}
catch {
    Write-Host "`nAn error occurred: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Write-Host "`nScript execution completed." -ForegroundColor Cyan
}
