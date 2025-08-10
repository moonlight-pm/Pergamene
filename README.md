# Pergamene

A beautiful iOS Bible reading app with a focus on distraction-free reading and elegant typography.

## Recent Updates

### Settings Panel Overlay System
- Settings panel is now a separate overlay that slides down over the reading content
- Pull down from the top of any chapter to reveal settings (requires ~90 point pull)
- Push up on the settings panel to dismiss (reverse gesture, no tap-to-dismiss)
- Elastic resistance provides natural, tactile feedback
- Semi-transparent dimming overlay shows visual hierarchy

### Reading Experience Improvements
- **Scroll Position Memory**: Each chapter remembers its exact scroll position
- **Floating Chapter Indicator**: Subtle bar appears when main header scrolls out of view
- **Improved Gesture Recognition**: Better discrimination between vertical pulls and horizontal swipes
- **Clean Architecture**: Settings no longer interfere with content scrolling

### Technical Improvements
- Refactored settings from unified scroll view to overlay architecture
- Simplified scroll view logic (no more offset calculations)
- Enhanced elastic pull mechanics with natural resistance curves
- Better separation of concerns between reader and settings UI

## Features

- **Elegant Typography**: Custom fonts (Cardo for body text, Unifraktur Maguntia for drop caps)
- **Parchment-style Design**: Warm, paper-like background texture
- **Drop Caps**: Beautiful illuminated first letters for each chapter
- **Verse Numbers**: Toggle on/off in settings, displayed in margins
- **Smart Navigation**: Swipe left/right to change chapters
- **Settings Panel**: Pull down to access, push up to dismiss
- **Reading Position**: Automatically saves your place in each chapter

## Architecture

- Pure UIKit implementation (no SwiftUI)
- Tuist for project generation
- Clean separation between UI layers (reader, settings, overlays)
- Efficient text caching for smooth performance

## Building

1. Install Tuist if needed: `curl -Ls https://install.tuist.io | bash`
2. Generate Xcode project: `tuist generate`
3. Open `Pergamene.xcworkspace`
4. Build and run

## Next Steps

- Horizontal chapter navigation with pre-rendered adjacent chapters
- Enhanced bookmarking and highlighting features
- Additional typography options

