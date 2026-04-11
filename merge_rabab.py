import json
import re

arabic_titles = {
    "Sawet Lee": "صوت لي",
    "Ant Men Yadre Alak": "انت من يقدر عليك",
    "Rd Al Soot": "رد الصوت",
    "La Lel Hob": "لا للحب",
    "Bas Habibi": "بس حبيبي",
    "Tezakar": "تذكر",
    "Hasset Belfarha": "حسيت بالفرحة",
    "Yaa Sahar Al Soot": "يا سحر الصوت",
    "Jarh Alzamn": "جرح الزمن",
    "Ragaa": "رجاء",
    "Basma Hlwaa": "بسمة حلوة",
    "Ma Agder Ansaah": "ما اقدر انساه",
    "Athadak": "اتحداك",
    "Akher Karari": "اخر قراري",
    "Ashaa Al Amal": "عاش الامل",
    "Nam Taqder": "نعم تقدر",
    "هذاك أول": "هذاك أول",
    "Jeat Atraf": "جيت اعترف",
    "Ghane Lel Farah": "غني للفرح",
    "Yomah": "يمه"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new rabab songs...")
    with open('rabab_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    # Clean titles and set Arabic titles
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
