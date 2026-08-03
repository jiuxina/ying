from pathlib import Path
from PIL import Image

root = Path(r"F:\xm\ying\daymark")
source = Image.open(root / "app.png").convert("RGBA")
icon_background = (9, 12, 22)


def composite_on_background(image: Image.Image) -> Image.Image:
    result = Image.new("RGB", image.size, icon_background)
    result.paste(image, mask=image.getchannel("A"))
    return result


def save_png(path: Path, size: int, *, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = source.resize((size, size), Image.Resampling.LANCZOS)
    output = composite_on_background(resized) if opaque else resized
    output.save(path, "PNG", optimize=True)


def place_in_safe_zone(path: Path, size: int, scale: float, *, opaque: bool) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    background = (*icon_background, 255) if opaque else (0, 0, 0, 0)
    canvas = Image.new("RGBA", (size, size), background)
    safe_size = round(size * scale)
    resized = source.resize((safe_size, safe_size), Image.Resampling.LANCZOS)
    offset = ((size - safe_size) // 2, (size - safe_size) // 2)
    canvas.alpha_composite(resized, offset)
    output = canvas.convert("RGB") if opaque else canvas
    output.save(path, "PNG", optimize=True)


android = {
    "mipmap-mdpi/ic_launcher.png": 48,
    "mipmap-hdpi/ic_launcher.png": 72,
    "mipmap-xhdpi/ic_launcher.png": 96,
    "mipmap-xxhdpi/ic_launcher.png": 144,
    "mipmap-xxxhdpi/ic_launcher.png": 192,
}
for relative, size in android.items():
    save_png(root / "android/app/src/main/res" / relative, size)
place_in_safe_zone(
    root / "android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png",
    432,
    0.66,
    opaque=False,
)

ios_set = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
ios = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}
for filename, size in ios.items():
    save_png(ios_set / filename, size, opaque=True)

mac_set = root / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
for size in (16, 32, 64, 128, 256, 512, 1024):
    save_png(mac_set / f"app_icon_{size}.png", size)

web = root / "web"
for filename, size in {
    "favicon.png": 32,
    "icons/Icon-192.png": 192,
    "icons/Icon-512.png": 512,
}.items():
    save_png(web / filename, size)
for filename, size in {
    "icons/Icon-maskable-192.png": 192,
    "icons/Icon-maskable-512.png": 512,
}.items():
    place_in_safe_zone(web / filename, size, 0.72, opaque=True)

source.save(
    root / "windows/runner/resources/app_icon.ico",
    format="ICO",
    sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
)
