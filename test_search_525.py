
import json
import urllib.request
import urllib.parse
import re

def lookup_album_tracks(collection_id):
    url = f"https://itunes.apple.com/lookup?id={collection_id}&entity=song"
    print(f"\n--- Testing Album Lookup ID: {collection_id} ---")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            print(f"Results found: {data['resultCount']}")
            for i, res in enumerate(data['results']):
                if res.get('wrapperType') == 'track':
                    print(f" {i}. {res.get('trackName')} - {res.get('artistName')} (ID: {res.get('trackId')})")
                else:
                    print(f" {i}. [{res.get('wrapperType').upper()}] {res.get('collectionName')}")
    except Exception as e:
        print(f"Error: {e}")

def fetch_itunes_preview(title, artist, year=None):
    term = f"{artist} {title}"
    clean_term = re.sub(r"\(.*?\)", "", term).strip()
    clean_term = re.sub(r"ft\..*", "", clean_term).strip()
    
    params = {
        'term': clean_term,
        'limit': 10,
        'media': 'music',
        'entity': 'song'
    }
    
    encoded_params = urllib.parse.urlencode(params)
    url = f"https://itunes.apple.com/search?{encoded_params}"
    
    print(f"\nSearching for: {clean_term} (Year filter: {year})")
    print(f"URL: {url}")
    
    try:
        req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            print(f"Results found: {data['resultCount']}")
            
            for i, res in enumerate(data['results']):
                r_date = res.get('releaseDate', '')
                r_year = r_date[:4] if r_date else 'Unknown'
                artist_name = res.get('artistName', 'Unknown')
                track_name = res.get('trackName', 'Unknown')
                print(f" {i+1}. {track_name} - {artist_name} ({r_year})")
                
                if artist and artist.lower() in artist_name.lower():
                    print(f"    [ARTIST MATCH]")
                
                if year:
                    if r_year == str(year):
                        print(f"    [YEAR MATCH]")
    except Exception as e:
        print(f"Error: {e}")

def search_artist_songs(artist_name, target_title):
    params = {
        'term': artist_name,
        'limit': 50,
        'media': 'music',
        'entity': 'song'
    }
    encoded_params = urllib.parse.urlencode(params)
    url = f"https://itunes.apple.com/search?{encoded_params}"
    print(f"\n--- Searching songs by artist: {artist_name} ---")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            print(f"Results found: {data['resultCount']}")
            
            for i, res in enumerate(data['results']):
                t_name = res.get('trackName', '')
                a_name = res.get('artistName', '')
                if target_title.lower() in t_name.lower():
                    print(f" [+] FOUND MATCH: {t_name} - {a_name} ({res.get('releaseDate', '')[:4]})")
                    print(f"     Preview: {res.get('previewUrl')}")
                    return res.get('previewUrl')
            print(" No match found in top 50 songs of artist.")
    except Exception as e:
        print(f"Error: {e}")
    return None

def lookup_id(track_id):
    url = f"https://itunes.apple.com/lookup?id={track_id}&media=music"
    print(f"\n--- Testing Lookup ID: {track_id} ---")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data['resultCount'] > 0:
                res = data['results'][0]
                print(f" Found: {res.get('trackName')} - {res.get('artistName')} ({res.get('releaseDate', '')[:4]})")
                print(f" Preview URL: {res.get('previewUrl')}")
            else:
                print(" No results found.")
    except Exception as e:
        print(f"Error: {e}")

def search_title_high_limit(title, target_artist):
    params = {
        'term': title,
        'limit': 200,
        'media': 'music',
        'entity': 'song'
    }
    encoded_params = urllib.parse.urlencode(params)
    url = f"https://itunes.apple.com/search?{encoded_params}"
    print(f"\n--- Searching title with high limit: {title} ---")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            print(f"Results found: {data['resultCount']}")
            
            for i, res in enumerate(data['results']):
                a_name = res.get('artistName', '')
                if target_artist.lower() in a_name.lower():
                    print(f" [+] FOUND MATCH at index {i+1}: {res.get('trackName')} - {a_name} ({res.get('releaseDate', '')[:4]})")
                    print(f"     Preview: {res.get('previewUrl')}")
                    return True
            print(" No match found in top 200 songs with this title.")
    except Exception as e:
        print(f"Error: {e}")
    return False

def search_album(artist_name, album_name):
    params = {
        'term': f"{artist_name} {album_name}",
        'limit': 5,
        'media': 'music',
        'entity': 'album'
    }
    encoded_params = urllib.parse.urlencode(params)
    url = f"https://itunes.apple.com/search?{encoded_params}"
    print(f"\n--- Searching album: {artist_name} - {album_name} ---")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            print(f"Results found: {data['resultCount']}")
            for i, res in enumerate(data['results']):
                print(f" {i+1}. {res.get('collectionName')} - {res.get('artistName')} (ID: {res.get('collectionId')})")
    except Exception as e:
        print(f"Error: {e}")

def search_artist_id(artist_name):
    params = {
        'term': artist_name,
        'limit': 1,
        'media': 'music',
        'entity': 'musicArtist'
    }
    encoded_params = urllib.parse.urlencode(params)
    url = f"https://itunes.apple.com/search?{encoded_params}"
    print(f"\n--- Searching artist ID: {artist_name} ---")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data['resultCount'] > 0:
                res = data['results'][0]
                print(f" Found: {res.get('artistName')} (ID: {res.get('artistId')})")
                return res.get('artistId')
            else:
                print(" Artist not found.")
    except Exception as e:
        print(f"Error: {e}")
    return None

def test_countries_for_song(title, artist):
    countries = ['US', 'AU', 'GB', 'SA', 'CA']
    for country in countries:
        params = {
            'term': f"{artist} {title}",
            'limit': 5,
            'media': 'music',
            'entity': 'song',
            'country': country
        }
        encoded_params = urllib.parse.urlencode(params)
        url = f"https://itunes.apple.com/search?{encoded_params}"
        print(f"\n--- Testing Country: {country} ---")
        try:
            req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode('utf-8'))
                print(f"Results found: {data['resultCount']}")
                for i, res in enumerate(data['results']):
                    print(f" {i+1}. {res.get('trackName')} - {res.get('artistName')} ({res.get('releaseDate', '')[:4]}) ID: {res.get('trackId')}")
        except Exception as e:
            print(f"Error: {e}")

def test_countries_for_album(artist_name, album_name):
    countries = ['US', 'AU', 'GB', 'SA', 'CA']
    for country in countries:
        params = {
            'term': f"{artist_name} {album_name}",
            'limit': 5,
            'media': 'music',
            'entity': 'album',
            'country': country
        }
        encoded_params = urllib.parse.urlencode(params)
        url = f"https://itunes.apple.com/search?{encoded_params}"
        print(f"\n--- Testing Country: {country} for Album: {album_name} ---")
        try:
            req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode('utf-8'))
                print(f"Results found: {data['resultCount']}")
                for i, res in enumerate(data['results']):
                    print(f" {i+1}. {res.get('collectionName')} - {res.get('artistName')} (ID: {res.get('collectionId')})")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    title = "California Gurls"
    artist = "Katy Perry ft. Snoop Dogg"
    
    print(f"Testing Search for: {title} by {artist}")
    fetch_itunes_preview(title, artist)
    
    # Try with cleaned title/artist as the script would
    fetch_itunes_preview("California Gurls", "Katy Perry")
