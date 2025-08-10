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

class UserDataManager {
    static let shared = UserDataManager()
    
    private let bookmarksKey = "pergamene.bookmarks"
    private let highlightsKey = "pergamene.highlights"
    private let readingPositionKey = "pergamene.readingPosition"
    
    private init() {}
    
    // MARK: - Bookmarks
    
    var bookmarks: [Bookmark] {
        get {
            guard let data = UserDefaults.standard.data(forKey: bookmarksKey),
                  let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) else {
                return []
            }
            return bookmarks
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: bookmarksKey)
            }
        }
    }
    
    func addBookmark(_ bookmark: Bookmark) {
        var current = bookmarks
        // Remove existing bookmark for same location if exists
        current.removeAll { $0.bookName == bookmark.bookName && $0.chapter == bookmark.chapter }
        current.append(bookmark)
        // Keep only last 5 bookmarks
        if current.count > 5 {
            current.removeFirst()
        }
        bookmarks = current
    }
    
    func removeBookmark(_ bookmark: Bookmark) {
        var current = bookmarks
        current.removeAll { $0.id == bookmark.id }
        bookmarks = current
    }
    
    // MARK: - Highlights
    
    var highlights: [Highlight] {
        get {
            guard let data = UserDefaults.standard.data(forKey: highlightsKey),
                  let highlights = try? JSONDecoder().decode([Highlight].self, from: data) else {
                return []
            }
            return highlights
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: highlightsKey)
            }
        }
    }
    
    func addHighlight(_ highlight: Highlight) {
        var current = highlights
        current.append(highlight)
        highlights = current
    }
    
    func removeHighlight(_ highlight: Highlight) {
        var current = highlights
        current.removeAll { $0.id == highlight.id }
        highlights = current
    }
    
    func highlightsForChapter(book: String, chapter: Int) -> [Highlight] {
        return highlights.filter { $0.bookName == book && $0.chapter == chapter }
    }
    
    // MARK: - Reading Position
    
    var readingPosition: ReadingPosition? {
        get {
            guard let data = UserDefaults.standard.data(forKey: readingPositionKey),
                  let position = try? JSONDecoder().decode(ReadingPosition.self, from: data) else {
                return nil
            }
            return position
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: readingPositionKey)
            }
        }
    }
    
    func saveReadingPosition(book: String, chapter: Int, scrollPosition: Double) {
        readingPosition = ReadingPosition(
            bookName: book,
            chapter: chapter,
            scrollPosition: scrollPosition,
            timestamp: Date()
        )
        
        // Also save the per-chapter position
        saveChapterScrollPosition(book: book, chapter: chapter, scrollPosition: scrollPosition)
    }
    
    // MARK: - Per-Chapter Scroll Positions
    
    private func chapterScrollKey(book: String, chapter: Int) -> String {
        return "pergamene.scroll.\(book).\(chapter)"
    }
    
    func saveChapterScrollPosition(book: String, chapter: Int, scrollPosition: Double) {
        let key = chapterScrollKey(book: book, chapter: chapter)
        UserDefaults.standard.set(scrollPosition, forKey: key)
    }
    
    func getChapterScrollPosition(book: String, chapter: Int) -> Double {
        let key = chapterScrollKey(book: book, chapter: chapter)
        return UserDefaults.standard.double(forKey: key)
    }
    
    func clearChapterScrollPosition(book: String, chapter: Int) {
        let key = chapterScrollKey(book: book, chapter: chapter)
        UserDefaults.standard.removeObject(forKey: key)
    }
}