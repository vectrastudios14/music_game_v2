import json
import re

arabic_titles = {
    "Ya Tabtab Wa Dallaa": "يا طبطب ودلع",
    "Inta Eyh": "إنت إيه",
    "Ya Albo": "يا قلبو",
    "Ah W Noss": "آه ونص",
    "Ma Tegi Hena": "ما تيجي هنا",
    "Badna Nwalee El Jaw": "بدنا نولع الجو",
    "Albi Ya Albi": "قلبي يا قلبي",
    "Yay": "ياي",
    "Akhasmak Ah": "أخاصمك آه",
    "Am Bet'alaa Feek": "عم بتعلق فيك",
    "Meen Dah Elly Nseik": "مين ده اللي نسيك",
    "Ebn El Geran": "إبن الجيران",
    "Hassa Beek": "حاسة بيك",
    "Salamat": "سلامات",
    "Oul Tani Eyh": "قول تاني كده",
    "Tegy Nenbeset": "تيجي ننبسط",
    "Fi Hagat": "في حاجات",
    "Aam Betaala' Feek": "عم بتعلق فيك",
    "Aala Shanak": "على شانك",
    "Maakoul El Gharam": "معقول الغرام"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new nancy songs...")
    with open('nancy_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    for song in new_songs:
        original_title = song['title']
        
        # Mapping "Oul Tani Keda" if the API brought it as "Oul Tani Eyh"
        if original_title == "Oul Tani Eyh":
            arabic_titles[original_title] = "قول تاني كده"
            
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
