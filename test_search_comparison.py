
import json
import urllib.request
import urllib.parse
import re

def fetch_itunes_preview(title, artist, year=None, country='US'):
    term = f"{artist} {title}"
    clean_term = re.sub(r"\(.*?\)", "", term).strip()
    clean_term = re.sub(r"ft\..*", "", clean_term).strip()
    
    params = {
        'term': clean_term,
        'limit': 50,
        'media': 'music',
        'entity': 'song',
        'country': country
    }
    
    encoded_params = urllib.parse.urlencode(params)
    url = f"https://itunes.apple.com/search?{encoded_params}"
    
    print(f"\nSearching {country} Store for: {clean_term}")
    print(f"URL: {url}")
    
    try:
        req = urllib.request.Request(url, headers={'User-Agent': "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            print(f"Results found: {data['resultCount']}")
            
            found = False
            for i, res in enumerate(data['results']):
                t_name = res.get('trackName', '')
                a_name = res.get('artistName', '')
                r_year = res.get('releaseDate', '')[:4]
                
                # Check for match (fuzzy)
                if artist.lower() in a_name.lower() or a_name.lower() in artist.lower():
                    if title.lower() in t_name.lower() or t_name.lower() in title.lower():
                        print(f" [+] MATCH FOUND at index {i+1}: {t_name} - {a_name} ({r_year})")
                        print(f"     Preview: {res.get('previewUrl')}")
                        found = True
                        break
                
                if i < 10:
                    print(f"  {i+1}. {t_name} - {a_name} ({r_year})")
            
            if not found:
                print(" [-] Original NOT found in top 50.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    print("--- Testing \"The Less I Know The Better\" (Tame Impala) ---")
    fetch_itunes_preview("The Less I Know The Better", "Tame Impala", country='US')
    fetch_itunes_preview("The Less I Know The Better", "Tame Impala", country='SA')
    
    print("\n--- Testing \"California Gurls\" (Katy Perry) ---")
    fetch_itunes_preview("California Gurls", "Katy Perry", country='US')
    fetch_itunes_preview("California Gurls", "Katy Perry", country='SA')
