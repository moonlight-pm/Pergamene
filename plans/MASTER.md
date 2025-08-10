# Pergamene - Master Development Plan

## Project Overview
A focused iOS Bible reading app featuring the Brenton Septuagint (Old Testament) and BSB translation (New Testament) with essential study tools.

## Core Specifications

### Scripture Texts
- **Old Testament**: Brenton Septuagint
  - Source: https://ebible.org/Scriptures/eng-Brenton_usfm.zip (USFM format)
  - 54 books including Apocrypha
  - Embedded offline in app bundle
- **New Testament**: BSB (Berean Standard Bible)
  - Source: https://bereanbible.com/bsb.xlsx (Excel format)
  - 27 books from Matthew to Revelation
  - Embedded offline in app bundle

### Primary Features
1. **Reading Experience**
   - Chapter-by-chapter reading view
   - Minimalist interface without navigation bars or tab bars
   - Continuous paragraph text display (no verse numbers shown)
   - Ornate drop caps at chapter beginnings
   - Swipe gestures for chapter navigation
   - Typography: Cardo font family optimized for biblical texts

2. **Bookmarks**
   - 3-5 physical-style bookmarks (mimicking cloth bookmarks)
   - Quick navigation between marked locations
   - Visual indicators in UI

3. **Highlighting**
   - Simple yellow highlighting
   - Persistent storage of highlights
   - Tap to highlight/unhighlight

4. **Sharing**
   - Tap verse to initiate share
   - Select range within current chapter
   - iOS native share sheet integration
   - Formatted text output with reference

5. **Future: Greek Interlinear Support**
   - Display Greek text alongside English
   - Word-by-word translation view
   - Toggle between views

### Technical Architecture

#### Platform Requirements
- **iOS Minimum Version**: iOS 15.0 (provides good feature set while maintaining broad compatibility)
- **Device Support**: iPhone only
- **Orientation**: Portrait only
- **UI Framework**: UIKit
- **Project Management**: Tuist

#### Data Architecture
- **Text Storage**: Binary plist (embedded in app bundle)
- **Scripture Models**:
  - Book (name, abbreviation, testament, orderIndex)
  - Chapter (number, book relationship, verses)
  - Verse (number, text, chapter relationship)
- **User Data Storage**: UserDefaults for application state
- **User Data Models**:
  - Bookmarks (book, chapter)
  - Highlights (book, chapter, verse)
  - Reading position (last read location)

## Development Status

### Completed Features
- ✅ USFM parser with comprehensive footnote/formatting removal
- ✅ Scripture text processing and plist generation
- ✅ Basic reading view with chapter navigation
- ✅ Minimalist UI without distracting chrome
- ✅ Cardo font integration for biblical typography
- ✅ Drop cap implementation (placeholder for custom artwork)
- ✅ Continuous paragraph text display
- ✅ Swipe gesture navigation
- ✅ Text wrapping around drop caps using UITextView exclusion paths

### In Progress
- 🔄 Drop cap artwork (currently using simple boxed letters)
- 🔄 Bookmarks functionality
- 🔄 Highlights functionality

### To Do
- 📝 BSB New Testament integration
- 📝 Share functionality
- 📝 Reading position persistence
- 📝 App Store submission

## Development Phases

## Future Enhancements (Post-Launch)
- Greek interlinear view
- iCloud sync for bookmarks/highlights
- Additional translations
- Search functionality
- Reading plans
- Cross-references
- Study notes/commentaries

## Technical Decisions

### Why iOS 15.0 Minimum?
- Provides async/await support
- Modern UIKit features and APIs
- Covers ~95% of active iOS devices
- Allows use of newer APIs while maintaining compatibility

### Why Embedded Texts?
- Guaranteed offline access
- No server costs
- Faster performance
- Predictable user experience

### Build Process
- Scripture texts downloaded from source during build
- Converted to binary plist format
- Embedded in app bundle
- Source texts archived with xz compression for repository storage

## Success Metrics
- Clean, bug-free reading experience
- Sub-second chapter loading
- Intuitive bookmark/highlight interactions
- Successful App Store approval
- Positive user feedback on simplicity

### Visual Theme
- **Illuminated Manuscript Style**: Rich colors, decorative elements, premium feel
- **Parchment backgrounds**: Creates authentic reading atmosphere
- **Careful typography**: Respects historical context while maintaining readability
