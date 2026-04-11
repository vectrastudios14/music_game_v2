import json
import re

arabic_titles = {
    "Fi 3esh2 El Banat": "في عشق البنات",
    "Shamandora": "شمندورة",
    "A Yasmarany": "يا أسمراني",
    "Yunis": "يونس",
    "لِلّي": "لِلّي",
    "Ya Hamaam": "يا حمام",
    "Hara El Saqueen": "حارة السقايين",
    "Lamma El Nasim": "لما النسيم",
    "So Ya So": "سو يا سو",
    "El Leila Ya Samra": "الليلة يا سمرا",
    "Eqrar": "إقرار",
    "Bab Elgamal": "باب الجمال",
    "Abo El Taaiyya": "أبو الطاقية",
    "Rabbak Lamma Yerid": "ربك لما يريد",
    "Waili": "ويلي",
    "Shababeek": "شبابيك",
    "Tag Taggeya": "طاق طاقية",
    "Sotek": "صوتك",
    "3ashan Nefham Ba’d Benkademlak Badal El Forsa 100": "عشان نفهم بعض",
    "Asmarany El Loun": "أسمراني اللون"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new mounir songs...")
    with open('mounir_new.json', 'r', encoding='utf-8') as f:
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
