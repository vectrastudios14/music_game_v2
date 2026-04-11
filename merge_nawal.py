import json
import re

arabic_titles = {
    "Aghla El Habayeb": "اغلى الحبايب",
    "Mandam a'leyk (2000 Remaster)": "ماندم عليك",
    "Alf W Meya": "الف ومية",
    "Elly Etmanetoh": "اللي اتمنيته",
    "Ya Gadaa": "يا جدع",
    "Al Nas Al Ozzaz": "الناس العزاز",
    "A'la Bali (2000 Remaster)": "على بالي",
    "Sawt Al Hodoo": "صوت الهدوء",
    "Alou": "قالوا",
    "Ghareeba Hal Deni": "غريبة هالدني",
    "Eneik Kaddabin": "عينيك كدابين",
    "Albi Da'a (2000 Remaster)": "قلبي دق",
    "Mesh Mesamha": "مش مسامحة",
    "Yama Alo": "ياما قالوا",
    "Rouhi Ya Rouhi": "روحي يا روحي",
    "Beyelbalak": "بيلبقلك",
    "Meny Leek": "مني ليك",
    "Wala Bahebak": "ولا بحبك",
    "Agy Bel Dalaa": "اجي بالدلع",
    "Bel Aleb": "بالقلب"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new nawal songs...")
    with open('nawal_new.json', 'r', encoding='utf-8') as f:
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
