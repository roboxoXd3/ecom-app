#!/bin/bash

# Dead Button Testing Script
# This script helps you test for dead buttons in your Flutter app

echo "🎯 Dead Button Testing Suite"
echo "=============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show menu
show_menu() {
    echo "Choose testing method:"
    echo ""
    echo "1) 🚀 Static Analysis (Fast - Scans all code)"
    echo "   - Scans entire codebase in seconds"
    echo "   - No manual work required"
    echo "   - Best for first-time scan"
    echo ""
    echo "2) 🧪 Widget Tests (Accurate - Tests specific screens)"
    echo "   - Runs actual widget tests"
    echo "   - Tests one screen at a time"
    echo "   - More accurate but requires test files"
    echo ""
    echo "3) 📚 Help - Show me how this works"
    echo ""
    echo "4) ❌ Exit"
    echo ""
}

# Function to run static analysis
run_static_analysis() {
    echo ""
    echo -e "${BLUE}🔍 Running Static Analysis...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    dart dead_button_analyzer.dart
    
    echo ""
    echo -e "${GREEN}✅ Static analysis complete!${NC}"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Review the findings above"
    echo "   2. Open each file and fix genuine issues"
    echo "   3. Add comments for intentionally disabled buttons"
    echo ""
}

# Function to run widget tests
run_widget_tests() {
    echo ""
    echo -e "${BLUE}🧪 Running Widget Tests...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check if test files exist
    if [ ! -f "test/dead_button_test.dart" ]; then
        echo -e "${YELLOW}⚠️  Widget test helper not found!${NC}"
        echo "Please make sure test/dead_button_test.dart exists."
        return
    fi
    
    echo "Running example dead button tests..."
    flutter test test/dead_button_test.dart -r expanded
    
    echo ""
    echo -e "${GREEN}✅ Widget tests complete!${NC}"
    echo ""
    echo "💡 To test specific screens:"
    echo "   1. Create a test file: test/screens/YOUR_SCREEN_test.dart"
    echo "   2. Use DeadButtonTester.findDeadButtons(tester)"
    echo "   3. Run: flutter test test/screens/YOUR_SCREEN_test.dart"
    echo ""
}

# Function to show help
show_help() {
    echo ""
    echo "📚 HOW IT WORKS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "We created 2 tools to find 'dead buttons' (buttons with no action):"
    echo ""
    echo "1️⃣  STATIC ANALYZER (Option 1)"
    echo "   • Reads your .dart files like text"
    echo "   • Searches for button code patterns"
    echo "   • Checks if they have handlers"
    echo "   • ✅ NO MANUAL WORK - Scans everything automatically"
    echo "   • ⚡ FAST - Takes only seconds"
    echo ""
    echo "2️⃣  WIDGET TESTS (Option 2)"
    echo "   • Actually builds your screens in memory"
    echo "   • Finds buttons at runtime"
    echo "   • More accurate for complex cases"
    echo "   • 📝 YOU WRITE TESTS for screens you care about"
    echo "   • 🎯 TARGETED - Checks specific screens"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "RECOMMENDED WORKFLOW:"
    echo ""
    echo "Step 1: Run Static Analyzer first (Option 1)"
    echo "        This gives you a quick overview of ALL buttons"
    echo ""
    echo "Step 2: Review the findings and fix obvious issues"
    echo ""
    echo "Step 3: Create widget tests for important screens (Option 2)"
    echo "        Example: Login, Checkout, Payment screens"
    echo ""
    echo "Step 4: Run tests regularly as part of development"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "For detailed documentation, see: DEAD_BUTTON_TESTING_GUIDE.md"
    echo ""
    read -p "Press Enter to continue..."
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            run_static_analysis
            read -p "Press Enter to continue..."
            ;;
        2)
            run_widget_tests
            read -p "Press Enter to continue..."
            ;;
        3)
            show_help
            ;;
        4)
            echo ""
            echo "👋 Goodbye! Happy coding!"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo "❌ Invalid choice. Please enter 1-4."
            echo ""
            read -p "Press Enter to continue..."
            ;;
    esac
    
    clear
done

