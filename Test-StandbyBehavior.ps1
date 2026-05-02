#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

$reportsDir = Join-Path $PSScriptRoot "reports"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Fix-ModernStandby - Standby Behavior Test" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "HOW TO USE THIS TOOL:" -ForegroundColor Yellow
Write-Host "  1. Run this script in the evening before closing the lid" -ForegroundColor White
Write-Host "  2. Review the active power requests shown below" -ForegroundColor White
Write-Host "  3. Close the lid and leave the device overnight" -ForegroundColor White
Write-Host "  4. Wake the device the next morning" -ForegroundColor White
Write-Host "  5. Return to this window and press Enter to generate the report" -ForegroundColor White
Write-Host ""

# ============================================================
# PRE-SLEEP - Active wake request check
# ============================================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  STEP 1 OF 2 - Active Power Requests (before closing lid)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If any [System] or [Display] entries appear below," -ForegroundColor Yellow
Write-Host "those components are actively blocking sleep entry." -ForegroundColor Yellow
Write-Host ""

powercfg /requests

Write-Host ""
Write-Host "If no [System] or [Display] entries are shown above: good." -ForegroundColor Green
Write-Host ""
Write-Host "Close the lid now and leave overnight." -ForegroundColor Cyan
Write-Host "Come back tomorrow morning and press Enter to generate the sleep report." -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter when you are ready to generate the report (run the morning after)"

# ============================================================
# POST-SLEEP - SleepStudy report
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  STEP 2 OF 2 - Generating SleepStudy Report..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir | Out-Null
}

$reportPath = Join-Path $reportsDir "sleepstudy_report.html"
powercfg /sleepstudy /output "$reportPath"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: sleepstudy failed with error $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Ensure the system has been in Modern Standby at least once since last boot." -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host ""
Write-Host "Report saved to: $reportPath" -ForegroundColor Green
Write-Host "Opening report..." -ForegroundColor Gray
Start-Process $reportPath

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  WHAT TO LOOK FOR IN THE REPORT:" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  DRIPS %%  : should be >= 80%% (green). Below 80%% = still draining." -ForegroundColor White
Write-Host "  DRAIN RATE: should be < 0.33%% per hour (green threshold)." -ForegroundColor White
Write-Host "  TOP OFFENDERS: any red component is keeping the CPU awake." -ForegroundColor White
Write-Host "                 Note the component name and type for escalation." -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to close"
