import json
import re
import os

path = r'C:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs_arabic.json'
output_path = r'C:\Users\kishi\OneDrive\Documents\music_game_v2\tmp\arabic_clues_review.txt'

with open(path, 'r', encoding='utf-8') as f:
    songs = json.load(f)

# Arabic years (Western digits) and era words
year_regex = re.compile(r'\b(19|20)\d{2}\b')
# Arabic words for: year, century, decade, 80s, 90s, 70s, 60s, 50s, era, decade, millennium
arabic_clue_words = [
    'سنة', 'عام', 'عقد', 'قرن', 'الألفية', 
    'الثمانينات', 'التسعينات', 'السبعينات', 'الستينات', 'الخمسينات', 
    'حقبة', 'منذ', 'بالألفية'
]

clue_matches = []
total_songs = len(songs)
matches_count = 0

for song in songs:
    facts = song.get('facts', [])
    found = False
    for fact in facts:
        if year_regex.search(fact):
            found = True
            break
        if any(word in fact for word in arabic_clue_words):
            found = True
            break
    
    if found:
        matches_count += 1
        clue_matches.append(f"--- {song.get('artist')} - {song.get('title')} ---")
        for fact in facts:
            clue_matches.append(fact)
        clue_matches.append("")

print(f"Total Arabic Songs: {total_songs}")
print(f"Songs with Time References: {matches_count}")

with open(output_path, 'w', encoding='utf-8') as f:
    f.write("\n".join(clue_matches))
