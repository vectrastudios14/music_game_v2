
import requests
import re
import json

url = "https://music.apple.com/us/album/dont-let-me-down-feat-daya/1105943809?i=1105944163"

def debug_fetch(input_url):
    print(f"Input URL: {input_url}")
    
    # Simulate regex logic
    lookup_id = None
    if "apple.com" in input_url or "itunes.com" in input_url:
        # Priority 1: i=...
        track_match = re.search(r'i=(\d+)', input_url)
        if track_match:
            lookup_id = track_match.group(1)
            print(f"Found Track ID (i=): {lookup_id}")
        else:
            # Priority 2: id...
            id_match = re.search(r'id(\d+)', input_url)
            if id_match:
                lookup_id = id_match.group(1)
                print(f"Found Album/Generic ID (id): {lookup_id}")

    if not lookup_id:
        print("No ID found.")
        return

    # Call iTunes API
    api_url = f"https://itunes.apple.com/lookup?id={lookup_id}&media=music"
    print(f"Calling API: {api_url}")
    
    try:
        response = requests.get(api_url)
        data = response.json()
        
        if data['resultCount'] > 0:
            result = data['results'][0]
            print("\n--- API Result ---")
            print(f"Artist: {result.get('artistName')}")
            print(f"Track: {result.get('trackName')}")
            print(f"Collection: {result.get('collectionName')}")
            print(f"Kind: {result.get('kind')}")
            print(f"Preview URL: {result.get('previewUrl')}")
            
            if result.get('previewUrl'):
                print("\nSUCCESS: Found preview URL.")
            else:
                print("\nFAILURE: No preview URL in result.")
        else:
            print("No results found from API.")
            
    except Exception as e:
        print(f"Error: {e}")

debug_fetch(url)
