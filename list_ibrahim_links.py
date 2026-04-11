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
  {"query": "Ibrahim Al Hakami Sho Beni", "title_ar": "شو بني"},
  {"query": "Ibrahim Al Hakami Mahma Teb3ed", "title_ar": "مهما تبعد"},
  {"query": "Ibrahim Al Hakami Alla Yejazeek", "title_ar": "الله يجازيك"},
  {"query": "Ibrahim Al Hakami Lawaatini", "title_ar": "لوعتني"},
  # {"query": "Ibrahim Al Hakami Al Qadiya", "title_ar": "القضية"}, # Might be album name primarily
  {"query": "Ibrahim Al Hakami Shta2telik", "title_ar": "اشتقتلك"},
  {"query": "Ibrahim Al Hakami Makhloq Eli", "title_ar": "مخلوق الي"},
  {"query": "Ibrahim Al Hakami Ghareeba Ya Donia", "title_ar": "غريبة يا دنيا"},
  {"query": "Ibrahim Al Hakami Aasher Safha", "title_ar": "عاشر صفحة"},
  {"query": "Ibrahim Al Hakami Shokran", "title_ar": "شكراً"},
  {"query": "Ibrahim Al Hakami Ya Ain", "title_ar": "يا عين"}, # Famous one too
  {"query": "Ibrahim Al Hakami Samehni", "title_ar": "سامحني"}
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
