import json
import re

arabic_titles = {
    "Youm Wara Youm": "يوم ورا يوم",
    "Ala Eih": "على ايه",
    "Aweni Beek": "قويني بيك",
    "Ma Khalass": "ما خلاص",
    "Mazal": "مازال",
    "Yallah Rouh": "يلا روح",
    "Hiya": "هي",
    "El Sa3a Etneen Belleil": "الساعة اتنين بالليل",
    "Hollelah": "هليلة",
    "Youm Wara Youm (feat. شاب مامي)": "يوم ورا يوم",
    "Mon Cheri": "مون شيري",
    "Ott W Far": "قط وفار",
    "Yammi": "يامي",
    "Kan Maly": "كان مالي",
    "Dahaktny": "ضحكتنى",
    "Bel Salama": "بالسلامة",
    "Alah Yesahilak": "الله يسهلك",
    "Aounek Oudaami": "عيونك قدامي",
    "Korbag": "كرباج",
    "Awaam Keda": "قوام كدة"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new samira songs...")
    with open('samira_new.json', 'r', encoding='utf-8') as f:
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
