#!/bin/bash
# ISOTOPE Flutter App — Complete Build Script
# Run this on any machine with Flutter installed

set -e

echo "========================================"
echo "ISOTOPE App — Build Script"
echo "========================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is NOT installed!"
    echo ""
    echo "Install Flutter first:"
    echo "  1. Visit: https://docs.flutter.dev/get-started/install"
    echo "  2. Download Flutter SDK"
    echo "  3. Extract to: ~/flutter"
    echo "  4. Add to PATH: export PATH=\"\$PATH:\$HOME/flutter/bin\""
    echo ""
    exit 1
fi

echo "✅ Flutter found: $(flutter --version)"
echo ""

# Navigate to app directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "📁 Building from: $PWD"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Check for Firebase configuration
if [ ! -f "android/app/google-services.json" ]; then
    echo "⚠️  WARNING: google-services.json not found!"
    echo "   Firebase features will not work."
    echo ""
    echo "   To add Firebase:"
    echo "   1. Go to: https://console.firebase.google.com"
    echo "   2. Create project: ISOTOPE"
    echo "   3. Add Android app (package: com.elev8digital.isotope)"
    echo "   4. Download google-services.json"
    echo "   5. Place in: android/app/google-services.json"
    echo ""
    read -p "Continue without Firebase? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build APK (for testing)
echo "📱 Building APK (release)..."
flutter build apk --release

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo ""
    echo "========================================"
    echo "✅ APK BUILD SUCCESSFUL!"
    echo "========================================"
    echo ""
    echo "📦 APK Location:"
    echo "   $PWD/build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📊 APK Size:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
    echo ""
    echo "📲 Install on Device:"
    echo "   adb install build/app/outputs/flutter-apk/app-release.apk"
    echo ""
else
    echo ""
    echo "❌ Build failed! Check errors above."
    exit 1
fi

# Build App Bundle (for Play Store)
echo ""
read -p "Also build Play Store bundle (.aab)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📦 Building App Bundle..."
    flutter build appbundle --release
    
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        echo ""
        echo "✅ App Bundle built!"
        echo "   Location: $PWD/build/app/outputs/bundle/release/app-release.aab"
    fi
fi

echo ""
echo "========================================"
echo "BUILD COMPLETE!"
echo "========================================"
echo ""
echo "Next Steps:"
echo "  1. Test APK on your phone"
echo "  2. Share with Elon for approval"
echo "  3. Upload to Play Store (use .aab file)"
echo ""
