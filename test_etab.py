import json
import urllib.request
import urllib.parse
import sys
import codecs

try:
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')
except Exception:
    pass

def search_itunes(term, country="sa"):
    url = f"https://itunes.apple.com/search?term={urllib.parse.quote(term)}&entity=song&limit=10&country={country}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            results = json.loads(response.read().decode('utf-8')).get('results', [])
            for r in results:
                print(f"Artist: {r.get('artistName')} | Song: {r.get('trackName')}")
    except Exception as e:
        print(f"Error: {e}")

print("--- Etab (SA) ---")
search_itunes("Etab", "sa")
print("\n--- عتاب (SA) ---")
search_itunes("عتاب", "sa")
print("\n--- Etab (US) ---")
search_itunes("Etab", "us")
