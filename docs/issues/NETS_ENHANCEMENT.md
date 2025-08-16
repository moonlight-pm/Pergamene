# Enhancement: Add NETS Translation Download and Processing

## Overview
Implement in-app downloading and processing of the New English Translation of the Septuagint (NETS) from PDF sources at https://ccat.sas.upenn.edu/nets/edition/. Due to distribution limitations, the PDFs must be downloaded and processed within the iOS app itself rather than being pre-bundled.

## Requirements

### Core Functionality
- Download NETS PDF files from the official source
- Parse PDFs to extract biblical text only (no footnotes, critical apparatus, or formatting)
- Convert extracted text to the app's scripture.plist format
- Store processed text for offline use
- Integrate NETS as a selectable Old Testament translation option

### Implementation Details

#### 1. Download Management
- **Batch Processing**: Download all NETS books as a single operation
- **Background Downloading**: Use URLSession background configuration for reliability
- **Progress Tracking**: Show download and processing progress to user
- **Error Handling**: Retry failed downloads, handle network interruptions gracefully

#### 2. PDF Processing
- Use PDFKit for text extraction (avoid OCR)
- Handle two-column layouts common in academic PDFs
- Extract verse numbers and chapter divisions accurately
- Ignore:
  - Headers and footers
  - Page numbers
  - Footnotes and critical apparatus
  - Special formatting and annotations

#### 3. User Interface Changes

##### Settings Screen
- Enhance version display to show:
  - Current OT: "Brenton Septuagint" or "NETS"
  - Current NT: "Berean Standard Bible"
- Add selection interface for choosing OT translation
- If NETS not downloaded, show "Download NETS" option
- Display download/processing progress (percentage, current book being processed)

##### Book Selection
- Seamlessly switch between translations when user changes selection
- No visual difference once NETS is downloaded and selected

#### 4. Data Storage
- Store as `nets_scripture.plist` in Documents directory
- Use same format as existing scripture.plist:
```swift
struct ScriptureData {
    let books: [Book]
}
struct Book {
    let name: String
    let abbreviation: String
    let testament: String
    let orderIndex: Int
    let chapters: [Chapter]
}
```

#### 5. Attribution
- Include attribution text in Settings: "NETS translation © 2007 by the International Organization for Septuagint and Cognate Studies"
- Respect academic use license terms

## Technical Approach

### Phase 1: Proof of Concept
Start with 3-4 books to validate the approach:
1. Genesis (longest book, good complexity test)
2. Psalms (poetry formatting challenges)
3. Isaiah (prophetic literature)
4. A minor prophet (shorter book for quick testing)

### Phase 2: Full Implementation
Once POC is validated:
1. Implement batch download for all books
2. Add robust error handling and retry logic
3. Optimize parsing performance
4. Complete UI integration

### Key Components to Build

1. **NETSDownloadManager**
   - Manage URLSession for PDF downloads
   - Track download progress
   - Handle background downloads
   - Coordinate parsing after download

2. **NETSPDFParser**
   - Extract text from PDF using PDFKit
   - Identify and parse verse numbers
   - Handle chapter breaks
   - Clean extracted text

3. **NETSDataConverter**
   - Convert parsed text to Book/Chapter/Verse structure
   - Generate plist file
   - Validate data integrity

4. **TranslationManager** (enhance existing or new)
   - Manage available translations
   - Switch between Brenton and NETS
   - Check download status
   - Provide translation to ScriptureManager

5. **UI Components**
   - Translation selector in Settings
   - Download progress view
   - Download trigger button

## URL Structure
NETS PDFs are available at: `https://ccat.sas.upenn.edu/nets/edition/[book-filename].pdf`

Examples:
- `01-gen-nets.pdf` - Genesis
- `19-ps-nets.pdf` - Psalms
- `23-isa-nets.pdf` - Isaiah

## Success Criteria
- Successfully download and parse all NETS OT books
- Extracted text is accurate with correct verse divisions
- User can switch between Brenton and NETS seamlessly
- Download process is reliable and handles interruptions
- App size remains reasonable (PDFs deleted after processing)
- No degradation in app performance

## Estimated Scope
- ~2-3 days for POC with initial books
- ~2-3 days for full implementation
- ~1 day for testing and polish

## Future Considerations
While not in initial scope, the system architecture should not preclude:
- Adding more NT translations
- Caching parsed data for faster subsequent access
- Partial downloads (selected books only) if needed