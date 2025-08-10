# Pergamene

A clean, focused iOS app for reading Scripture without distractions.

## Features

- **Minimalist Interface**: No tab bars, navigation bars, or UI clutter
- **Elegant Typography**: Uses the Cardo font family, specifically designed for biblical texts
- **Drop Caps**: Beautiful ornate drop caps at the beginning of each chapter (placeholder for custom artwork)
- **Continuous Text**: Scripture displayed as flowing paragraphs without verse numbers for immersive reading
- **Gesture Navigation**: Swipe left/right to navigate between chapters
- **Currently Available**: Brenton Septuagint (Old Testament)

## Design Philosophy

Pergamene embraces the traditional book reading experience:
- Text flows as continuous paragraphs, not broken by verse numbers
- Each chapter begins with an ornate drop cap, reminiscent of medieval manuscripts
- Clean, distraction-free interface focused entirely on the text
- Typography optimized for long-form reading

## Technical Details

### Scripture Text Processing

The app uses a custom USFM (Unified Standard Format Markers) parser to convert scripture texts into a clean, readable format. The parser:

- Removes all footnotes and cross-references 
- Strips formatting markers (like `\f`, `\x`, `\sc`, etc.)
- Cleans up character styles while preserving the text
- Outputs clean text in a structured plist format for efficient loading

### Typography

- **Primary Font**: Cardo - A classical serif font designed for biblical scholarship
- **Drop Caps**: Currently uses a simple boxed letter placeholder, ready for custom ornamental artwork
- **Text Layout**: Uses UITextView with exclusion paths for proper text wrapping around drop caps

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