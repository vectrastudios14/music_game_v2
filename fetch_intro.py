import urllib.request
import json
import urllib.parse

def fetch_preview(term):
    query = urllib.parse.quote(term)
    url = f"https://itunes.apple.com/search?term={query}&media=music&limit=1"
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            if data['resultCount'] > 0:
                print(data['results'][0]['previewUrl'])
            else:
                print("No results found.")
    except Exception as e:
        print(f"Error: {e}")

fetch_preview("Uptown Funk Mark Ronson")
fetch_preview("Happy Pharrell Williams")
