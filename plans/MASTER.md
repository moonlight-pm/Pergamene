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
- ✅ Scripture text processing and plist generation (OT: Brenton Septuagint, NT: BSB)
- ✅ UIPageViewController-based horizontal chapter navigation
- ✅ Vertical scrolling within chapters
- ✅ Minimalist UI without tab bars or navigation bars
- ✅ Cardo font integration for biblical typography
- ✅ UnifrakturMaguntia Gothic font for drop caps
- ✅ Drop cap implementation with boxed ornate letters
- ✅ Continuous paragraph text display with verse markers
- ✅ Verse numbers in left margin (toggleable via settings)
- ✅ Text wrapping around drop caps using UITextView exclusion paths
- ✅ Top gradient overlay in safe area (transparent to 70% dark)
- ✅ Pull-down settings panel with elastic animation
- ✅ Book selection via tapping book title
- ✅ Floating chapter indicator while scrolling
- ✅ Reading position persistence per chapter
- ✅ Settings persistence (verse numbers toggle)

### In Progress
- 🔄 Enhanced Settings Panel
  - App name "Pergamene" in Gothic drop cap font
  - Display Bible texts used (OT: Brenton Septuagint, NT: Berean Standard Bible)
  - Instructions button opening modal with usage guide
- 🔄 Improved Floating Chapter Indicator
  - Extend to top of safe area
  - Add 30% transparency for better text visibility underneath
- 🔄 Smart Scroll Position Management
  - Track last viewed timestamp per chapter
  - Reset position to top if last viewed > 24 hours ago
  - Preserve current chapter scroll position
- 🔄 Verse Sharing Feature
  - Long press on verse with soft haptic feedback
  - Selection mode with inverted text highlighting (light brown)
  - Multi-verse selection via tapping
  - Share via iOS native share sheet
  - Format: "verse text" - Book Chapter:Verses

### To Do
- 📝 Haptic feedback for page turns
- 📝 Bookmarks functionality (3-5 ribbon metaphor - TBD)
- 📝 Highlights functionality
- 📝 Chapter navigation within book (chapter selector)
- 📝 App Store submission

### Known Issues
- 📝 Verse selection sheet has 1-1.5 second delay on first presentation (iOS sheet presentation limitation)

## Implementation Details

### Settings Panel Enhancements
- **App Title**: Display "Pergamene" using UnifrakturMaguntia font (same as drop caps)
- **Bible Texts Info**: 
  - "Old Testament: Brenton Septuagint"
  - "New Testament: Berean Standard Bible"
- **Instructions Modal**:
  - "Swipe left/right to navigate chapters"
  - "Tap the book name to select a different book"
  - "Pull down from top to access settings"
  - "Long press on text to share verses"
  - "Toggle verse numbers in settings"

### Floating Chapter Indicator Improvements
- Extend background to cover full safe area (status bar)
- Apply 30% transparency (70% opaque) to allow text visibility underneath
- Maintain fade in/out animation on scroll
- Keep current positioning logic based on scroll offset

### Smart Scroll Position Management
- Store timestamp with each chapter's scroll position in UserDefaults
- On chapter load:
  - Check if last viewed > 24 hours ago
  - If yes, reset to top (position 0)
  - If no, restore saved position
- Current chapter always maintains position during session

### Verse Sharing Implementation
- **Long Press Detection**: 
  - Add UILongPressGestureRecognizer to verse text views
  - Trigger on verse boundaries (detect which verse was pressed)
  - Soft haptic feedback (UIImpactFeedbackGenerator with light style)
- **Selection Mode UI**:
  - Overlay mode with dimmed background
  - Inverted text selection (light brown background, dark text)
  - Tap verses to toggle selection
  - "Cancel" and "Share" buttons
  - Verse numbers also inverted when selected
- **Share Format**:
  - Multi-line text with proper verse breaks
  - Citation format: "- BookName Chapter:StartVerse-EndVerse"
  - Example: "In the beginning God created... - Genesis 1:1-2"

### Haptic Feedback
- Page turns: UISelectionFeedbackGenerator (subtle tick)
- Long press: UIImpactFeedbackGenerator.light
- Selection toggles: UISelectionFeedbackGenerator

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
