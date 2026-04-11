import json
import re

def count_time_references():
    path = r'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json'
    with open(path, 'r', encoding='utf-8') as f:
        songs = json.load(f)

    year_pattern = re.compile(r'\b(19|20)\d{2}\b')
    era_pattern = re.compile(r'\b\d{2}\'?s\b|nineties|eighties|seventies|sixties|fifties|era|decade|century|millennium', re.IGNORECASE)

    count = 0
    total_songs = len(songs)
    matching_songs = []

    for song in songs:
        trivia = song.get('triviaFact', '')
        if year_pattern.search(trivia) or era_pattern.search(trivia):
            count += 1
            matching_songs.append({
                'artist': song.get('artist', 'Unknown'),
                'title': song.get('title', 'Unknown'),
                'year': song.get('year', 'Unknown'),
                'trivia': trivia
            })

    print(f"Total English Songs: {total_songs}")
    print(f"Songs with Time References: {count}")
    print("\nSample of matched songs:")
    for s in matching_songs[:10]:
        print(f"- {s['artist']} - {s['title']} ({s['year']}): {s['trivia']}")

if __name__ == "__main__":
    count_time_references()
