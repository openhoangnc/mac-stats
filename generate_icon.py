import os
import subprocess
import sys

image_path = "app_icon.jpg"
iconset_dir = "AppIcon.iconset"

os.makedirs(iconset_dir, exist_ok=True)

if not os.path.exists(image_path):
    print(f"Source image not found at {image_path}")
    sys.exit(1)

sizes = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for size, fname in sizes:
    out_path = os.path.join(iconset_dir, fname)
    cmd = ["sips", "-s", "format", "png", "-z", str(size), str(size), image_path, "--out", out_path]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

print("Created iconset files with sips PNG format successfully.")

result = subprocess.run(["iconutil", "-c", "icns", iconset_dir], capture_output=True, text=True)
if result.returncode == 0:
    print("Generated AppIcon.icns successfully.")
else:
    print(f"iconutil error: {result.stderr}")
