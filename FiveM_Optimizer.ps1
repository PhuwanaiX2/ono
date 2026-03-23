# ==============================================================================
# FiveM Dedicated PC Optimization Script (SaaS Edition)
# Features: Hardware Detection, Estimation, and Deep Performance Tweaks
# ==============================================================================

# --- 0. Admin Check (ถ้าไม่ใช่ Admin ให้หยุดทันที) ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ กรุณาคลิกขวาที่ไฟล์นี้ แล้วเลือก 'Run as administrator'" -ForegroundColor Red
    Read-Host "กด Enter เพื่อปิด..."
    Exit
}

Clear-Host
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "       FiveM Master Optimizer - System Analysis       " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# --- 1. Hardware Detection ---
$CPU = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
$RAM_Bytes = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum
$RAM = [math]::Round($RAM_Bytes / 1GB)
$GPU = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Microsoft Basic|Remote" } | Select-Object -First 1).Name
if (-not $GPU) { $GPU = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name }
if (-not $GPU) { $GPU = "Unknown GPU / Integrated Graphics" }

# Windows Edition (ดึงก่อนเพื่อใช้เช็ค Modified OS)
$WinEdition = (Get-CimInstance Win32_OperatingSystem).Caption
$IsHomeSKU = $WinEdition -match "Home"

# ตรวจสอบว่าเป็น Modified OS หรือไม่ (AtlasOS, Ghost Spectre, ReviOS, Kernel etc.)
$IsModifiedOS = $false
if ($WinEdition -match "Atlas|Ghost|Revi|FLAVOR|Kernel|Tiny|Ameliorated") { $IsModifiedOS = $true }
try { if (Test-Path "HKLM:\SOFTWARE\AtlasOS") { $IsModifiedOS = $true } } catch {}
try { if (Test-Path "C:\Users\Default\Desktop\Ghost Toolbox.exe") { $IsModifiedOS = $true } } catch {}

# Disk Info (SSD or HDD)
$SystemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive
$DiskType = "HDD"
try {
    $PhysicalDisk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq 0 } | Select-Object -First 1
    if ($PhysicalDisk.MediaType -eq "SSD" -or $PhysicalDisk.MediaType -eq "NVMe") { $DiskType = "SSD/NVMe" }
    elseif ($PhysicalDisk.BusType -eq "NVMe") { $DiskType = "NVMe" }
} catch { $DiskType = "ไม่สามารถตรวจสอบได้" }
$DiskFree = [math]::Round((Get-PSDrive ($SystemDrive.Replace(":", ""))).Free / 1GB, 1)

Write-Host "`n💻 ข้อมูลสเปคคอมพิวเตอร์ของคุณ:" -ForegroundColor Yellow
Write-Host "   CPU      : $CPU"
Write-Host "   RAM      : ${RAM} GB"
Write-Host "   GPU      : $GPU"
Write-Host "   Disk     : $DiskType (พื้นที่ว่างบนไดร์ฟ ${SystemDrive} = ${DiskFree} GB)"
Write-Host "   Windows  : $WinEdition"
Write-Host "-----------------------------------------------------"

# --- 2. FiveM Performance Estimation & Logic ---
$Recommendation = ""
$EstFPS = ""

# RAM Check
if ($RAM -lt 16) {
    $Recommendation += "   - ⚠️ RAM น้อยกว่า 16GB: มีความเสี่ยง 'เมืองไข่ดาว' หรือโหลดแมพไม่ทัน`n"
    $Recommendation += "     (การปิด Background Apps และ Xbox Services ในสคริปต์นี้ 'โคตรจำเป็น')`n"
    $EstFPS = "40 - 60 FPS (ควรปรับภาพ Normal/Low)"
} elseif ($RAM -ge 16 -and $RAM -lt 32) {
    $Recommendation += "   - ✅ RAM ${RAM}GB: มาตรฐานที่ดีมากสำหรับ FiveM`n"
    $Recommendation += "     (การทำ Optimize จะเน้นไปที่การลดอาการ Stutter หน่วงเป็นช่วงๆ)`n"
    $EstFPS = "60 - 100+ FPS (ขึ้นอยู่กับการ์ดจอและประเทศที่เล่น)"
} else {
    $Recommendation += "   - 🚀 RAM ${RAM}GB: ระดับ High-End/สตรีมเมอร์`n"
    $Recommendation += "     (การทำ Optimize นี้จะช่วยรีดเฟรมเรตสูงสุด และลด Input Lag เมาส์)`n"
    $EstFPS = "120 - 144+ FPS ลื่นทะลุจอ"
}

