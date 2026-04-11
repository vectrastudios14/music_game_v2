import json
import re
import sys
import codecs

try:
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')
except Exception:
    pass

arabic_titles = {
    "Nour Einy": "نور عيني",
    "Ergaaly": "ارجعلي",
    "Teleefony Rann": "تليفوني رن",
    "Ana Wala Aref": "أنا ولا عارف",
    "Ana Wala 3aref": "أنا ولا عارف",
    "Makontesh Mobayen": "ماكنتش مبين",
    "Nassiny Leh": "ناسيني ليه",
    "Nasseeny Leih": "ناسيني ليه",
    "Hayati Fdak": "حياتي فداك",
    "Ta3ba Kol El Nas": "تعبا كل الناس",
    "Taaba Koll el Nas": "تعابى كل الناس",
    "Ya Bent El Eh": "يا بنت الإيه",
    "Taaly Eishy": "تعالي عيشي",
    "Eish Besho'ak": "عيش بشوقك",
    "Etamen": "إطمن",
    "Smile": "سمايل",
    "Wenta Ma'aia": "وإنت معايا",
    "Kol Haga Bena (From Ahwak)": "كل حاجة بينا",
    "Elly Gai Ahla": "اللي جاي أحلى",
    "Right Where I'm Supposed to Be": "رايت وير أيم سوبوزد تو بي", # Optional transliteration
    "Maleket Gamal El Kon": "ملكة جمال الكون",
    "Heya Di": "هيا دي",
    "Ya Ta3ebny": "يا تاعبني",
    "Come Back to Me": "كام باك تو مي",
    "Kol Marra": "كل مرة",
    "Ya Waheshny": "يا واحشني",
    "Hadalaany (From Bhabak Movie)": "هدلعني",
    "هرمون السعادة (من فيلم تاج)": "هرمون السعادة"
}

def clean_title(title):
    # Ensure titles like 'هرمون السعادة (من فيلم تاج)' or 'Kol Haga Bena (From Ahwak)' get cleaned
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new thosny songs...")
    with open('thosny_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    for song in new_songs:
        original_title = song['title']
        
        if original_title in arabic_titles:
            song['titleAr'] = arabic_titles[original_title]
        else:
            try:
                print(f"Warning: No translation for {original_title}")
            except UnicodeEncodeError:
                print("Warning: No translation for an Arabic title")
            
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
