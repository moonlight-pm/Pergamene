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
    
    func parseDirectory(at path: String) -> [Book] {
        var books: [Book] = []
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            let usfmFiles = files.filter { $0.hasSuffix(".usfm") || $0.hasSuffix(".USFM") }
                .sorted()
            
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
                    let verseText = String(parts[1])
                        .replacingOccurrences(of: "\\", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    currentVerses.append(Verse(number: verseNum, text: verseText))
                }
            }
        }
        
        // Add last chapter
        if let chapter = currentChapter {
            chapters.append(Chapter(number: chapter.number, verses: currentVerses))
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

// MARK: - Excel Parser for BSB (placeholder)

class BSBParser {
    func parseExcelFile(at path: String, startIndex: Int) -> [Book] {
        // Note: Full Excel parsing would require additional libraries
        // For now, this is a placeholder that would need python or
        // a separate tool to convert Excel to JSON first
        print("Note: BSB Excel parsing requires separate preprocessing")
        return []
    }
}

// MARK: - Main Conversion Process

let arguments = CommandLine.arguments
let projectRoot = arguments.count > 1 ? arguments[1] : FileManager.default.currentDirectoryPath

let downloadDir = "\(projectRoot)/downloads"
let outputDir = "\(projectRoot)/Projects/Pergamene/Resources/Texts"

// Create output directory
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Parse Brenton Septuagint
print("Parsing Brenton Septuagint...")
let usfmParser = USFMParser()
let otBooks = usfmParser.parseDirectory(at: "\(downloadDir)/brenton")

// Parse BSB New Testament (placeholder)
print("Parsing BSB New Testament...")
let bsbParser = BSBParser()
let ntBooks = bsbParser.parseExcelFile(at: "\(downloadDir)/bsb.xlsx", startIndex: otBooks.count)

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