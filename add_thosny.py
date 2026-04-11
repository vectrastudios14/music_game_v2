import json
import urllib.request
import urllib.parse
import time
import sys
import codecs

try:
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')
except Exception:
    pass

def search_itunes(term, limit=100):
    url = f"https://itunes.apple.com/search?term={urllib.parse.quote(term)}&entity=song&limit={limit}&country=eg"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode('utf-8')).get('results', [])
    except Exception as e:
        print(f"Error: {e}")
        return []

def get_arabic_metadata(track_id):
    url = f"https://itunes.apple.com/lookup?id={track_id}&lang=ar_sa&country=eg"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8')).get('results', [])
            if data:
                return data[0].get('trackName', ''), data[0].get('artistName', '')
    except:
        pass
    return '', ''

def main():
    print("Fetching songs for Tamer Hosny...")
    results = search_itunes("Tamer Hosny")
    results.extend(search_itunes("تامر حسني"))
    
    with open('assets/songs_arabic.json', 'r', encoding='utf-8') as f:
        existing_songs = json.load(f)
        
    existing_titles = {s['title'].lower() for s in existing_songs if 'Tamer' in s.get('artist', '') or 'تامر' in s.get('artistAr', '')}
    
    new_songs = []
    
    base_id = "ara_thosny"
    count = 1
    album_counts = {}
    
    for r in results:
        if len(new_songs) >= 20:
            break
            
        title = r.get('trackName', '')
        artist = r.get('artistName', '')
        album = r.get('collectionName', 'Unknown Album')
        
        # Check if artist is exactly Tamer Hosny or تامر حسني to prevent matching with similar names
        if artist != 'Tamer Hosny' and artist != 'تامر حسني':
            if 'tamer' not in artist.lower() and 'تامر' not in artist:
                continue
            
        if title.lower() in existing_titles:
            continue
            
        # Implementing max 2 songs per album limit
        if album_counts.get(album, 0) >= 2:
            print(f"Skipping {title} - Album limit reached for {album}")
            continue
            
        track_id = r.get('trackId')
        title_ar, artist_ar = get_arabic_metadata(track_id)
        
        if not title_ar: title_ar = title
        if not artist_ar: artist_ar = 'تامر حسني'
        
        preview_url = r.get('previewUrl')
        if not preview_url: continue
        
        year = r.get('releaseDate', '')[:4]
        artwork = r.get('artworkUrl100', '').replace('100x100', '600x600')
        genre = r.get('primaryGenreName', 'Arabic')
        
        song = {
            "id": f"{base_id}_{count}",
            "artist": artist,
            "title": title,
            "artistAr": "تامر حسني",
            "titleAr": title_ar,
            "year": year,
            "styles": [genre] if genre else ["ArabicPop", "Egyptian"],
            "link": preview_url,
            "artworkUrl": artwork
        }
        
        new_songs.append(song)
        existing_titles.add(title.lower())
        album_counts[album] = album_counts.get(album, 0) + 1
        count += 1
        
        print(f"Added: {title_ar} - {title} ({year}) [Album: {album}]")
        time.sleep(0.5)
        
    print(f"\nFetched {len(new_songs)} songs.")
    
    with open('thosny_new.json', 'w', encoding='utf-8') as f:
        json.dump(new_songs, f, indent=4, ensure_ascii=False)
        
    print("Saved to thosny_new.json.")

if __name__ == "__main__":
    main()
