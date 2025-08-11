#!/bin/bash

# Generate all required iOS app icon sizes from a 1024x1024 source image
# Usage: ./generate-app-icons.sh

SOURCE_ICON="../Pergamene/Resources/AppIcon.png"
OUTPUT_DIR="../Pergamene/Resources/AppIcon.appiconset"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if source exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "Error: Source icon not found at $SOURCE_ICON"
    exit 1
fi

echo "Generating app icons from $SOURCE_ICON..."

# iPhone icons
sips -z 180 180 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-60@3x.png" > /dev/null
sips -z 120 120 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-60@2x.png" > /dev/null

# iPad icons (if needed in future)
sips -z 167 167 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-83.5@2x.png" > /dev/null
sips -z 152 152 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-76@2x.png" > /dev/null
sips -z 76 76 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-76.png" > /dev/null

# Settings icons
sips -z 87 87 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-29@3x.png" > /dev/null
sips -z 58 58 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-29@2x.png" > /dev/null
sips -z 29 29 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-29.png" > /dev/null

# Spotlight icons
sips -z 120 120 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-40@3x.png" > /dev/null
sips -z 80 80 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-40@2x.png" > /dev/null
sips -z 40 40 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-40.png" > /dev/null

# Notification icons
sips -z 60 60 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-20@3x.png" > /dev/null
sips -z 40 40 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-20@2x.png" > /dev/null
sips -z 20 20 "$SOURCE_ICON" --out "$OUTPUT_DIR/AppIcon-20.png" > /dev/null

# App Store icon (just copy the original)
cp "$SOURCE_ICON" "$OUTPUT_DIR/AppIcon-1024.png"

echo "App icons generated successfully in $OUTPUT_DIR"

# Create Contents.json for the icon set
cat > "$OUTPUT_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "Contents.json created"