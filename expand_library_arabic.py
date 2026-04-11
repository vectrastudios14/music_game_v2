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

# --- Configuration ---
SONGS_FILE = r'assets/songs_arabic.json'
LOG_FILE = r'expansion_log_arabic.txt'
TARGET_PER_YEAR = 5  # Reduced target for "Right Now" speed, can increase later
START_YEAR = 1980    # Started a bit later for better digital availability
END_YEAR = 2025
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

known_ids = set()

def log(message):
    timestamp = datetime.now().strftime("%H:%M:%S")
    formatted_message = f"[{timestamp}] {message}"
    print(formatted_message)
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(formatted_message + "\n")
    except Exception:
        pass

def load_songs():
    if not os.path.exists(SONGS_FILE):
        return []
    with open(SONGS_FILE, 'r', encoding='utf-8') as f:
        try:
            return json.load(f)
        except:
            return []

def save_songs(songs):
    with open(SONGS_FILE, 'w', encoding='utf-8') as f:
        json.dump(songs, f, indent=4, ensure_ascii=False)

def fetch_json(url):
    time.sleep(random.uniform(0.5, 1.5)) # Polite delay
    try:
        req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        log(f"Error fetching {url}: {e}")
    return None

def has_arabic(text):
    if not text: return False
    return bool(re.search(r'[\u0600-\u06FF]', str(text)))

def expand_library():
    log("--- Starting STRICT Arabic Expansion ---")
    songs = load_songs()
    
    # Populate known IDs to avoid duplicates
    for s in songs:
        if 'id' in s:
            parts = s['id'].split('_') 
            if len(parts) > 1:
                # Store unique key based on title+artist to avoid dupes across IDs
                key = f"{s.get('artist', '')}{s.get('title', '')}"
                known_ids.add(key)

    total_added = 0
    countries = ['SA', 'EG', 'AE', 'LB'] # Saudi, Egypt, UAE, Lebanon
    
    # We will search year by year
    for year in range(START_YEAR, END_YEAR + 1):
        # Check how many we have for this year
        count = sum(1 for s in songs if str(s.get('year')) == str(year))
        if count >= TARGET_PER_YEAR:
            continue

        needed = TARGET_PER_YEAR - count
        log(f"Year {year}: Have {count}, Need {needed}")

        # Search Queries - Specific to Arabic
        queries = [
            f"Arabic Hits {year}",
            f"Top Arabic {year}",
            f"Best of Arabic {year}",
            f"أغاني {year}",
            f"{year} عربي"
        ]

        added_this_year = 0
        
        for q in queries:
            if added_this_year >= needed: break
            
            for country in countries:
                if added_this_year >= needed: break
                
                term = urllib.parse.quote(q)
                url = f"https://itunes.apple.com/search?term={term}&media=music&entity=song&limit=50&country={country}"
                
                data = fetch_json(url)
                if not data or 'results' not in data:
                    continue

                for track in data['results']:
                    if added_this_year >= needed: break
                    
                    # Basic Validation
                    if track.get('kind') != 'song': continue
                    if not track.get('previewUrl'): continue
                    
                    release_date = track.get('releaseDate', '')
                    if not release_date.startswith(str(year)): continue

                    track_id = track.get('trackId')
                    artist = track.get('artistName')
                    title = track.get('trackName')
                    genre = track.get('primaryGenreName', '')
                    
                    # STRICT FILTERING
                    
                    # 1. Fetch Arabic Localized Metadata
                    lookup_url = f"https://itunes.apple.com/lookup?id={track_id}&lang=ar_sa&country={country}"
                    local_data = fetch_json(lookup_url)
                    
                    artist_ar = artist
                    title_ar = title
                    
                    if local_data and 'results' in local_data and len(local_data['results']) > 0:
                        item = local_data['results'][0]
                        artist_ar = item.get('artistName', artist)
                        title_ar = item.get('trackName', title)

                    # 2. Check for Arabic Script
                    has_ar_script = has_arabic(artist_ar) or has_arabic(title_ar)
                    
                    # 3. Check for specific Arabic Genres (strict list)
                    is_ar_genre = any(g.lower() in genre.lower() for g in ['arabic', 'khaliji', 'maghreb', 'levant', 'raï', 'shaabi', 'dabke'])

                    # 4. Strict Decision Logic
                    # MUST have Arabic script OR be explicitly in an Arabic genre AND not be a known false positive genre
                    is_western_genre = any(g.lower() in genre.lower() for g in ['rock', 'country', 'alternative', 'metal', 'punk'])
                    
                    if is_western_genre and not has_ar_script:
                        continue # Skip "Rock" songs unless they have Arabic titles

                    if not (has_ar_script or is_ar_genre):
                        continue # Skip if neither script nor genre matches

                    # Check Duplicates
                    key = f"{artist}{title}"
                    if key in known_ids: continue
                    
                    # Add Song
                    new_id = f"ara_{year}_{len(songs) + 1}"
                    new_song = {
                        "id": new_id,
                        "artist": artist, 
                        "title": title,
                        "artistAr": artist_ar,
                        "titleAr": title_ar,
                        "year": str(year),
                        "styles": [genre] if genre else ["Arabic"],
                        "link": track.get('previewUrl'),
                        "artworkUrl": track.get('artworkUrl100', '').replace('100x100', '600x600')
                    }
                    
                    songs.append(new_song)
                    known_ids.add(key)
                    added_this_year += 1
                    total_added += 1
                    
                    log(f"  [+] Added: {title_ar} - {artist_ar} ({year}) [{genre}]")

        if added_this_year > 0:
            save_songs(songs)

    log(f"Expansion Finish. Total Added: {total_added}")

if __name__ == "__main__":
    expand_library()
