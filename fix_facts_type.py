
import json

def fix_types():
    path = r'assets/songs.json'
    try:
        with open(path, 'r', encoding='utf-8') as f:
            songs = json.load(f)
            
        fixed_count = 0
        for song in songs:
            facts = song.get('facts')
            if facts and isinstance(facts, str):
                song['facts'] = [facts]
                fixed_count += 1
                
        print(f"Fixed {fixed_count} songs where facts was a String.")
        
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(songs, f, indent=2)
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    fix_types()
