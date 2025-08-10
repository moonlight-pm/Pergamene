import Foundation

// MARK: - User Data Models

struct Bookmark: Codable {
    let id: UUID
    let bookName: String
    let chapter: Int
    let timestamp: Date
    let color: BookmarkColor
    
    init(bookName: String, chapter: Int, color: BookmarkColor = .red) {
        self.id = UUID()
        self.bookName = bookName
        self.chapter = chapter
        self.timestamp = Date()
        self.color = color
    }
}

enum BookmarkColor: String, Codable, CaseIterable {
    case red = "red"
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case brown = "brown"
    
    var displayName: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        case .green: return "Green"
        case .purple: return "Purple"
        case .brown: return "Brown"
        }
    }
}

struct Highlight: Codable {
    let id: UUID
    let bookName: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let text: String
    let timestamp: Date
    
    init(bookName: String, chapter: Int, verseStart: Int, verseEnd: Int, text: String) {
        self.id = UUID()
        self.bookName = bookName
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.text = text
        self.timestamp = Date()
    }
}

struct ReadingPosition: Codable {
    let bookName: String
    let chapter: Int
    let scrollPosition: Double
    let timestamp: Date
}

// MARK: - User Data Manager

/// Manages user-generated content: bookmarks, highlights, and reading position
/// Uses UserDefaults for persistence with JSON encoding
final class UserDataManager {
    static let shared = UserDataManager()
    
    // MARK: - Constants
    
    private enum Keys {
        static let bookmarks = "pergamene.bookmarks"
        static let highlights = "pergamene.highlights"
        static let readingPosition = "pergamene.readingPosition"
    }
    
    private enum Limits {
        static let maxBookmarks = 5
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Bookmarks
    
    /// All saved bookmarks
    var bookmarks: [Bookmark] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.bookmarks),
                  let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) else {
                return []
            }
            return bookmarks
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.bookmarks)
            }
        }
    }
    
    /// Add a new bookmark, replacing any existing bookmark for the same chapter
    /// - Parameter bookmark: The bookmark to add
    func addBookmark(_ bookmark: Bookmark) {
        var current = bookmarks
        
        // Remove existing bookmark for same location if exists
        current.removeAll { $0.bookName == bookmark.bookName && $0.chapter == bookmark.chapter }
        current.append(bookmark)
        
        // Keep only the most recent bookmarks
        if current.count > Limits.maxBookmarks {
            current.removeFirst()
        }
        
        bookmarks = current
    }
    
    /// Remove a specific bookmark
    /// - Parameter bookmark: The bookmark to remove
    func removeBookmark(_ bookmark: Bookmark) {
        var current = bookmarks
        current.removeAll { $0.id == bookmark.id }
        bookmarks = current
    }
    
    // MARK: - Highlights
    
    /// All saved highlights
    var highlights: [Highlight] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.highlights),
                  let highlights = try? JSONDecoder().decode([Highlight].self, from: data) else {
                return []
            }
            return highlights
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.highlights)
            }
        }
    }
    
    /// Add a new highlight
    /// - Parameter highlight: The highlight to add
    func addHighlight(_ highlight: Highlight) {
        var current = highlights
        current.append(highlight)
        highlights = current
    }
    
    /// Remove a specific highlight
    /// - Parameter highlight: The highlight to remove
    func removeHighlight(_ highlight: Highlight) {
        var current = highlights
        current.removeAll { $0.id == highlight.id }
        highlights = current
    }
    
    /// Get all highlights for a specific chapter
    /// - Parameters:
    ///   - book: The book name
    ///   - chapter: The chapter number
    /// - Returns: Array of highlights for the specified chapter
    func highlightsForChapter(book: String, chapter: Int) -> [Highlight] {
        return highlights.filter { $0.bookName == book && $0.chapter == chapter }
    }
    
    // MARK: - Reading Position
    
    /// The last saved reading position
    var readingPosition: ReadingPosition? {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.readingPosition),
                  let position = try? JSONDecoder().decode(ReadingPosition.self, from: data) else {
                return nil
            }
            return position
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.readingPosition)
            }
        }
    }
    
    /// Save the current reading position
    /// - Parameters:
    ///   - book: The book name
    ///   - chapter: The chapter number
    ///   - scrollPosition: The scroll position within the chapter
    func saveReadingPosition(book: String, chapter: Int, scrollPosition: Double) {
        readingPosition = ReadingPosition(
            bookName: book,
            chapter: chapter,
            scrollPosition: scrollPosition,
            timestamp: Date()
        )
        
        // Also save the per-chapter position for navigation
        saveChapterScrollPosition(book: book, chapter: chapter, scrollPosition: scrollPosition)
    }
    
    // MARK: - Per-Chapter Scroll Positions
    
    private func chapterScrollKey(book: String, chapter: Int) -> String {
        return "pergamene.scroll.\(book).\(chapter)"
    }
    
    /// Save the scroll position for a specific chapter
    /// - Parameters:
    ///   - book: The book name
    ///   - chapter: The chapter number
    ///   - scrollPosition: The scroll position within the chapter
    func saveChapterScrollPosition(book: String, chapter: Int, scrollPosition: Double) {
        let key = chapterScrollKey(book: book, chapter: chapter)
        UserDefaults.standard.set(scrollPosition, forKey: key)
    }
    
    /// Get the saved scroll position for a specific chapter
    /// - Parameters:
    ///   - book: The book name
    ///   - chapter: The chapter number
    /// - Returns: The saved scroll position, or 0 if none exists
    func getChapterScrollPosition(book: String, chapter: Int) -> Double {
        let key = chapterScrollKey(book: book, chapter: chapter)
        return UserDefaults.standard.double(forKey: key)
    }
    
    /// Clear the saved scroll position for a specific chapter
    /// - Parameters:
    ///   - book: The book name
    ///   - chapter: The chapter number
    func clearChapterScrollPosition(book: String, chapter: Int) {
        let key = chapterScrollKey(book: book, chapter: chapter)
        UserDefaults.standard.removeObject(forKey: key)
    }
}