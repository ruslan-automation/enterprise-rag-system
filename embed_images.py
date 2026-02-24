import os
import base64

base_path = r"c:\Users\79514\Desktop\Antigravity\Life_Strategy\Portfolio\02_Legal_RAG"
html_file = os.path.join(base_path, "HR_RAG_antigravity.html")

# Complete list of images found in the directory
image_files = [
    "1_botfather..jpg",
    "Gorq-1.jpg",
    "Groq_2.jpg",
    "Groq_3.jpg",
    "OpenRouter-1.jpg",
    "OpenRouter-2.jpg",
    "OpenRouter-3.jpg",
    "Screenshot_2.jpg",
    "Zarub_1.jpg"
]

print(f"Reading HTML file: {html_file}")
try:
    with open(html_file, "r", encoding="utf-8") as f:
        html_content = f.read()
except FileNotFoundError:
    print("Error: HTML file not found")
    exit(1)

for img_name in image_files:
    img_path = os.path.join(base_path, img_name)
    
    if os.path.exists(img_path):
        print(f"Processing {img_name}...")
        try:
            with open(img_path, "rb") as img_f:
                encoded_string = base64.b64encode(img_f.read()).decode('utf-8')
                
            mime_type = "image/jpeg"
            if img_name.lower().endswith(".png"):
                mime_type = "image/png"
                
            data_uri = f"data:{mime_type};base64,{encoded_string}"
            
            # Simple replacement
            search_str = f'src="{img_name}"'
            
            if search_str in html_content:
                html_content = html_content.replace(search_str, f'src="{data_uri}"')
                print(f"  [OK] Embedded")
            else:
                print(f"  [SKIP] Tag not found in HTML (already embedded?)")
        except Exception as e:
            print(f"  [ERROR] Could not process image: {e}")
    else:
        print(f"  [MISSING] File not found: {img_name}")

print("Saving HTML...")
with open(html_file, "w", encoding="utf-8") as f:
    f.write(html_content)

print("COMPLETED DIRECTLY")
