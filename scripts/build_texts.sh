#!/bin/bash

# Master script to download and process scripture texts

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Building Scripture Texts ==="

# Step 1: Download source texts
echo "Step 1: Downloading source texts..."
"$SCRIPT_DIR/download_texts.sh"

# Step 2: Parse BSB Excel to JSON (if Python available)
echo "Step 2: Checking for BSB parsing requirements..."
if command -v python3 &> /dev/null; then
    if python3 -c "import pandas" &> /dev/null 2>&1; then
        echo "Parsing BSB Excel file..."
        python3 "$SCRIPT_DIR/parse_bsb.py" \
            "$PROJECT_ROOT/downloads/bsb.xlsx" \
            "$PROJECT_ROOT/downloads/bsb_nt.json"
    else
        echo "Warning: pandas not installed. Run: pip3 install pandas openpyxl"
        echo "Skipping BSB parsing for now..."
    fi
else
    echo "Warning: Python 3 not found. BSB parsing requires Python with pandas."
fi

# Step 3: Convert to plist format
echo "Step 3: Converting to plist format..."
"$SCRIPT_DIR/convert_texts.swift" "$PROJECT_ROOT"

echo "=== Build complete ==="
echo "Scripture texts are ready in projects/Pergamene/Resources/Texts/"