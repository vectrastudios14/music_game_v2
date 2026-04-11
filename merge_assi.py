import json
import re

arabic_titles = {
    "Bhibbek We Bghar": "بحبك وبغار",
    "Jan Jnooni": "جن جنوني",
    "سالونى": "سألوني",
    "كوني القمر": "كوني القمر",
    "Belarabi": "بالعربي",
    "Mitil El Kithba": "متل الكذبة",
    "Kasser Adem": "كسر عضم",
    "Lebnani": "لبناني",
    "Dakatt Alpi": "دقات قلبي",
    "Howara": "هوارة",
    "عرس قلبي (feat. Assi El Hallani)": "عرس قلبي",
    "الهوارة": "الهوارة",
    "Ya Naker El Maarouf (Live From Egypt/2010)": "يا ناكر المعروف",
    "الحق علينا": "الحق علينا",
    "Oley Jayi ( with Carol samaha )": "قولي جايي",
    "Bab Aam Yebki": "باب عم يبكي",
    "Yemken": "يمكن",
    "Baoul Ma Baoul": "بقول ما بقول",
    "Ya Rayhin Loubnan": "يا رايحين لبنان",
    "قلبي شاطر": "قلبي شاطر"
}

def clean_title(title):
    # Remove things like (feat. Assi El Hallani), (Live From Egypt/2010), ( with Carol samaha )
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new assi songs...")
    with open('assi_new.json', 'r', encoding='utf-8') as f:
        new_songs = json.load(f)

    # Clean titles and set Arabic titles
    for song in new_songs:
        original_title = song['title']
        
        if original_title in arabic_titles:
            song['titleAr'] = arabic_titles[original_title]
        else:
            print(f"Warning: No translation for {original_title}")
            
        # Also clean the english title
        clean_eng_title = clean_title(original_title)
        
        # We need an English-script version of the title for searchability if possible
        # but the API returned Arabic for some. Let's just leave it clean
        song['title'] = clean_eng_title
    
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
