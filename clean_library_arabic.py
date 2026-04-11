import json
import re
import os

SONGS_FILE = 'assets/songs_arabic.json'
BACKUP_FILE = 'assets/songs_arabic_backup.json'

def has_arabic(text):
    if not text: return False
    return bool(re.search(r'[\u0600-\u06FF]', str(text)))

def clean_library():
    if not os.path.exists(SONGS_FILE):
        print(f"Error: {SONGS_FILE} not found.")
        return

    # Load
    with open(SONGS_FILE, 'r', encoding='utf-8') as f:
        songs = json.load(f)

    # Backup
    with open(BACKUP_FILE, 'w', encoding='utf-8') as f:
        json.dump(songs, f, indent=4, ensure_ascii=False)
    print(f"Backup created at {BACKUP_FILE}")

    original_count = len(songs)
    cleaned_songs = []

    for s in songs:
        artist_en = s.get('artist', '')
        title_en = s.get('title', '')
        genres = s.get('styles', [])
        
        # 1. Check for Arabic script in ORIGINAL fields
        ar_script_original = has_arabic(artist_en) or has_arabic(title_en)
        
        # 2. Check for Arabic genre
        is_ar_genre = any('arabic' in g.lower() or 'khaliji' in g.lower() or 'maghreb' in g.lower() or 'levant' in g.lower() for g in genres)
        
        if ar_script_original or is_ar_genre:
            cleaned_songs.append(s)
        else:
            print(f"Removing: {title_en} - {artist_en}")

    # Save
    with open(SONGS_FILE, 'w', encoding='utf-8') as f:
        json.dump(cleaned_songs, f, indent=4, ensure_ascii=False)

    print(f"\nCleaning Complete!")
    print(f"Original: {original_count}")
    print(f"Cleaned:  {len(cleaned_songs)}")
    print(f"Removed:  {original_count - len(cleaned_songs)}")

if __name__ == "__main__":
    clean_library()
