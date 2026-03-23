# ==============================================================================
# FiveM Optimizer - RESTORE (Fast Admin Edition)
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to close..."
    Exit
}

Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "    FiveM Optimizer - RESTORE DEFAULTS       " -ForegroundColor Yellow
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

# 3. Background Apps & Bing Search
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name GlobalUserDisabled -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 1 -Force -ErrorAction SilentlyContinue

# 4. Mouse Acceleration (Default string values)
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value "1" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value "6" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value "10" -Type String -Force -ErrorAction SilentlyContinue

# 5. Hibernation
powercfg.exe /hibernate on

# 6. Balanced Power Plan & Remove Ultimate
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
$ultPlan = powercfg -list 2>$null | Select-String "Ultimate Performance"
if ($ultPlan) {
    $guid = ($ultPlan.ToString().Trim() -split '\s+')[3]
    if ($guid) { powercfg -delete $guid 2>$null }
}

# 7. Priority & Network Throttling
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name Win32PrioritySeparation -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -Type DWord -Force -ErrorAction SilentlyContinue

# 8. Remove Defender Exclusion
try { Remove-MpPreference -ExclusionPath "$env:LOCALAPPDATA\FiveM" -ErrorAction SilentlyContinue } catch {}

# 9. Restore Fullscreen Optimizations & Visual Effects
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 10. QoS Policy Remove
Remove-NetQosPolicy -Name "FiveMLag*" -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "✅ System restored to Windows defaults successfully!" -ForegroundColor Green
Write-Host "Please restart the PC for changes to take full effect." -ForegroundColor Yellow
Read-Host "Press Enter to exit..."
