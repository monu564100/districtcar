# ==============================================================================
# DISTRICT CAR — PRODUCTION APK BUILD AUTOMATION SCRIPT (POWERSHELL)
# ==============================================================================
$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$OutputDir = Join-Path $ProjectRoot "build_outputs"
$LandingDir = Join-Path $ProjectRoot "landing"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
if (-not (Test-Path $LandingDir)) {
    New-Item -ItemType Directory -Path $LandingDir | Out-Null
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "      DISTRICT CAR — MOBILE APPLICATION BUILD PIPELINE    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. CUSTOMER APPLICATION
Write-Host ""
Write-Host "🚀 Building Customer App Release APK (com.districtcar.customer)..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectRoot "customer_app")
flutter clean
flutter pub get
flutter build apk --release

$CustomerApk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $CustomerApk) {
    Copy-Item $CustomerApk (Join-Path $OutputDir "DistrictCar_Customer_Release.apk") -Force
    Copy-Item $CustomerApk (Join-Path $LandingDir "DistrictCar_Customer_Release.apk") -Force
    Write-Host "✅ Customer APK successfully built: $OutputDir\DistrictCar_Customer_Release.apk" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to locate Customer release APK." -ForegroundColor Red
    exit 1
}

# 2. DRIVER APPLICATION
Write-Host ""
Write-Host "🚀 Building Driver / Partner Release APK (com.drivercardistrict.app)..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectRoot "driver_app")
flutter clean
flutter pub get
flutter build apk --release

$DriverApk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $DriverApk) {
    Copy-Item $DriverApk (Join-Path $OutputDir "DistrictCar_Driver_Release.apk") -Force
    Copy-Item $DriverApk (Join-Path $LandingDir "DistrictCar_Driver_Release.apk") -Force
    Write-Host "✅ Driver APK successfully built: $OutputDir\DistrictCar_Driver_Release.apk" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to locate Driver release APK." -ForegroundColor Red
    exit 1
}

Set-Location $ProjectRoot

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🎉 ALL BUILDS COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "Customer APK: $OutputDir\DistrictCar_Customer_Release.apk" -ForegroundColor White
Write-Host "Driver APK:   $OutputDir\DistrictCar_Driver_Release.apk" -ForegroundColor White
Write-Host "Landing Page: $LandingDir\index.html" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
