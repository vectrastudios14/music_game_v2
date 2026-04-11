import json
import re

arabic_titles = {
    "Allah Aleik Ya Seedy": "الله عليك يا سيدي",
    "Tetraga Feya": "تترجى فيا",
    "Sahrany": "سحراني",
    "El Ayam El Helwa": "الايام الحلوة",
    "Aktar Mn Keda Eh": "اكتر من كدة ايه",
    "Addak": "قدك",
    "Elly Mdawebny": "اللي مدوبني",
    "Ahla Menhom": "احلى منهم",
    "Ya Remoshaha": "يا رموشها",
    "Moshtaq": "مشتاق",
    "Habeeby": "حبيبي",
    "Habeeb El Alb": "حبيب القلب",
    "Bahebo": "بحبه",
    "Daaq Elalb": "دق القلب",
    "Ameel Amla": "عامل عملة",
    "Kol Youm Yehlaw": "كل يوم يحلو",
    "Meen Howa": "مين هو",
    "Aref Habibi": "عارف حبيبي",
    "Dawbony Eineh": "دوبوني عينيه",
    "Esmak Eih": "اسمك ايه"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new ehab songs...")
    with open('ehab_new.json', 'r', encoding='utf-8') as f:
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
