import Foundation

// MARK: - Scripture Data Models

struct ScriptureData: Codable {
    let books: [Book]
}

struct Book: Codable, Equatable {
    let name: String
    let abbreviation: String
    let testament: String
    let orderIndex: Int
    let chapters: [Chapter]
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.name == rhs.name && lhs.orderIndex == rhs.orderIndex
    }
}

struct Chapter: Codable {
    let number: Int
    let verses: [Verse]
}

struct Verse: Codable {
    let number: Int
    let text: String
}

// MARK: - Scripture Manager

/// Manages loading and access to scripture data from bundled plist files
/// Loads both Old Testament and New Testament data into memory on initialization
final class ScriptureManager {
    static let shared = ScriptureManager()
    
    // MARK: - Private Properties
    
    private var scriptureData: ScriptureData?
    private let plistFileName = "scripture"
    private var isLoaded = false
    
    // MARK: - Initialization
    
    private init() {
        loadScripture()
    }
    
    // MARK: - Private Methods
    
    private func loadScripture() {
        guard !isLoaded else { return }
        
        let decoder = PropertyListDecoder()
        
        // Load all scripture from single file
        if let url = Bundle.main.url(forResource: plistFileName, withExtension: "plist"),
           let data = try? Data(contentsOf: url) {
            do {
                scriptureData = try decoder.decode(ScriptureData.self, from: data)
                isLoaded = true
                print("Successfully loaded \(scriptureData?.books.count ?? 0) books")
            } catch {
                print("Failed to decode scripture data: \(error)")
            }
        } else {
            print("Failed to load \(plistFileName).plist")
        }
    }
    
    // MARK: - Public Interface
    
    /// All available books in order
    var books: [Book] {
        return scriptureData?.books ?? []
    }
    
    /// Find a book by its full name
    /// - Parameter name: The full name of the book (e.g., "Genesis")
    /// - Returns: The book if found, nil otherwise
    func book(named name: String) -> Book? {
        return books.first { $0.name == name }
    }
    
    /// Find a book by its abbreviation
    /// - Parameter abbr: The abbreviation of the book (e.g., "Gen")
    /// - Returns: The book if found, nil otherwise
    func book(withAbbreviation abbr: String) -> Book? {
        return books.first { $0.abbreviation == abbr }
    }
    
    /// Get a specific chapter from a book
    /// - Parameters:
    ///   - bookName: The full name of the book
    ///   - chapter: The chapter number
    /// - Returns: The chapter if found, nil otherwise
    func chapter(bookName: String, chapter: Int) -> Chapter? {
        guard let book = book(named: bookName) else { return nil }
        return book.chapters.first { $0.number == chapter }
    }
    
    /// Whether scripture data has been loaded and is ready for use
    var isReady: Bool {
        return isLoaded
    }
}