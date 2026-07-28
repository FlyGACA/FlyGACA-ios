#!/bin/bash
# Process screenshots: add device frames, optimize for App Store
# Requires: ImageMagick (brew install imagemagick)

set -e

SCREENSHOTS_DIR="${PWD}/screenshots"
RAW_DIR="${SCREENSHOTS_DIR}/raw"
FRAMES_DIR="${SCREENSHOTS_DIR}/device-frames"

echo "🎨 FlyGACA Screenshot Processing"
echo "================================="

# Check ImageMagick
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick not found. Install with: brew install imagemagick"
    exit 1
fi

mkdir -p "${FRAMES_DIR}/iPhone"
mkdir -p "${FRAMES_DIR}/iPad"

# Process iPhone screenshots
echo "📱 Processing iPhone screenshots..."
for file in "${RAW_DIR}"/iPhone15Pro/portrait/*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # Frame dimensions: 1179x2556 -> add bezel
        convert "$file" \
            -bordercolor black -border 40 \
            "${FRAMES_DIR}/iPhone/${filename%.*}-framed.png"
        echo "  ✓ $filename"
    fi
done

# Process iPad screenshots
echo "🖥️  Processing iPad screenshots..."
for file in "${RAW_DIR}"/iPadPro/portrait/*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        convert "$file" \
            -bordercolor black -border 50 \
            "${FRAMES_DIR}/iPad/${filename%.*}-framed.png"
        echo "  ✓ $filename"
    fi
done

echo ""
echo "✅ Processing complete!"
echo "📂 Framed screenshots saved to: ${FRAMES_DIR}"
