import UIKit

// MARK: - Bookmark Model

struct BookmarkItem: Codable, Equatable {
    let id: UUID
    let bookName: String
    let chapter: Int
    let shortName: String  // e.g., "Gen 1", "Matt 5"
    var colorHex: String    // Hex color for the ribbon
    let createdAt: Date
    
    init(bookName: String, chapter: Int, shortName: String, colorHex: String? = nil) {
        self.id = UUID()
        self.bookName = bookName
        self.chapter = chapter
        self.shortName = shortName
        self.colorHex = colorHex ?? BookmarkColors.randomBrownShade()
        self.createdAt = Date()
    }
}

// MARK: - Bookmark Colors

struct BookmarkColors {
    // Pre-defined theme colors with consistent saturation/luminosity
    static let themeColors = [
        "#8B4513", // Saddle Brown (default)
        "#CD5C5C", // Indian Red
        "#4682B4", // Steel Blue
        "#6B8E23", // Olive Drab
        "#9370DB", // Medium Purple
        "#FF8C00", // Dark Orange
        "#DAA520", // Goldenrod
        "#DB7093", // Pale Violet Red
        "#5F9EA0", // Cadet Blue
        "#A0522D", // Sienna
        "#708090"  // Slate Gray
    ]
    
    // Brown shades for automatic assignment
    static let brownShades = [
        "#8B4513", // Saddle Brown
        "#A0522D", // Sienna
        "#964B00", // Traditional Brown
        "#654321", // Dark Brown
        "#8B7355", // Burlywood4
        "#826644", // Raw Umber
        "#7B3F00", // Chocolate
        "#80461B", // Russet
        "#954535", // Chestnut
        "#6F4E37"  // Coffee
    ]
    
    static func randomBrownShade() -> String {
        brownShades.randomElement() ?? brownShades[0]
    }
    
    static func colorFromHex(_ hex: String) -> UIColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

// MARK: - BookmarkManager

class BookmarkManager {
    static let shared = BookmarkManager()
    
    private let bookmarksKey = "PergameneBookmarks"
    private let lastNonBookmarkPositionKey = "LastNonBookmarkPosition"
    
    private init() {}
    
    // MARK: - Bookmark Management
    
    func getBookmarks() -> [BookmarkItem] {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([BookmarkItem].self, from: data) else {
            return []
        }
        return bookmarks
    }
    
    func saveBookmarks(_ bookmarks: [BookmarkItem]) {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        }
    }
    
    func addBookmark(bookName: String, chapter: Int) -> BookmarkItem {
        var bookmarks = getBookmarks()
        
        // Check if bookmark already exists
        if !bookmarks.contains(where: { $0.bookName == bookName && $0.chapter == chapter }) {
            let shortName = createShortName(for: bookName, chapter: chapter)
            let bookmark = BookmarkItem(bookName: bookName, chapter: chapter, shortName: shortName)
            bookmarks.append(bookmark)
            saveBookmarks(bookmarks)
            return bookmark
        }
        
        // Return existing bookmark if it exists
        return bookmarks.first(where: { $0.bookName == bookName && $0.chapter == chapter })!
    }
    
    func deleteBookmark(_ bookmark: BookmarkItem) {
        var bookmarks = getBookmarks()
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks(bookmarks)
    }
    
    func updateBookmarkColor(_ bookmark: BookmarkItem, colorHex: String) {
        var bookmarks = getBookmarks()
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index].colorHex = colorHex
            saveBookmarks(bookmarks)
        }
    }
    
    func bookmarkExists(for bookName: String, chapter: Int) -> Bool {
        let bookmarks = getBookmarks()
        return bookmarks.contains(where: { $0.bookName == bookName && $0.chapter == chapter })
    }
    
    // MARK: - Navigation History
    
    struct NavigationPosition: Codable {
        let bookName: String
        let chapter: Int
        let scrollPosition: CGFloat
    }
    
    func saveLastNonBookmarkPosition(bookName: String, chapter: Int, scrollPosition: CGFloat) {
        // Only save if this position is not a bookmark
        if !bookmarkExists(for: bookName, chapter: chapter) {
            let position = NavigationPosition(bookName: bookName, chapter: chapter, scrollPosition: scrollPosition)
            if let data = try? JSONEncoder().encode(position) {
                UserDefaults.standard.set(data, forKey: lastNonBookmarkPositionKey)
            }
        }
    }
    
    func getLastNonBookmarkPosition() -> NavigationPosition? {
        guard let data = UserDefaults.standard.data(forKey: lastNonBookmarkPositionKey),
              let position = try? JSONDecoder().decode(NavigationPosition.self, from: data) else {
            return nil
        }
        return position
    }
    
    func clearLastNonBookmarkPosition() {
        UserDefaults.standard.removeObject(forKey: lastNonBookmarkPositionKey)
    }
    
    // MARK: - Helper Methods
    
    private func createShortName(for bookName: String, chapter: Int) -> String {
        // Create abbreviated book names
        let abbreviations: [String: String] = [
            "Genesis": "Gen",
            "Exodus": "Ex",
            "Leviticus": "Lev",
            "Numbers": "Num",
            "Deuteronomy": "Deut",
            "Joshua": "Josh",
            "Judges": "Judg",
            "Ruth": "Ruth",
            "1 Samuel": "1 Sam",
            "2 Samuel": "2 Sam",
            "1 Kings": "1 Kgs",
            "2 Kings": "2 Kgs",
            "1 Chronicles": "1 Chr",
            "2 Chronicles": "2 Chr",
            "Ezra": "Ezra",
            "Nehemiah": "Neh",
            "Esther": "Esth",
            "Job": "Job",
            "Psalms": "Ps",
            "Proverbs": "Prov",
            "Ecclesiastes": "Eccl",
            "Song of Solomon": "Song",
            "Isaiah": "Isa",
            "Jeremiah": "Jer",
            "Lamentations": "Lam",
            "Ezekiel": "Ezek",
            "Daniel": "Dan",
            "Hosea": "Hos",
            "Joel": "Joel",
            "Amos": "Amos",
            "Obadiah": "Obad",
            "Jonah": "Jonah",
            "Micah": "Mic",
            "Nahum": "Nah",
            "Habakkuk": "Hab",
            "Zephaniah": "Zeph",
            "Haggai": "Hag",
            "Zechariah": "Zech",
            "Malachi": "Mal",
            // New Testament
            "Matthew": "Matt",
            "Mark": "Mark",
            "Luke": "Luke",
            "John": "John",
            "Acts": "Acts",
            "Romans": "Rom",
            "1 Corinthians": "1 Cor",
            "2 Corinthians": "2 Cor",
            "Galatians": "Gal",
            "Ephesians": "Eph",
            "Philippians": "Phil",
            "Colossians": "Col",
            "1 Thessalonians": "1 Thess",
            "2 Thessalonians": "2 Thess",
            "1 Timothy": "1 Tim",
            "2 Timothy": "2 Tim",
            "Titus": "Titus",
            "Philemon": "Phlm",
            "Hebrews": "Heb",
            "James": "Jas",
            "1 Peter": "1 Pet",
            "2 Peter": "2 Pet",
            "1 John": "1 John",
            "2 John": "2 John",
            "3 John": "3 John",
            "Jude": "Jude",
            "Revelation": "Rev"
        ]
        
        let abbrev = abbreviations[bookName] ?? String(bookName.prefix(3))
        return "\(abbrev) \(chapter)"
    }
}