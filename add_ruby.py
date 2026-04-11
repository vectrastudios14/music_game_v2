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

def search_itunes_ae(term, limit=100): # Adding AE lookup too
    url = f"https://itunes.apple.com/search?term={urllib.parse.quote(term)}&entity=song&limit={limit}&country=ae"
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
    print("Fetching songs for Ruby...")
    results = search_itunes("Ruby")
    results.extend(search_itunes("روبي"))
    results.extend(search_itunes_ae("Ruby"))
    results.extend(search_itunes_ae("روبي"))
    
    with open('assets/songs_arabic.json', 'r', encoding='utf-8') as f:
        existing_songs = json.load(f)
        
    existing_titles = {s['title'].lower() for s in existing_songs if 'Ruby' in s.get('artist', '') or 'روبي' in s.get('artistAr', '')}
    
    new_songs = []
    
    base_id = "ara_ruby"
    count = 1
    
    for r in results:
        if len(new_songs) >= 20:
            break
            
        title = r.get('trackName', '')
        artist = r.get('artistName', '')
        album = r.get('collectionName', 'Unknown Album')
        
        genre = r.get('primaryGenreName', 'Arabic')
        if genre.lower() not in ['arabic pop', 'world', 'arabic', 'middle eastern', 'pop']:
            continue
        
        if artist.lower() != 'ruby' and artist != 'روبي' and artist != 'Ruby':
             if 'ruby' not in artist.lower() and 'روبي' not in artist:
                 continue
            
        if title.lower() in existing_titles:
            continue
            
        track_id = r.get('trackId')
        title_ar, artist_ar = get_arabic_metadata(track_id)
        
        if not title_ar: title_ar = title
        if not artist_ar: artist_ar = 'روبي'
        
        preview_url = r.get('previewUrl')
        if not preview_url: continue
        
        year = r.get('releaseDate', '')[:4]
        artwork = r.get('artworkUrl100', '').replace('100x100', '600x600')
        
        song = {
            "id": f"{base_id}_{count}",
            "artist": artist,
            "title": title,
            "artistAr": "روبي",
            "titleAr": title_ar,
            "year": year,
            "styles": [genre] if genre else ["ArabicPop", "Egyptian"],
            "link": preview_url,
            "artworkUrl": artwork
        }
        
        new_songs.append(song)
        existing_titles.add(title.lower())
        count += 1
        
        print(f"Added: {title_ar} - {title} ({year}) [Album: {album}]")
        time.sleep(0.5)
        
    print(f"\nFetched {len(new_songs)} songs.")
    
    with open('ruby_new.json', 'w', encoding='utf-8') as f:
        json.dump(new_songs, f, indent=4, ensure_ascii=False)
        
    print("Saved to ruby_new.json.")

if __name__ == "__main__":
    main()
