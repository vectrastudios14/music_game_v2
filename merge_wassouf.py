import json

arabic_titles = {
    "Helaf el Amar": "حلف القمر",
    "Rohi Yanssmah": "روحي يا نسمة",
    "Targahali": "ترغلي يا ترغلي",
    "Habet Ermy L Shabak": "حبيت ارمي الشبك",
    "Tabib Garrah": "طبيب جراح",
    "Kalam Ennas (2000 Remaster)": "كلام الناس",
    "Lail El Ashekin": "ليل العاشقين",
    "Garahouna": "جرحونا",
    "Law Naweit": "لو نويت",
    "El Hawa Sultan": "الهوى سلطان",
    "Yalle Teabna Snen Be Hawak": "ياللي تعبنا سنين في هواه",
    "Dobna Ala Ghyabak": "دبنا ع غيابك",
    "Had Yensa Albo": "حد ينسى قلبه",
    "Seket El Kalam": "سكت الكلام",
    "Habibi Kidah (2000 Remaster)": "حبيبي كده",
    "Erdha Bennaseeb": "ارضى بالنصيب",
    "El Houb el Awalani (2000 Remaster)": "الحب الاولاني",
    "Bta'atebni 'Ala Kilmat": "بتعاتبني على كلمة",
    "Ya Baya'ein el Hawa (2000 Remaster)": "يا بياعين الهوى",
    "Aah Habayeb": "آه حبايب"
}

def main():
    print("Reading new wassouf songs...")
    with open('wassouf_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    # Clean titles and set Arabic titles
    for song in new_songs:
        original_title = song['title']
        
        # Determine cleaned title if it has remaster string
        clean_title = original_title.replace(" (2000 Remaster)", "")
        song['title'] = clean_title
        
        if original_title in arabic_titles:
            song['titleAr'] = arabic_titles[original_title]
        else:
            print(f"Warning: No translation for {original_title}")
    
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
