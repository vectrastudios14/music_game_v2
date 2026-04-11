import urllib.request
import urllib.parse
import json
import time
import sys
import codecs

# Force UTF-8 for console output
try:
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')
except Exception:
    pass

songs = [
  {"query": "Ayed Saqi Al Atash", "title_ar": "ساقي العطش"},
  {"query": "Ayed Talaat Fih", "title_ar": "طالعت فيه"},
  {"query": "Ayed Faman Allah", "title_ar": "فمان الله"},
  {"query": "Ayed Al Masafa", "title_ar": "المسافه"},
  {"query": "Ayed Gaza Allah Khair", "title_ar": "جزى الله خير"},
  {"query": "Ayed Lammah", "title_ar": "لماح"},
  {"query": "Ayed Ya Sahiby", "title_ar": "يا صاحبي"},
  {"query": "Ayed Wallah Ma Yirmish", "title_ar": "والله ما يرمش"},
  {"query": "Ayed Bel Moot Ja", "title_ar": "بالموت جا"},
  {"query": "Ayed Fazet Lak", "title_ar": "فزت لك"},
  {"query": "Ayed La Hawl Wala Qowa", "title_ar": "لا حول ولا قوة"},
  {"query": "Ayed Anan Al Sama", "title_ar": "عنان السما"}
]

print("Fetching links from iTunes...\n")

for song in songs:
    term = urllib.parse.quote(song["query"])
    url = f"https://itunes.apple.com/search?term={term}&media=music&entity=song&limit=1&country=SA"
    
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data["resultCount"] > 0:
                track = data["results"][0]
                print(f"**{song['title_ar']}** ({track.get('releaseDate', '')[:4]})")
                print(f"Link: {track.get('trackViewUrl')}")
                print(f"Preview: {track.get('previewUrl')}")
                print("-" * 20)
            else:
                print(f"**{song['title_ar']}** - Not Found")
                print("-" * 20)
    except Exception as e:
        print(f"Error fetching {song['query']}: {e}")
    
    time.sleep(1.5)