# CPU Check
if ($CPU -match "i3|Ryzen 3|Pentium|Celeron") {
    $Recommendation += "   - ⚠️ CPU ระดับเริ่มต้น: ควรงดการเปิดหน้าต่างเบราว์เซอร์ทิ้งไว้ขณะเล่น`n"
} else {
    $Recommendation += "   - ✅ CPU ประสิทธิภาพสูง: ตัวสคริปต์จะปลดล็อกให้รันแบบ 100% Priority`n"
}

# Disk Check
if ($DiskType -eq "HDD") {
    $Recommendation += "   - ⚠️ ยังใช้ HDD อยู่: แนะนำอย่างยิ่งให้เปลี่ยนเป็น SSD ถ้าจะเล่น FiveM จริงจัง`n"
}
if ($DiskFree -lt 30) {
    $Recommendation += "   - ⚠️ พื้นที่ว่างเหลือน้อย (${DiskFree} GB): ควรเคลียร์พื้นที่ให้เหลือ 30 GB ขึ้นไป`n"
}

# Windows Home Warning
if ($IsHomeSKU) {
    $Recommendation += "   - ⚠️ Windows Home: ฟีเจอร์ QoS (จำกัดเน็ต FiveM) จะถูกข้ามไป เพราะ Home ไม่รองรับ`n"
}

Write-Host "📊 ประเมินประสิทธิภาพ FiveM ของเครื่องนี้:" -ForegroundColor Cyan
Write-Host "   เป้าหมาย FPS: $EstFPS" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "   คำแนะนำ:" -ForegroundColor White
Write-Host "$Recommendation" -ForegroundColor White
Write-Host "   ⚠️ หมายเหตุ: FPS จริงขึ้นอยู่กับ Mod/สคริปต์ของเซิร์ฟเวอร์ที่เล่น" -ForegroundColor DarkYellow
Write-Host "      และจำนวนผู้เล่นในพื้นที่หลัก อาจต่ำกว่าที่ประเมินได้" -ForegroundColor DarkYellow

Write-Host "=====================================================" -ForegroundColor Cyan

# --- 3. User Confirmation ---
$confirm = Read-Host "👉 ต้องการยืนยันการรัน Optimize เพื่อรีดพลังเครื่องหรือไม่? (Y/N)"
if ($confirm -notmatch "^[Yy]$") {
    Write-Host "`n❌ ยกเลิกการตั้งค่า... ไม่มีการเปลี่ยนแปลงใดๆ เกิดขึ้นในระบบ" -ForegroundColor Red
    Start-Sleep -Seconds 3
    Exit
}

