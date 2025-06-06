#!/bin/bash

echo "🔧 Starting Flutter run with APK path fix..."

# Create the expected output directory structure
mkdir -p build/app/outputs/flutter-apk

# Function to copy APK when it's generated
copy_apk() {
    if [ -f "android/app/build/outputs/flutter-apk/app-debug.apk" ]; then
        cp "android/app/build/outputs/flutter-apk/app-debug.apk" "build/app/outputs/flutter-apk/app-debug.apk"
        echo "✅ APK copied to expected location"
    fi
}

# Run flutter run in background
flutter run &
FLUTTER_PID=$!

# Monitor for APK generation and copy it
while kill -0 $FLUTTER_PID 2>/dev/null; do
    copy_apk
    sleep 2
done

wait $FLUTTER_PID 