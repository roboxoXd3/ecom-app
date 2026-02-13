#!/bin/bash

# 🚀 Build AAB with Null Safety & UX Fixes
# This script builds the Android App Bundle with all recent fixes applied

set -e  # Exit on error

echo "🔧 Building AAB with Fixes Applied"
echo "=================================="
echo ""
echo "📋 Changes included in this build:"
echo "  ✅ Fixed null check errors in cart_controller.dart"
echo "  ✅ Fixed null check errors in order_repository.dart"
echo "  ✅ Fixed null check errors in wishlist_repository.dart"
echo "  ✅ Fixed null check errors in product_model.dart"
echo "  ✅ Fixed null check errors in qa_model.dart"
echo "  ✅ Fixed unauthenticated user UX (no error snackbars)"
echo "  ✅ Fixed address_controller.dart authentication handling"
echo "  ✅ Fixed payment_method_controller.dart authentication handling"
echo "  ✅ Fixed order_controller.dart authentication handling"
echo ""
echo "🧹 Step 1: Cleaning previous builds..."
flutter clean

echo ""
echo "📦 Step 2: Getting dependencies..."
flutter pub get

echo ""
echo "🔨 Step 3: Building AAB (Release + Obfuscated)..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo ""
echo "✅ Build Complete!"
echo ""
echo "📍 Your new AAB file is located at:"
echo "   build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "📊 File size:"
du -h build/app/outputs/bundle/release/app-release.aab

echo ""
echo "🎯 Next Steps:"
echo "  1. Test the app locally: flutter install --release"
echo "  2. Upload to Google Play Console: https://play.google.com/console"
echo "  3. Create new release with this AAB file"
echo ""
echo "📝 Version Info:"
echo "   Build Date: $(date)"
echo "   Changes: Null Safety & UX Fixes Applied"
echo ""
echo "🚀 Ready for Play Store upload!"

