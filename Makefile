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
	@cd Projects && tuist generate

# Build the app
build: generate
	@echo "🏗️  Building app..."
	@cd Projects && xcodebuild -workspace Pergamene.xcworkspace -scheme Pergamene -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	@cd Projects && tuist clean
	@rm -rf Projects/*.xcodeproj Projects/*.xcworkspace
	@rm -rf Projects/Derived
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Pergamene-*
	@echo "✅ Clean complete"

# Format Swift code
format:
	@echo "✨ Formatting Swift code..."
	@swiftformat Projects/Pergamene/ --config .swiftformat

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
	@cd Projects && xcodebuild test -workspace Pergamene.xcworkspace -scheme PergameneTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Build and run on simulator
run: generate
	@echo "📱 Running on simulator..."
	@cd Projects && xcodebuild -workspace Pergamene.xcworkspace -scheme Pergamene -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath build
	@xcrun simctl boot "iPhone 15" 2>/dev/null || true
	@xcrun simctl install "iPhone 15" Projects/build/Build/Products/Debug-iphonesimulator/Pergamene.app
	@xcrun simctl launch "iPhone 15" pm.moonlight.Pergamene

# Open in Xcode
open: generate
	@echo "📂 Opening in Xcode..."
	@open Projects/Pergamene.xcworkspace

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
	@cd Projects && xcodebuild -workspace Pergamene.xcworkspace -scheme Pergamene -destination 'platform=iOS Simulator,name=iPhone 15' build

# Install app on device (requires device ID)
install-device:
	@echo "📱 Installing on device..."
	@echo "Add your device ID to the Makefile or run:"
	@echo "  xcodebuild -workspace Projects/Pergamene.xcworkspace -scheme Pergamene -destination 'id=YOUR_DEVICE_ID' install"

# Archive for App Store
archive: generate
	@echo "📦 Creating archive..."
	@cd Projects && xcodebuild -workspace Pergamene.xcworkspace -scheme Pergamene -configuration Release archive -archivePath build/Pergamene.xcarchive

# Show project statistics
stats:
	@echo "📊 Project Statistics:"
	@echo ""
	@echo "Swift files: $$(find Projects/Pergamene/Sources -name '*.swift' | wc -l)"
	@echo "Lines of code: $$(find Projects/Pergamene/Sources -name '*.swift' -exec wc -l {} + | tail -1)"
	@echo ""
	@echo "Test files: $$(find Projects/Pergamene/Tests -name '*.swift' | wc -l)"
	@echo ""

# Check for TODO comments
todos:
	@echo "📝 TODOs in code:"
	@grep -r "TODO:" Projects/Pergamene/Sources --include="*.swift" || echo "No TODOs found"

# Verify project is ready to build
verify:
	@echo "🔍 Verifying project..."
	@command -v tuist >/dev/null 2>&1 && echo "✅ Tuist installed" || echo "❌ Tuist not found"
	@command -v swiftformat >/dev/null 2>&1 && echo "✅ SwiftFormat installed" || echo "❌ SwiftFormat not found"
	@[ -f Projects/Pergamene/Resources/Texts/scripture.plist ] && echo "✅ Scripture texts present" || echo "❌ Scripture texts missing - run 'make texts'"
	@[ -d Projects/Pergamene.xcworkspace ] && echo "✅ Xcode project generated" || echo "⚠️  Xcode project not generated - run 'make generate'"