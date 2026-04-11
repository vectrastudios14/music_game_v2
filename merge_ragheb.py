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
    "Nassiny El Donya": "نسيني الدنيا",
    "Sahran Maak El Lail": "سهران معاك الليلة",
    "Sereena Ya Donya": "سيرينا يا دنيا",
    "Maghram Ya Lail": "مغرم يا ليل",
    "Baachaek": "بعشقك",
    "Assef Habibty": "آسف حبيبتي",
    "Elli Baana": "اللي باعنا",
    "El Hob El Kebir": "الحب الكبير",
    "Yalla Habibi (feat. Seyi Shay & Costi) [Summer Hit]": "يلا حبيبي",
    "Moush Belkalam": "مش بالكلام",
    "Alby Eshekha": "قلبي عشقها",
    "Trekni Lahali": "تركني لحالي",
    "Ana Esmi Habibak": "أنا اسمي حبيبك",
    "Fi kteer Helween": "في كتير حلوين",
    "Tab Leh": "طب ليه",
    "Sodfi": "صدفة",
    "Albi Ashe2ha (Remake Version)": "قلبي عشقها",
    "ETTIEEL": "التقيل التقيل",
    "Fawran Gharam": "فوراً غرام",
    "Ya Rayt (Shkoon Extended Mix)": "يا ريت",
    "Alamteni": "علمتيني"
}

def clean_title(title):
    title = re.sub(r'\s*\(.*?\)', '', title)
    title = re.sub(r'\s*\[.*?\]', '', title)
    return title.strip()

def main():
    print("Reading new ragheb songs...")
    with open('ragheb_new.json', 'r', encoding='utf-8') as f:
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
