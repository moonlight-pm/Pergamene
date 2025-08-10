#!/usr/bin/env swift

import Foundation
import AppKit

// Script to extract individual drop cap letters from a grid image
// The image appears to be a 6x5 grid (30 cells total for 26 letters + decorative elements)

let inputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "../projects/Pergamene/Resources/DropCaps/drop-caps-alphabet.jpg"
let outputDir = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "../projects/Pergamene/Resources/DropCaps"

guard let inputImage = NSImage(contentsOfFile: inputPath) else {
    print("Error: Could not load image from \(inputPath)")
    exit(1)
}

let imageSize = inputImage.size
print("Image size: \(imageSize.width) x \(imageSize.height)")

// Assuming a 6x5 grid layout (6 columns, 5 rows)
let cols = 6
let rows = 5
let cellWidth = imageSize.width / CGFloat(cols)
let cellHeight = imageSize.height / CGFloat(rows)

print("Cell size: \(cellWidth) x \(cellHeight)")

// Letters A-Z in reading order
let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

// Create output directory if needed
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Extract each letter
for (index, letter) in letters.enumerated() {
    let row = index / cols
    let col = index % cols
    
    let x = CGFloat(col) * cellWidth
    let y = imageSize.height - CGFloat(row + 1) * cellHeight // Flip Y coordinate
    
    // Create a cropped image
    let cropRect = NSRect(x: x, y: y, width: cellWidth, height: cellHeight)
    
    guard let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Error: Could not get CGImage")
        continue
    }
    
    guard let croppedCGImage = cgImage.cropping(to: CGRect(x: x, y: CGFloat(cgImage.height) - y - cellHeight, width: cellWidth, height: cellHeight)) else {
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

print("Extraction complete!")