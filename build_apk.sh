#!/bin/bash
# ISOTOPE Flutter APK Build Script
# Run this on your VPS to build the release APK

set -e

echo "========================================"
echo "  ISOTOPE - APK Build Script"
echo "  ELEV8 DIGITAL | $(date)"
echo "========================================"

# Set up environment
export PATH="$PATH:/root/flutter/bin:/root/android-sdk/cmdline-tools/latest/bin:/root/android-sdk/platform-tools"
export ANDROID_HOME=/root/android-sdk
export ANDROID_SDK_ROOT=/root/android-sdk
export JAVA_HOME=/usr

# Navigate to mobile app
cd /root/isotope/apps/mobile

echo ""
echo "[1/5] Cleaning previous build..."
flutter clean

echo ""
echo "[2/5] Getting dependencies..."
flutter pub get

echo ""
echo "[3/5] Checking Flutter setup..."
flutter doctor -v | grep -E "(Flutter|Android toolchain|Linux toolchain)"

echo ""
echo "[4/5] Building release APK..."
flutter build apk --release

echo ""
echo "[5/5] Build complete!"
echo ""
echo "========================================"
echo "  APK Location:"
echo "  build/app/outputs/flutter-apk/app-release.apk"
echo "========================================"
echo ""
echo "To install on device:"
echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "To copy to your machine:"
echo "  scp root@185.167.97.193:/root/isotope/apps/mobile/build/app/outputs/flutter-apk/app-release.apk ~/Downloads/"
echo ""
