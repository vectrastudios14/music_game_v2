import json

def get_artists(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return sorted(list(set(song['artist'] for song in data)))

arabic_artists = get_artists('assets/songs_arabic.json')
english_artists = get_artists('assets/songs.json')

print("--- ARABIC ARTISTS ---")
for a in arabic_artists:
    print(a)

print("\n--- ENGLISH ARTISTS ---")
for a in english_artists:
    print(a)
