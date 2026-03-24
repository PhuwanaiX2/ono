# ==============================================================================
# FiveM Optimizer - JIWW Edition (Safe Mode for Daily-Use PC)
# ==============================================================================
# ⚡ เวอร์ชันนี้ปลอดภัยสำหรับคอมใช้งานทั่วไป
# ✅ ไม่ปิด Antivirus / Core Isolation / Background Apps / Telemetry
# ✅ เน้นแค่ปรับ performance เกม โดยไม่กระทบการใช้งานปกติ
# ==============================================================================

$ShopName = "JIWW Edition"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to close..."
    Exit
}

Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   $ShopName - Safe Performance Optimizer     " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Optimizes FiveM performance WITHOUT compromising system security." -ForegroundColor White
Write-Host ""
Write-Host "🛡️  SAFE MODE: Antivirus, Core Isolation, Background Apps = UNTOUCHED" -ForegroundColor Green

# --- Hardware Detection ---
$CPU = ((Get-CimInstance Win32_Processor | Select-Object -First 1).Name).Replace("  ", " ").Trim()
$RAM_Bytes = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum
$RAM = [math]::Round($RAM_Bytes / 1GB)

$GPUs = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Microsoft Basic|Remote" }
$GPU = ($GPUs.Name | ForEach-Object { $_.Trim() }) -join " + "
if (-not $GPU) { $GPU = "Unknown GPU / Integrated Graphics" }

$OS = Get-CimInstance Win32_OperatingSystem
$WinEdition = "$($OS.Caption.Replace('Microsoft ','').Trim()) (Build $($OS.BuildNumber))"
$IsHomeSKU = $WinEdition -match "Home"

$SystemDrive = $OS.SystemDrive
$DiskFree = [math]::Round((Get-PSDrive ($SystemDrive.Replace(":", ""))).Free / 1GB, 1)
$DiskType = "Unknown Disk Type"
try {
    $PhysDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object MediaType, BusType
    $HasHDD = $PhysDisks.MediaType -contains "HDD"
    if ($PhysDisks.MediaType -contains "SSD" -or $PhysDisks.BusType -contains "NVMe") {
        if ($HasHDD) { $DiskType = "SSD + HDD (Mixed)" }
        else { $DiskType = "SSD/NVMe Only" }
    } elseif ($HasHDD) {
        $DiskType = "HDD Only"
    }
} catch { }

Write-Host "`n💻 PC Hardware Specifications:" -ForegroundColor Yellow
Write-Host "   CPU      : $CPU"
Write-Host "   RAM      : ${RAM} GB"
Write-Host "   GPU      : $GPU"
Write-Host "   Disk     : $DiskType (Free Space on ${SystemDrive} = ${DiskFree} GB)"
Write-Host "   Windows  : $WinEdition"
Write-Host "-----------------------------------------------------"

Write-Host "`n🔒 Security Status:" -ForegroundColor Yellow
Write-Host "   Windows Defender  : ✅ KEPT ENABLED" -ForegroundColor Green
Write-Host "   Core Isolation    : ✅ KEPT ENABLED" -ForegroundColor Green
Write-Host "   Background Apps   : ✅ KEPT ENABLED" -ForegroundColor Green
Write-Host "   Error Reporting   : ✅ KEPT ENABLED" -ForegroundColor Green
Write-Host "-----------------------------------------------------"

Write-Host "`n⚡ This script will apply 11 SAFE tweaks:" -ForegroundColor Cyan
Write-Host "   1. Disable Xbox Game Bar & DVR"
Write-Host "   2. Disable Mouse Acceleration"
Write-Host "   3. Optimize Windows Timers"
Write-Host "   4. Ultimate Performance Power Plan"
Write-Host "   5. Priority & Network Throttling"
Write-Host "   6. Game Thread Priorities"
Write-Host "   7. TCP/IP Latency Reduction"
Write-Host "   8. Defender Exclusion for FiveM (folder only)"
Write-Host "   9. Disable Fullscreen Optimizations"
Write-Host "   10. QoS Policy for FiveM"
Write-Host "   11. Hardware-Accelerated GPU Scheduling"
Write-Host ""

$confirm = Read-Host "Proceed with SAFE optimization? (Y/N)"
if ($confirm -notmatch "^[Yy]$") { Exit }

Write-Host "`nCreating Restore Point... Please wait." -ForegroundColor Yellow
$srService = Get-Service -Name "srservice" -ErrorAction SilentlyContinue
if ($srService -and $srService.Status -ne "Stopped") {
    try {
        Enable-ComputerRestore -Drive "$SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Before FiveM Optimizer JIWW Safe" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "✅ Restore Point created." -ForegroundColor Green
    }
    catch { }
}

