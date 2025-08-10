#!/usr/bin/env swift

import Foundation

// Read the NT JSON
let jsonPath = "downloads/bsb_nt.json"
let outputPath = "projects/Pergamene/Resources/Texts/NewTestament.plist"

guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) else {
    print("Error: Could not read JSON file at \(jsonPath)")
    exit(1)
}

guard let books = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
    print("Error: Could not parse JSON")
    exit(1)
}

print("Loaded \(books.count) NT books")

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

// Convert to plist format matching the OT structure
var plistBooks: [[String: Any]] = []

for (index, book) in books.enumerated() {
    guard let name = book["name"] as? String,
          let chapters = book["chapters"] as? [[String: Any]] else {
        continue
    }
    
    var plistChapters: [[String: Any]] = []
    
    for chapter in chapters {
        guard let number = chapter["number"] as? Int,
              let verses = chapter["verses"] as? [[String: Any]] else {
            continue
        }
        
        var plistVerses: [[String: Any]] = []
        
        for verse in verses {
            guard let verseNumber = verse["number"] as? Int,
                  let text = verse["text"] as? String else {
                continue
            }
            
            plistVerses.append([
                "number": verseNumber,
                "text": text
            ])
        }
        
        plistChapters.append([
            "number": number,
            "verses": plistVerses
        ])
    }
    
    // Add book with order index (starting at 40 for NT) and abbreviation
    plistBooks.append([
        "name": name,
        "abbreviation": abbreviations[name] ?? name,
        "testament": "New",
        "orderIndex": 40 + index,
        "chapters": plistChapters
    ])
}

// Create the root dictionary
let plistRoot: [String: Any] = [
    "books": plistBooks,
    "version": "BSB",
    "language": "en"
]

// Save as binary plist
do {
    let plistData = try PropertyListSerialization.data(
        fromPropertyList: plistRoot,
        format: .binary,
        options: 0
    )
    
    // Create directory if needed
    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    
    try plistData.write(to: outputURL)
    
    // Print file size
    let fileSize = try FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? Int ?? 0
    let sizeMB = Double(fileSize) / (1024 * 1024)
    
    print("Successfully created NT plist at: \(outputPath)")
    print("File size: \(String(format: "%.2f", sizeMB)) MB")
    
    // Print summary
    var totalVerses = 0
    for book in plistBooks {
        if let chapters = book["chapters"] as? [[String: Any]] {
            for chapter in chapters {
                if let verses = chapter["verses"] as? [[String: Any]] {
                    totalVerses += verses.count
                }
            }
        }
    }
    print("Total verses: \(totalVerses)")
    
} catch {
    print("Error saving plist: \(error)")
    exit(1)
}