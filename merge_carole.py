import json
import re

arabic_titles = {
    "Khallik Behalak": "خليك بحالك",
    "Ettala Fia": "اتطلع فيي",
    "Esma'ny": "اسمعني",
    "Ghali Aliya": "غالي علي",
    "Adwaa' El Shohra": "أضواء الشهرة",
    "Sahranine": "سهرانين",
    "Aoul Ansak": "أقول أنساك",
    "Ensa Hmoumak": "انسى همومك",
    "Habbet Delwaat": "حبيت دلوقت",
    "Hodoudy El Sama": "حدودي السما",
    "مغرومة بمين": "مغرومة بمين",
    "Yama Layaly": "ياما ليالي",
    "Ana Sharak": "انا سحرك", # "انا سحرك"
    "Fawda": "فوضى",
    "Aaool Ansak": "أقول أنساك",
    "Rouh Fell": "روح فل",
    "Ragalak": "أرجعلك", # "راجعالك"
    "Majnouni (Jeet)": "مجنونة",
    "Hayda Adari": "هيدا قدري",
    "Nasskha Menni": "نسخة مني"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new carole songs...")
    with open('carole_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    for song in new_songs:
        original_title = song['title']
        
        # Some manual fixing for specific songs
        if original_title == "Ana Sharak":
             arabic_titles[original_title] = "انا سحرك"
        if original_title == "Ragalak":
             arabic_titles[original_title] = "راجعالك"
        
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
