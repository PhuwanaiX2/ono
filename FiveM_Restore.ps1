# ==============================================================================
# FiveM Optimizer - RESTORE (คืนค่ากลับเป็นค่าเริ่มต้นของ Windows)
# ==============================================================================

# --- 0. Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ กรุณาคลิกขวาที่ไฟล์นี้ แล้วเลือก 'Run as administrator'" -ForegroundColor Red
    Read-Host "กด Enter เพื่อปิด..."
    Exit
}

Clear-Host
Write-Host "=====================================================" -ForegroundColor Yellow
Write-Host "    FiveM Optimizer - RESTORE (คืนค่าเริ่มต้น)       " -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  สคริปต์นี้จะคืนค่า Windows กลับเป็นค่าเดิมทั้งหมด" -ForegroundColor Red
Write-Host "   (ย้อนกลับทุกอย่างที่ FiveM_Optimizer.ps1 ทำไว้)" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "👉 ยืนยันการคืนค่า? (Y/N)"
if ($confirm -notmatch "^[Yy]$") {
    Write-Host "`n❌ ยกเลิก... ไม่มีการเปลี่ยนแปลงใดๆ" -ForegroundColor Red
    Start-Sleep -Seconds 3
    Exit
}

Write-Host "`n🔄 กำลังคืนค่า...`n" -ForegroundColor Cyan

# 1. Enable Telemetry
Write-Host "[1/14] Restoring Telemetry..."
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -Force -ErrorAction SilentlyContinue
Set-Service -Name diagtrack -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name diagtrack -ErrorAction SilentlyContinue
Set-Service -Name wermgr -StartupType Automatic -ErrorAction SilentlyContinue

# 2. Enable Xbox Game Bar & GameDVR
Write-Host "[2/14] Restoring Xbox Game Bar and GameDVR..."
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name AppCaptureEnabled -Value 1 -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name AllowGameDVR -Force -ErrorAction SilentlyContinue

# 3. Enable Background Apps
Write-Host "[3/14] Restoring Background Apps..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name GlobalUserDisabled -Value 0 -Force -ErrorAction SilentlyContinue

# 4. Enable Bing Search in Start Menu
Write-Host "[4/14] Restoring Bing Search..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 1 -Force -ErrorAction SilentlyContinue

# 5. Enable Mouse Acceleration (ค่าเริ่มต้น Windows)
Write-Host "[5/14] Restoring Mouse Acceleration (default)..."
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value 1 -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value 6 -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value 10 -Force

# 6. Enable Hibernation
Write-Host "[6/14] Restoring Hibernation..."
powercfg.exe /hibernate on

# 7. Set Balanced Power Plan (ค่าเริ่มต้น)
Write-Host "[7/14] Restoring Balanced Power Plan..."
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e

# 8. Reset PriorityControl (ค่าเริ่มต้น = 2 / 0x00000002)
Write-Host "[8/14] Restoring PriorityControl (default = 2)..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name Win32PrioritySeparation -Value 2 -Type DWord -Force

# 9. Reset Network Throttling (ค่าเริ่มต้น = 10 / 0x0000000A)
Write-Host "[9/14] Restoring Network Throttling (default = 10)..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force

# 10. Reset System Responsiveness (ค่าเริ่มต้น = 20)
Write-Host "[10/14] Restoring System Responsiveness (default = 20)..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -Type DWord -Force

# 11. Remove FiveM from Defender Exclusion
Write-Host "[11/14] Removing FiveM from Defender Exclusions..."
$FiveMPath = "$env:LOCALAPPDATA\FiveM"
try { Remove-MpPreference -ExclusionPath $FiveMPath -ErrorAction SilentlyContinue } catch {}

# 12. Enable Fullscreen Optimizations (FSO)
Write-Host "[12/14] Restoring Fullscreen Optimizations..."
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 13. Restore Windows Visual Effects (ค่าเริ่มต้น = Let Windows decide)
Write-Host "[13/14] Restoring Windows Visual Effects..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 14. Remove QoS Policies
Write-Host "[14/14] Removing QoS Policies (FiveMLag)..."
Remove-NetQosPolicy -Name "FiveMLag*" -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "`n=====================================================" -ForegroundColor Green
Write-Host " ✅ คืนค่าทั้งหมดสำเร็จ! เครื่องกลับสู่ค่าเริ่มต้นแล้ว " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "กรุณารีสตาร์ทเครื่องเพื่อให้การคืนค่าสมบูรณ์ที่สุด" -ForegroundColor Yellow
Read-Host "กด Enter เพื่อปิดหน้าต่างนี้..."
