import json
import re

arabic_titles = {
    "Ya Hobi Lk": "يا حبي لك",
    "Bada Yehbny": "بدا يحبني",
    "Al Qarar Al Saab": "القرار الصعب",
    "Zalmtoni": "ظلمتوني",
    "Tair Al Saed": "طير السعد",
    "Bade Yehbni": "بدي يحبني",
    "Ya Hally": "يا حلي",
    "He Wa Hi Wa Ho": "هي و هي و هو",
    "Basharone": "بشروني",
    "Emta Ana Ashofik": "امتى انا اشوفك",
    "Al Mahba": "المحبة",
    "Layale Al Sahare": "ليالي السهاري",
    "Jani Alasmar": "جاني الأسمر",
    "Alashanah": "علشانه",
    "Thaleth Youm": "ثالث يوم",
    "Sonbalan": "سنبلان",
    "Shakankari": "شكنكاري",
    "Sheraa": "شراع",
    "Lahtat Altedeea": "لحظة التوديع",
    "Matar Al Ain": "مطر العين"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new etab songs...")
    with open('etab_new.json', 'r', encoding='utf-8') as f:
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
