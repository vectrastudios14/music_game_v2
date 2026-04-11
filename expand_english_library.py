import json
import requests
import time
import random
import os
import re

SONGS_FILE = 'assets/songs.json'

def load_songs():
    if not os.path.exists(SONGS_FILE):
        print(f"Error: {SONGS_FILE} not found.")
        return []
    with open(SONGS_FILE, 'r', encoding='utf-8-sig') as f:
        return json.load(f)

def save_songs(songs):
    with open(SONGS_FILE, 'w', encoding='utf-8') as f:
        json.dump(songs, f, indent=4, ensure_ascii=False)

def clean_title(title):
    # Remove things like "Remastered", "Live", etc for comparison
    return re.sub(r'\(.*?\)', '', title).strip().lower()

def get_itunes_songs(artist_name):
    url = "https://itunes.apple.com/search"
    params = {
        "term": artist_name,
        "media": "music",
        "entity": "song",
        "limit": 20,
        "sort": "recent" # iTunes API 'recent' often gives popular hits too, or we can remove sort for default relevance/popularity
    }
    # Remove sort param to get default popularity sort
    del params["sort"]
    
    try:
        response = requests.get(url, params=params, timeout=10)
        if response.status_code == 200:
            return response.json().get('results', [])
    except Exception as e:
        print(f"Error searching for {artist_name}: {e}")
    return []

def main():
    print("Starting library expansion...")
    songs = load_songs()
    if not songs:
        return

    # 1. Identify unique artists and existing songs
    existing_artists = set()
    existing_keys = set() # (artist_lower, title_lower_cleaned)

    for s in songs:
        artist = s.get('artist', '')
        title = s.get('title', '')
        if artist:
            existing_artists.add(artist)
            existing_keys.add((artist.lower(), clean_title(title)))

    print(f"Found {len(existing_artists)} unique artists.")
    
    songs_added_count = 0
    
    # Sort artists to be deterministic or just process
    sorted_artists = sorted(list(existing_artists))

    for i, artist in enumerate(sorted_artists):
        print(f"[{i+1}/{len(sorted_artists)}] Processing: {artist}")
        
        results = get_itunes_songs(artist)
        
        # Filter and pick 2
        added_for_this_artist = 0
        
        for track in results:
            if added_for_this_artist >= 2:
                break
                
            t_artist = track.get('artistName', '')
            t_title = track.get('trackName', '')
            t_year = track.get('releaseDate', '')[:4]
            t_preview = track.get('previewUrl')
            t_artwork = track.get('artworkUrl100')
            
            if not t_preview:
                continue

            # Check strict matching to ensure it's the same artist (iTunes fuzzy search)
            if artist.lower() not in t_artist.lower():
                continue

            # Check if exists
            key = (artist.lower(), clean_title(t_title))
            if key in existing_keys:
                continue
                
            # Add new song
            new_id = f"ext_{t_year}_{int(time.time())}_{random.randint(100,999)}"
            new_song = {
                "id": new_id,
                "artist": artist, # Keep original artist name from our DB for consistency
                "title": t_title,
                "year": t_year,
                "styles": ["Pop"], # Default style
                "link": t_preview,
                "artworkUrl": t_artwork, # Assuming schema uses artworkUrl
                "previewUrl": t_preview
            }
            
            # Add to list and existing keys to prevent adding duplicate within this run
            songs.append(new_song)
            existing_keys.add(key)
            added_for_this_artist += 1
            songs_added_count += 1
            print(f"  + Added: {t_title} ({t_year})")
        
        # Sleep to avoid blocking
        time.sleep(1.5)
        
        # Save periodically every 5 artists to avoid data loss
        if (i + 1) % 5 == 0:
            save_songs(songs)
            print(f"  > Saved progress. Total added so far: {songs_added_count}")

    save_songs(songs)
    print(f"Finished! Total new songs added: {songs_added_count}")
    input("Press Enter to close window...")

if __name__ == "__main__":
    main()
