import json
import re

arabic_titles = {
    "Ayonha": "عيونها",
    "Ayonha (feat. Mounir)": "عيونها",
    "Reet": "ريت",
    "Bethebeny": "بتحبني",
    "Einy": "عيني",
    "Ghazaly": "غزالي",
    "Khodny Ben Edek": "خدني بين ايديك",
    "Wallah": "والله",
    "Ayonha (Mixed)": "عيونها",
    "Aieny": "عيني",
    "Ayonha (SHIHA Club Mix)": "عيونها",
    "Geboole Akhebaroh": "جيبولي أخباره",
    "Zahmet El Ayam (feat. Ehab Tawfik, Hisham Abbas & Mostafa Amar)": "زحمة الأيام",
    "Bethebny (feat. Salwa Abd El Wahab)": "بتحبني",
    "Efham Baa": "إفهم بقا",
    "Eyonha": "عيونها",
    "Ageelek": "أجيلك",
    "نسمه صبا": "نسمة صبا",
    "Ana Baba": "أنا بابا"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new hamid songs...")
    with open('hamid_new.json', 'r', encoding='utf-8') as f:
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
