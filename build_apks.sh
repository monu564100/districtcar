#!/bin/bash
# ==============================================================================
# DISTRICT CAR — PRODUCTION APK BUILD AUTOMATION SCRIPT
# ==============================================================================
set -e

echo "=========================================================="
echo "      DISTRICT CAR — MOBILE APPLICATION BUILD PIPELINE    "
echo "=========================================================="

# Check for Flutter SDK
if ! command -v flutter &> /dev/null; then
    echo "⚠️ Flutter SDK is not detected in your current PATH."
    echo "Please ensure Flutter SDK is installed and added to PATH:"
    echo "  export PATH=\"\$PATH:/path/to/flutter/bin\""
    echo ""
    echo "Download Flutter SDK from: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter SDK detected: $(flutter --version | head -n 1)"

# Check for Android SDK / Java
if ! command -v java &> /dev/null; then
    echo "⚠️ Java JDK is not detected. Android builds require JDK 17+."
    echo "Install via Homebrew: brew install openjdk@17"
    exit 1
fi

echo "✅ Java Runtime detected: $(java -version 2>&1 | head -n 1)"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/build_outputs"
mkdir -p "$OUTPUT_DIR"

# ------------------------------------------------------------------------------
# 1. BUILD CUSTOMER APPLICATION APK
# ------------------------------------------------------------------------------
echo ""
echo "🚀 Building Customer App Release APK (com.districtcar.customer)..."
cd "$PROJECT_ROOT/customer_app"
flutter clean
flutter pub get
flutter build apk --release

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp "build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/DistrictCar_Customer_Release.apk"
    echo "✅ Customer APK successfully built: $OUTPUT_DIR/DistrictCar_Customer_Release.apk"
else
    echo "❌ Failed to locate Customer release APK."
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. BUILD DRIVER / VENDOR APPLICATION APK
# ------------------------------------------------------------------------------
echo ""
echo "🚀 Building Driver / Partner Release APK (com.drivercardistrict.app)..."
cd "$PROJECT_ROOT/driver_app"
flutter clean
flutter pub get
flutter build apk --release

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp "build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/DistrictCar_Driver_Release.apk"
    echo "✅ Driver APK successfully built: $OUTPUT_DIR/DistrictCar_Driver_Release.apk"
else
    echo "❌ Failed to locate Driver release APK."
    exit 1
fi

echo ""
echo "=========================================================="
echo "🎉 ALL BUILDS COMPLETED SUCCESSFULLY!"
echo "Customer APK: $OUTPUT_DIR/DistrictCar_Customer_Release.apk"
echo "Driver APK:   $OUTPUT_DIR/DistrictCar_Driver_Release.apk"
echo "=========================================================="
