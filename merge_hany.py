import json
import re

arabic_titles = {
    "Lesa Btesaaly": "لسه بتسألي",
    "Yaretny": "ياريتني",
    "El Mafroud": "المفروض",
    "Sa'ltek": "سألتك",
    "Garhy Ana": "جرحي انا",
    "Bahibak Ana": "بحبك انا",
    "Bahebak Ya Ghaly": "بحبك يا غالي",
    "Nesyanak Sa'b": "نسيانك صعب",
    "Kefaya": "كفاية",
    "Bekol El Omr": "بكل العمر",
    "Asaheb Meen": "اصاحب مين",
    "Alli El Dehkaya": "علي الضحكاية",
    "Adfa'lak Oumry": "ادفعلك عمري",
    "Sebteeny Leh": "سبتيني ليه",
    "Tekhsary": "تخسري",
    "Habeb Enaya": "حبيب عينيا",
    "Beena": "بينا",
    "Fark Fel Ehsas": "فرق في الاحساس",
    "Han'eesh": "هنعيش",
    "Daawet Farah": "دعوة فرح"
}

def clean_title(title):
    # Remove things like (feat. Assi El Hallani), (Live From Egypt/2010), ( with Carol samaha )
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new hany songs...")
    with open('hany_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    # Clean titles and set Arabic titles
    for song in new_songs:
        original_title = song['title']
        
        if original_title in arabic_titles:
            song['titleAr'] = arabic_titles[original_title]
        else:
            print(f"Warning: No translation for {original_title}")
            
        # Also clean the english title
        clean_eng_title = clean_title(original_title)
        
        # We need an English-script version of the title for searchability if possible
        # but the API returned Arabic for some. Let's just leave it clean
        song['title'] = clean_eng_title
    
    print("Reading songs_arabic.json...")
    with open('assets/songs_arabic.json', 'r', encoding='utf-8') as f:
        current_songs = json.load(f)

    # Append
    current_songs.extend(new_songs)

    print("Saving songs_arabic.json...")
    with open('assets/songs_arabic.json', 'w', encoding='utf-8') as f:
        json.dump(current_songs, f, indent=4, ensure_ascii=False)

    print("Success. Run verify_songs.py to be sure.")

if __name__ == "__main__":
    main()
