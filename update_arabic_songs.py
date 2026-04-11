import json
import re
import os

JSON_PATH = 'assets/songs_arabic.json'
MD_PATH = r'C:\Users\kishi\.gemini\antigravity\brain\a5f0ac58-4e2c-4182-b3cc-11a2c846f4ae\arabic_songs_review.md'

def main():
    if not os.path.exists(JSON_PATH):
        print(f"Error: {JSON_PATH} not found.")
        return

    if not os.path.exists(MD_PATH):
        print(f"Error: {MD_PATH} not found.")
        return

    # Load existing songs
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        songs = json.load(f)
    
    songs_map = {s['id']: s for s in songs}
    
    # Parse Markdown
    with open(MD_PATH, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    deleted_count = 0
    updated_count = 0
    
    # Locate table start
    table_start = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('| DELETE |'):
            table_start = i + 2 # Skip header and separator
            break
            
    if table_start == -1:
        print("Error: Markdown table not found.")
        return

    # Process rows
    current_ids = set()
    
    for line in lines[table_start:]:
        if not line.strip().startswith('|'): continue
        
        parts = [p.strip() for p in line.split('|')]
        # | [ ] | ID | Artist | Title | TitleAr | ArtistAr | Link |
        # parts indices: 0="", 1="[ ]", 2="ID", 3="Artist", 4="Title", 5="TitleAr", 6="ArtistAr", ...
        
        if len(parts) < 7: continue
        
        is_deleted = '[x]' in parts[1].lower()
        song_id = parts[2]
        title_ar = parts[5]
        artist_ar = parts[6]
        
        if song_id not in songs_map:
            continue

        if is_deleted:
            del songs_map[song_id]
            deleted_count += 1
        else:
            current_ids.add(song_id)
            song = songs_map[song_id]
            
            # Update fields if changed
            if song.get('titleAr') != title_ar or song.get('artistAr') != artist_ar:
                song['titleAr'] = title_ar
                song['artistAr'] = artist_ar
                updated_count += 1

    # Reconstruct list preserving original order (minus deleted)
    # Actually, better to just use the map values, but order might change.
    # Let's simple filter the original list to preserve order for remaining items
    final_list = []
    
    # We use a trick: iterating over the original list logic might be complex if we rely solely on map.
    # Simplest: Just use values from map.
    final_list = list(songs_map.values())
    
    # Sort by ID to keep it tidy or Year? Original was loosely sorted.
    # Let's sort by Year then ID
    final_list.sort(key=lambda x: (x.get('year', '0'), x['id']))

    with open(JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(final_list, f, indent=4, ensure_ascii=False)

    print(f"Success! Deleted: {deleted_count}, Updated Metadata: {updated_count}")

if __name__ == '__main__':
    main()
