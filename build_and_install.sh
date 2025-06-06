#!/bin/bash

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔨 Building APK..."
cd android && ./gradlew assembleDebug && cd ..

echo "📱 Installing APK on device..."
/Users/rian/Library/Android/sdk/platform-tools/adb install android/app/build/outputs/apk/debug/app-debug.apk

echo "✅ Done! Your app should be installed and ready to use." 