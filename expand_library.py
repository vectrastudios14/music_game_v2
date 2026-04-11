import json
import urllib.request
import urllib.parse
import time
import random
import os
import re
from datetime import datetime

# --- Configuration ---
# --- Configuration ---
SONGS_FILE = r'assets/songs.json'
LOG_FILE = r'expansion_log.txt'
TARGET_PER_YEAR = 18
START_YEAR = 1970
END_YEAR = 2025
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

# Safety/Human-like settings
MIN_DELAY = 1.0
MAX_DELAY = 3.0
LONG_DELAY_THRESHOLD = 50 # request count
LONG_DELAY_MIN = 30
LONG_DELAY_MAX = 60

request_count = 0

def log(message):
    timestamp = datetime.now().strftime("%H:%M:%S")
    formatted_message = f"[{timestamp}] {message}"
    print(formatted_message)
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(formatted_message + "\n")
    except Exception:
        pass

def human_sleep():
    time.sleep(random.uniform(MIN_DELAY, MAX_DELAY))

def long_sleep_check():
    global request_count
    request_count += 1
    if request_count >= LONG_DELAY_THRESHOLD:
        sleep_time = random.uniform(LONG_DELAY_MIN, LONG_DELAY_MAX)
        log(f"\n[SAFETY] Taking a long break for {sleep_time:.1f}s...")
        time.sleep(sleep_time)
        request_count = 0

def fetch_json(url):
    human_sleep()
    long_sleep_check()
    try:
        req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        log(f"Error fetching {url}: {e}")
    return None

def search_albums(query, limit=5):
    params = urllib.parse.urlencode({
        'term': query,
        'media': 'music',
        'entity': 'album',
        'limit': limit
    })
    return fetch_json(f"https://itunes.apple.com/search?{params}")

def lookup_album_tracks(collection_id):
    params = urllib.parse.urlencode({
        'id': collection_id,
        'entity': 'song'
    })
    return fetch_json(f"https://itunes.apple.com/lookup?{params}")

def load_songs():
    if not os.path.exists(SONGS_FILE):
        return []
    with open(SONGS_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_songs(songs):
    with open(SONGS_FILE, 'w', encoding='utf-8') as f:
        json.dump(songs, f, indent=4)

def normalize(text):
    return re.sub(r'[^a-zA-Z0-9]', '', str(text)).lower()

def expand_library():
    # Append to log file on start
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write("\n--- Resuming Music Library Expansion ---\n")

    log("--- Expanding Music Library ---")
    songs = load_songs()
    
    # Analyze current library
    songs_by_year = {}
    known_keys = set()
    
    for s in songs:
        y = str(s.get('year', '0'))
        songs_by_year[y] = songs_by_year.get(y, 0) + 1
        # Create a unique key for dup check: normalized artist + title
        key = normalize(s.get('artist', '')) + normalize(s.get('title', ''))
        known_keys.add(key)

    total_added = 0
    
    for year in range(START_YEAR, END_YEAR + 1):
        s_year = str(year)
        count = songs_by_year.get(s_year, 0)
        needed = TARGET_PER_YEAR - count
        
        if needed <= 0:
            # log(f"Year {year}: {count} songs (SKIPPING - Sufficient)")
            continue
            
        log(f"Year {year}: {count} songs. Need {needed} more.")
        
        # Search strategies
        queries = [f"Hits of {year}", f"Best of {year}", f"{year} Hits", f"Billboard {year}"]
        
        added_for_year = 0
        
        for q in queries:
            if added_for_year >= needed:
                break
                
            log(f"  Searching albums for '{q}'...")
            results = search_albums(q)
            
            if not results or 'results' not in results:
                continue
                
            # Iterate albums
            for album in results['results']:
                if added_for_year >= needed:
                    break
                    
                coll_id = album.get('collectionId')
                coll_name = album.get('collectionName', 'Unknown')
                log(f"    Checking album: {coll_name}")
                
                tracks = lookup_album_tracks(coll_id)
                if not tracks or 'results' not in tracks:
                    continue
                    
                # results[0] is album, 1..N are songs
                for item in tracks['results'][1:]:
                    if added_for_year >= needed:
                        break
                        
                    if item.get('wrapperType') != 'track':
                        continue
                        
                    # Verify Year
                    # releaseDate format: "1970-01-23T08:00:00Z"
                    r_date = item.get('releaseDate', '')
                    if not r_date.startswith(s_year):
                        continue # Strict year match
                        
                    # Check Dup
                    artist = item.get('artistName', 'Unknown')
                    title = item.get('trackName', 'Unknown')
                    preview = item.get('previewUrl')
                    genre = item.get('primaryGenreName', 'Pop')
                    
                    if not preview:
                        continue
                        
                    key = normalize(artist) + normalize(title)
                    if key in known_keys:
                        continue
                        
                    # Add song
                    new_song = {
                        "id": f"auto_{year}_{len(songs) + total_added + 1}",
                        "artist": artist,
                        "year": s_year,
                        "styles": [genre],
                        "link": preview,
                        "title": title
                    }
                    
                    songs.append(new_song)
                    known_keys.add(key)
                    added_for_year += 1
                    total_added += 1
                    log(f"      [+] Added: {title} - {artist}")
        
        # Save after each year to be safe
        save_songs(songs)
        log(f"  Saved progress. Total added so far: {total_added}")
        
    log(f"\nExpansion Complete. Grand Total Added: {total_added}")

if __name__ == "__main__":
    expand_library()
