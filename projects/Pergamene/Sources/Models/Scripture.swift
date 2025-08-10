import Foundation

// MARK: - Scripture Data Models

struct ScriptureData: Codable {
    let books: [Book]
}

struct Book: Codable {
    let name: String
    let abbreviation: String
    let testament: String
    let orderIndex: Int
    let chapters: [Chapter]
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
        
        guard let url = Bundle.main.url(forResource: plistFileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load scripture plist")
            return
        }
        
        let decoder = PropertyListDecoder()
        do {
            scriptureData = try decoder.decode(ScriptureData.self, from: data)
            isLoaded = true
            print("Loaded \(scriptureData?.books.count ?? 0) books into memory")
            
            // Log memory usage for debugging
            let totalVerses = scriptureData?.books.reduce(0) { total, book in
                total + book.chapters.reduce(0) { chapterTotal, chapter in
                    chapterTotal + chapter.verses.count
                }
            } ?? 0
            print("Total verses loaded: \(totalVerses)")
        } catch {
            print("Failed to decode scripture data: \(error)")
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