#!/bin/bash

echo "🚀 Building Release APK for Be Smart"
echo "======================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Analyze code for issues
echo "🔍 Analyzing code..."
flutter analyze --no-fatal-infos

# Build release APK with no tree-shake-icons flag
echo "🔨 Building release APK..."
flutter build apk --release --no-tree-shake-icons --verbose

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Release APK built successfully!"
    echo "📱 APK location: android/app/build/outputs/flutter-apk/app-release.apk"
    
    # Show APK size
    APK_SIZE=$(du -h android/app/build/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "📊 APK Size: $APK_SIZE"
    
    echo ""
    echo "🎉 Build completed successfully!"
    echo "You can install the APK using:"
    echo "adb install android/app/build/outputs/flutter-apk/app-release.apk"
    
    # Copy APK to root directory for easy access
    cp android/app/build/outputs/flutter-apk/app-release.apk ./ecom_app-release.apk
    echo "📋 APK copied to: ./ecom_app-release.apk"
else
    echo "❌ Build failed! Check the error messages above."
    exit 1
fi 