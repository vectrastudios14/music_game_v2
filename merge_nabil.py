import json
import re

arabic_titles = {
    "Sadeni": "صادني",
    "Nwrt Ya Halaha": "نورت يا حلاها",
    "Yally Tegool": "يااللي تقول",
    "Ya Hamad": "يا حمد",
    "Ana Ma Ansak": "أنا ما أنساك",
    "Al Shooq": "الشوق",
    "Alaah Ya Zanah": "الله يا زينه",
    "Aezer Al Nafas": "أعذر النفس",
    "Yhya Al Alam": "يحيى العلم",
    "Sabah Al Khear": "صباح الخير",
    "Ma Arwa'ak": "ما اروعك",
    "Al Esheg Yezbah": "العشق يذبح",
    "Wesh Mesawe": "وش مسوي",
    "Lelheen Ahebha": "للحين أحبها",
    "Alla Khear": "على خير",
    "Laubat Alaemi": "لعبة الأيام",
    "Gaany": "جاني",
    "Shuall": "شعيل",
    "Tabaan Gheir": "طبعا غير",
    "Elly Malah Awal": "اللي ماله أول"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new nabil songs...")
    with open('nabil_new.json', 'r', encoding='utf-8') as f:
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
