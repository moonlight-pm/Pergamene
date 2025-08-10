# Scripture Text Processing Scripts

These scripts download and process the scripture source texts for the Pergamene app.

## Prerequisites

- bash
- curl
- unzip
- xz
- Swift (for conversion script)
- Python 3 with pandas (optional, for BSB parsing)

To install Python dependencies (if needed):
```bash
pip3 install pandas openpyxl
```

## Usage

Run the master build script:
```bash
./build_texts.sh
```

This will:
1. Download the Brenton Septuagint (USFM format) from eBible.org
2. Download the BSB New Testament (Excel format) from bereanbible.com
3. Parse and convert the texts to binary plist format
4. Place the processed texts in `Projects/Pergamene/Resources/Texts/`
5. Create a compressed archive of source texts for repository storage

## Individual Scripts

- `download_texts.sh` - Downloads source texts
- `parse_bsb.py` - Parses BSB Excel file to JSON (requires Python + pandas)
- `convert_texts.swift` - Converts texts to binary plist format
- `build_texts.sh` - Master script that runs everything

## Output

- `Projects/Pergamene/Resources/Texts/scripture.plist` - Binary plist for app
- `source_texts/source_texts.tar.xz` - Compressed archive of original texts