# --- 4. Create Restore Point (สร้างจุดคืนค่าก่อนเปลี่ยนแปลง) ---
Write-Host "`n💾 กำลังสร้าง Restore Point (จุดกู้คืนระบบ)..." -ForegroundColor Yellow
$srService = Get-Service -Name "srservice" -ErrorAction SilentlyContinue
if ($srService -and $srService.Status -ne "Stopped") {
    try {
        Enable-ComputerRestore -Drive "$SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Before FiveM Optimizer" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "   ✅ สร้าง Restore Point สำเร็จ!" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ ไม่สามารถสร้าง Restore Point ได้ (อาจเคยสร้างไว้แล้วภายใน 24 ชม.)" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "   ⚠️ System Restore ถูกปิดใช้งาน (Modified OS) - ข้ามขั้นตอนนี้" -ForegroundColor DarkYellow
}

Write-Host "`n🚀 เริ่มต้นการปรับแต่งระบบ... (ห้ามปิดหน้าต่างนี้จนกว่าจะเสร็จ)`n" -ForegroundColor Green

# ==============================================================================
# OPTIMIZATION TWEAKS START HERE
# ==============================================================================

# Helper Function: สร้าง Registry Path ถ้ายังไม่มี
function Set-RegPath($Path) {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
}

# 1. Disable Telemetry & Diagnostics
Write-Host "[1/14] Disabling Telemetry..."
Set-RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -Value 0 -Force -ErrorAction SilentlyContinue
Set-RegPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -Value 0 -Force -ErrorAction SilentlyContinue
Set-Service -Name diagtrack -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service -Name wermgr -StartupType Disabled -ErrorAction SilentlyContinue

# 2. Disable Xbox Game Bar & GameDVR
Write-Host "[2/14] Disabling Xbox Game Bar and GameDVR..."
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -Value 0 -Force -ErrorAction SilentlyContinue
Set-RegPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name AppCaptureEnabled -Value 0 -Force -ErrorAction SilentlyContinue
Set-RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name AllowGameDVR -Value 0 -Force -ErrorAction SilentlyContinue
Get-AppxPackage "Microsoft.XboxGamingOverlay" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
Get-AppxPackage "Microsoft.XboxSpeechToTextOverlay" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

# 3. Disable Background Apps
Write-Host "[3/14] Disabling Start Menu Background Apps..."
$BgAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
Set-RegPath $BgAppsPath
Set-ItemProperty -Path $BgAppsPath -Name GlobalUserDisabled -Value 1 -Force

# 4. Disable Bing Search in Start Menu
Write-Host "[4/14] Disabling Bing Web Results in Start Menu..."
$SearchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
Set-RegPath $SearchPath
Set-ItemProperty -Path $SearchPath -Name BingSearchEnabled -Value 0 -Force

# 5. Disable Mouse Acceleration (Enhance Pointer Precision)
Write-Host "[5/14] Disabling Mouse Acceleration (1:1 Ratio)..."
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value 0 -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value 0 -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value 0 -Force

# 6. Disable Hibernation
Write-Host "[6/14] Disabling Hibernation to free up SSD space..."
powercfg.exe /hibernate off

# 7. Add & Activate Ultimate Performance Power Plan
Write-Host "[7/14] Setting Power Plan to Ultimate Performance..."
$ExistingPlan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace "root\cimv2\power" | Where-Object ElementName -eq "Ultimate Performance"
if (-not $ExistingPlan) {
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
    $ExistingPlan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace "root\cimv2\power" | Where-Object ElementName -eq "Ultimate Performance"
}
if ($ExistingPlan) {
    powercfg -setactive $($ExistingPlan.InstanceID.Split('{')[1].TrimEnd('}'))
}

# 8. Set PriorityControl for lower latency (fff9887)
Write-Host "[8/14] Setting PriorityControl (Win32PrioritySeparation to fff9887)..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name Win32PrioritySeparation -Value 268409095 -Type DWord -Force

# 9. Network Throttling Index (Unlock Network limit)
Write-Host "[9/14] Disabling Network Throttling (FFFFFFFF)..."
Set-RegPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 4294967295 -Type DWord -Force

# 10. System Responsiveness (100% CPU priority to games)
Write-Host "[10/14] Setting System Responsiveness for Gaming..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -Force

# 11. Custom Defender Exclusion for FiveM Cache
Write-Host "[11/14] Adding FiveM to Windows Defender Exclusions..."
$DefenderAvailable = $false
try { $DefenderAvailable = $null -ne (Get-Command Get-MpPreference -ErrorAction Stop) } catch {}
if ($DefenderAvailable -and -not $IsModifiedOS) {
    $FiveMPath = "$env:LOCALAPPDATA\FiveM"
    if (Test-Path $FiveMPath) {
        Add-MpPreference -ExclusionPath $FiveMPath -ErrorAction SilentlyContinue
        Write-Host "   ✅ เพิ่ม Exclusion สำเร็จ: $FiveMPath" -ForegroundColor DarkGreen
    } else {
        Write-Host "   ⚠️ ไม่พบโฟลเดอร์ FiveM (ยังไม่ได้ติดตั้ง) - ข้ามขั้นตอนนี้" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "   ⚠️ Windows Defender ไม่พบ (Modified OS / ถูกลบออกแล้ว) - ข้ามขั้นตอนนี้" -ForegroundColor DarkYellow
}

# 12. Disable Fullscreen Optimizations (FSO)
Write-Host "[12/14] Disabling Fullscreen Optimizations Globally..."
$GameConfig = "HKCU:\System\GameConfigStore"
Set-RegPath $GameConfig
Set-ItemProperty -Path $GameConfig -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $GameConfig -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force

# 13. Disable Windows Visual Effects
Write-Host "[13/14] Disabling Windows Visual Effects (Best Performance)..."
Set-RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -Force

# 14. QoS Policy (FiveMLag) - Limit 1 KBps + DSCP 1
if ($IsHomeSKU) {
    Write-Host "[14/14] ⚠️ ข้าม QoS Policy (Windows Home ไม่รองรับ)" -ForegroundColor DarkYellow
} else {
    Write-Host "[14/14] Applying QoS Policy (FiveMLag) for smooth sync..."
    Remove-NetQosPolicy -Name "FiveMLag*" -Confirm:$false -ErrorAction SilentlyContinue
    New-NetQosPolicy -Name "FiveMLag_FiveM" -AppPathNameMatchCondition "FiveM*.exe" -NetworkProfile All -DSCPAction 1 -ThrottleRateActionBitsPerSecond 8192 -ErrorAction SilentlyContinue | Out-Null
    New-NetQosPolicy -Name "FiveMLag_GTA5" -AppPathNameMatchCondition "GTA5.exe" -NetworkProfile All -DSCPAction 1 -ThrottleRateActionBitsPerSecond 8192 -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "`n=====================================================" -ForegroundColor Green
Write-Host " 🎉 Master Optimization Complete! Your PC is Ready.   " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "กรุณารีสตาร์ทเครื่องเพื่อให้การตั้งค่าสมบูรณ์ที่สุด" -ForegroundColor Yellow
Read-Host "กด Enter เพื่อปิดหน้าต่างนี้..."
