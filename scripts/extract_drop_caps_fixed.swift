#!/usr/bin/env swift

import Foundation
import AppKit

// Script to extract individual drop cap letters from the Freepik grid image
// The image has a large O on the left, then A-Z in a grid on the right

let inputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "../projects/Pergamene/Resources/DropCaps/drop-caps-alphabet.jpg"
let outputDir = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "../projects/Pergamene/Resources/DropCaps"

guard let inputImage = NSImage(contentsOfFile: inputPath) else {
    print("Error: Could not load image from \(inputPath)")
    exit(1)
}

let imageSize = inputImage.size
print("Image size: \(imageSize.width) x \(imageSize.height)")

// The large O on the left appears to take about 250px width
// The remaining grid is approximately 376px wide with 6 columns
let gridStartX: CGFloat = 250
let gridWidth = imageSize.width - gridStartX
let gridHeight = imageSize.height

// Grid is 6 columns x 4 rows (24 letters) + 2 more letters in row 5
let cols = 6
let rows = 5
let cellWidth = gridWidth / CGFloat(cols)
let cellHeight = gridHeight / CGFloat(rows)

print("Grid starts at x: \(gridStartX)")
print("Cell size: \(cellWidth) x \(cellHeight)")

// Letters A-Z in reading order (excluding O which is the large one)
let letters = Array("ABCDEFGHIJKLMNPQRSTUVWXYZ") // Note: O will be handled separately

// Create output directory if needed
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// First, extract the large O from the left side
guard let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Error: Could not get CGImage")
    exit(1)
}

// Extract the large O (approximately 0-250px width)
let oWidth: CGFloat = 240
let oHeight: CGFloat = 240
let oX: CGFloat = 5
let oY: CGFloat = 5

if let croppedO = cgImage.cropping(to: CGRect(x: oX, y: CGFloat(cgImage.height) - oY - oHeight, width: oWidth, height: oHeight)) {
    let oImage = NSImage(cgImage: croppedO, size: NSSize(width: oWidth, height: oHeight))
    
    if let tiffData = oImage.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
        
        let outputPath = "\(outputDir)/drop-cap-O.png"
        try? pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Saved: drop-cap-O.png (large)")
    }
}

// Extract the grid letters (A-N, P-Z)
var letterIndex = 0
for row in 0..<rows {
    for col in 0..<cols {
        // Skip cells that would be beyond our letter count
        if letterIndex >= letters.count {
            break
        }
        
        let letter = letters[letterIndex]
        letterIndex += 1
        
        let x = gridStartX + CGFloat(col) * cellWidth
        let y = CGFloat(row) * cellHeight
        
        guard let croppedCGImage = cgImage.cropping(to: CGRect(x: x, y: y, width: cellWidth, height: cellHeight)) else {
            print("Error: Could not crop image for letter \(letter)")
            continue
        }
        
        let croppedImage = NSImage(cgImage: croppedCGImage, size: NSSize(width: cellWidth, height: cellHeight))
        
        // Save as PNG
        guard let tiffData = croppedImage.tiffRepresentation,
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
}

print("Extraction complete!")