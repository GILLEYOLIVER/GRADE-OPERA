from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets" / "branding" / "app_icon_master.png"
FINAL_PNG = ROOT / "assets" / "branding" / "app_icon.png"
WINDOWS_ICO = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
MACOS_ICON_DIR = (
    ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
)

BACKGROUND = (118, 118, 118)
ICON_SIZES = (16, 20, 24, 32, 40, 48, 64, 128, 256)
MACOS_SIZES = (16, 32, 64, 128, 256, 512, 1024)


def flatten_brand_colors(image: Image.Image) -> Image.Image:
    """Converte a arte gerada em cinza e branco planos, preservando as bordas."""
    source = image.convert("RGB")
    output = Image.new("RGB", source.size, BACKGROUND)
    source_pixels = source.load()
    output_pixels = output.load()

    for y in range(source.height):
        for x in range(source.width):
            red, green, blue = source_pixels[x, y]
            luminance = (red * 299 + green * 587 + blue * 114) / 1000
            coverage = max(0.0, min(1.0, (luminance - 150) / 80))
            output_pixels[x, y] = tuple(
                round(background + (255 - background) * coverage)
                for background in BACKGROUND
            )

    return output


def main() -> None:
    master = Image.open(MASTER)
    side = min(master.size)
    left = (master.width - side) // 2
    top = (master.height - side) // 2
    square = master.crop((left, top, left + side, top + side))
    final = flatten_brand_colors(square)

    FINAL_PNG.parent.mkdir(parents=True, exist_ok=True)
    final.save(FINAL_PNG, format="PNG", optimize=True)

    WINDOWS_ICO.parent.mkdir(parents=True, exist_ok=True)
    final.save(WINDOWS_ICO, format="ICO", sizes=[(size, size) for size in ICON_SIZES])

    MACOS_ICON_DIR.mkdir(parents=True, exist_ok=True)
    for size in MACOS_SIZES:
        resized = final.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(MACOS_ICON_DIR / f"app_icon_{size}.png", optimize=True)

    print(f"PNG: {FINAL_PNG}")
    print(f"ICO: {WINDOWS_ICO}")
    print(f"macOS: {MACOS_ICON_DIR}")


if __name__ == "__main__":
    main()
