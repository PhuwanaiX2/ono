# ==============================================================================
# FiveM Optimizer Verification Script
# ==============================================================================
# make UTF-8 work better in PowerShell text output/input
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
function Check-Reg {
    param([string]$Path, [string]$Name, $Expected)
    try {
        $value = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
        if ($value -eq $Expected) { Write-Host "OK: $Path\\$Name = $value" -ForegroundColor Green }
        else { Write-Host "WARN: $Path\\$Name = $value (expected $Expected)" -ForegroundColor Yellow }
    }
    catch {
        Write-Host "MISSING: $Path\\$Name" -ForegroundColor Red
    }
}

Write-Host '==== FiveM Optimizer Check: System Settings / Check Setting  ====' -ForegroundColor Cyan
Check-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Check-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
Check-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
Check-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0'
Check-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0'
Check-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0'
Check-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
Check-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'IRQ8Priority' 1
Check-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 4294967295
Check-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0
Check-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
Check-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0
Check-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1

Write-Host '==== Power Scheme ====' -ForegroundColor Cyan
$activePlan = (powercfg /getactivescheme 2>$null)
if ($activePlan) { Write-Host $activePlan -ForegroundColor Green } else { Write-Host 'Could not query active plan' -ForegroundColor Yellow }

Write-Host '==== QoS Policies ====' -ForegroundColor Cyan
Get-NetQosPolicy -ErrorAction SilentlyContinue | Where-Object Name -like 'FiveMLag*' | Format-Table Name,AppPathNameMatchCondition,DSCPAction -AutoSize

Write-Host '==== BCDEdit flags check ====' -ForegroundColor Cyan
bcdedit /enum {current} | Select-String -Pattern 'useplatformclock|disabledynamictick|useplatformtick' | ForEach-Object {Write-Host $_.Line}

Write-Host '`nInspection complete. Press Enter to close' -ForegroundColor Cyan
Read-Host
