import json
import re

arabic_titles = {
    "Shoof Aothor": "شوف عذر",
    "Qanoon Kefak": "قانون كيفك",
    "Sawaha Qalbi": "سواها قلبي",
    "Kan Yhemny": "كان يهمني",
    "Shaghel Baly": "شاغل بالي",
    "Ethebny": "اتحبني",
    "Shokran": "شكرا",
    "Lahzat Alloqa": "لحظة اللقا",
    "Kabeer Al Shooq": "كبير الشوق",
    "Kabrtak Ala Sidak": "كبرتك على سيدك",
    "Al Sourah": "الصورة",
    "Jeetni Maksour": "جيتني مكسور",
    "Henain": "حنين",
    "Roh Najdya": "روح نجدية",
    "Sharha We Aatb": "شرهة وعتب",
    "Yamen Allah": "يامن الله",
    "Mabahabesh Had Ela Enta": "مابحبش حد الا انت",
    "Tsadeg": "تصدق",
    "Katabtak": "كتبتك",
    "Samehtak Keter": "سامحتك كتير"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new assala songs...")
    with open('assala_new.json', 'r', encoding='utf-8') as f:
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
