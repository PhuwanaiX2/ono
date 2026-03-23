# ==============================================================================
# FiveM Dedicated PC Optimization Script - V2 (Max Performance & Low Latency)
# ==============================================================================

# --- SHOP/BRAND SETTINGS ---
# คุณสามาถเปลี่ยนชื่อร้านหรือทีมงานของคุณตรงนี้ให้ลูกค้าเห็นได้
$ShopName = "OONO Shop"
# ---------------------------

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to close..."
    Exit
}

Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   $ShopName - Performance Optimizer V2      " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "This script applies advanced tweaks for Maximum FPS and Minimum Input Lag." -ForegroundColor White

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

$IsModifiedOS = $false
$ModifiedOSName = ""
if ($WinEdition -match "Atlas|Ghost|Revi|FLAVOR|Kernel|Tiny|Ameliorated") { $IsModifiedOS = $true }
try { if (Test-Path "HKLM:\SOFTWARE\AtlasOS") { $IsModifiedOS = $true; $ModifiedOSName = "AtlasOS" } } catch {}
try { if (Test-Path "HKLM:\SOFTWARE\ReviOS") { $IsModifiedOS = $true; $ModifiedOSName = "ReviOS" } } catch {}

$SystemDrive = $OS.SystemDrive
$DiskFree = [math]::Round((Get-PSDrive ($SystemDrive.Replace(":", ""))).Free / 1GB, 1)
$DiskType = "Unknown Disk Type"
$HasHDD = $false
try {
    $PhysDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object MediaType, BusType
    if ($PhysDisks.MediaType -contains "HDD") { $HasHDD = $true }
    
    if ($PhysDisks.MediaType -contains "SSD" -or $PhysDisks.BusType -contains "NVMe") {
        if ($HasHDD) { $DiskType = "SSD + HDD (Mixed)" }
        else { $DiskType = "SSD/NVMe Only" }
    } elseif ($HasHDD) {
        $DiskType = "HDD Only"
    } else {
        $DiskType = "Unknown Disk Type"
    }
} catch { }

Write-Host "`n💻 PC Hardware Specifications:" -ForegroundColor Yellow
Write-Host "   CPU      : $CPU"
Write-Host "   RAM      : ${RAM} GB"
Write-Host "   GPU      : $GPU"
Write-Host "   Disk     : $DiskType (Free Space on ${SystemDrive} = ${DiskFree} GB)"
if ($IsModifiedOS -and $ModifiedOSName) {
    Write-Host "   Windows  : $WinEdition (🔧 Modified OS: $ModifiedOSName)" -ForegroundColor Magenta
}
else {
    Write-Host "   Windows  : $WinEdition"
}
Write-Host "-----------------------------------------------------"

$Recommendation = ""
$EstFPS = ""

if ($RAM -lt 16) {
    $Recommendation += "   - ⚠️ RAM under 16GB: High risk of 'texture loss' or slow map rendering.`n"
    $Recommendation += "     (Closing background apps and disabling Xbox services is extremely necessary.)`n"
    $EstFPS = "40 - 60 FPS (Recommend Normal/Low settings)"
}
elseif ($RAM -ge 16 -and $RAM -lt 32) {
    $Recommendation += "   - ✅ RAM ${RAM}GB: Excellent standard for FiveM.`n"
    $Recommendation += "     (Optimization will focus on reducing micro-stutters and input lag.)`n"
    $EstFPS = "60 - 100+ FPS (Depends on GPU and the server's population)"
}
else {
    $Recommendation += "   - 🚀 RAM ${RAM}GB: High-End / Streamer Tier.`n"
    $Recommendation += "     (Optimization will maximize framerates and drastically lower input lag.)`n"
    $EstFPS = "120 - 144+ FPS Limitless"
}

if ($CPU -match "i3|Ryzen 3|Pentium|Celeron") {
    $Recommendation += "   - ⚠️ Entry-Level CPU: Do not leave browsers or heavy background apps open while playing.`n"
}
else {
    $Recommendation += "   - ✅ High-Performance CPU: The script will unlock 100% priority for the game.`n"
}

