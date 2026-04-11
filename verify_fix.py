
import sys
import os

# Add the directory containing migrate_songs_human.py to path
sys.path.append(r'c:\Users\kishi\OneDrive\Documents\music-game-flutter')

from migrate_songs_human import fetch_itunes_preview

def verify():
    print("Verifying fetch_itunes_preview robustness...")
    
    # Test 1: The problematic song
    title = "The Less I Know The Better"
    artist = "Tame Impala"
    print(f"\nSearching for: {title} by {artist}")
    
    url = fetch_itunes_preview(title, artist)
    
    if url:
        print(f"SUCCESS: Found URL: {url}")
        print("Verification PASSED.")
    else:
        print("FAILURE: Song not found.")
        print("Verification FAILED.")

if __name__ == "__main__":
    verify()
