import json
import re

arabic_titles = {
    "Law Yesaalouni": "لو يسألوني",
    "Mas Wi Loli": "ماس ولولي",
    "Fat El Awan": "فات الأوان",
    "Ela Hona": "الى هنا",
    "Ya Bashar": "يا بشر",
    "La fiesta (feat. ZAD)": "La fiesta",
    "Darb Al Mahabaa": "درب المحبة",
    "Wahishni Shakhs": "واحشني شخص",
    "Maghanaje": "مغنجة",
    "Alaa Hoonk": "على هونك",
    "Yamak Mazaji": "يمك مزاجي",
    "Ma Had Yehes Bi Elaasheq": "ما حد يحس بالعاشق",
    "Ahla Couple": "احلى كبل",
    "Aasheg Dhamian": "عاشق ضميان",
    "Farhet Qalbi": "فرحة قلبي",
    "Maqlab": "مقلب",
    "Elard Ghanat (Megana)": "الارض غنت",
    "Methlak Habibi": "مثلك حبيبي",
    "Eltowafah": "التوافة",
    "Sahby": "صاحبي"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new diana songs...")
    with open('diana_new.json', 'r', encoding='utf-8') as f:
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
