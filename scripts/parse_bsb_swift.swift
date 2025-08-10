#!/usr/bin/env swift

import Foundation

// First, let's use a simple approach - convert Excel to CSV first
// Then parse the CSV in Swift

struct Verse {
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
}

// NT book names
let ntBooks = [
    "Matthew", "Mark", "Luke", "John", "Acts",
    "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
    "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
    "1 Timothy", "2 Timothy", "Titus", "Philemon",
    "Hebrews", "James", "1 Peter", "2 Peter",
    "1 John", "2 John", "3 John", "Jude", "Revelation"
]

print("Note: This script requires the BSB Excel file to be converted to CSV first")
print("You can use Excel, Numbers, or an online converter")
print("Expected CSV format: Book,Chapter,Verse,Text")

// For now, let's create a placeholder structure for NT books
// This will be populated when we have the actual BSB data

var ntData: [String: Any] = [:]

for bookName in ntBooks {
    ntData[bookName] = [
        "name": bookName,
        "testament": "New",
        "chapters": [[String: Any]]() // Will be filled with actual data
    ]
}

// Save placeholder structure
let outputPath = "downloads/nt_structure.json"
if let jsonData = try? JSONSerialization.data(withJSONObject: ntData, options: [.prettyPrinted, .sortedKeys]) {
    try? jsonData.write(to: URL(fileURLWithPath: outputPath))
    print("Created NT structure template at \(outputPath)")
}