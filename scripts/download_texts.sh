#!/bin/bash

# Script to download scripture source texts
# Brenton Septuagint (USFM) and BSB New Testament (Excel)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOWNLOAD_DIR="$PROJECT_ROOT/downloads"
ARCHIVE_DIR="$PROJECT_ROOT/source_texts"

echo "Setting up directories..."
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$ARCHIVE_DIR"

# Download Brenton Septuagint
echo "Downloading Brenton Septuagint..."
BRENTON_URL="https://ebible.org/Scriptures/eng-Brenton_usfm.zip"
BRENTON_ZIP="$DOWNLOAD_DIR/eng-Brenton_usfm.zip"

if [ ! -f "$BRENTON_ZIP" ]; then
    curl -L -o "$BRENTON_ZIP" "$BRENTON_URL"
    echo "Downloaded Brenton Septuagint"
else
    echo "Brenton Septuagint already downloaded"
fi

# Extract Brenton files
echo "Extracting Brenton Septuagint..."
unzip -o -q "$BRENTON_ZIP" -d "$DOWNLOAD_DIR/brenton"

# Download BSB Excel file
echo "Downloading BSB New Testament..."
BSB_URL="https://bereanbible.com/bsb.xlsx"
BSB_FILE="$DOWNLOAD_DIR/bsb.xlsx"

if [ ! -f "$BSB_FILE" ]; then
    curl -L -o "$BSB_FILE" "$BSB_URL"
    echo "Downloaded BSB"
else
    echo "BSB already downloaded"
fi

# Create compressed archive for repository
echo "Creating compressed archive for repository..."
cd "$DOWNLOAD_DIR"
tar -cf - brenton bsb.xlsx | xz -9 > "$ARCHIVE_DIR/source_texts.tar.xz"
echo "Archive created at $ARCHIVE_DIR/source_texts.tar.xz"

echo "Download complete!"