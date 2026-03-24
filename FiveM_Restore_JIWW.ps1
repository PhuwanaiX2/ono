# ==============================================================================
# FiveM Optimizer - RESTORE (JIWW Safe Edition)
# ==============================================================================
# Reverts only the SAFE tweaks applied by FiveM_Optimizer_JIWW.ps1
# ==============================================================================

$ShopName = "JIWW Edition"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to close..."
    Exit
}

Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==============================================" -ForegroundColor Yellow
Write-Host "    $ShopName - RESTORE DEFAULTS (Safe)       " -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor Yellow
Write-Host "This will revert all SAFE tweaks to Windows defaults." -ForegroundColor White

$confirm = Read-Host "Proceed with system restore? (Y/N)"
if ($confirm -notmatch "^[Yy]$") { Exit }

Write-Host "`nReverting tweaks... please wait." -ForegroundColor Cyan

function Show-Progress($StepNum, $StepName) {
    Write-Host "[$StepNum/11] $StepName..." -NoNewline -ForegroundColor White
    Start-Sleep -Milliseconds 150
    Write-Host " Done!" -ForegroundColor Green
}

# 1. Xbox Game Bar & DVR
Show-Progress "1" "Restoring Xbox Game Bar & DVR"
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name AppCaptureEnabled -Value 1 -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name AllowGameDVR -Force -ErrorAction SilentlyContinue

# 2. Mouse Acceleration & USB
Show-Progress "2" "Restoring Mouse & USB Settings"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value "1" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value "6" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value "10" -Type String -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -Force -ErrorAction SilentlyContinue

# 3. Timer Tweaks (BCDEdit Revert)
Show-Progress "3" "Restoring Windows Timers (HPET)"
bcdedit /deletevalue useplatformtick 2>$null | Out-Null
bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
bcdedit /deletevalue useplatformclock 2>$null | Out-Null

# 4. Balanced Power Plan & Remove Ultimate
Show-Progress "4" "Restoring Balanced Power Plan"
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
$ultPlan = powercfg -list 2>$null | Select-String "Ultimate Performance"
if ($ultPlan) {
    $guid = ($ultPlan.ToString().Trim() -split '\s+')[3]
    if ($guid) { powercfg -delete $guid 2>$null }
}

# 5. Priority & Network Throttling
Show-Progress "5" "Restoring Priority & Network Throttling"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name Win32PrioritySeparation -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ8Priority" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -Type DWord -Force -ErrorAction SilentlyContinue

# 6. Game Tasks Priority
Show-Progress "6" "Restoring Game Task Priorities"
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "SFIO Priority" -Force -ErrorAction SilentlyContinue

# 7. TCP/IP Latency Revert
Show-Progress "7" "Restoring TCP/IP Network Settings"
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpNoDelay" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPAckFrequency" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPDelAckTicks" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -Force -ErrorAction SilentlyContinue
$tcpInterfaces = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -ErrorAction SilentlyContinue
foreach ($iface in $tcpInterfaces) {
    Remove-ItemProperty -Path $iface.PSPath -Name "TcpNoDelay" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -Force -ErrorAction SilentlyContinue
}

# 8. Remove Defender Exclusion
Show-Progress "8" "Removing Defender Exclusion"
try { Remove-MpPreference -ExclusionPath "$env:LOCALAPPDATA\FiveM" -ErrorAction SilentlyContinue } catch {}

# 9. Restore Fullscreen Optimizations
Show-Progress "9" "Restoring Fullscreen Optimizations"
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 10. QoS Policy Remove
Show-Progress "10" "Removing Advanced QoS Policy"
Remove-NetQosPolicy -Name "FiveMLag*" -Confirm:$false -ErrorAction SilentlyContinue

# 11. Restore HAGS
Show-Progress "11" "Restoring GPU Scheduling (HAGS)"
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  ✅ System restored to defaults successfully! " -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

# Network Reset Feature (Optional)
$netReset = Read-Host "`nDo you want to reset Network Adapters and clear DNS cache? (Y/N)"
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
