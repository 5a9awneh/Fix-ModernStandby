#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  Fix-ModernStandby - Apply Standby Fix" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will apply the following changes:" -ForegroundColor Yellow
Write-Host "  - Disable Networking Connectivity in Standby" -ForegroundColor Yellow
Write-Host "  - Disable Fast Startup" -ForegroundColor Yellow
Write-Host "  - Disable Allow Wake Timers (AC and DC)" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Type YES to continue or press Enter to abort"
if ($confirm -ne 'YES') {
    Write-Host "Aborted. No changes were made." -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    exit 0
}
Write-Host ""

$success = $true

# ============================================================
# 1 - Networking Connectivity in Standby -> Disabled
# ============================================================
Write-Host "[1/3] Disabling Networking Connectivity in Standby..." -ForegroundColor Cyan

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\f15576e8-98b7-4186-b944-eafa664402d9" /v Attributes /t REG_DWORD /d 2 /f | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "  (1a) reg add Attributes failed with error $LASTEXITCODE"
    $success = $false
}

powercfg /setacvalueindex SCHEME_CURRENT 238C9FA8-0AAD-41ED-83F4-97BE242C8F20 f15576e8-98b7-4186-b944-eafa664402d9 0 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "  (1b) setacvalueindex failed with error $LASTEXITCODE"
    $success = $false
}

powercfg /setdcvalueindex SCHEME_CURRENT 238C9FA8-0AAD-41ED-83F4-97BE242C8F20 f15576e8-98b7-4186-b944-eafa664402d9 0 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "  (1c) setdcvalueindex failed with error $LASTEXITCODE"
    $success = $false
}

if ($success) { Write-Host "  Done." -ForegroundColor Green }

# ============================================================
# 2 - Fast Startup -> Disabled
# ============================================================
Write-Host "[2/3] Disabling Fast Startup..." -ForegroundColor Cyan

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "  (2) HiberbootEnabled reg add failed with error $LASTEXITCODE"
    $success = $false
} else {
    Write-Host "  Done." -ForegroundColor Green
}

# ============================================================
# 3 - Allow Wake Timers -> Disabled (AC and DC)
# ============================================================
Write-Host "[3/3] Disabling Allow Wake Timers..." -ForegroundColor Cyan

$step3Success = $true

powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "  (3a) setacvalueindex RTCWAKE failed with error $LASTEXITCODE"
    $success = $false
    $step3Success = $false
}

powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "  (3b) setdcvalueindex RTCWAKE failed with error $LASTEXITCODE"
    $success = $false
    $step3Success = $false
}

# Apply all changes to the active power scheme
powercfg /setactive SCHEME_CURRENT | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "  setactive SCHEME_CURRENT failed with error $LASTEXITCODE"
    $step3Success = $false
}

if ($step3Success) { Write-Host "  Done." -ForegroundColor Green }

# ============================================================
# Summary
# ============================================================
Write-Host ""
if ($success) {
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "  All three settings applied." -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
} else {
    Write-Host "=======================================" -ForegroundColor Yellow
    Write-Host "  Completed with warnings - review above" -ForegroundColor Yellow
    Write-Host "=======================================" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  - Networking Connectivity in Standby : DISABLED" -ForegroundColor White
Write-Host "  - Fast Startup                        : DISABLED" -ForegroundColor White
Write-Host "  - Allow Wake Timers                   : DISABLED" -ForegroundColor White
Write-Host ""
Write-Host "*** A REBOOT IS REQUIRED for the Fast Startup change to take effect. ***" -ForegroundColor Yellow
Write-Host "    Reboot now, then verify with Test-StandbyBehavior (TEST.bat)." -ForegroundColor White
Write-Host ""
Write-Host "To verify manually after reboot:" -ForegroundColor Gray
Write-Host "  powercfg /query SCHEME_CURRENT 238C9FA8-0AAD-41ED-83F4-97BE242C8F20 f15576e8-98b7-4186-b944-eafa664402d9" -ForegroundColor Gray
Write-Host "  powercfg /query SCHEME_CURRENT SUB_SLEEP RTCWAKE" -ForegroundColor Gray
Write-Host "  reg query `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power`" /v HiberbootEnabled" -ForegroundColor Gray
Write-Host "  (All three should return 0x00000000)" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to close"
