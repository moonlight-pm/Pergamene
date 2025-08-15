import UIKit

// MARK: - Bookmark Model

struct BookmarkItem: Codable, Equatable {
    let id: UUID
    let bookName: String
    let chapter: Int
    let shortName: String  // e.g., "Gen 1", "Matt 5"
    var colorHex: String    // Hex color for the ribbon
    let createdAt: Date
    var orderIndex: Int     // For maintaining stable order
    
    init(bookName: String, chapter: Int, shortName: String, colorHex: String? = nil, orderIndex: Int = 0) {
        self.id = UUID()
        self.bookName = bookName
        self.chapter = chapter
        self.shortName = shortName
        self.colorHex = colorHex ?? BookmarkColors.randomBrownShade()
        self.createdAt = Date()
        self.orderIndex = orderIndex
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
        "#DAA520"  // Goldenrod
    ]
    
    // Brown shades for automatic assignment
    static let brownShades = [
        "#8B4513", // Saddle Brown
        "#964B00", // Traditional Brown
        "#654321", // Dark Brown
        "#8B7355", // Burlywood4
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
    private let currentBookmarkKey = "CurrentBookmark"
    
    private init() {}
    
    // MARK: - Bookmark Management
    
    func getBookmarks() -> [BookmarkItem] {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([BookmarkItem].self, from: data) else {
            return []
        }
        // Return bookmarks sorted by orderIndex for stable positioning
        return bookmarks.sorted { $0.orderIndex < $1.orderIndex }
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
            // Get abbreviation from the actual book data and capitalize properly
            let rawAbbreviation = ScriptureManager.shared.books
                .first(where: { $0.name == bookName })?
                .abbreviation ?? String(bookName.prefix(3))
            // Capitalize first letter only (e.g., "EZR" -> "Ezr")
            let abbreviation = rawAbbreviation.prefix(1).uppercased() + rawAbbreviation.dropFirst().lowercased()
            let shortName = "\(abbreviation) \(chapter)"
            
            // Set orderIndex to be at the end of the list
            let maxOrder = bookmarks.map { $0.orderIndex }.max() ?? -1
            let bookmark = BookmarkItem(bookName: bookName, chapter: chapter, shortName: shortName, orderIndex: maxOrder + 1)
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
    
    func reorderBookmarks(_ reorderedBookmarks: [BookmarkItem]) {
        // Update order indices based on new positions
        var updatedBookmarks = reorderedBookmarks
        for (index, _) in updatedBookmarks.enumerated() {
            updatedBookmarks[index].orderIndex = index
        }
        saveBookmarks(updatedBookmarks)
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
    
    // MARK: - Current Bookmark Management
    
    func setCurrentBookmark(_ bookmark: BookmarkItem?) {
        if let bookmark = bookmark,
           let data = try? JSONEncoder().encode(bookmark) {
            UserDefaults.standard.set(data, forKey: currentBookmarkKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentBookmarkKey)
        }
    }
    
    func getCurrentBookmark() -> BookmarkItem? {
        guard let data = UserDefaults.standard.data(forKey: currentBookmarkKey),
              let bookmark = try? JSONDecoder().decode(BookmarkItem.self, from: data) else {
            return nil
        }
        return bookmark
    }
    
    func updateCurrentBookmarkIfNeeded(bookName: String, chapter: Int) {
        // Only update if we have a current bookmark
        guard let currentBookmark = getCurrentBookmark() else { return }
        
        // Update the bookmark to the new position
        var bookmarks = getBookmarks()
        
        // Find the bookmark to update
        if let index = bookmarks.firstIndex(where: { $0.id == currentBookmark.id }) {
            // Get abbreviation from the actual book data and capitalize properly
            let rawAbbreviation = ScriptureManager.shared.books
                .first(where: { $0.name == bookName })?
                .abbreviation ?? String(bookName.prefix(3))
            // Capitalize first letter only (e.g., "EZR" -> "Ezr")
            let abbreviation = rawAbbreviation.prefix(1).uppercased() + rawAbbreviation.dropFirst().lowercased()
            let shortName = "\(abbreviation) \(chapter)"
            
            // Update the bookmark in place to preserve order
            bookmarks[index] = BookmarkItem(
                bookName: bookName,
                chapter: chapter,
                shortName: shortName,
                colorHex: currentBookmark.colorHex,
                orderIndex: bookmarks[index].orderIndex  // Preserve the order index
            )
            
            saveBookmarks(bookmarks)
            setCurrentBookmark(bookmarks[index])
        }
    }
    
    func clearCurrentBookmark() {
        UserDefaults.standard.removeObject(forKey: currentBookmarkKey)
    }
}