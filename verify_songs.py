import json

def verify_songs():
    try:
        with open('assets/songs.json', 'r', encoding='utf-8') as f:
            songs = json.load(f)
        
        missing_year_count = 0
        songs_with_missing_year = []
        
        for song in songs:
            if 'year' not in song or not song['year']:
                missing_year_count += 1
                songs_with_missing_year.append(song.get('title', 'Unknown Title'))
        
        if missing_year_count == 0:
            print(f"SUCCESS: All {len(songs)} songs have a release year.")
        else:
            print(f"FAILURE: {missing_year_count} songs are missing a release year.")
            for title in songs_with_missing_year[:10]:
                print(f" - {title}")
            if len(songs_with_missing_year) > 10:
                print(f" ... and {len(songs_with_missing_year) - 10} more.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    verify_songs()
