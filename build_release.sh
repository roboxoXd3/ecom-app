#!/bin/bash

echo "🏗️  Building Be Smart App for Google Play Store..."
echo ""

# Clean
echo "1️⃣  Cleaning previous builds..."
flutter clean

# Get dependencies
echo "2️⃣  Getting dependencies..."
flutter pub get

# Build AAB
echo "3️⃣  Building Android App Bundle..."
flutter build appbundle --release

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📦 Your .AAB file is located at:"
    echo "   build/app/outputs/bundle/release/app-release.aab"
    echo ""
    echo "📊 File info:"
    ls -lh build/app/outputs/bundle/release/app-release.aab
    echo ""
    echo "🚀 Ready to upload to Google Play Console!"
else
    echo ""
    echo "❌ Build failed. Please check the errors above."
fi


