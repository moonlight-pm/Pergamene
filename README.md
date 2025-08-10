# Pergamene

A clean, focused iOS app for reading Scripture without distractions.

## Features

- **Clean Reading Experience**: No ads, no distractions - just the text
- **Multiple Translations**: Currently includes the Brenton Septuagint (Old Testament)
- **Bookmarks**: Save your favorite passages for quick access
- **Highlights**: Mark important verses for study
- **Native iOS Design**: Built with SwiftUI for a modern, responsive interface

## Technical Details

### Scripture Text Processing

The app uses a custom USFM (Unified Standard Format Markers) parser to convert scripture texts into a clean, readable format. The parser:

- Removes all footnotes and cross-references 
- Strips formatting markers (like `\f`, `\x`, `\sc`, etc.)
- Cleans up character styles while preserving the text
- Outputs clean text in a structured plist format for efficient loading

### Building

1. Ensure you have Xcode 15+ installed
2. Run `make setup` to download and process scripture texts
3. Open the project in Xcode and build

### Project Structure

```
Pergamene/
├── Makefile                 # Build automation
├── scripts/                 # Text processing scripts
│   ├── build_texts.sh      # Downloads source texts
│   └── convert_texts.swift # USFM parser and converter
├── projects/               
│   └── Pergamene/          # iOS app source
│       ├── Sources/        # Swift source files
│       └── Resources/      # App resources including processed texts
└── downloads/              # Downloaded source texts (git-ignored)
```

## License

The scripture texts are in the public domain. The app code is proprietary.