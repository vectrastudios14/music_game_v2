import json
import re

arabic_titles = {
    "El Watar El Hassas": "الوتر الحساس",
    "Kolly Melkak": "كلي ملكك",
    "Halawat Al Dounia": "حلاوة الدنيا",
    "Garrabte Teabead": "جربت تبعد",
    "Ya Sababeen El Shay": "يا صبابين الشاي",
    "Ala Baly": "على بالي",
    "2al Sa3aban 3aleh": "قال صعبان عليه",
    "Mashaier": "مشاعر",
    "Ya Betfaker Ya Bet7es": "يا بتفكر يا بتحس",
    "Eh Eh": "إيه إيه",
    "Katar Khaere": "كتر خيري",
    "Ah Ya Leil": "آه يا ليل",
    "Kol Maghanni": "كل ما أغني",
    "Kol Ma Aghani": "كل ما أغني", # duplicate or alternative naming
    "Enkatble Aomr": "انكتبلي عمر",
    "Wahda Be Wahda": "واحدة بواحدة",
    "Bi Kelma Menak": "بكلمة منك",
    "Ana Mesh Bitaat El Kalam Dah (Remix)": "أنا مش بتاعة الكلام ده",
    "Wel Nabi Law Gani": "والنبي لو جاني"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new sherine songs...")
    with open('sherine_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    for song in new_songs:
        original_title = song['title']
        
        if original_title in arabic_titles:
            song['titleAr'] = arabic_titles[original_title]
        else:
            print(f"Warning: No translation for {original_title}")
            
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
