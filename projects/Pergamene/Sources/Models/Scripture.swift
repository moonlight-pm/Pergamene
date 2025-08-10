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
    private let loadingQueue = DispatchQueue(label: "com.pergamene.scriptureLoading", qos: .userInitiated)
    private var isLoading = false
    private var loadingCompletion: [(() -> Void)] = []
    
    private init() {
        // Start loading immediately but asynchronously
        loadScriptureAsync()
    }
    
    private func loadScriptureAsync() {
        guard !isLoading else { return }
        isLoading = true
        
        loadingQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard let url = Bundle.main.url(forResource: self.plistFileName, withExtension: "plist"),
                  let data = try? Data(contentsOf: url) else {
                print("Failed to load scripture plist")
                self.isLoading = false
                return
            }
            
            let decoder = PropertyListDecoder()
            do {
                let decodedData = try decoder.decode(ScriptureData.self, from: data)
                
                DispatchQueue.main.async {
                    self.scriptureData = decodedData
                    self.isLoading = false
                    print("Loaded \(decodedData.books.count) books")
                    
                    // Call any pending completions
                    self.loadingCompletion.forEach { $0() }
                    self.loadingCompletion.removeAll()
                }
            } catch {
                print("Failed to decode scripture data: \(error)")
                self.isLoading = false
            }
        }
    }
    
    private func ensureLoaded(completion: @escaping () -> Void) {
        if scriptureData != nil {
            completion()
        } else if isLoading {
            loadingCompletion.append(completion)
        } else {
            loadScriptureAsync()
            loadingCompletion.append(completion)
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
    
    func preloadData(completion: @escaping () -> Void) {
        ensureLoaded(completion: completion)
    }
}