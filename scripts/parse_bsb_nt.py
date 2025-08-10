#!/usr/bin/env python3
"""
Parse BSB Excel file to extract New Testament books into JSON format
"""

import json
import sys
import pandas as pd
from pathlib import Path

def parse_bsb_nt(excel_path, output_path):
    """Parse BSB Excel file and extract NT books"""
    
    print(f"Reading BSB Excel file from {excel_path}...")
    df = pd.read_excel(excel_path, sheet_name='BSB')
    
    # The BSB Excel has columns: Book, Chapter, Verse, Text
    print(f"Loaded {len(df)} verses")
    
    # NT books start with Matthew (book 40 in Protestant order, but varies in BSB)
    # Let's identify NT books by name
    nt_books = [
        'Matthew', 'Mark', 'Luke', 'John', 'Acts',
        'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
        'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
        '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
        'Hebrews', 'James', '1 Peter', '2 Peter',
        '1 John', '2 John', '3 John', 'Jude', 'Revelation'
    ]
    
    # Filter to NT books only
    nt_df = df[df['Book'].isin(nt_books)]
    print(f"Found {len(nt_df)} NT verses")
    
    # Build the structure
    books = {}
    for book_name in nt_books:
        book_df = nt_df[nt_df['Book'] == book_name]
        if book_df.empty:
            continue
            
        chapters = {}
        for chapter_num in book_df['Chapter'].unique():
            chapter_df = book_df[book_df['Chapter'] == chapter_num]
            verses = []
            for _, row in chapter_df.iterrows():
                verses.append({
                    'number': int(row['Verse']),
                    'text': str(row['Text']).strip()
                })
            chapters[str(chapter_num)] = verses
        
        books[book_name] = {
            'name': book_name,
            'chapters': chapters
        }
    
    # Save to JSON
    print(f"Writing NT data to {output_path}...")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(books, f, indent=2, ensure_ascii=False)
    
    print(f"Successfully extracted {len(books)} NT books")
    
    # Print summary
    for book_name in books:
        num_chapters = len(books[book_name]['chapters'])
        num_verses = sum(len(ch) for ch in books[book_name]['chapters'].values())
        print(f"  {book_name}: {num_chapters} chapters, {num_verses} verses")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python parse_bsb_nt.py <excel_file> <output_json>")
        sys.exit(1)
    
    excel_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    
    if not excel_path.exists():
        print(f"Error: Excel file not found: {excel_path}")
        sys.exit(1)
    
    try:
        parse_bsb_nt(excel_path, output_path)
    except ImportError:
        print("Error: Required libraries not installed")
        print("Run: pip3 install pandas openpyxl")
        sys.exit(1)
    except Exception as e:
        print(f"Error parsing BSB: {e}")
        sys.exit(1)