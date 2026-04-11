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
  {"query": "Dalia Mubarak Elly Yemshy 3ady", "title_ar": "اللي يمشي عادي"},
  {"query": "Dalia Mubarak Tra Haqi", "title_ar": "ترا حقي"},
  {"query": "Dalia Mubarak Ketha Momken", "title_ar": "كذا ممكن"},
  {"query": "Dalia Mubarak Ya Leil Ya Ein", "title_ar": "يا ليل يا عين"},
  {"query": "Dalia Mubarak Habiba", "title_ar": "حبيبة"},
  {"query": "Dalia Mubarak Areen Al Ashq", "title_ar": "عرين العشق"},
  {"query": "Dalia Mubarak Qaharni", "title_ar": "قهرني"},
  {"query": "Dalia Mubarak Khethni", "title_ar": "خذني"},
  {"query": "Dalia Mubarak Qalabt El Tawlah", "title_ar": "قلبت الطاولة"},
  {"query": "Dalia Mubarak Eshrit Sinin", "title_ar": "عشرة سنين"},
  {"query": "Dalia Mubarak Min El Akher", "title_ar": "من الآخر"}
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
