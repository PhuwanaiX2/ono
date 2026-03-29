# ==============================================================================
# FiveM Optimizer - V2 + JIWW Combined Script
# ==============================================================================
# make UTF-8 work better in PowerShell text output/input
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
# เริ่มสคริปต์แบบโต้ตอบทีละขั้น
function Prompt-YesNo {
    param([string]$Message)
    do {
        $response = Read-Host "$Message (Y/N)"
        if ($response -match '^[Yy]$') { return $true }
        if ($response -match '^[Nn]$') { return $false }
        Write-Host 'Please enter Y or N / กรุณาใส่ Y หรือ N' -ForegroundColor Yellow
    } while ($true)
}

function Assert-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host 'Please run as Administrator / กรุณาเปิดด้วยสิทธิ์ผู้ดูแลระบบ' -ForegroundColor Red
        Read-Host 'Press Enter to close... / กด Enter เพื่อปิด...' 
        Exit 1
    }
}

function Create-RestorePoint {
    param([string]$Description = 'Before FiveM Optimizer')
    $srService = Get-Service -Name 'srservice' -ErrorAction SilentlyContinue
    if ($srService -and $srService.Status -ne 'Stopped') {
        try {
            $systemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive
            Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            Write-Host '✅ Restore Point created.' -ForegroundColor Green
            return $true
        }
        catch {
            Write-Warning '⚠️ Failed to create restore point automatically. Continue at your own risk.'
            return $false
        }
    }
    else {
        Write-Warning '⚠️ System Restore service is not available or stopped. Skipping restore point.'
        return $false
    }
}

function Set-RegValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] $Value,
        [string]$Type = 'DWord'
    )
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    try {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed: $Path\\$Name = $Value ($Type)"
    }
}

function Show-Progress {
    param([int]$Step, [string]$Text)
    Write-Host "[$Step] $Text..." -NoNewline
    Start-Sleep -Milliseconds 200
    Write-Host ' Done!' -ForegroundColor Green
}

function Invoke-RemoteCheckScript {
    param([string]$RepoUrl = 'https://raw.githubusercontent.com/PhuwanaiX2/ono/main')
    
    Write-Host "`nDownloading check script... / กำลังดาวน์โหลดสคริปต์ตรวจสอบ..." -ForegroundColor Cyan
    try {
        $checkScript = Invoke-RestMethod -Uri "$RepoUrl/NTSHOP_SET_Check.ps1" -ErrorAction Stop
        Write-Host "✅ Download complete. Running check... / ดาวน์โหลดเสร็จ รันการตรวจสอบ..." -ForegroundColor Green
        Invoke-Expression $checkScript
    }
    catch {
        Write-Warning "⚠️ Cannot download check script from GitHub: $_ / ไม่สามารถดาวน์โหลด check script จาก GitHub: $_"
        Write-Host "Instruction: run this command manually: / คำแนะนำ: รันคำสั่งนี้ด้วยตัวเอง:" -ForegroundColor Yellow
        Write-Host "irm https://raw.githubusercontent.com/PhuwanaiX2/ono/main/NTSHOP_SET_Check.ps1 | iex" -ForegroundColor Green
    }
}

