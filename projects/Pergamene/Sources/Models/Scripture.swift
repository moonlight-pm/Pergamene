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

class ScriptureManager {
    static let shared = ScriptureManager()
    
    private var scriptureData: ScriptureData?
    private let plistFileName = "scripture"
    private var isLoaded = false
    
    private init() {
        // Load immediately on initialization
        loadScripture()
    }
    
    private func loadScripture() {
        guard !isLoaded else { return }
        
        var allBooks: [Book] = []
        let decoder = PropertyListDecoder()
        
        // Load Old Testament
        if let url = Bundle.main.url(forResource: plistFileName, withExtension: "plist"),
           let data = try? Data(contentsOf: url) {
            do {
                let otData = try decoder.decode(ScriptureData.self, from: data)
                allBooks.append(contentsOf: otData.books)
                print("Loaded \(otData.books.count) OT books into memory")
            } catch {
                print("Failed to decode OT scripture data: \(error)")
            }
        } else {
            print("Failed to load OT scripture plist")
        }
        
        // Load New Testament
        if let url = Bundle.main.url(forResource: "NewTestament", withExtension: "plist"),
           let data = try? Data(contentsOf: url) {
            do {
                let ntData = try decoder.decode(ScriptureData.self, from: data)
                allBooks.append(contentsOf: ntData.books)
                print("Loaded \(ntData.books.count) NT books into memory")
            } catch {
                print("Failed to decode NT scripture data: \(error)")
            }
        } else {
            print("Failed to load NT scripture plist")
        }
        
        // Combine into single ScriptureData
        if !allBooks.isEmpty {
            scriptureData = ScriptureData(books: allBooks)
            isLoaded = true
            
            // Log memory usage for debugging
            let totalVerses = allBooks.reduce(0) { total, book in
                total + book.chapters.reduce(0) { chapterTotal, chapter in
                    chapterTotal + chapter.verses.count
                }
            }
            print("Total verses loaded: \(totalVerses)")
        }
    }
    
    var books: [Book] {
        return scriptureData?.books ?? []
    }
    
    func book(named name: String) -> Book? {
        return books.first { $0.name == name }
    }
    
    func book(withAbbreviation abbr: String) -> Book? {
        return books.first { $0.abbreviation == abbr }
    }
    
    func chapter(bookName: String, chapter: Int) -> Chapter? {
        guard let book = book(named: bookName) else { return nil }
        return book.chapters.first { $0.number == chapter }
    }
    
    var isReady: Bool {
        return isLoaded
    }
}