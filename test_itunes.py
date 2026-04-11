import requests
import json

url = "https://itunes.apple.com/search"
params = {
    "term": "tame impala the less i know the better",
    "limit": 5,
    "media": "music",
    "entity": "song"
}

try:
    response = requests.get(url, params=params)
    data = response.json()
    for result in data.get("results", []):
        print(f"Track: {result.get('trackName')}")
        print(f"Artist: {result.get('artistName')}")
        print(f"Kind: {result.get('kind')}")
        print(f"Media: {result.get('wrapperType')}")
        print(f"Preview: {result.get('previewUrl')}")
        print("-" * 20)
    if not data.get("results"):
        print("No results found.")
except Exception as e:
    print(f"Error: {e}")