function Apply-CommonTweaks {
    Show-Progress 1 'Disabling Xbox Game Bar & DVR'
    Set-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-RegValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0

    Show-Progress 2 'Disabling Mouse Acceleration'
    Set-RegValue 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-RegValue 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-RegValue 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'

    Show-Progress 3 'Enabling Ultimate Performance Power Plan'
    $plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace 'root\cimv2\power' | Where-Object ElementName -eq 'Ultimate Performance'
    if (-not $plan) {
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
        $plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace 'root\cimv2\power' | Where-Object ElementName -eq 'Ultimate Performance'
    }
    if ($plan) { powercfg -setactive $($plan.InstanceID.Split('{')[1].TrimEnd('}')) }

    Show-Progress 4 'Setting Priority & Network Throttling'
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'IRQ8Priority' 1
    Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 4294967295
    Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 0

    Show-Progress 5 'Adding Defender Exclusion for FiveM folder'
    try { Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\FiveM" -ErrorAction SilentlyContinue } catch {}

    Show-Progress 6 'Disabling Fullscreen Optimizations'
    Set-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1
    Set-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_EFSEFeatureFlags' 0

    Show-Progress 7 'Enabling Hardware-Accelerated GPU Scheduling'
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2

    Show-Progress 8 'Configuring QoS policies for FiveM/GTA5'
    if (-not ($env:OS -match 'Windows_NT' -and (Get-CimInstance Win32_OperatingSystem).Caption -match 'Home')) {
        Remove-NetQosPolicy -Name 'FiveMLag*' -Confirm:$false -ErrorAction SilentlyContinue
        $qosApps = @('FiveM.exe','GTA5.exe','FiveM_b2545_GTAProcess.exe','FiveM_b2699_GTAProcess.exe','FiveM_b2802_GTAProcess.exe','FiveM_b3095_GTAProcess.exe','FiveM_b3258_GTAProcess.exe')
        foreach ($app in $qosApps) {
            $policy = 'FiveMLag_' + ($app -replace '\.exe$','')
            New-NetQosPolicy -Name $policy -AppPathNameMatchCondition $app -NetworkProfile All -DSCPAction 46 -ErrorAction SilentlyContinue | Out-Null
        }
    }
    else {
        Write-Host '(Windows Home detected: skipping QoS policy)' -ForegroundColor Yellow
    }
}

function Apply-V2OnlyTweaks {
    Show-Progress 9 'Disabling SysMain (if not HDD to maximize speed)'
    $phys = Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($phys -and $phys.MediaType -ne 'HDD') {
        Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
        Set-Service -Name SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    }

    Show-Progress 10 'Timer tweaks (BCDEdit)'
    bcdedit /deletevalue useplatformtick 2>$null | Out-Null
    bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
    bcdedit /deletevalue useplatformclock 2>$null | Out-Null

    Show-Progress 11 'Disabling Hibernation'
    powercfg /hibernate off

    Show-Progress 12 'Disabling Core Isolation (HVCI)'
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0

    Show-Progress 13 'Disabling Fault Tolerant Heap'
    Set-RegValue 'HKLM:\Software\Microsoft\FTH' 'Enabled' 0

    Show-Progress 14 'Disabling Power Throttling'
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1

    Show-Progress 15 'Optimizing Delivery Optimization'
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0

    Show-Progress 16 'Disabling Network Large Send Offload'
    Set-RegValue 'HKLM:\System\CurrentControlSet\Services\TCPIP\Parameters' 'DisableTaskOffload' 1
}

function Run-Optimizer {
    Assert-Admin

    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "   FiveM Optimizer (interactive run)" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan

    $confirmStart = Prompt-YesNo 'Step 1: Check system specs and start optimization? / ตรวจสเปคเครื่องและต้องการเริ่ม optimization?'
    if (-not $confirmStart) { Write-Host 'Canceled by user / ยกเลิกโดยผู้ใช้.' -ForegroundColor Yellow; return }

    Write-Host "`nStep 2: Recommended command to run first (if not already): / แนะนำคำสั่งก่อนเริ่ม (ถ้ายังไม่รัน):" -ForegroundColor Cyan
    Write-Host "Set-ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor Green
    $policyConfirm = Prompt-YesNo 'Run Set-ExecutionPolicy Bypass -Scope Process -Force now? / ต้องการสั่งเปลี่ยน ExecutionPolicy ตอนนี้?'
    if ($policyConfirm) {
        try { Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop; Write-Host '✅ ปรับ ExecutionPolicy เรียบร้อย' -ForegroundColor Green }
        catch { Write-Warning '⚠️ ไม่สามารถปรับ ExecutionPolicy ได้'; }
    }

    Write-Host "`nStep 3: Choose mode / เลือกโหมด" -ForegroundColor Cyan
    Write-Host "   1) V2 (Aggressive mode for FiveM-focused PCs) / โหมดเข้มข้น" 
    Write-Host "   2) Safe (JIWW - Safer for general daily-use PCs) / โหมดปลอดภัย"
    do {
        $choose = Read-Host 'Please select 1 or 2 / กรุณาเลือก 1 หรือ 2'
        if ($choose -eq '1') { $Mode = 'V2'; break }
        if ($choose -eq '2') { $Mode = 'Safe'; break }
        Write-Host 'Please enter 1 or 2 / กรุณาเลือกให้ถูกต้อง (1 หรือ 2)' -ForegroundColor Yellow
    } while ($true)

    $confirmMode = Prompt-YesNo "Confirm mode $Mode and start tweaks? / ยืนยันโหมด $Mode แล้วเริ่มตั้งค่า?"
    if (-not $confirmMode) { Write-Host 'Canceled by user / ยกเลิกโดยผู้ใช้.' -ForegroundColor Yellow; return }

    $hasRestore = Create-RestorePoint -Description "Before FiveM Optimizer ($Mode)"
    if (-not $hasRestore) { Write-Warning '⚠️ Restore point unavailable. Create one manually if possible / ยังสร้าง restore point ไม่ได้ กรุณาสร้างด้วยตนเองหากเป็นไปได้' }

    Write-Host "`nกำลังปรับตั้งค่า mode: $Mode" -ForegroundColor Cyan
    Apply-CommonTweaks
    if ($Mode -eq 'V2') { Apply-V2OnlyTweaks }

    Write-Host "`n✅ Optimization completed ($Mode mode)." -ForegroundColor Green

    Write-Host "`nStep 4: Verification / ตรวจผลการปรับ" -ForegroundColor Cyan
    $runCheck = Prompt-YesNo 'Run verification script now? / ต้องการรันสคริปต์ตรวจสอบตอนนี้?'
    if ($runCheck) {
        Invoke-RemoteCheckScript
    }
    else {
        Write-Host "👍 You can run the verification script manually later / สามารถรันสคริปต์ตรวจสอบด้วยตัวเองอีกครั้งได้:" -ForegroundColor Cyan
        Write-Host "irm https://raw.githubusercontent.com/PhuwanaiX2/ono/main/NTSHOP_SET_Check.ps1 | iex" -ForegroundColor Green
    }
    Write-Host '`nOptimization complete. Press Enter to close' -ForegroundColor Cyan
    Read-Host
}

Run-Optimizer
