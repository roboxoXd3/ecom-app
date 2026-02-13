#!/bin/bash

# 16 KB Page Size Testing Script for Android
# This script helps test your Flutter app on 16 KB page size configuration

set -e

echo "🔍 16 KB Page Size Compatibility Test"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Setup Android SDK paths
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin

echo "📦 Step 1: Building APK for testing..."
echo "--------------------------------------"
flutter build apk --debug

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ APK built successfully${NC}"
APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
echo "APK location: $APK_PATH"
echo ""

echo "📱 Step 2: Checking for available devices..."
echo "--------------------------------------"

# Check for connected physical devices
DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l | xargs)

if [ "$DEVICES" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $DEVICES connected device(s)${NC}"
    echo ""
    echo "Available devices:"
    adb devices -l
    echo ""
    
    # Get device info
    echo "📊 Device Information:"
    echo "--------------------------------------"
    
    # Check if device supports 16 KB
    PAGE_SIZE=$(adb shell getconf PAGE_SIZE 2>/dev/null || echo "unknown")
    
    if [ "$PAGE_SIZE" = "16384" ]; then
        echo -e "${GREEN}✅ Device is using 16 KB page size!${NC}"
        echo "This is perfect for testing."
    elif [ "$PAGE_SIZE" = "4096" ]; then
        echo -e "${YELLOW}⚠️  Device is using 4 KB page size${NC}"
        echo "This won't test 16 KB compatibility. You can still test but results won't be conclusive."
    else
        echo -e "${YELLOW}⚠️  Could not determine page size (got: $PAGE_SIZE)${NC}"
    fi
    
    echo ""
    echo "Android Version: $(adb shell getprop ro.build.version.release)"
    echo "SDK Level: API $(adb shell getprop ro.build.version.sdk)"
    echo "Device Model: $(adb shell getprop ro.product.model)"
    echo ""
    
    read -p "Do you want to install and test on this device? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "📲 Step 3: Installing APK..."
        echo "--------------------------------------"
        adb install -r "$APK_PATH"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ App installed successfully${NC}"
            echo ""
            echo "🚀 Step 4: Launching app..."
            echo "--------------------------------------"
            adb shell am start -n com.besmartmall.app/.MainActivity
            
            echo ""
            echo -e "${GREEN}✅ App launched!${NC}"
            echo ""
            echo "📋 TESTING CHECKLIST:"
            echo "===================="
            echo "Please test the following on your device:"
            echo ""
            echo "  1. ☐ App launches without crash"
            echo "  2. ☐ Navigate to home screen"
            echo "  3. ☐ View product listings"
            echo "  4. ☐ Open Google Maps (location features)"
            echo "  5. ☐ Play a video (video_player)"
            echo "  6. ☐ Use image picker (camera/gallery)"
            echo "  7. ☐ Test checkout flow"
            echo "  8. ☐ Check WebView pages"
            echo ""
            echo "🔍 Monitoring for crashes..."
            echo "Press Ctrl+C when done testing"
            echo ""
            
            # Monitor logcat for crashes
            adb logcat | grep -E "FATAL|AndroidRuntime|crash|Native"
        else
            echo -e "${RED}❌ Installation failed${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠️  No physical devices connected${NC}"
    echo ""
    echo "📱 Available Testing Options:"
    echo "=============================="
    echo ""
    echo "Option 1: Connect a Physical Device"
    echo "  - Connect your Android phone via USB"
    echo "  - Enable USB debugging"
    echo "  - Run this script again"
    echo ""
    echo "Option 2: Use Firebase Test Lab (Recommended)"
    echo "  - Free tier includes 15 tests per day"
    echo "  - Tests on real 16 KB devices"
    echo "  - Get detailed reports"
    echo ""
    echo "  Setup:"
    echo "  1. Install gcloud CLI: https://cloud.google.com/sdk/docs/install"
    echo "  2. Run: gcloud auth login"
    echo "  3. Run: gcloud firebase test android run \\"
    echo "       --type robo \\"
    echo "       --app build/app/outputs/flutter-apk/app-debug.apk \\"
    echo "       --device model=oriole,version=35"
    echo ""
    echo "Option 3: Create Android 14+ Emulator with 16 KB"
    echo "  Note: Requires Android SDK with API 35 system image"
    echo ""
fi

echo ""
echo "📄 APK Ready for Testing:"
echo "=========================="
echo "Location: $APK_PATH"
echo ""
echo "You can also:"
echo "  - Upload to Play Console Internal Testing track"
echo "  - Share APK for manual testing on 16 KB devices"
echo ""

