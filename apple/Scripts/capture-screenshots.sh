#!/bin/bash
# FlyGACA iOS App Screenshot Capture Script
# Captures marketing screenshots from Xcode simulators
# Run on macOS with Xcode 16+

set -e

# Configuration
SCREENSHOTS_DIR="${PWD}/screenshots"
RAW_DIR="${SCREENSHOTS_DIR}/raw"
DEVICES=("iPhone15Pro" "iPadPro")
ORIENTATIONS=("portrait" "landscape")
SCHEME="PPL"  # Change to capture different app variants (PPL, ELPT, AIP, CPL, IR, ATPL)

# Bundle id per scheme — keep in sync with apple/Apps/<App>/<App>.xcconfig.
declare -A BUNDLE_IDS=(
  [PPL]="com.flygaca.ppl"
  [ELPT]="com.flygaca.elpt"
  [AIP]="com.flygaca.aip"
  [CPL]="com.flygaca.cpl"
  [IR]="com.flygaca.ir"
  [ATPL]="com.flygaca.atpl"
)
BUNDLE_ID="${BUNDLE_IDS[$SCHEME]:?Unknown SCHEME '$SCHEME' — add it to BUNDLE_IDS}"

echo "🎬 FlyGACA Screenshot Capture Tool"
echo "=================================="

# Step 1: Generate Xcode project
echo "📦 Step 1: Generating Xcode project..."
if ! command -v xcodegen &> /dev/null; then
    echo "❌ XcodeGen not found. Install with: brew install xcodegen"
    exit 1
fi
cd "$(dirname "$0")/.."
xcodegen generate

# Step 2: Create screenshots directory
echo "📁 Step 2: Creating output directories..."
mkdir -p "${RAW_DIR}/iPhone15Pro/portrait"
mkdir -p "${RAW_DIR}/iPhone15Pro/landscape"
mkdir -p "${RAW_DIR}/iPadPro/portrait"
mkdir -p "${RAW_DIR}/iPadPro/landscape"

# Step 3: Build the app for simulators
echo "🔨 Step 3: Building for simulators..."
xcodebuild build-for-testing \
  -scheme "${SCHEME}" \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath build/ \
  -quiet

# Step 4: Launch iPhone simulator and capture screenshots
echo "📸 Step 4: Capturing iPhone 15 Pro screenshots..."

# Boot iPhone simulator
open -a Simulator
xcrun simctl boot "iPhone 15 Pro" 2>/dev/null || true
sleep 2

# Install and run app
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/"${SCHEME}.app"
xcrun simctl launch booted ${BUNDLE_ID} &

# Wait for app to launch
sleep 3

# Capture home screen
xcrun simctl io booted screenshot "${RAW_DIR}/iPhone15Pro/portrait/01-home.png"

# Simulate taps to navigate to quiz
# Note: These coordinates are approximate and may need adjustment
xcrun simctl io booted tap 195 400  # Tap quiz section
sleep 2
xcrun simctl io booted screenshot "${RAW_DIR}/iPhone15Pro/portrait/02-quiz-list.png"

# Tap first quiz bank
xcrun simctl io booted tap 195 250
sleep 2
xcrun simctl io booted screenshot "${RAW_DIR}/iPhone15Pro/portrait/03-quiz-question.png"

# Return to home and capture other screens
xcrun simctl terminate booted ${BUNDLE_ID}
sleep 1

# Step 5: Landscape orientation
echo "📸 Capturing landscape screenshots..."
xcrun simctl launch booted ${BUNDLE_ID} &
sleep 3
xcrun simctl io booted rotate left
sleep 1
xcrun simctl io booted screenshot "${RAW_DIR}/iPhone15Pro/landscape/01-quiz-landscape.png"

# Step 6: iPad screenshots
echo "📸 Capturing iPad Pro screenshots..."
xcrun simctl terminate booted ${BUNDLE_ID}
sleep 1
xcrun simctl shutdown booted

xcrun simctl boot "iPad Pro 12.9-inch (7th generation)" 2>/dev/null || true
sleep 2

xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/"${SCHEME}.app"
xcrun simctl launch booted ${BUNDLE_ID} &
sleep 3

xcrun simctl io booted screenshot "${RAW_DIR}/iPadPro/portrait/01-home.png"
xcrun simctl io booted rotate left
sleep 1
xcrun simctl io booted screenshot "${RAW_DIR}/iPadPro/landscape/01-home-landscape.png"

# Cleanup
xcrun simctl terminate booted ${BUNDLE_ID}
xcrun simctl shutdown booted

echo ""
echo "✅ Screenshot capture complete!"
echo "📂 Screenshots saved to: ${RAW_DIR}"
echo ""
echo "Next steps:"
echo "1. Review screenshots in ${RAW_DIR}"
echo "2. Add device frames using: scripts/process-screenshots.sh"
echo "3. Run: npm run screenshots:index"
