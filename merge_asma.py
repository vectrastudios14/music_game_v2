import json
import re

arabic_titles = {
    "Adri": "أدري",
    "Safi": "صافي",
    "Awal Esheq": "أول عشق",
    "Ha Hna Jina": "ها حنا جينا",
    "Hakawa": "حكاوا",
    "We9tach": "وقتاش",
    "Wana Maak": "وانا معاك",
    "Kahel Al Thalam": "كحل الظلام",
    "Ahebah Mout": "احبه موت",
    "Abeek La": "ابيك لى",
    "Derti Liya Tayara": "درتي ليا الطيارة",
    "Thalath Marat": "ثلاث مرات",
    "Zahab": "ذهب",
    "Ayouno": "عيونو",
    "Ala Ma Athen": "على ما اظن",
    "Samt El Walah": "صمت الوله",
    "Sid Lghram": "سيد الغرام",
    "Galbi Kebeer": "قلبي كبير",
    "Hada Hali Min Baadak": "هذا حالي من بعدك",
    "Ya Ben Sidi": "يا بن سيدي"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new asma songs...")
    with open('asma_new.json', 'r', encoding='utf-8') as f:
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
