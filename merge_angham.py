import json
import re

arabic_titles = {
    "هو انت مين": "هو انت مين",
    "Sidi Wesalak": "سيدي وصالك",
    "W Nefdal Norkos": "ونفضل نرقص",
    "Omry Maak": "عمري معاك",
    "أحلامنا (feat. Cairokee)": "أحلامنا",
    "تيجي نسيب": "تيجي نسيب",
    "Loha Bahta": "لوحة باهتة",
    "Sebtely Alby": "سبتلي قلبي",
    "خليني شوية معاك": "خليني شوية معاك",
    "Seebk Enta": "سيبك انت",
    "خليك معاها": "خليك معاها",
    "نسينا نعيش": "نسينا نعيش",
    "Galbi Maai": "قلبي معي",
    "كان برئ": "كان برئ",
    "بقالك قلب": "بقالك قلب",
    "Bahebak We Bartahlak": "بحبك وبرتاحلك",
    "اسكت": "اسكت",
    "Ana Baatoh Kteer": "انا بعته كتير",
    "ايه الأخبار": "ايه الأخبار",
    "Arrafha Beya": "عرفها بيا"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new angham songs...")
    with open('angham_new.json', 'r', encoding='utf-8') as f:
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
