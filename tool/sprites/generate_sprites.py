"""Gera os sprites em pixel art do EcoPlanet a partir de matrizes de texto.

Cada caractere da matriz é um pixel; '.' é transparente. As cores seguem a
paleta do GDD (seção 11). Rodar a partir da raiz do projeto:

    python tool/sprites/generate_sprites.py [--preview PASTA]

Saída: assets/sprites/<grupo>/<nome>.png (tamanho real, sem escala).
Com --preview, grava também uma prancha ampliada para revisão.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites"

# Paleta (RGBA). Contorno escuro em todos os sprites.
PALETTE: dict[str, tuple[int, int, int, int]] = {
    "o": (0x1E, 0x12, 0x38, 255),  # contorno
    "g": (0xFF, 0xC9, 0x4A, 255),  # dourado
    "G": (0xFF, 0xE6, 0xA0, 255),  # dourado claro (brilho)
    "d": (0xD9, 0x9A, 0x2B, 255),  # dourado escuro (sombra)
    "e": (0x1E, 0x12, 0x38, 255),  # olho
    "c": (0xFF, 0x8F, 0xB1, 255),  # bochecha rosa
    "w": (0xB6, 0x9C, 0xFF, 255),  # asa lilás
    "W": (0xE8, 0xDE, 0xFF, 255),  # asa clara
}

# Lumi, 16x16: espírito dourado com antena brilhante e asinhas lilás.
LUMI_IDLE = [
    "................",
    ".......oo.......",
    "......oGGo......",
    ".......oo.......",
    ".....oooooo.....",
    "....oGGggggo....",
    "...oGGgggggdo...",
    "...oGgeggegdo...",
    "oo.ogcggggcdo.oo",
    "oWWwogggggdowWWo",
    ".oWwogggggdowWo.",
    "..oo.oggggdo.oo.",
    "......oddo......",
    ".......oo.......",
    "................",
    "................",
]

SPRITES: dict[str, list[str]] = {
    "lumi/lumi_idle_0": LUMI_IDLE,
}


def render(rows: list[str]) -> Image.Image:
    height = len(rows)
    width = len(rows[0])
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        if len(row) != width:
            raise ValueError(f"linha {y} com {len(row)} pixels, esperado {width}")
        for x, char in enumerate(row):
            if char == ".":
                continue
            image.putpixel((x, y), PALETTE[char])
    return image


def write_preview(images: dict[str, Image.Image], folder: Path, scale: int = 12) -> Path:
    """Prancha ampliada sobre o azul-marinho do céu, para revisão."""
    pad = 16
    cell = max(max(i.width, i.height) for i in images.values()) * scale
    sheet = Image.new(
        "RGBA",
        (pad + len(images) * (cell + pad), cell + 2 * pad),
        (0x0B, 0x16, 0x30, 255),
    )
    for index, image in enumerate(images.values()):
        big = image.resize((image.width * scale, image.height * scale), Image.NEAREST)
        sheet.alpha_composite(big, (pad + index * (cell + pad), pad))
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / "sprites_preview.png"
    sheet.save(path)
    return path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", type=Path, help="pasta para a prancha ampliada")
    args = parser.parse_args()

    images = {name: render(rows) for name, rows in SPRITES.items()}
    for name, image in images.items():
        path = OUT_DIR / f"{name}.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path)
        print("gerado", path.relative_to(ROOT))

    if args.preview:
        print("preview", write_preview(images, args.preview))


if __name__ == "__main__":
    main()
