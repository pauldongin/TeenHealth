#!/bin/bash

# TeenHealth — Quick Setup Script
# Run this from the TeenHealth directory to generate the Xcode project

echo "🌱 TeenHealth — Project Setup"
echo "================================"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "Installing xcodegen..."
    brew install xcodegen
fi

# Generate Xcode project
echo "Generating TeenHealth.xcodeproj..."
xcodegen generate

# Open in Xcode
echo "Opening in Xcode..."
open TeenHealth.xcodeproj

echo ""
echo "✅ Done! In Xcode:"
echo "  1. Select your development team in Signing & Capabilities"
echo "  2. Add HealthKit capability in Signing & Capabilities"
echo "  3. Build & run on a device (HealthKit requires real device)"
echo ""
echo "📱 App features:"
echo "  • Food logging with photo, quick-pick, and search"
echo "  • HealthKit step/activity/weight sync"
echo "  • Personalized goals with progress rings"
echo "  • Coach messaging thread"
echo "  • Gamification: points, levels, badges"
echo "  • Educational articles (6 topics)"
echo "  • COPPA-compliant consent flow"
echo "  • Privacy: on-device storage, no ads, no data selling"
