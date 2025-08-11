# Pergamene iOS App Makefile
# Commands for building and managing the project

.PHONY: help setup texts generate build clean format test run install-deps open commit

# Default target - show help
help:
	@echo "Pergamene Project Commands:"
	@echo ""
	@echo "  make setup        - Complete project setup (install deps, download texts, generate project)"
	@echo "  make texts        - Download and process scripture texts"
	@echo "  make generate     - Generate Xcode project with Tuist"
	@echo "  make build        - Build the iOS app"
	@echo "  make clean        - Clean build artifacts and generated files"
	@echo "  make format       - Format Swift code with swiftformat"
	@echo "  make test         - Run unit tests"
	@echo "  make run          - Build and run on simulator"
	@echo "  make install-deps - Install required dependencies"
	@echo "  make open         - Open project in Xcode"
	@echo "  make commit       - Format code and commit changes"
	@echo ""

# Complete setup from scratch
setup: install-deps texts generate
	@echo "✅ Project setup complete!"
	@echo "Run 'make open' to open in Xcode"

# Install required dependencies
install-deps:
	@echo "📦 Checking dependencies..."
	@command -v tuist >/dev/null 2>&1 || (echo "Installing Tuist..." && curl -Ls https://install.tuist.io | bash)
	@command -v swiftformat >/dev/null 2>&1 || (echo "Installing SwiftFormat..." && brew install swiftformat)
	@command -v python3 >/dev/null 2>&1 || echo "⚠️  Python 3 not found - needed for BSB parsing"
	@python3 -c "import pandas" 2>/dev/null || echo "⚠️  Run 'pip3 install pandas openpyxl' for BSB support"
	@echo "✅ Dependencies checked"

# Download and process scripture texts
texts:
	@echo "📖 Building scripture texts..."
	@chmod +x scripts/*.sh scripts/*.swift
	@./scripts/build_texts.sh

# Generate Xcode project with Tuist
generate:
	@echo "🔨 Generating Xcode project..."
	@cd projects && tuist generate

# Build the app
build: generate
	@echo "🏗️  Building app..."
	@cd projects && xcodebuild -workspace Pergamene.xcworkspace -scheme Pergamene -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15' build

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	@cd projects && tuist clean
	@rm -rf projects/*.xcodeproj projects/*.xcworkspace
	@rm -rf projects/Derived
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Pergamene-*
	@echo "✅ Clean complete"

# Format Swift code
format:
	@echo "✨ Formatting Swift code..."
	@swiftformat projects/Pergamene/ --config .swiftformat

# Create .swiftformat config if it doesn't exist
.swiftformat:
	@echo "# SwiftFormat configuration" > .swiftformat
	@echo "# Pergamene iOS App" >> .swiftformat
	@echo "" >> .swiftformat
	@echo "--indent 4" >> .swiftformat
	@echo "--indentcase false" >> .swiftformat
	@echo "--trimwhitespace always" >> .swiftformat
	@echo "--voidtype tuple" >> .swiftformat
	@echo "--nospaceoperators ..<,...<" >> .swiftformat
	@echo "--header strip" >> .swiftformat
	@echo "--commas inline" >> .swiftformat
	@echo "--semicolons never" >> .swiftformat
	@echo "--disable redundantSelf,trailingCommas" >> .swiftformat

# Run tests
test: generate
	@echo "🧪 Running tests..."
	@cd projects && xcodebuild test -workspace Pergamene.xcworkspace -scheme PergameneTests -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15'

# Build and run on simulator
run: generate
	@echo "📱 Running on simulator..."
	@cd projects && xcodebuild -workspace Pergamene.xcworkspace -scheme Pergamene -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16 Pro Max' -derivedDataPath build
	@xcrun simctl boot "iPhone 16 Pro Max" 2>/dev/null || true
	@xcrun simctl install "iPhone 16 Pro Max" projects/build/Build/Products/Debug-iphonesimulator/Pergamene.app
	@xcrun simctl launch "iPhone 16 Pro Max" pm.moonlight.Pergamene

# Open in Xcode
open: generate
	@echo "📂 Opening in Xcode..."
	@open projects/Pergamene.xcworkspace

# Format and commit changes
commit: format
	@echo "💾 Committing changes..."
	@git add -A
	@git status

# Download texts only
download-texts:
	@echo "⬇️  Downloading scripture texts..."
	@./scripts/download_texts.sh

# Convert texts only (assumes already downloaded)
convert-texts:
	@echo "🔄 Converting texts to plist..."
	@./scripts/convert_texts.swift $$(pwd)

# Quick build without regenerating project
quick-build:
	@echo "⚡ Quick build..."
	@cd projects && xcodebuild -workspace Pergamene.xcworkspace -scheme Pergamene -destination 'platform=iOS Simulator,OS=17.5,name=iPhone 15' build

# Install app on device (requires device ID)
install-device:
	@echo "📱 Installing on device..."
	@echo "Add your device ID to the Makefile or run:"
	@echo "  xcodebuild -workspace projects/Pergamene.xcworkspace -scheme Pergamene -destination 'id=YOUR_DEVICE_ID' install"

# Archive for App Store
archive: generate
	@echo "📦 Creating archive..."
	@cd projects && xcodebuild -workspace Pergamene.xcworkspace -scheme Pergamene -configuration Release archive -archivePath build/Pergamene.xcarchive

# Show project statistics
stats:
	@echo "📊 Project Statistics:"
	@echo ""
	@echo "Swift files: $$(find projects/Pergamene/Sources -name '*.swift' | wc -l)"
	@echo "Lines of code: $$(find projects/Pergamene/Sources -name '*.swift' -exec wc -l {} + | tail -1)"
	@echo ""
	@echo "Test files: $$(find projects/Pergamene/Tests -name '*.swift' | wc -l)"
	@echo ""

# Check for TODO comments
todos:
	@echo "📝 TODOs in code:"
	@grep -r "TODO:" projects/Pergamene/Sources --include="*.swift" || echo "No TODOs found"

# Verify project is ready to build
verify:
	@echo "🔍 Verifying project..."
	@command -v tuist >/dev/null 2>&1 && echo "✅ Tuist installed" || echo "❌ Tuist not found"
	@command -v swiftformat >/dev/null 2>&1 && echo "✅ SwiftFormat installed" || echo "❌ SwiftFormat not found"
	@[ -f projects/Pergamene/Resources/Texts/scripture.plist ] && echo "✅ Scripture texts present" || echo "❌ Scripture texts missing - run 'make texts'"
	@[ -d projects/Pergamene.xcworkspace ] && echo "✅ Xcode project generated" || echo "⚠️  Xcode project not generated - run 'make generate'"
