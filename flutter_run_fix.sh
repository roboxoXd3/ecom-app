#!/bin/bash

# Flutter APK Location Fix Script
# This script fixes the common Flutter build issue where APK files are generated 
# but Flutter can't find them in the expected location.

echo "🔧 Setting up APK symbolic links..."

# Create the directory structure Flutter expects
mkdir -p build/app/outputs/flutter-apk

# Create symbolic links for both debug and release APKs
ln -sf ../../../../android/app/build/outputs/flutter-apk/app-debug.apk build/app/outputs/flutter-apk/app-debug.apk
ln -sf ../../../../android/app/build/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/app-release.apk

echo "✅ APK symbolic links created successfully!"

# Run flutter with the provided arguments
echo "🚀 Running Flutter with arguments: $@"
flutter run "$@" 