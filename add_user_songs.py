import json
import urllib.request
import urllib.parse
import time
import random
import os
import re
import sys
from datetime import datetime
import codecs

# Force UTF-8 for console output
try:
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')
except Exception:
    pass

INPUT_FILE = 'songs_to_add.json'
LIBRARY_FILE = 'assets/songs_arabic.json'
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

def fetch_json(url):
    # Increased delay to 3-5 seconds to avoid 429 Rate Limit
    time.sleep(random.uniform(3.0, 5.0))
    try:
        req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        log(f"Error fetching: {e}")
    return None

def main():
    if not os.path.exists(INPUT_FILE):
        log("Input file not found.")
        return

    # Load input - use utf-8-sig to handle potential BOM
    with open(INPUT_FILE, 'r', encoding='utf-8-sig') as f:
        content = f.read()
        content = re.sub(r'//.*', '', content)
        try:
            new_songs_list = json.loads(content)
        except json.JSONDecodeError as e:
            log(f"JSON Decode Error: {e}")
            return

    # Load existing library - use utf-8-sig here too
    existing_songs = []
    if os.path.exists(LIBRARY_FILE):
        try:
            with open(LIBRARY_FILE, 'r', encoding='utf-8-sig') as f:
                existing_songs = json.load(f)
        except json.JSONDecodeError:
             # Try plain utf-8 if sig fails (unlikely if empty or manual edit)
             try:
                 with open(LIBRARY_FILE, 'r', encoding='utf-8') as f:
                    existing_songs = json.load(f)
             except:
                 log("Could not load existing library.")
                 return

    existing_ids = set(s['id'] for s in existing_songs)
    
    added_count = 0
    
    for item in new_songs_list:
        artist_query = item['artist']
        title_query = item['title']
        year_query = str(item['year'])
        
        query = f"{artist_query} {title_query}"
        term = urllib.parse.quote(query)
        
        # Search in Saudi Store
        url = f"https://itunes.apple.com/search?term={term}&media=music&entity=song&limit=5&country=SA"
        
        log(f"Searching: {query} ({year_query})...")
        data = fetch_json(url)
        
        best_match = None
        
        if data and data['resultCount'] > 0:
            for res in data['results']:
                r_date = res.get('releaseDate', '')
                r_year = r_date[:4] if r_date else ''
                
                if not res.get('previewUrl'):
                    continue
                
                try:
                    diff = abs(int(r_year) - int(year_query))
                    if diff <= 3: 
                         best_match = res
                         break
                except:
                    continue
            
            if not best_match and data['results']:
                 if data['results'][0].get('previewUrl'):
                     best_match = data['results'][0]
        
        if best_match:
            itunes_artist = best_match.get('artistName', artist_query)
            itunes_title = best_match.get('trackName', title_query)
            itunes_year = best_match.get('releaseDate', '')[:4]
            genre = best_match.get('primaryGenreName', 'Arabic')
            artwork = best_match.get('artworkUrl100', '').replace('100x100', '600x600')
            preview = best_match.get('previewUrl')
            
            idx = 1
            while True:
                new_id = f"ara_{itunes_year}_{idx}"
                if new_id not in existing_ids:
                    existing_ids.add(new_id)
                    break
                idx += 1
                
            new_song = {
                "id": new_id,
                "artist": itunes_artist, 
                "title": itunes_title,
                "artistAr": artist_query, 
                "titleAr": title_query,   
                "year": itunes_year,
                "styles": [genre],
                "link": preview,
                "artworkUrl": artwork
            }
            
            existing_songs.append(new_song)
            added_count += 1
            log(f"  [+] Added: {itunes_title} - {itunes_artist}")
            
        else:
            log(f"  [-] Not found or no preview: {query}")
            
    # Save back - use utf-8 to write
    with open(LIBRARY_FILE, 'w', encoding='utf-8') as f:
        json.dump(existing_songs, f, indent=4, ensure_ascii=False)
        
    log(f"Completed. Added {added_count} songs.")

if __name__ == '__main__':
    main()
