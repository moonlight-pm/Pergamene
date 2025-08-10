# Pergamene Project Context

## Project Overview
Pergamene is a minimalist iOS app for reading Scripture without distractions. It focuses on creating a beautiful, book-like reading experience reminiscent of traditional printed bibles and medieval manuscripts.

## Current State

### Completed Features
- **Text Processing**: USFM parser that removes all footnotes, cross-references, and formatting markers
- **Minimalist UI**: No tab bars, navigation bars, or UI chrome - just the text
- **Typography**: Cardo font family (designed for biblical scholarship)
- **Drop Caps**: Placeholder implementation with boxed letters (ready for custom artwork)
- **Continuous Text**: Chapters display as single paragraphs without verse numbers
- **Navigation**: Swipe gestures for chapter navigation
- **Text Layout**: Proper text wrapping around drop caps using UITextView exclusion paths

### Architecture
- **Platform**: iOS 15.0+ (iPhone only, portrait orientation)
- **UI Framework**: UIKit (not SwiftUI)
- **Project Management**: Tuist
- **Data Storage**: Binary plist embedded in app bundle
- **Scripture Source**: Brenton Septuagint (Old Testament) from USFM files

### Design Philosophy
- Embrace traditional book reading experience
- Text flows as continuous paragraphs
- Each chapter begins with an ornate drop cap
- Clean, distraction-free interface
- Typography optimized for long-form reading

## Key Files and Directories

### Source Code
- `projects/Pergamene/Sources/` - Main iOS app source
  - `ReadingViewController.swift` - Main reading interface
  - `Models/Scripture.swift` - Data models
  - `AppDelegate.swift` - App entry point

### Scripts
- `scripts/convert_texts.swift` - USFM parser and text processor
- `scripts/build_texts.sh` - Downloads source texts
- `scripts/extract_drop_caps*.swift` - Drop cap image extraction utilities

### Resources
- `projects/Pergamene/Resources/Texts/` - Processed scripture plist
- `projects/Pergamene/Resources/Fonts/` - Cardo font files
- `projects/Pergamene/Resources/DropCaps/` - Drop cap images (placeholder)

### Documentation
- `plans/MASTER.md` - Detailed project specifications
- `README.md` - Project overview

## Current Implementation Details

### Drop Caps
Currently using a simple bordered box with the first letter. The infrastructure is ready to swap in custom ornamental images:
- 70x70 pixel box with brown border
- Cardo Bold font at 56pt
- Text wraps around using UITextView exclusion path

### Text Display
- Single UITextView per chapter
- Justified alignment with 10pt line spacing
- Cardo Regular at 20pt
- Parchment-colored background

### Navigation
- Swipe left: next chapter
- Swipe right: previous chapter
- Automatic book transitions at chapter boundaries

## Next Steps
1. Create or source ornamental drop cap artwork
2. Implement bookmarks functionality
3. Implement highlights functionality  
4. Add BSB New Testament
5. Implement share functionality
6. Add reading position persistence

## Important Notes
- This is NOT a commercial app - personal/educational use only
- Using public domain texts (Brenton Septuagint)
- Fonts are open source from Google Fonts
- Drop cap images need to be created or sourced with appropriate licensing
- Main plan document is in `/plans/MASTER.md`