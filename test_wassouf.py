import urllib.request
import json
import urllib.parse

def search_itunes(term, entity='song', limit=50):
    url = f"https://itunes.apple.com/search?term={urllib.parse.quote(term)}&entity={entity}&limit={limit}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            return data.get('results', [])
    except Exception as e:
        print(f"Error: {e}")
        return []

results = search_itunes("George Wassouf")
songs = []
for r in results:
    if r.get('wrapperType') == 'track':
        songs.append({
            'artistName': r.get('artistName'),
            'trackName': r.get('trackName'),
            'releaseDate': r.get('releaseDate', '')[:4],
            'previewUrl': r.get('previewUrl'),
            'artworkUrl100': r.get('artworkUrl100')
        })

for i, s in enumerate(songs[:20]):
    print(f"{i+1}. {s['artistName']} - {s['trackName']} ({s['releaseDate']})")
