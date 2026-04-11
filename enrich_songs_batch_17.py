import json
import os

LIBRARY_FILE = 'assets/songs.json'

TRIVIA = {
    ("Kings of Leon", "Sex On Fire"): "The band initially hesitated to release this song, fearing it was too 'pop' compared to their earlier sound.",
    ("Kings of Leon", "Use Somebody"): "Won the Grammy for Record of the Year in 2010, becoming a global crossover indie-rock anthem.",
    ("Kesha", "Your Love Is My Drug"): "Known for its upbeat electro-pop production and a music video inspired by psychedelic art.",
    ("Kesha", "Die Young"): "Kesha stated the song is about celebrating the moment and living life to the fullest.",
    ("Kesha", "Blow"): "Features a high-concept music video involving James Van Der Beek, showcasing Kesha's playful humor.",
    ("Khalid", "Young Dumb & Broke"): "A relatable high school anthem that reached #1 on the Billboard Hot R&B Songs chart in 2017.",
    ("Khalid", "Location"): "Khalid recorded this song while still in high school; it became a viral hit that launched his global career.",
    ("Khalid", "Better"): "A smooth, atmospheric R&B track that explores the comfort and security of a supportive relationship.",
    ("Khalid", "Talk"): "Produced by Disclosure, it features a unique electronic-soul production that earned a Grammy nomination.",
    ("Benny Blanco, Halsey & Khalid", "Eastside"): "Benny Blanco's debut single as a lead artist, telling a nostalgic story of young love.",
    ("Khalid", "Saved"): "One of Khalid's earliest tracks, exploring the bittersweet feeling of holding onto an ex's phone number.",
    ("Khalid", "Coaster"): "A soulful, stripped-back ballad that highlights Khalid's raw vocal talent and emotional depth.",
    ("Khalid", "8TEEN"): "Captures the feeling of freedom and transition that comes with being 18 and on the verge of adulthood.",
    ("Khalid", "Saturday Nights"): "A tender acoustic track where Khalid offers support to a partner struggling with family issues.",
    ("Khalid ft. Ty Dolla $ign & 6LACK", "Otw"): "A smooth R&B collaboration that captures the feeling of a late-night drive to see someone special.",
    ("Khalid & Disclosure", "Know Your Worth"): "An empowering anthem produced by Disclosure, encouraging listeners to value themselves.",
    ("Kendrick Lamar ft. Zacari", "LOVE."): "Kendrick described this as a 'true love song', a rare romantic moment in the intense 'DAMN.' album.",
    ("Kendrick Lamar & SZA", "All The Stars"): "The lead single from the 'Black Panther' soundtrack, nominated for an Academy Award.",
    ("Kendrick Lamar ft. Rihanna", "LOYALTY."): "Features Rihanna and explores the importance of trust and commitment in personal and professional life.",
    ("Kendrick Lamar", "King Kunta"): "References character Kunta Kinte, blending funk influences with a powerful message of resilience.",
    ("Kendrick Lamar", "Alright"): "Became an unofficial anthem for social justice movements globally, symbolizing hope and perseverance.",
    ("Kendrick Lamar", "Bitch, Don't Kill My Vibe"): "Explores Kendrick's struggle to maintain artistic integrity and personal peace amidst industry pressure.",
    ("Kendrick Lamar ft. Drake", "Poetic Justice"): "Samples Janet Jackson's 'Any Time, Any Place', bridging classic R&B and modern hip-hop.",
    ("Kendrick Lamar", "Swimming Pools (Drank)"): "Often misinterpreted as a party anthem, the lyrics actually address the social pressure of alcoholism.",
    ("Kendrick Lamar", "DNA."): "Produced by Mike Will Made-It; the second half was recorded specifically to match Kendrick's frantic flow.",
    ("Kendrick Lamar", "ELEMENT."): "Kendrick declares his dominance in the rap game, stating he would die for his art and his 'element'.",
    ("Kendrick Lamar", "Not Like Us"): "A 2024 viral hit that dominated social media and the charts during Kendrick's high-profile rap feud.",
    ("Kendrick Lamar", "i"): "Won the Grammy for Best Rap Performance and Best Rap Song, celebrating self-love and internal strength.",
    ("Kendrick Lamar ft. Jay Rock", "Money Trees"): "Explores the allure and dangers of seeking wealth in the inner city, featuring a 'sun-drenched' production.",
    ("ScHoolboy Q ft. Kendrick Lamar", "Collard Greens"): "Kendrick performs part of his verse in Spanish, showcasing his versatility and cultural range.",
    ("Kendrick Lamar ft. Dr. Dre", "The Recipe"): "A love letter to the California lifestyle, featuring Dr. Dre and sampling Twin Sister's 'Meet the Friends'.",
    ("Kendrick Lamar ft. Travis Scott", "Big Shot"): "Featured on the 'Black Panther' soundtrack, celebrating confidence and 'boss' status.",
    ("The Weeknd & Kendrick Lamar", "Pray For Me"): "A high-stakes collaboration capturing the cinematic intensity of the 'Black Panther' world.",
    ("Future, Metro Boomin & Kendrick Lamar", "Like That"): "Sparked massive shifts in the rap landscape in 2024, leading to several high-profile 'diss' tracks.",
    ("Kendrick Lamar", "Euphoria"): "A masterful 6-minute exercise in lyricism and flow, addressing Kendrick's position in the music hierarchy.",
    ("Kendrick Lamar", "Humble"): "Kendrick's first solo #1 hit on the Billboard Hot 100, known for its ironic 'sit down' hook.",
    ("Kendrick Lamar ft. MC Eiht", "M.A.A.D City"): "A raw, cinematic exploration of Kendrick's experiences growing up in Compton.",
    ("Kim Carnes", "Bette Davis Eyes"): "Kim Carnes' version stayed at #1 for nine weeks and won the Record of the Year Grammy in 1982.",
    ("Kenny Loggins", "Footloose"): "Written for the 1984 film of the same name; its energy remains a staple of dance parties globally.",
    ("Kenny Loggins", "Danger Zone"): "The iconic theme from 'Top Gun', forever associated with high-speed jet action and 80s cool.",
    ("Huey Lewis & The News", "The Power of Love"): "Featured in 'Back to the Future'; the band was initially reluctant to write a song for a movie.",
    ("Huey Lewis & The News", "Hip to Be Square"): "Famously used in the film 'American Psycho' during one of its most darkly comedic scenes.",
    ("Huey Lewis & The News", "I Want a New Drug"): "A new wave hit that faced a legal dispute over similarities to the 'Ghostbusters' theme.",
    ("Huey Lewis & The News", "If This Is It"): "Known for its 'a cappella' intro and a music video filmed on a sunny beach in Santa Cruz.",
    ("Huey Lewis & The News", "Stuck with You"): "Reached #1 on the Billboard Hot 100 and won a Grammy nomination for its catchy rock-pop sound.",
    ("Huey Lewis & The News", "Doing It All for My Baby"): "A horn-driven track that showcases the band's deep appreciation for 60s R&B and soul.",
    ("Huey Lewis & The News", "Jacob's Ladder"): "Written by Bruce Hornsby, it became the band's third #1 hit on the Billboard Hot 100.",
    ("Dolly Parton", "Jolene"): "Dolly wrote this and 'I Will Always Love You' on the very same day in 1973.",
    ("Dolly Parton", "9 to 5"): "The typewriter sound at the start was created by Dolly clicking her acrylic fingernails together."
}

def main():
    if not os.path.exists(LIBRARY_FILE):
        print("Library file not found.")
        return

    with open(LIBRARY_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    updated_count = 0
    for song in data:
        key = (song['artist'], song['title'])
        if key in TRIVIA:
            if not song.get('facts'):
                song['facts'] = [TRIVIA[key]]
                updated_count += 1
            elif TRIVIA[key] not in song['facts']:
                song['facts'].append(TRIVIA[key])
                updated_count += 1

    with open(LIBRARY_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

    print(f"Successfully enriched {updated_count} additional songs with trivia.")

if __name__ == '__main__':
    main()
