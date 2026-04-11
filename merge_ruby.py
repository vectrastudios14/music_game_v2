import json
import re
import sys
import codecs

try:
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')
except Exception:
    pass

arabic_titles = {
    "Leih Beydary Keda": "ليه بيداري كده",
    "Enta Aaref Leih": "إنت عارف ليه",
    "Kol Ma Aollo Ah": "كل ما أقوله آه",
    "Ghawy": "غاوي",
    "Eba Abelny": "إبقى قابلني",
    "Ana Omry Mastaneit Had": "أنا عمري ما أستنيت حد",
    "Maiel Ya Liel": "ميل يا ليل",
    "Meshit Wara Ehsasy": "مشيت ورا إحساسي",
    "Nadl Wa Ayouta": "ندل وعيوطة",
    "Meshit Wara Ehsasy Oriental": "مشيت ورا إحساسي",
    "Mesh Hatedar": "مش هتقدر", 
    "Maly": "مالي",
    "Maly House": "مالي",
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new ruby songs...")
    with open('ruby_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    for song in new_songs:
        original_title = song['title']
        
        if original_title in arabic_titles:
            song['titleAr'] = arabic_titles[original_title]
        else:
            try:
                print(f"Warning: No translation for {original_title}")
            except UnicodeEncodeError:
                print("Warning: No translation for a song with Arabic characters in English title")
            
        song['title'] = clean_title(original_title)
    
    print("Reading songs_arabic.json...")
    with open('assets/songs_arabic.json', 'r', encoding='utf-8') as f:
        current_songs = json.load(f)

    current_songs.extend(new_songs)

    print("Saving songs_arabic.json...")
    with open('assets/songs_arabic.json', 'w', encoding='utf-8') as f:
        json.dump(current_songs, f, indent=4, ensure_ascii=False)

    print("Success. Run verify_songs.py to be sure.")

if __name__ == "__main__":
    main()
