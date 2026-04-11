import json
import re

arabic_titles = {
    "Qesat Al Saa": "قصة الساعة",
    "Teer Alshog": "طير الشوق",
    "Thahab": "ذهب ذهب",
    "Eshtaqt Lk": "اشتقت لك",
    "Ma Knt Adry": "ما كنت أدري",
    "Ahebah Kolesh": "أحبه كلش",
    "Enti Enti": "إنتي إنتي",
    "Amana": "أمانة",
    "Qabel Saah": "قبل ساعة",
    "Mutashikh": "متشخص",
    "Naweet El Buad": "نويت البعد",
    "Yerdon": "يردون",
    "Shay Fee Galbi": "شي في قلبي",
    "Dahekat El Omr": "ضحكة العمر",
    "Swalef Al Lel": "سوالف الليل",
    "Ya Zaalan": "يا زعلان",
    "Al Qadi Radey": "القاضي راضي",
    "Kel Youm": "كل يوم",
    "Ghdrtini": "غدرتيني",
    "Ya Bu Elmalga": "يا بو الملجا"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new walid songs...")
    with open('walid_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    for song in new_songs:
        original_title = song['title']
        
        # fix thahab
        if original_title == "Thahab":
             arabic_titles[original_title] = "ذهب ذهب"
             
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
