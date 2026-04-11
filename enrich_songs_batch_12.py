import json
import os

LIBRARY_FILE = 'assets/songs.json'

TRIVIA = {
    ("Evanescence", "Going Under"): "Amy Lee's lyrics describe escaping a toxic relationship and regaining personal identity.",
    ("Tim McGraw", "It's Your Love"): "Tim McGraw and Faith Hill were already married when they recorded this famous real-life couple duet.",
    ("Faith Hill", "This Kiss"): "Faith Hill's breakout pop crossover hit, known for its playful and romantic 90s country-pop sound.",
    ("Fat Joe", "Lean Back [feat. Lil Jon, Eminem, Mase & Remy Martin]"): "Popularized the 'Lean Back' dance move, where dancers simply lean back with their hands down.",
    ("Fat Joe", "Get It Poppin' (feat. Nelly)"): "A high-energy club collab between Fat Joe and Nelly that reached the top 10 in 2005.",
    ("Fergie", "Big Girls Don't Cry (Personal)"): "Fergie stated this was a very personal song about the maturity required to walk away from a relationship.",
    ("Fergie", "Clumsy"): "Samples the 1960s hit 'The Girl Can't Help It' by Little Richard, celebrating a playful pop style.",
    ("Fetty Wap", "Sweet Yamz"): "A soulful, viral 2022 remake by Fetty Wap of a song originally by the duo Masego and Devin Morrison.",
    ("Fine Young Cannibals", "Good Thing"): "Features a distinct soul-pop sound and was a massive global #1 hit famously used in many 80s films.",
    ("Fleetwood Mac", "The Chain"): "The only song on the legendary 'Rumours' album credited to all five members of Fleetwood Mac.",
    ("Fleetwood Mac", "Silver Springs"): "Originally recorded as a B-side for 'Go Your Own Way', it became a massive fan favorite during live shows.",
    ("Flo Rida", "Low (feat. T-Pain)"): "Apple Bottom jeans and boots with the fur! Set a record for the best-selling digital single of the 2000s.",
    ("Frankie Valli", "My Eyes Adored You"): "Frankie Valli's first solo #1 hit after his immense success with The Four Seasons.",
    ("George Harrison", "My Sweet Lord"): "The first solo single by a former Beatle to reach #1 on global charts.",
    ("George Harrison", "Give Me Love (Give Me Peace on Earth)"): "Known for George Harrison's signature slide guitar work and a message of universal peace.",
    ("Fleetwood Mac", "Go Your Own Way"): "Lindsey Buckingham wrote this about his painful breakup with bandmate Stevie Nicks while they were still in the band.",
    ("Fleetwood Mac", "Dreams"): "Stevie Nicks' response to 'Go Your Own Way'; it became Fleetwood Mac's only #1 single on the Billboard Hot 100.",
    ("Fleetwood Mac", "Landslide"): "Stevie Nicks wrote this in Aspen, Colorado, while contemplating her future career and relationship.",
    ("Fleetwood Mac", "Little Lies"): "Features distinct 80s electronic production with Christine McVie taking the lead on vocals.",
    ("Fleetwood Mac", "Everywhere"): "Known for its shimmering pop sound and for being one of the most radio-friendly hits of the 1980s.",
    ("Fleetwood Mac", "Rhiannon"): "Stevie Nicks was inspired by a novel character, unaware at the time that Rhiannon was also a Welsh goddess.",
    ("Peter Gabriel", "Sledgehammer"): "Features a revolutionary claymation music video that is the most-played video in MTV history.",
    ("Peter Gabriel", "In Your Eyes"): "Famously used in the film 'Say Anything...' during the iconic boombox scene.",
    ("Peter Gabriel", "Don't Give Up"): "Gabriel wrote the lyrics to offer hope to those struggling with economic hardship in the 80s.",
    ("Gary Numan", "Cars"): "A landmark synth-pop single featuring a cold, robotic vocal delivery and prominent Moog synthesizers.",
    ("George Michael", "Careless Whisper"): "George Michael wrote the famous saxophone hook while riding a bus when he was only 17 years old.",
    ("George Michael", "Faith"): "The iconic 'organ' intro is actually a reference to the Wham! hit 'Freedom' played at a slower tempo.",
    ("George Michael", "Freedom! '90"): "Does not feature George Michael in the video; instead, it stars five of the world's top supermodels.",
    ("George Michael", "Father Figure"): "Originally written as a dance track, Michael realized it worked better as a soulful, atmospheric ballad.",
    ("George Michael", "One More Try"): "An emotional 6-minute soul ballad that reached #1 on both the Pop and R&B charts.",
    ("George Michael", "Jesus to a Child"): "A deeply personal tribute to George Michael's partner Anselmo Feleppa, who had passed away.",
    ("George Michael", "Fastlove"): "Features a sample from Patrice Rushen's 'Forget Me Nots' and explores the concept of fleeting romance.",
    ("George Michael", "Killer / Papa Was a Rollin' Stone"): "A high-energy live mashup that showcased George Michael's incredible vocal range and stage presence.",
    ("George Michael", "Amazing"): "A highlight of the 'Patience' album, celebrating George Michael's return to form in the early 2000s.",
    ("Wham!", "The Edge of Heaven"): "Wham!'s final single before the duo officially disbanded in 1986.",
    ("Wham!", "I'm Your Man"): "George Michael wrote and produced this entirely on his own, signaling his transition to a solo career.",
    ("Wham!", "Wake Me Up Before You Go-Go"): "Inspired by a note Andrew Ridgeley left for his mother that accidentally said 'don't wake me up up'.",
    ("Wham!", "Last Christmas"): "Wham! donated all royalties from this holiday classic to Ethiopian famine relief efforts in 1984.",
    ("Wham!", "Club Tropicana"): "The music video was filmed at the Pikes Hotel in Ibiza, a famous haunt for 80s celebrities.",
    ("Wham!", "Bad Boys"): "A high-energy early Wham! hit that solidified their 'teen heartthrob' status in the UK.",
    ("Wham!", "Everything She Wants"): "George Michael's personal favorite Wham! song, cited as the start of his mature songwriting.",
    ("Wham!", "A Ray of Sunshine"): "A fun, energetic track from the first Wham! album, 'Fantastic'.",
    ("Wham!", "I Am Your Gun"): "Shows Wham!'s early experimentation with soul and funk influences.",
    ("Wham!", "If You Were There"): "A cover of The Isley Brothers original, showcasing Wham!'s deep appreciation for R&B legends.",
    ("Wham!", "Heartbeat"): "A smooth, soulful early-80s pop ballad from the multi-platinum 'Make It Big' album.",
    ("Wham!", "Freedom"): "Inspired by the group's historic 1985 tour of China, the first by a Western pop group.",
    ("Madonna", "Like A Virgin"): "The iconic performance at the first-ever VMAs made Madonna a household name and a pop icon.",
    ("Madonna", "Material Girl"): "The music video is a direct tribute to Marilyn Monroe's 'Diamonds Are a Girl's Best Friend'.",
    ("Madonna", "Like a Prayer"): "The video sparked massive controversy for its religious imagery, leading Pepsi to cancel a million-dollar deal."
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
