#!/usr/bin/env python3

"""
Parse BSB Excel file and extract New Testament books to JSON format
"""

import sys
import json
import pandas as pd
from pathlib import Path

def parse_bsb(excel_path, output_path):
    """Parse BSB Excel file and extract NT books"""
    
    # Read Excel file
    df = pd.read_excel(excel_path)
    
    # BSB Excel format has columns: Book, Chapter, Verse, Text
    books = {}
    current_book = None
    current_chapter = None
    current_verses = []
    
    # NT book names and abbreviations
    nt_books = {
        'Matthew': 'Matt', 'Mark': 'Mark', 'Luke': 'Luke', 'John': 'John',
        'Acts': 'Acts', 'Romans': 'Rom', '1 Corinthians': '1Cor', '2 Corinthians': '2Cor',
        'Galatians': 'Gal', 'Ephesians': 'Eph', 'Philippians': 'Phil', 'Colossians': 'Col',
        '1 Thessalonians': '1Thess', '2 Thessalonians': '2Thess', '1 Timothy': '1Tim',
        '2 Timothy': '2Tim', 'Titus': 'Titus', 'Philemon': 'Phlm', 'Hebrews': 'Heb',
        'James': 'Jas', '1 Peter': '1Pet', '2 Peter': '2Pet', '1 John': '1John',
        '2 John': '2John', '3 John': '3John', 'Jude': 'Jude', 'Revelation': 'Rev'
    }
    
    for _, row in df.iterrows():
        book_name = row.get('Book', '')
        chapter_num = row.get('Chapter', 0)
        verse_num = row.get('Verse', 0)
        text = row.get('Text', '')
        
        # Skip if not a NT book
        if book_name not in nt_books:
            continue
            
        # Initialize book if new
        if book_name not in books:
            books[book_name] = {
                'name': book_name,
                'abbreviation': nt_books[book_name],
                'testament': 'New',
                'chapters': {}
            }
        
        # Initialize chapter if new
        if chapter_num not in books[book_name]['chapters']:
            books[book_name]['chapters'][chapter_num] = []
        
        # Add verse
        books[book_name]['chapters'][chapter_num].append({
            'number': verse_num,
            'text': text
        })
    
    # Convert to list format
    book_list = []
    for book_name, book_data in books.items():
        chapters = []
        for chapter_num in sorted(book_data['chapters'].keys()):
            chapters.append({
                'number': chapter_num,
                'verses': book_data['chapters'][chapter_num]
            })
        
        book_list.append({
            'name': book_data['name'],
            'abbreviation': book_data['abbreviation'],
            'testament': book_data['testament'],
            'chapters': chapters
        })
    
    # Save to JSON
    with open(output_path, 'w') as f:
        json.dump(book_list, f, indent=2)
    
    print(f"Parsed {len(book_list)} NT books from BSB")
    return book_list

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: parse_bsb.py <excel_file> <output_json>")
        sys.exit(1)
    
    excel_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        parse_bsb(excel_file, output_file)
        print(f"Successfully saved to {output_file}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)