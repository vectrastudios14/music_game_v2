from PIL import Image
import os

def remove_white_background(input_path, output_path):
    print(f"Processing {input_path}...")
    try:
        img = Image.open(input_path)
        img = img.convert("RGBA")
        datas = img.getdata()
    
        newData = []
        for item in datas:
            # Change all white (also shades of whites)
            # to transparent
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)
    
        img.putdata(newData)
        img.save(output_path, "PNG")
        print(f"Saved to {output_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    current_dir = os.getcwd()
    
    # Process GTS Logo (White Background)
    input_gts = os.path.join(current_dir, "assets", "gts-logo.png")
    output_gts = os.path.join(current_dir, "assets", "gts-logo-transparent.png")
    if os.path.exists(input_gts):
        remove_white_background(input_gts, output_gts)

    # Process BoA Logo (Black/Dark Background)
    input_boa = os.path.join(current_dir, "assets", "boa-logo-final-v4.png")
    output_boa = os.path.join(current_dir, "assets", "boa-logo-transparent.png")
    
    print(f"Processing {input_boa}...")
    try:
        img = Image.open(input_boa)
        img = img.convert("RGBA")
        datas = img.getdata()
    
        newData = []
        for item in datas:
            # Change all black (also shades of black) to transparent
            # Adjust threshold as needed
            if item[0] < 50 and item[1] < 50 and item[2] < 50:
                newData.append((0, 0, 0, 0))
            else:
                newData.append(item)
    
        img.putdata(newData)
        img.save(output_boa, "PNG")
        print(f"Saved to {output_boa}")
    except Exception as e:
        print(f"Error processing BoA logo: {e}")