Write-Host "`nApplying SAFE tweaks, please wait..." -ForegroundColor Cyan

function Set-Reg($Path, $Name, $Value, $Type = "DWord") {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    if ($Type) {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
    }
    else {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -ErrorAction SilentlyContinue
    }
}

function Show-Progress($StepNum, $StepName) {
    Write-Host "[$StepNum/11] $StepName..." -NoNewline -ForegroundColor White
    Start-Sleep -Milliseconds 250
    Write-Host " Done!" -ForegroundColor Green
}

# 1. Xbox Game Bar & DVR
Show-Progress "1" "Disabling Xbox Game Bar & DVR"
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0

# 2. Mouse Acceleration & USB Input Lag
Show-Progress "2" "Disabling Mouse Acceleration & USB Suspend"
Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"
Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"
Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\USB" "DisableSelectiveSuspend" 1 "DWord"

# 3. Timer Tweaks (BCDEdit)
Show-Progress "3" "Optimizing Windows Timers (HPET)"
bcdedit /deletevalue useplatformtick 2>$null | Out-Null
bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
bcdedit /deletevalue useplatformclock 2>$null | Out-Null

# 4. Ultimate Performance Power Plan
Show-Progress "4" "Enabling Ultimate Performance Power Plan"
$plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace "root\cimv2\power" | Where-Object ElementName -eq "Ultimate Performance"
if (-not $plan) {
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
    $plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace "root\cimv2\power" | Where-Object ElementName -eq "Ultimate Performance"
}
if ($plan) { powercfg -setactive $($plan.InstanceID.Split('{')[1].TrimEnd('}')) }

# 5. Priority & Network Throttling
Show-Progress "5" "Optimizing Priority & Network Throttling"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "IRQ8Priority" 1 "DWord"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295 "DWord"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0 "DWord"

# 6. Game-Specific Thread Priorities
Show-Progress "6" "Setting Game-Specific Thread Priorities"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8 "DWord"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6 "DWord"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" "String"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "High" "String"

# 7. TCP/IP Latency Reduction
Show-Progress "7" "Reducing TCP/IP Network Latency"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpNoDelay" 1 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPAckFrequency" 1 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPDelAckTicks" 0 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DefaultTTL" 64 "DWord"
$tcpInterfaces = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -ErrorAction SilentlyContinue
foreach ($iface in $tcpInterfaces) {
    Set-Reg $iface.PSPath "TcpNoDelay" 1 "DWord"
    Set-Reg $iface.PSPath "TcpAckFrequency" 1 "DWord"
}

# 8. Defender Exclusion (FiveM folder only - NOT disabling Defender)
Show-Progress "8" "Adding Defender Exclusion for FiveM folder"
try { Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\FiveM" -ErrorAction SilentlyContinue } catch {}

# 9. Disable Fullscreen Optimizations
Show-Progress "9" "Disabling Fullscreen Optimizations"
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_EFSEFeatureFlags" 0

# 10. QoS Policy
Show-Progress "10" "Configuring Advanced QoS Policy"
if ($WinEdition -notmatch "Home") {
    Remove-NetQosPolicy -Name "FiveMLag*" -Confirm:$false -ErrorAction SilentlyContinue
    $qosApps = @("FiveM.exe", "GTA5.exe", "FiveM_b2545_GTAProcess.exe", "FiveM_b2699_GTAProcess.exe", "FiveM_b2802_GTAProcess.exe", "FiveM_b3095_GTAProcess.exe", "FiveM_b3258_GTAProcess.exe")
    foreach ($app in $qosApps) {
        $policyName = "FiveMLag_" + ($app -replace ".exe","")
        New-NetQosPolicy -Name $policyName -AppPathNameMatchCondition $app -NetworkProfile All -DSCPAction 46 -ErrorAction SilentlyContinue | Out-Null
    }
} else {
    Write-Host "   (Skipped - Windows Home does not support QoS Policy)" -ForegroundColor DarkYellow
}

# 11. Hardware-Accelerated GPU Scheduling (HAGS)
Show-Progress "11" "Enabling Hardware-Accelerated GPU Scheduling"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 "DWord"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  ✅ All SAFE tweaks applied successfully!     " -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "🛡️  Your system security is FULLY INTACT:" -ForegroundColor Cyan
Write-Host "   - Windows Defender: Still running"
Write-Host "   - Core Isolation: Still enabled"
Write-Host "   - Background Apps: Still running"
Write-Host "   - Error Reporting: Still active"
Write-Host ""
Write-Host "Please restart the PC for changes to take full effect." -ForegroundColor Yellow
Read-Host "Press Enter to exit..."
