import urllib.request
import urllib.parse
import json
import time
import sys
import codecs

# Force UTF-8 for console output
try:
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')
except Exception:
    pass

songs = [
    # Top Hits
    {"query": "Abdul Karim Abdul Qader Ashtreek", "title_ar": "أشتريك"},
    {"query": "Abdul Karim Abdul Qader Alsout Aljareeh", "title_ar": "الصوت الجريح"},
    {"query": "Abdul Karim Abdul Qader Ghareeb", "title_ar": "غريب"},
    {"query": "Abdul Karim Abdul Qader Red Alzeyarah", "title_ar": "رد الزيارة"},
    {"query": "Abdul Karim Abdul Qader Ahebak", "title_ar": "أحبك"},
    {"query": "Abdul Karim Abdul Qader Mohal", "title_ar": "محال"},
    {"query": "Abdul Karim Abdul Qader Fe Ayoon Albashr", "title_ar": "في عيون البشر"},
    {"query": "Abdul Karim Abdul Qader La Trouh", "title_ar": "لا تروح"},
    {"query": "Abdul Karim Abdul Qader Wainak", "title_ar": "وينك"},
    {"query": "Abdul Karim Abdul Qader Ma Neisnah", "title_ar": "ما نسيناه"},
    
    # Famous Tracks
    {"query": "Abdul Karim Abdul Qader Ya Ghalahom", "title_ar": "يا غلاهم"},
    {"query": "Abdul Karim Abdul Qader Heya Leilah", "title_ar": "هي ليلة"},
    {"query": "Abdul Karim Abdul Qader Akhonak Leah", "title_ar": "أخونك ليه"},
    {"query": "Abdul Karim Abdul Qader Resalah Men Emra'ah", "title_ar": "رسالة من امرأة"},
    {"query": "Abdul Karim Abdul Qader Alaaraf", "title_ar": "الاعتراف"},
    {"query": "Abdul Karim Abdul Qader Aakhir Kalam", "title_ar": "آخر كلام"},
    {"query": "Abdul Karim Abdul Qader Baseetah", "title_ar": "بسيطة"},
    {"query": "Abdul Karim Abdul Qader ZahmtJerooh", "title_ar": "زحمة جروح"},
    {"query": "Abdul Karim Abdul Qader Hobak Ent Ghear", "title_ar": "حبك أنت غير"},
    {"query": "Abdul Karim Abdul Qader Eltaayna", "title_ar": "التقينا"},
    
    # More Classics
    {"query": "Abdul Karim Abdul Qader Ya Theglha", "title_ar": "يا ثقلها"},
    {"query": "Abdul Karim Abdul Qader Khade'a W Makhdo'a", "title_ar": "خادع ومخدوع"},
    {"query": "Abdul Karim Abdul Qader Maak Bamshi", "title_ar": "معك بمشي"},
    {"query": "Abdul Karim Abdul Qader Ele Yehebak", "title_ar": "اللي يحبك"},
    {"query": "Abdul Karim Abdul Qader Zaree Alshar", "title_ar": "زارع الشر"},
    {"query": "Abdul Karim Abdul Qader Khashf Hesab", "title_ar": "كشف حساب"},
    {"query": "Abdul Karim Abdul Qader Ensa Elwad", "title_ar": "انسى الوعد"},
    {"query": "Abdul Karim Abdul Qader Gethabny", "title_ar": "كذبني"},
    {"query": "Abdul Karim Abdul Qader Shakhbarik", "title_ar": "شخبارك"},
    {"query": "Abdul Karim Abdul Qader Kol aljerah", "title_ar": "كل الجراح"},
    
    # Additional Songs
    {"query": "Abdul Karim Abdul Qader Hata Alnethar", "title_ar": "حتى النظر"},
    {"query": "Abdul Karim Abdul Qader Geab Wo Ana Geab", "title_ar": "غيب وأنا غيب"},
    {"query": "Abdul Karim Abdul Qader Ma Amna'ek", "title_ar": "ما أمنعك"},
    {"query": "Abdul Karim Abdul Qader Kol El Hob", "title_ar": "كل الحب"},
    {"query": "Abdul Karim Abdul Qader Ward Al Gharam", "title_ar": "ورد الغرام"},
    {"query": "Abdul Karim Abdul Qader Ya Shams Omri", "title_ar": "يا شمس عمري"},
    {"query": "Abdul Karim Abdul Qader Ya Ghalyah", "title_ar": "يا غالية"},
    {"query": "Abdul Karim Abdul Qader Majrouh", "title_ar": "مجروح"},
    {"query": "Abdul Karim Abdul Qader Eshtagtilak", "title_ar": "اشتقت لك"},
    {"query": "Abdul Karim Abdul Qader Habas Hobi", "title_ar": "حبس حبي"},
    
    # Final Batch
    {"query": "Abdul Karim Abdul Qader Ma Hammaha Shay", "title_ar": "ما همها شي"},
    {"query": "Abdul Karim Abdul Qader Ana Elly Youm Tmaneytak", "title_ar": "أنا اللي يوم تمنيتك"},
    {"query": "Abdul Karim Abdul Qader Men Bean Alnas", "title_ar": "من بين الناس"},
    {"query": "Abdul Karim Abdul Qader Ana Welly", "title_ar": "أنا ويلي"},
    {"query": "Abdul Karim Abdul Qader Namet Aowny", "title_ar": "نامت عيوني"},
    {"query": "Abdul Karim Abdul Qader Ashtaq Leek", "title_ar": "أشتاق ليك"},
    {"query": "Abdul Karim Abdul Qader Maloom Men Yashky", "title_ar": "مظلوم من يشكي"},
    {"query": "Abdul Karim Abdul Qader Zain", "title_ar": "زين"},
    {"query": "Abdul Karim Abdul Qader Alhob Lek Wahdek", "title_ar": "الحب لك وحدك"},
    {"query": "Abdul Karim Abdul Qader Fatenat Alawahez", "title_ar": "فاتنة"}
]

print("Fetching links from iTunes for Abdul Karim Abdul Qader...\n")

for song in songs:
    term = urllib.parse.quote(song["query"])
    # Searching specifically in Saudi Arabia store as it often has good Arabic coverage
    url = f"https://itunes.apple.com/search?term={term}&media=music&entity=song&limit=1&country=SA"
    
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data["resultCount"] > 0:
                track = data["results"][0]
                release_date = track.get('releaseDate', '')[:4]
                print(f"**{song['title_ar']}** ({release_date})")
                print(f"Link: {track.get('trackViewUrl')}")
                print(f"Preview: {track.get('previewUrl')}")
                print("-" * 20)
            else:
                print(f"**{song['title_ar']}** - Not Found")
                print("-" * 20)
    except Exception as e:
        print(f"Error fetching {song['query']}: {e}")
    
    # Sleep to avoid rate limiting
    time.sleep(1.2)
