# ==============================================================================
# FiveM Optimizer - RESTORE V2 (Fast Admin Edition)
# ==============================================================================

# --- SHOP/BRAND SETTINGS ---
# คุณสามาถเปลี่ยนชื่อร้านหรือทีมงานของคุณตรงนี้ให้ลูกค้าเห็นได้
$ShopName = "NT SHOP"
# ---------------------------

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to close..."
    Exit
}

Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "    $ShopName - RESTORE DEFAULTS V2          " -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "This will revert your system to Windows default settings." -ForegroundColor White

$confirm = Read-Host "Proceed with system restore? (Y/N)"
if ($confirm -notmatch "^[Yy]$") { Exit }

Write-Host "`nReverting tweaks... please wait." -ForegroundColor Cyan

# 1. Telemetry
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -Force -ErrorAction SilentlyContinue
Set-Service -Name diagtrack -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name diagtrack -ErrorAction SilentlyContinue
Set-Service -Name WerSvc -StartupType Manual -ErrorAction SilentlyContinue

# 2. Xbox Game Bar & DVR
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name AppCaptureEnabled -Value 1 -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name AllowGameDVR -Force -ErrorAction SilentlyContinue

# 3. Background Apps, Search, SysMain
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name GlobalUserDisabled -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 1 -Force -ErrorAction SilentlyContinue
Set-Service -Name SysMain -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name SysMain -ErrorAction SilentlyContinue
Set-Service -Name WSearch -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name WSearch -ErrorAction SilentlyContinue

# 4. Mouse Acceleration & USB
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value "1" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value "6" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value "10" -Type String -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -Force -ErrorAction SilentlyContinue

# 5. Timer Tweaks (BCDEdit Revert)
bcdedit /deletevalue useplatformtick | Out-Null
bcdedit /deletevalue disabledynamictick | Out-Null

# 6. Hibernation
powercfg.exe /hibernate on

# 7. Balanced Power Plan & Remove Ultimate
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
$ultPlan = powercfg -list 2>$null | Select-String "Ultimate Performance"
if ($ultPlan) {
    $guid = ($ultPlan.ToString().Trim() -split '\s+')[3]
    if ($guid) { powercfg -delete $guid 2>$null }
}

# 8. Priority & Network Throttling
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name Win32PrioritySeparation -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -Type DWord -Force -ErrorAction SilentlyContinue

# 9. Game Tasks Priority 
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "SFIO Priority" -Force -ErrorAction SilentlyContinue

# 10. TCP/IP Latency Revert
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpNoDelay" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPAckFrequency" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPDelAckTicks" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -Force -ErrorAction SilentlyContinue

# 11. Remove Defender Exclusion
try { Remove-MpPreference -ExclusionPath "$env:LOCALAPPDATA\FiveM" -ErrorAction SilentlyContinue } catch {}

# 12. Restore Fullscreen Optimizations & Visual Effects
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 13. QoS Policy Remove
Remove-NetQosPolicy -Name "FiveMLag*" -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "✅ System restored to Windows defaults successfully!" -ForegroundColor Green

# 14. Network Reset Feature (BONUS V2)
$netReset = Read-Host "`nDo you want to reset Network Adapters and clear DNS cache? (Recommended if you had lag) (Y/N)"
if ($netReset -match "^[Yy]$") {
    Write-Host "Resetting Network Interfaces..." -ForegroundColor Cyan
    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null
    ipconfig /flushdns | Out-Null
    Write-Host "✅ Network Reset complete." -ForegroundColor Green
}

Write-Host "`nPlease restart your PC to apply all default settings." -ForegroundColor Yellow
Read-Host "Press Enter to exit..."
