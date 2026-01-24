import json
import urllib.request
import urllib.parse
import time
import random
import os

SONGS_FILE = 'assets/songs.json'
ITUNES_URL = 'https://itunes.apple.com/search'

def load_songs():
    with open(SONGS_FILE, 'r', encoding='utf-8-sig') as f:
        return json.load(f)

def save_songs(songs):
    with open(SONGS_FILE, 'w', encoding='utf-8') as f:
        json.dump(songs, f, indent=4)
    print(f"Saved {len(songs)} songs to {SONGS_FILE}")

def get_itunes_year(artist, title):
    query = f"{artist} {title}"
    params = urllib.parse.urlencode({'term': query, 'media': 'music', 'limit': '1'})
    url = f"{ITUNES_URL}?{params}"
    
    try:
        # Use a timeout of 10 seconds
        with urllib.request.urlopen(url, timeout=10) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                if data['resultCount'] > 0:
                    result = data['results'][0]
                    release_date = result.get('releaseDate') # Format: 1978-11-10T08:00:00Z
                    if release_date and len(release_date) >= 4:
                        return release_date[:4]
    except Exception as e:
        print(f"Error fetching {query}: {e}")
    return None

def main():
    if not os.path.exists(SONGS_FILE):
        print(f"File not found: {SONGS_FILE}")
        return

    songs = load_songs()
    count = 0
    updated_count = 0
    
    # Filter for songs that need fixing (1970)
    to_fix = [s for s in songs if s.get('year') == '1970']
    
    print(f"Found {len(to_fix)} songs with year '1970' out of {len(songs)} total.")
    
    if not to_fix:
        print("No songs to fix!")
        return

    print("Starting human-like correction... (Press Ctrl+C to stop safely)")
    
    try:
        for song in songs:
            if song.get('year') == '1970':
                artist = song.get('artist')
                title = song.get('title')
                
                print(f"[{count+1}/{len(to_fix)}] Fixing: {artist} - {title}...", end='', flush=True)
                
                year = get_itunes_year(artist, title)
                
                if year:
                    song['year'] = year
                    print(f" FOUND: {year}")
                    updated_count += 1
                else:
                    print(f" NOT FOUND (keeping 1970)")
                
                count += 1
                
                # Auto-save every 10 songs to be safe
                if updated_count % 10 == 0 and updated_count > 0:
                    save_songs(songs)
                
                # HUMAN DELAY: 1.5 to 3.5 seconds
                delay = random.uniform(1.5, 3.5)
                time.sleep(delay)

    except KeyboardInterrupt:
        print("\nStopping early...")
    finally:
        save_songs(songs)
        print(f"\nDone. Updated {updated_count} songs.")

if __name__ == '__main__':
    main()
