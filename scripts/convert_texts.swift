#!/usr/bin/env swift

import Foundation

// MARK: - Data Models

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

struct ScriptureData: Codable {
    let books: [Book]
}

// MARK: - USFM Parser for Brenton Septuagint

class USFMParser {
    
    // Clean USFM text by removing footnotes and formatting markers
    private func cleanUSFMText(_ text: String) -> String {
        var cleaned = text
        
        // Remove footnote markers and their content
        // Pattern: \f + ... \f* (footnotes with all content between)
        let footnotePattern = #"\\f\s*\+.*?\\f\*"#
        cleaned = cleaned.replacingOccurrences(
            of: footnotePattern,
            with: "",
            options: .regularExpression
        )
        
        // Remove cross-reference markers
        // Pattern: \x ... \x*
        let crossRefPattern = #"\\x\s*\+.*?\\x\*"#
        cleaned = cleaned.replacingOccurrences(
            of: crossRefPattern,
            with: "",
            options: .regularExpression
        )
        
        // Remove character style markers (like \sc...\sc*, \it...\it*, etc.)
        let characterStylePattern = #"\\[a-z]+\s+([^\\]*)\\[a-z]+\*"#
        cleaned = cleaned.replacingOccurrences(
            of: characterStylePattern,
            with: "$1",
            options: .regularExpression
        )
        
        // Remove standalone inline markers
        let inlineMarkerPattern = #"\\[a-z]+\*?"#
        cleaned = cleaned.replacingOccurrences(
            of: inlineMarkerPattern,
            with: "",
            options: .regularExpression
        )
        
        // Remove footnote references that might remain (like f + fr 1:4 fqa ... f*)
        let footnoteRefPattern = #"f\s*\+[^f]*f\*"#
        cleaned = cleaned.replacingOccurrences(
            of: footnoteRefPattern,
            with: "",
            options: .regularExpression
        )
        
        // Remove any remaining backslashes
        cleaned = cleaned.replacingOccurrences(of: "\\", with: "")
        
        // Clean up any double spaces
        cleaned = cleaned.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        
        return cleaned
    }
    
    func parseDirectory(at path: String) -> [Book] {
        var books: [Book] = []
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            
            // Filter out unwanted files (front matter, appendix, etc.)
            let excludedFiles = ["00-FRTeng-Brenton.usfm", "01-INTeng-Brenton.usfm", 
                                "97-BAKeng-Brenton.usfm", "98-OTHeng-Brenton.usfm",
                                "99-XXAeng-Brenton.usfm", "100-XXBeng-Brenton.usfm", 
                                "101-XXCeng-Brenton.usfm"]
            
            let usfmFiles = files.filter { file in
                (file.hasSuffix(".usfm") || file.hasSuffix(".USFM")) && 
                !excludedFiles.contains(file)
            }.sorted()
            
            for (index, file) in usfmFiles.enumerated() {
                let filePath = "\(path)/\(file)"
                if let book = parseUSFMFile(at: filePath, orderIndex: index) {
                    books.append(book)
                    print("Parsed: \(book.name)")
                }
            }
        } catch {
            print("Error reading directory: \(error)")
        }
        
        return books
    }
    
    private func parseUSFMFile(at path: String, orderIndex: Int) -> Book? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Failed to read file: \(path)")
            return nil
        }
        
        let lines = content.components(separatedBy: .newlines)
        var bookName = ""
        var bookAbbreviation = ""
        var chapters: [Chapter] = []
        var currentChapter: Chapter?
        var currentVerses: [Verse] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Book name
            if trimmed.starts(with: "\\h ") {
                bookName = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                
                // Special case: Remove "(Greek)" from Esther and Daniel
                bookName = bookName.replacingOccurrences(of: " (Greek)", with: "")
                
                // Special case: Rename "Ezra and Nehemiah" to just "Ezra"
                if bookName == "Ezra and Nehemiah" {
                    bookName = "Ezra"
                }
            }
            
            // Book ID (abbreviation)
            if trimmed.starts(with: "\\id ") {
                let parts = trimmed.dropFirst(4).split(separator: " ")
                if !parts.isEmpty {
                    bookAbbreviation = String(parts[0])
                }
            }
            
            // Chapter marker
            if trimmed.starts(with: "\\c ") {
                // Save previous chapter
                if let chapter = currentChapter {
                    chapters.append(Chapter(number: chapter.number, verses: currentVerses))
                }
                
                // Start new chapter
                let chapterNumStr = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                if let chapterNum = Int(chapterNumStr) {
                    currentChapter = Chapter(number: chapterNum, verses: [])
                    currentVerses = []
                }
            }
            
            // Verse
            if trimmed.starts(with: "\\v ") {
                let verseContent = String(trimmed.dropFirst(3))
                let parts = verseContent.split(separator: " ", maxSplits: 1)
                
                if parts.count >= 2,
                   let verseNum = Int(parts[0]) {
                    let rawText = String(parts[1])
                    let cleanedText = cleanUSFMText(rawText)
                    
                    currentVerses.append(Verse(number: verseNum, text: cleanedText))
                }
            }
        }
        
        // Add last chapter
        if let chapter = currentChapter {
            chapters.append(Chapter(number: chapter.number, verses: currentVerses))
        }
        
        // Filter out unwanted books (Appendix-like books)
        let unwantedBooks = ["Errata", "1844 Preface", "Table of Chapters and Verses in Jeremiah"]
        if unwantedBooks.contains(bookName) {
            return nil
        }
        
        // Special case: Limit Ezra to first 10 chapters
        if bookName == "Ezra" {
            chapters = Array(chapters.prefix(10))
        }
        
        if !bookName.isEmpty && !chapters.isEmpty {
            return Book(
                name: bookName,
                abbreviation: bookAbbreviation,
                testament: "Old",
                orderIndex: orderIndex,
                chapters: chapters
            )
        }
        
        return nil
    }
}

