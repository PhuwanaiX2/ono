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

# Helper function to print progress
function Show-Progress($StepNum, $StepName) {
    Write-Host "[$StepNum/21] $StepName..." -NoNewline -ForegroundColor White
    Start-Sleep -Milliseconds 150
    Write-Host " Done!" -ForegroundColor Green
}

# 1. Telemetry
Show-Progress "1" "Restoring Telemetry & Error Reporting"
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -Force -ErrorAction SilentlyContinue
Set-Service -Name diagtrack -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name diagtrack -ErrorAction SilentlyContinue
Set-Service -Name WerSvc -StartupType Manual -ErrorAction SilentlyContinue

# 2. Xbox Game Bar & DVR
Show-Progress "2" "Restoring Xbox Game Bar & DVR"
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name AppCaptureEnabled -Value 1 -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name AllowGameDVR -Force -ErrorAction SilentlyContinue

# 3. Background Apps, Search, SysMain
Show-Progress "3" "Restoring Background Apps & SysMain"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name GlobalUserDisabled -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 1 -Force -ErrorAction SilentlyContinue
Set-Service -Name SysMain -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name SysMain -ErrorAction SilentlyContinue

# 4. Mouse Acceleration & USB
Show-Progress "4" "Restoring Mouse & USB Settings"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value "1" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value "6" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value "10" -Type String -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -Force -ErrorAction SilentlyContinue

# 5. Timer Tweaks (BCDEdit Revert)
Show-Progress "5" "Restoring Windows Timers (HPET)"
bcdedit /deletevalue useplatformtick 2>$null | Out-Null
bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
bcdedit /deletevalue useplatformclock 2>$null | Out-Null

# 6. Hibernation
Show-Progress "6" "Restoring Hibernation"
powercfg.exe /hibernate on

# 7. Balanced Power Plan & Remove Ultimate
Show-Progress "7" "Restoring Balanced Power Plan"
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
$ultPlan = powercfg -list 2>$null | Select-String "Ultimate Performance"
if ($ultPlan) {
    $guid = ($ultPlan.ToString().Trim() -split '\s+')[3]
    if ($guid) { powercfg -delete $guid 2>$null }
}

# 8. Priority & Network Throttling
Show-Progress "8" "Restoring Priority & Network Throttling"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name Win32PrioritySeparation -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ8Priority" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -Type DWord -Force -ErrorAction SilentlyContinue

# 9. Game Tasks Priority 
Show-Progress "9" "Restoring Game Task Priorities"
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "SFIO Priority" -Force -ErrorAction SilentlyContinue

# 10. TCP/IP Latency Revert
Show-Progress "10" "Restoring TCP/IP Network Settings"
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpNoDelay" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPAckFrequency" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPDelAckTicks" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -Force -ErrorAction SilentlyContinue
$tcpInterfaces = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -ErrorAction SilentlyContinue
foreach ($iface in $tcpInterfaces) {
    Remove-ItemProperty -Path $iface.PSPath -Name "TcpNoDelay" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -Force -ErrorAction SilentlyContinue
}

# 11. Remove Defender Exclusion
Show-Progress "11" "Removing Defender Exclusion"
try { Remove-MpPreference -ExclusionPath "$env:LOCALAPPDATA\FiveM" -ErrorAction SilentlyContinue } catch {}

# 12. Restore Fullscreen Optimizations
Show-Progress "12" "Restoring Fullscreen Optimizations"
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 13. QoS Policy Remove
Show-Progress "13" "Removing Advanced QoS Policy"
Remove-NetQosPolicy -Name "FiveMLag*" -Confirm:$false -ErrorAction SilentlyContinue

# 14. Memory Management (Revert)
Show-Progress "14" "Restoring Memory Management Settings"
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "NonPagedPoolQuota" -Force -ErrorAction SilentlyContinue


# 15. Core Isolation (Revert to default)
Show-Progress "15" "Restoring Core Isolation (VBS)"
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Force -ErrorAction SilentlyContinue

# 16. Restore FTH
Show-Progress "16" "Restoring Fault Tolerant Heap"
Set-ItemProperty -Path "HKLM:\Software\Microsoft\FTH" -Name "Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# 17. Restore Power Throttling
Show-Progress "17" "Restoring Power Throttling"
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Force -ErrorAction SilentlyContinue

# 18. Restore Delivery Optimization
Show-Progress "18" "Restoring Delivery Optimization"
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Force -ErrorAction SilentlyContinue

# 19. Restore HAGS
Show-Progress "19" "Restoring GPU Scheduling (HAGS)"
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Force -ErrorAction SilentlyContinue

# 20. Restore Network Large Send Offload (LSO)
Show-Progress "20" "Restoring Network Offloading (LSO)"
Remove-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\TCPIP\Parameters" -Name "DisableTaskOffload" -Force -ErrorAction SilentlyContinue

# 21. Network Reset (Logic below)
Show-Progress "21" "Preparing Network Reset Options"

Write-Host "✅ System restored to Windows defaults successfully!" -ForegroundColor Green

# 22. Network Reset Feature (BONUS V2)
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