if ($HasHDD) {
    $Recommendation += "   - ⚠️ HDD Detected: Playing FiveM or GTA V on an HDD can cause map texture loss.`n"
    $Recommendation += "     (SysMain/Superfetch will be kept ENABLED to help your HDD load faster.)`n"
}
if ($DiskFree -lt 30) {
    $Recommendation += "   - ⚠️ Low Disk Space (${DiskFree} GB): Need at least 30 GB free for smooth cache allocations.`n"
}
if ($IsHomeSKU) {
    $Recommendation += "   - ⚠️ Windows Home: Advanced QoS Network Policy will be skipped as it's unsupported.`n"
}

Write-Host "📊 FiveM Performance Estimation:" -ForegroundColor Cyan
Write-Host "   Target FPS: $EstFPS" -ForegroundColor Green
Write-Host "`n   Admin/Client Recommendations:" -ForegroundColor White
Write-Host "$Recommendation" -ForegroundColor White
Write-Host "   ⚠️ Note: Actual FPS depends heavily on the specific FiveM server's mods, maps, and player count." -ForegroundColor DarkYellow

Write-Host "=============================================" -ForegroundColor Cyan

$confirm = Read-Host "Proceed with V2 optimization? (Y/N)"
if ($confirm -notmatch "^[Yy]$") { Exit }

Write-Host "`nCreating Restore Point... Please wait." -ForegroundColor Yellow
$SystemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive
$srService = Get-Service -Name "srservice" -ErrorAction SilentlyContinue
if ($srService -and $srService.Status -ne "Stopped") {
    try {
        Enable-ComputerRestore -Drive "$SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Before FiveM Optimizer V2" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "✅ Restore Point created." -ForegroundColor Green
    }
    catch { }
}

Write-Host "`nApplying V2 tweaks natively, please wait..." -ForegroundColor Cyan

function Set-Reg($Path, $Name, $Value, $Type = "DWord") {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    if ($Type) {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
    }
    else {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -ErrorAction SilentlyContinue
    }
}

# Helper function to print progress
function Show-Progress($StepNum, $StepName) {
    Write-Host "[$StepNum/20] $StepName..." -NoNewline -ForegroundColor White
    Start-Sleep -Milliseconds 250
    Write-Host " Done!" -ForegroundColor Green
}

# 1. Telemetry & Tracking
Show-Progress "1" "Disabling Telemetry & Tracking"
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Stop-Service -Name diagtrack -Force -ErrorAction SilentlyContinue 
Set-Service -Name diagtrack -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service -Name WerSvc -StartupType Disabled -ErrorAction SilentlyContinue

# 2. Xbox Game Bar & DVR
Show-Progress "2" "Disabling Xbox Game Bar & DVR"
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0

# 3. Background Apps, Bing Search & SysMain
Show-Progress "3" "Disabling Background Apps & Bing Search"
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
if (-not $HasHDD) {
    Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
    Set-Service -Name SysMain -StartupType Disabled -ErrorAction SilentlyContinue
}

# 4. Mouse Acceleration & USB Input Lag (Raw input 1:1)
Show-Progress "4" "Disabling Mouse Acceleration & USB Suspend"
Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"
Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"
Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\USB" "DisableSelectiveSuspend" 1 "DWord"

# 5. Timer Tweaks (BCDEdit - Let Windows Handle Modern HPET)
Show-Progress "5" "Optimizing Windows Timers (HPET)"
bcdedit /deletevalue useplatformtick 2>$null | Out-Null
bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
bcdedit /deletevalue useplatformclock 2>$null | Out-Null

# 6. Hibernation
Show-Progress "6" "Disabling Hibernation"
powercfg.exe /hibernate off

# 7. Ultimate Performance Power Plan
Show-Progress "7" "Enabling Ultimate Performance Power Plan"
$plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace "root\cimv2\power" | Where-Object ElementName -eq "Ultimate Performance"
if (-not $plan) {
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
    $plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace "root\cimv2\power" | Where-Object ElementName -eq "Ultimate Performance"
}
if ($plan) { powercfg -setactive $($plan.InstanceID.Split('{')[1].TrimEnd('}')) }