// MARK: - BSB NT Parser from JSON

class BSBParser {
    func parseNTFromJSON(at path: String, startIndex: Int) -> [Book] {
        var books: [Book] = []
        
        // Book abbreviations for NT
        let abbreviations: [String: String] = [
            "Matthew": "Matt",
            "Mark": "Mark",
            "Luke": "Luke",
            "John": "John",
            "Acts": "Acts",
            "Romans": "Rom",
            "1 Corinthians": "1Cor",
            "2 Corinthians": "2Cor",
            "Galatians": "Gal",
            "Ephesians": "Eph",
            "Philippians": "Phil",
            "Colossians": "Col",
            "1 Thessalonians": "1Thess",
            "2 Thessalonians": "2Thess",
            "1 Timothy": "1Tim",
            "2 Timothy": "2Tim",
            "Titus": "Titus",
            "Philemon": "Phlm",
            "Hebrews": "Heb",
            "James": "Jas",
            "1 Peter": "1Pet",
            "2 Peter": "2Pet",
            "1 John": "1John",
            "2 John": "2John",
            "3 John": "3John",
            "Jude": "Jude",
            "Revelation": "Rev"
        ]
        
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("Warning: Could not read NT JSON file at \(path)")
            return []
        }
        
        guard let jsonBooks = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            print("Warning: Could not parse NT JSON")
            return []
        }
        
        for (index, jsonBook) in jsonBooks.enumerated() {
            guard let name = jsonBook["name"] as? String,
                  let jsonChapters = jsonBook["chapters"] as? [[String: Any]] else {
                continue
            }
            
            var chapters: [Chapter] = []
            
            for jsonChapter in jsonChapters {
                guard let number = jsonChapter["number"] as? Int,
                      let jsonVerses = jsonChapter["verses"] as? [[String: Any]] else {
                    continue
                }
                
                var verses: [Verse] = []
                
                for jsonVerse in jsonVerses {
                    guard let verseNumber = jsonVerse["number"] as? Int,
                          let text = jsonVerse["text"] as? String else {
                        continue
                    }
                    
                    verses.append(Verse(number: verseNumber, text: text))
                }
                
                chapters.append(Chapter(number: number, verses: verses))
            }
            
            let book = Book(
                name: name,
                abbreviation: abbreviations[name] ?? name,
                testament: "New",
                orderIndex: startIndex + index,
                chapters: chapters
            )
            
            books.append(book)
            print("Parsed: \(book.name)")
        }
        
        return books
    }
}

// MARK: - Main Conversion Process

let arguments = CommandLine.arguments
let projectRoot = arguments.count > 1 ? arguments[1] : FileManager.default.currentDirectoryPath

let downloadDir = "\(projectRoot)/downloads"
let outputDir = "\(projectRoot)/projects/Pergamene/Resources/Texts"

// Create output directory
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Parse Brenton Septuagint
print("Parsing Brenton Septuagint...")
let usfmParser = USFMParser()
let otBooks = usfmParser.parseDirectory(at: "\(downloadDir)/brenton")

// Parse BSB New Testament from JSON
print("Parsing BSB New Testament...")
let bsbParser = BSBParser()
let ntBooks = bsbParser.parseNTFromJSON(at: "\(downloadDir)/bsb_nt.json", startIndex: otBooks.count)

// Combine all books
let allBooks = otBooks + ntBooks
let scriptureData = ScriptureData(books: allBooks)

// Save to plist
let encoder = PropertyListEncoder()
encoder.outputFormat = .binary

do {
    let data = try encoder.encode(scriptureData)
    let outputPath = "\(outputDir)/scripture.plist"
    try data.write(to: URL(fileURLWithPath: outputPath))
    print("Successfully saved \(allBooks.count) books to \(outputPath)")
} catch {
    print("Error saving plist: \(error)")
}

print("Conversion complete!")