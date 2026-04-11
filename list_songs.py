import json

try:
    with open('assets/songs.json', 'r', encoding='utf-8') as f:
        songs = json.load(f)
        print(f"Total songs: {len(songs)}")
        for song in songs:
            print(f"{song['id']}|{song['title']}|{song['artist']}")
except Exception as e:
    print(f"Error: {e}")