# 8. Priority & Network Throttling
Show-Progress "8" "Optimizing Priority & Network Throttling"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "IRQ8Priority" 1 "DWord"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295 "DWord"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0 "DWord"

# 9. Game Specific Threads Priority (V2 Tweak)
Show-Progress "9" "Setting Game-Specific Thread Priorities"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8 "DWord"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6 "DWord"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" "String"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "High" "String"

# 10. TCP/IP Latency Reduction (Leatrix Fix)
Show-Progress "10" "Reducing TCP/IP Network Latency"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpNoDelay" 1 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPAckFrequency" 1 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPDelAckTicks" 0 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DefaultTTL" 64 "DWord"
$tcpInterfaces = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -ErrorAction SilentlyContinue
foreach ($iface in $tcpInterfaces) {
    Set-Reg $iface.PSPath "TcpNoDelay" 1 "DWord"
    Set-Reg $iface.PSPath "TcpAckFrequency" 1 "DWord"
}

# 11. Defender Exclusion
Show-Progress "11" "Adding Defender Exclusion for FiveM"
try { Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\FiveM" -ErrorAction SilentlyContinue } catch {}

# 12. Disable Fullscreen Optimizations & Visual Effects
Show-Progress "12" "Disabling Fullscreen Optimizations"
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_EFSEFeatureFlags" 0

# 13. QoS Policy (FiveMLag)
Show-Progress "13" "Configuring Advanced QoS Policy"
$WinEdition = (Get-CimInstance Win32_OperatingSystem).Caption
if ($WinEdition -notmatch "Home") {
    Remove-NetQosPolicy -Name "FiveMLag*" -Confirm:$false -ErrorAction SilentlyContinue
    $qosApps = @("FiveM.exe", "GTA5.exe", "FiveM_b2545_GTAProcess.exe", "FiveM_b2699_GTAProcess.exe", "FiveM_b2802_GTAProcess.exe", "FiveM_b3095_GTAProcess.exe", "FiveM_b3258_GTAProcess.exe")
    foreach ($app in $qosApps) {
        $policyName = "FiveMLag_" + ($app -replace ".exe","")
        New-NetQosPolicy -Name $policyName -AppPathNameMatchCondition $app -NetworkProfile All -DSCPAction 46 -ErrorAction SilentlyContinue | Out-Null
    }
}

# 14. Memory Management (Non-Paged Pool & Cache)
Show-Progress "14" "Optimizing Memory Management"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 0 "DWord"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "NonPagedPoolQuota" 0 "DWord"


# 15. Disable Core Isolation (Memory Integrity - High FPS Impact)
Show-Progress "15" "Disabling Core Isolation (VBS/HVCI)"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0 "DWord"

# 16. Disable Fault Tolerant Heap (FTH)
Show-Progress "16" "Disabling Fault Tolerant Heap"
Set-Reg "HKLM:\Software\Microsoft\FTH" "Enabled" 0 "DWord"

# 17. Disable Power Throttling
Show-Progress "17" "Disabling Power Throttling"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1 "DWord"

# 18. Optimize Delivery Optimization (Bypass P2P)
Show-Progress "18" "Optimizing Windows Update Delivery"
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0 "DWord"

# 19. Enable Hardware-Accelerated GPU Scheduling (HAGS)
Show-Progress "19" "Enabling Hardware-Accelerated GPU Scheduling"
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 "DWord"

# 20. Disable Network Large Send Offload (LSO)
Show-Progress "20" "Disabling Network Large Send Offload"
Set-Reg "HKLM:\System\CurrentControlSet\Services\TCPIP\Parameters" "DisableTaskOffload" 1 "DWord"

Write-Host "✅ All V2 settings applied successfully!" -ForegroundColor Green
Write-Host "Please restart the PC for changes to take full effect." -ForegroundColor Yellow
Read-Host "Press Enter to exit..."
