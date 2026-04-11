import json
import re

arabic_titles = {
    "Betmoun": "بتمون",
    "Ayshalak": "عايشالك",
    "Faker": "فاكر",
    "Baddi Doub": "بدي دوب",
    "Ayami Bik (Wana a'dar)": "أيامي بيك",
    "Aa Bali Habibi": "عبالي حبيبي",
    "Hob Kol Hayaty": "حب كل حياتي",
    "Law": "لو",
    "Min Awel Dekika": "من أول دقيقة",
    "Bastanak": "بستناك",
    "Ana W Bass": "أنا وبس",
    "Elissa": "إليسا",
    "Betghib Betrouh": "بتغيب بتروح",
    "Kermalak": "كرمالك",
    "Asaad Wahda": "أسعد واحدة",
    "Halet Hob": "حالة حب",
    "قبل أى حد (ماتحسبهاش عيش وغامر)": "قبل أي حد",
    "Mawtini": "موطني",
    "Chafouna Tneyn": "شافونا تنين",
    "Ma Tendam 3a Shi": "ما تندم على شي"
}

def clean_title(title):
    # If the original title is already primarily Arabic, just keep it clean
    title = re.sub(r'\s*\(.*?\)', '', title)
    return title.strip()

def main():
    print("Reading new elissa songs...")
    with open('elissa_new.json', 'r', encoding='utf-8') as f:
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
