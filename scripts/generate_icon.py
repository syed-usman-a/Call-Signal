#!/usr/bin/env python3
"""Optional recreation of the included geometric app icon. Requires Pillow."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1] / "App/Assets.xcassets"
icon_dir = root / "AppIcon.appiconset"
accent_dir = root / "AccentColor.colorset"
icon_dir.mkdir(parents=True, exist_ok=True)
accent_dir.mkdir(parents=True, exist_ok=True)
image = Image.new("RGB", (1024, 1024), (9, 14, 23))
draw = ImageDraw.Draw(image)
draw.ellipse((148, 148, 876, 876), outline=(24, 47, 48), width=3)
draw.ellipse((208, 208, 816, 816), outline=(33, 67, 63), width=3)
for index, height in enumerate([132, 262, 412, 262, 132]):
    x = 300 + index * 91
    y = (1024 - height) // 2
    draw.rounded_rectangle((x, y, x + 60, y + height), radius=30, fill=(102, 232, 186))
image.save(icon_dir / "AppIcon.png")
(root / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))
(icon_dir / "Contents.json").write_text(json.dumps({"images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": {"author": "xcode", "version": 1}}, indent=2))
(accent_dir / "Contents.json").write_text(json.dumps({"colors": [{"idiom": "universal", "color": {"color-space": "srgb", "components": {"red": "0.400", "green": "0.910", "blue": "0.730", "alpha": "1.000"}}}], "info": {"author": "xcode", "version": 1}}, indent=2))
print("Generated app icon and accent color assets.")
