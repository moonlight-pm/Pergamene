#!/usr/bin/env swift

import Foundation
import AppKit

let inputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "../projects/Pergamene/Resources/DropCaps/drop-caps-alphabet.jpg"
let outputDir = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "../projects/Pergamene/Resources/DropCaps"

guard let inputImage = NSImage(contentsOfFile: inputPath) else {
    print("Error: Could not load image from \(inputPath)")
    exit(1)
}

// Create output directory if needed
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

guard let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Error: Could not get CGImage")
    exit(1)
}

print("Image size: \(cgImage.width) x \(cgImage.height)")

// Based on visual inspection:
// - Large O: approximately 0-235px width, full height
// - Grid starts at x=250px
// - Grid has 7 columns in first 3 rows, then 5 in last row
// - Each cell is approximately 53x62px

// First extract the large O
let oRect = CGRect(x: 22, y: 5, width: 210, height: 240)
if let croppedO = cgImage.cropping(to: oRect) {
    let oImage = NSImage(cgImage: croppedO, size: NSSize(width: oRect.width, height: oRect.height))
    
    if let tiffData = oImage.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
        
        let outputPath = "\(outputDir)/drop-cap-O.png"
        try? pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Saved: drop-cap-O.png")
    }
}

// Grid layout (visually determined)
let gridStartX = 250
let cellWidth = 53
let cellHeight = 62

// Letter positions in grid (row, col)
let letterPositions: [(Character, Int, Int)] = [
    // Row 0
    ("A", 0, 0), ("B", 0, 1), ("C", 0, 2), ("D", 0, 3), ("E", 0, 4), ("F", 0, 5), ("G", 0, 6),
    // Row 1  
    ("H", 1, 0), ("I", 1, 1), ("J", 1, 2), ("K", 1, 3), ("L", 1, 4), ("M", 1, 5), ("N", 1, 6),
    // Row 2 - O is skipped as it's the large one
    ("P", 2, 1), ("Q", 2, 2), ("R", 2, 3), ("S", 2, 4), ("T", 2, 5), ("U", 2, 6),
    // Row 3
    ("V", 3, 0), ("W", 3, 1), ("X", 3, 2), ("Y", 3, 3), ("Z", 3, 4)
]

for (letter, row, col) in letterPositions {
    let x = gridStartX + col * cellWidth
    let y = row * cellHeight
    
    let rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
    
    guard let croppedImage = cgImage.cropping(to: rect) else {
        print("Error: Could not crop image for letter \(letter)")
        continue
    }
    
    let letterImage = NSImage(cgImage: croppedImage, size: NSSize(width: cellWidth, height: cellHeight))
    
    guard let tiffData = letterImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Error: Could not convert to PNG for letter \(letter)")
        continue
    }
    
    let outputPath = "\(outputDir)/drop-cap-\(letter).png"
    
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Saved: drop-cap-\(letter).png")
    } catch {
        print("Error saving \(letter): \(error)")
    }
}

print("Extraction complete!")