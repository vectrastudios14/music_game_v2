import json
import re

arabic_titles = {
    "Aicha": "عائشة",
    "Didi": "ديدي",
    "Abdel Kader (Live)": "عبد القادر",
    "C’est la vie": "C'est la vie",
    "Aicha (Version Mixte)": "عائشة",
    "Hiya Hiya (feat. Pitbull)": "هي هي",
    "Mas Wi Loli": "ماس ولولي",
    "Ana Âacheck": "أنا عاشق",
    "Trigue Lycee": "طريق الليسي",
    "Menayfa": "منايفة",
    "Kaiss Wa Laila": "قيس وليلى",
    "Khayef": "خايف",
    "Mezinek Ya Aädra": "مزينك يا عذراء",
    "Gouloulha Dji": "قولولها تجي",
    "El Hadja": "الحاجة",
    "Ya Rayah (Live)": "يا رايح",
    "Wahrane": "وهران",
    "C'est la vie": "C'est la vie",
    "Aicha (Live)": "عائشة",
    "Encore une fois": "Encore une fois"
}

def clean_title(title):
    # Remove things inside parentheses
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new khaled songs...")
    with open('khaled_new.json', 'r', encoding='utf-8') as f:
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
