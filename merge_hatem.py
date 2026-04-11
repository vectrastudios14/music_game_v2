import json
import re

arabic_titles = {
    "Shealoma": "شعلومة",
    "Berdak": "برضك",
    "Ya Taer": "يا طير",
    "Mhajer": "مهاجر",
    "Wahed Yeheb Wahed": "واحد يحب واحد",
    "Mawal Elrooh": "موال الروح",
    "Eldonia Ma Teswa": "الدنيا ما تسوى",
    "Shoof El Qahar": "شوف القهر",
    "Aakher Yoom": "اخر يوم",
    "Athal Mahboob": "اظل محبوب",
    "Sho Yaany": "شو يعني",
    "Ana Habetak": "انا حبيتك",
    "Al Qaleb Daeilak": "القلب داعيلك",
    "Dictory": "دكتوري",
    "Ma Yeswaa Damea": "ما يسوى دمعة",
    "La Yezaloon El Hbaieb": "لا يزعلون الحبايب",
    "Aghla Nasi": "اغلى ناسي",
    "Nom Ma Nemet": "نوم ما نمت",
    "Ad El Maam": "عض المام",
    "Shayeb Rasi": "شايب راسي"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new hatem songs...")
    with open('hatem_new.json', 'r', encoding='utf-8') as f:
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
