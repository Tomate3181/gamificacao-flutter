"""Gera todos os sprites em pixel art do EcoPlanet.

Estilo (GDD, seção 11): pixel art com contorno escuro, paleta do céu noturno
(azul-marinho, teal, lilás, rosa-quente) e dourado para destaques.

Os desenhos são matrizes de texto: cada caractere é um pixel e '.' é
transparente. O contorno escuro e a sombra (luz vindo de cima) são
aplicados automaticamente, para todos os sprites terem o mesmo acabamento.

Rodar a partir da raiz do projeto:

    python tool/sprites/generate_sprites.py [--preview PASTA]

Saída em assets/sprites/<grupo>/<nome>.png, no tamanho real.
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites"

RGBA = tuple[int, int, int, int]

OUTLINE: RGBA = (0x1E, 0x12, 0x38, 255)
NAVY = (0x1E, 0x12, 0x38)


# ---------------------------------------------------------------------------
# Cores
# ---------------------------------------------------------------------------
def hex_rgba(value: str) -> RGBA:
    value = value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), 255)


def mix(a: RGBA, b: tuple[int, int, int], t: float) -> RGBA:
    return (
        round(a[0] + (b[0] - a[0]) * t),
        round(a[1] + (b[1] - a[1]) * t),
        round(a[2] + (b[2] - a[2]) * t),
        255,
    )


def light(color: RGBA) -> RGBA:
    return mix(color, (255, 248, 225), 0.28)


def dark(color: RGBA) -> RGBA:
    # Sombra puxada para o roxo do contorno, para combinar com o céu.
    return mix((round(color[0] * 0.78), round(color[1] * 0.78), round(color[2] * 0.82), 255), NAVY, 0.18)


class Shaded:
    """Cor com sombra automática: claro no topo, escuro embaixo/direita."""

    def __init__(self, base: str, texture: bool = True) -> None:
        self.base = hex_rgba(base)
        self.light = light(self.base)
        self.dark = dark(self.base)
        self.texture = texture


Palette = dict[str, "str | Shaded"]


# ---------------------------------------------------------------------------
# Renderização de matrizes
# ---------------------------------------------------------------------------
def to_grid(rows: list[str]) -> list[list[str | None]]:
    width = len(rows[0])
    grid: list[list[str | None]] = []
    for y, row in enumerate(rows):
        if len(row) != width:
            raise ValueError(f"linha {y} com {len(row)} pixels, esperado {width}: {row!r}")
        grid.append([None if c == "." else c for c in row])
    return grid


def render(
    grid: list[list[str | None]],
    palette: Palette,
    outline: bool = True,
    no_outline: frozenset[str] = frozenset(),
) -> Image.Image:
    height, width = len(grid), len(grid[0])
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))

    def at(x: int, y: int) -> str | None:
        if 0 <= x < width and 0 <= y < height:
            return grid[y][x]
        return None

    for y in range(height):
        for x in range(width):
            char = grid[y][x]
            if char is None:
                continue
            spec = palette[char]
            if isinstance(spec, Shaded):
                if at(x, y - 1) != char:
                    color = spec.light
                elif at(x, y + 1) != char or at(x + 1, y) != char:
                    color = spec.dark
                elif spec.texture and (x * 7 + y * 13 + x * y) % 9 == 0:
                    color = spec.dark
                else:
                    color = spec.base
            else:
                color = hex_rgba(spec)
            image.putpixel((x, y), color)

    if outline:
        for y in range(height):
            for x in range(width):
                if grid[y][x] is not None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    neighbor = at(x + dx, y + dy)
                    if neighbor is not None and neighbor not in no_outline:
                        image.putpixel((x, y), OUTLINE)
                        break
    return image


def sprite(rows: list[str], palette: Palette, **kwargs) -> Image.Image:
    return render(to_grid(rows), palette, **kwargs)


# ---------------------------------------------------------------------------
# Lumi (16x16): espírito dourado com antena brilhante e asinhas lilás
# ---------------------------------------------------------------------------
LUMI_BODY = [
    "................",
    "................",
    ".......GG.......",
    "................",
    "................",
    ".....GGgggg.....",
    "....GGgggggd....",
    "....Ggeggegd....",
    "....gcggggcd....",
    ".....gggggd.....",
    ".....gggggd.....",
    "......gggd......",
    ".......dd.......",
    "................",
    "................",
    "................",
]

LUMI_PALETTE: Palette = {
    "G": "#FFE6A0",  # brilho
    "g": "#FFC94A",  # dourado
    "d": "#D99A2B",  # sombra
    "e": "#1E1238",  # olhos
    "c": "#FF8FB1",  # bochechas
    "r": "#C2456E",  # boca
    "W": "#E8DEFF",  # asa clara
    "w": "#B69CFF",  # asa lilás
    "T": "#2EC4B6",  # bolha de oxigênio
    "t": "#B8FFF5",  # brilho da bolha
    "S": "#FFF6C8",  # centro do brilho
    "s": "#FFC94A",  # pontas do brilho
}

# Asa esquerda em três posições (x, y, cor). A direita é espelhada.
WINGS = {
    "mid": [(1, 9, "W"), (2, 9, "W"), (3, 9, "w"), (2, 10, "W"), (3, 10, "w")],
    "up": [(1, 7, "W"), (2, 7, "W"), (2, 8, "W"), (3, 8, "w"), (3, 9, "w")],
    "down": [(1, 10, "W"), (2, 10, "W"), (3, 10, "w"), (2, 11, "W"), (3, 11, "w")],
}


def sparkle(cx: int, cy: int) -> list[tuple[int, int, str]]:
    return [(cx, cy, "S"), (cx - 1, cy, "s"), (cx + 1, cy, "s"), (cx, cy - 1, "s"), (cx, cy + 1, "s")]


def lumi_frame(
    wings: str,
    dy: int = 0,
    face: str = "normal",
    sparkles: tuple[tuple[int, int], ...] = (),
    orb: bool = False,
) -> Image.Image:
    grid = to_grid(LUMI_BODY)

    if face == "look":  # olhando para o lado (seguindo)
        grid[7][6], grid[7][9] = "g", "g"
        grid[7][7], grid[7][10] = "e", "e"
    elif face == "happy":  # sorriso
        grid[9][7], grid[9][8] = "r", "r"
    elif face == "blink":
        grid[7][6], grid[7][9] = "d", "d"

    for x, y, char in WINGS[wings]:
        grid[y][x] = char
        grid[y][15 - x] = char

    if orb:
        for x, y, char in ((7, 13, "t"), (8, 13, "T"), (7, 14, "T"), (8, 14, "T")):
            grid[y][x] = char

    # Sobe/desce o corpo inteiro.
    if dy:
        empty = [None] * 16
        shifted = [list(empty) for _ in range(16)]
        for y in range(16):
            if 0 <= y + dy < 16:
                shifted[y + dy] = grid[y]
        grid = shifted

    for cx, cy in sparkles:
        for x, y, char in sparkle(cx, cy):
            if 0 <= x < 16 and 0 <= y < 16 and grid[y][x] is None:
                grid[y][x] = char

    return render(grid, LUMI_PALETTE, no_outline=frozenset("Ss"))


def lumi_sprites() -> dict[str, Image.Image]:
    frames = {
        # Vagando: bate as asas devagar e pisca de vez em quando.
        "wandering": [
            lumi_frame("mid"),
            lumi_frame("down", dy=-1),
            lumi_frame("mid"),
            lumi_frame("up", face="blink"),
        ],
        # Seguindo: olha para o lado e bate as asas rápido.
        "following": [
            lumi_frame("up", face="look"),
            lumi_frame("down", dy=-1, face="look"),
            lumi_frame("up", face="look"),
            lumi_frame("down", dy=-1, face="look"),
        ],
        # Feliz: sorri, pula e solta brilhos.
        "happy": [
            lumi_frame("down", face="happy", sparkles=((2, 3),)),
            lumi_frame("up", dy=-1, face="happy", sparkles=((13, 2),)),
            lumi_frame("down", dy=-1, face="happy", sparkles=((2, 4), (13, 12))),
            lumi_frame("mid", face="happy", sparkles=((13, 4),)),
        ],
        # Coletando: segura uma bolha de oxigênio e brilhos sobem.
        "collecting": [
            lumi_frame("mid", orb=True, sparkles=((12, 12),)),
            lumi_frame("up", orb=True, sparkles=((12, 9),)),
            lumi_frame("mid", orb=True, sparkles=((12, 6), (3, 12))),
            lumi_frame("down", orb=True, sparkles=((3, 9),)),
        ],
    }
    return {
        f"lumi/lumi_{state}_{i}": image
        for state, images in frames.items()
        for i, image in enumerate(images)
    }


# ---------------------------------------------------------------------------
# Árvores (16x16), na ordem da tabela de espécies (seção 5)
# ---------------------------------------------------------------------------
BARK = Shaded("#7A4A2E", texture=False)

TREES: dict[str, tuple[list[str], Palette]] = {
    # 1. Muda: arvorezinha jovem
    "tree_1": (
        [
            "................",
            "................",
            "................",
            "................",
            "................",
            "......LLLL......",
            "....LLLLLLLL....",
            "...LLLLLLLLLL...",
            "...LLLLLLLLLL...",
            "....LLLLLLLL....",
            "......LRRL......",
            ".......RR.......",
            ".......RR.......",
            ".......RR.......",
            "......RRRR......",
            "................",
        ],
        {"L": Shaded("#5BD16F"), "R": BARK},
    ),
    # 2. Bambu: hastes com nós
    "tree_2": (
        [
            "................",
            "....l.....l.....",
            "...lBB...BBl....",
            "....BB..lBB.....",
            "....bb...bb.....",
            "..llBB...BBll...",
            "....BB...BB.....",
            "....BBl..bb.....",
            "....bb..lBB.....",
            "....BB...BB..B..",
            "...lBB...BB.lB..",
            "....BB...bb..b..",
            "....bb...BB..B..",
            "....BB...BB..B..",
            "....BB...BB..B..",
            "................",
        ],
        {"B": Shaded("#9BD65A", texture=False), "b": "#5E8F2E", "l": "#4FB860"},
    ),
    # 3. Carvalho: copa larga e tronco grosso
    "tree_3": (
        [
            "................",
            "....LLL..LLL....",
            "..LLLLLLLLLLLL..",
            ".LLLLLLLLLLLLLL.",
            ".LLLLLLLLLLLLLL.",
            ".LLLLLLLLLLLLLL.",
            "..LLLLLLLLLLLL..",
            "...LLLLLLLLLL...",
            ".....LLRRLL.....",
            "......RRRR......",
            ".......RR.......",
            ".......RR.......",
            ".......RR.......",
            "......RRRR......",
            ".....RR..RR.....",
            "................",
        ],
        {"L": Shaded("#3A9A4F"), "R": BARK},
    ),
    # 4. Pinheiro: camadas com neve (bônus em planetas frios)
    "tree_4": (
        [
            "................",
            ".......ss.......",
            "......NNNN......",
            ".....NNNNNN.....",
            "......sNNN......",
            ".....NNNNNN.....",
            "....sNNNNNNN....",
            ".....NNNNNN.....",
            "....NNNNNNNs....",
            "...NNNNNNNNNN...",
            "..sNNNNNNNNNNN..",
            ".......RR.......",
            ".......RR.......",
            ".......RR.......",
            "......RRRR......",
            "................",
        ],
        {"N": Shaded("#1F7A5C"), "s": "#E8F0FF", "R": BARK},
    ),
    # 5. Cerejeira: copa rosa com flores
    "tree_5": (
        [
            "................",
            ".....PPPPPP.....",
            "...PPPPPPPPPP...",
            "..PPpPPPPPPpPP..",
            ".PPPPPPpPPPPPPP.",
            ".PpPPPPPPPPPpPP.",
            ".PPPPPpPPPPPPPP.",
            "..PPPPPPPPpPPP..",
            "...PPPRRPPPP....",
            ".......RR.......",
            "......RR........",
            "......RR........",
            ".......RR.......",
            ".......RR.......",
            "......RRRR......",
            "................",
        ],
        {"P": Shaded("#FF8FB1"), "p": "#FFE3EE", "R": Shaded("#5A3442", texture=False)},
    ),
    # 6. Mangue: raízes sobre a água (bônus em planetas com água)
    "tree_6": (
        [
            "................",
            ".....LLLLLL.....",
            "...LLLLLLLLLL...",
            "..LLLLLLLLLLLL..",
            "..LLLLLLLLLLLL..",
            "...LLLLLLLLLL...",
            ".....LRRRRL.....",
            "......RRRR......",
            ".......RR.......",
            "......RRRR......",
            ".....RRRRRR.....",
            "....RR.RR.RR....",
            "...RR..RR..RR...",
            ".wwRRwwRRwwRRww.",
            "..wwwwwwwwwwww..",
            "................",
        ],
        {"L": Shaded("#2F9E6E"), "R": BARK, "w": "#3FA7E0"},
    ),
    # 7. Sequoia: alta, tronco avermelhado
    "tree_7": (
        [
            "................",
            ".......QQ.......",
            "......QQQQ......",
            ".....QQQQQQ.....",
            "....QQQQQQQ.....",
            ".....QQQQQQQ....",
            "....QQQQQQQ.....",
            ".....QQQQQQQ....",
            "....QQQQQQQQ....",
            ".....QQQQQQQ....",
            "......QRRQ......",
            ".......RRR......",
            ".......RRR......",
            ".......RRR......",
            "......RRRRR.....",
            "................",
        ],
        {"Q": Shaded("#2A6B45"), "R": Shaded("#B4533A", texture=False)},
    ),
    # 8. Árvore ancestral: copa de aurora com frutos dourados (lendária)
    "tree_8": (
        [
            "................",
            "...AA.AAAA.AA...",
            "..AAAAAVAAAAAA..",
            ".AAYAAAAAAAVAAA.",
            ".AVAAAAAAAAAYAA.",
            ".AAAAYAAAAVAAAA.",
            "..AAAAAAAAAAAA..",
            "...AAVARRAAA....",
            "......RRRR......",
            ".......RY.......",
            ".......RR.......",
            "......RRRR......",
            ".....RRRRRR.....",
            "....RR.RR.RR....",
            "...RR..RR..RR...",
            "................",
        ],
        {
            "A": Shaded("#2EC4B6"),
            "V": "#B69CFF",
            "Y": "#FFE066",
            "R": Shaded("#6B4A8A", texture=False),
        },
    ),
    # Muda crescendo (antes de virar árvore)
    "sprout": (
        [
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "....LLL..LLL....",
            ".....LLLLLL.....",
            ".......SS.......",
            ".......SS.......",
            ".....MMMMMM.....",
            "....MMMMMMMM....",
            "................",
        ],
        {"L": Shaded("#7BE08A", texture=False), "S": "#4FA35A", "M": Shaded("#7A5236", texture=False)},
    ),
}


def tree_sprites() -> dict[str, Image.Image]:
    return {f"trees/{name}": sprite(rows, palette) for name, (rows, palette) in TREES.items()}


# ---------------------------------------------------------------------------
# Ruído suave e periódico (para terreno e planetas)
# ---------------------------------------------------------------------------
class ValueNoise:
    def __init__(self, seed: str, cells: int, period: int) -> None:
        rnd = random.Random(seed)
        self.cells = cells
        self.period = period
        self.values = [[rnd.random() for _ in range(cells)] for _ in range(cells)]

    def __call__(self, x: float, y: float) -> float:
        fx = x / self.period * self.cells
        fy = y / self.period * self.cells
        x0, y0 = math.floor(fx), math.floor(fy)
        tx, ty = fx - x0, fy - y0
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        c = self.cells

        def v(i: int, j: int) -> float:
            return self.values[j % c][i % c]

        top = v(x0, y0) + (v(x0 + 1, y0) - v(x0, y0)) * tx
        bottom = v(x0, y0 + 1) + (v(x0 + 1, y0 + 1) - v(x0, y0 + 1)) * tx
        return top + (bottom - top) * ty


# ---------------------------------------------------------------------------
# Terreno (16x16, emenda sem costura): poluído e reflorestado por tema
# ---------------------------------------------------------------------------
THEMES = ("desert", "forest", "island", "tundra", "mountain")

GROUND = {
    "desert": {
        "polluted": ("#7A6A55", "#6B5B49", "#8A7962"),
        "restored": ("#4FA35A", "#438F4E", "#C9A86A"),
    },
    "forest": {
        "polluted": ("#5A4A42", "#4E4039", "#66554B"),
        "restored": ("#2F8A4E", "#287843", "#3A9A57"),
    },
    "island": {
        "polluted": ("#6A6458", "#5C564B", "#77705F"),
        "restored": ("#3DA35D", "#348F51", "#4CB86B"),
    },
    "tundra": {
        "polluted": ("#6E6A72", "#5F5B63", "#7E7A84"),
        "restored": ("#4C9A6A", "#41885D", "#DDE8F5"),
    },
    "mountain": {
        "polluted": ("#5D5560", "#514A54", "#6B6370"),
        "restored": ("#3F8A55", "#367A4A", "#8A8396"),
    },
}

THEME_ACCENT = {
    "desert": "#E3C27E",  # areia
    "forest": "#6FCF7F",  # broto
    "island": "#3FA7E0",  # água
    "tundra": "#F4F8FF",  # neve
    "mountain": "#A49CB2",  # pedrinha
}


TILE_VARIANTS = ("a", "b", "c", "d")


def ground_tile(theme: str, kind: str, variant: str) -> Image.Image:
    seed = f"{theme}-{kind}-{variant}"
    rnd = random.Random(seed)
    noise = ValueNoise(seed, cells=4, period=16)
    base, shade, alt = (hex_rgba(c) for c in GROUND[theme][kind])

    image = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            n = noise(x, y) + rnd.uniform(-0.12, 0.12)
            color = shade if n < 0.38 else alt if n > 0.72 else base
            image.putpixel((x, y), color)

    def put(x: int, y: int, color: str) -> None:
        image.putpixel((x % 16, y % 16), hex_rgba(color))

    if kind == "polluted":
        ox, oy = rnd.randrange(16), rnd.randrange(16)
        if variant in "ac":
            # Mancha de óleo com reflexo.
            for dx, dy in ((0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1), (1, 2), (2, 2)):
                put(ox + dx, oy + dy, "#2B2233")
            put(ox + 1, oy + 1, "#5A4B7A")
        lx, ly = (ox + 8) % 16, (oy + 7) % 16
        if variant == "a":  # lata
            put(lx, ly, "#9AA3AD")
            put(lx + 1, ly, "#9AA3AD")
            put(lx + 2, ly, "#4A4E57")
            put(lx, ly - 1, "#C8D0D8")
        elif variant == "b":  # garrafa
            put(lx, ly, "#4E7A6A")
            put(lx, ly + 1, "#4E7A6A")
            put(lx, ly + 2, "#2F5247")
            put(lx, ly - 1, "#A9C9BC")
        if variant in "bd":
            # Galhos secos.
            tx, ty = rnd.randrange(16), rnd.randrange(16)
            for i in range(4):
                put(tx + i, ty - i // 2, "#3B302A")
        if variant == "d":
            # Fumaça de poluição.
            for _ in range(3):
                put(rnd.randrange(16), rnd.randrange(16), "#8C8494")
    else:
        # Tufos de grama.
        tuft = light(base)
        for _ in range(7):
            gx, gy = rnd.randrange(16), rnd.randrange(16)
            image.putpixel((gx, gy), tuft)
            image.putpixel((gx, (gy - 1) % 16), tuft)
            image.putpixel(((gx + 1) % 16, gy), dark(base))
        # Flores.
        flowers = {"a": ("#FF8FB1", "#FFC94A"), "b": ("#B69CFF",), "c": ("#FFF6C8", "#FF8FB1"), "d": ()}
        for color in flowers[variant]:
            fx, fy = rnd.randrange(16), rnd.randrange(16)
            put(fx, fy, color)
            put(fx + 1, fy, color)
            put(fx, fy + 1, color)
            put(fx + 1, fy + 1, "#FFFFFF")
        # Detalhe do tema.
        ax, ay = rnd.randrange(16), rnd.randrange(16)
        for dx, dy in ((0, 0), (1, 0), (0, 1)):
            put(ax + dx, ay + dy, THEME_ACCENT[theme])
    return image


def tile_sprites() -> dict[str, Image.Image]:
    return {
        f"tiles/{theme}_{kind}_{variant}": ground_tile(theme, kind, variant)
        for theme in THEMES
        for kind in ("polluted", "restored")
        for variant in TILE_VARIANTS
    }


# ---------------------------------------------------------------------------
# Planetas (32x32): um por tema, com luz vindo do canto superior esquerdo
# ---------------------------------------------------------------------------
PLANETS = {
    # (cor principal, cor secundária, detalhe, proporção da secundária)
    "desert": ("#D9A55B", "#B9773E", "#4FA35A", 0.42),
    "forest": ("#3A9157", "#2E6FB5", "#7BE08A", 0.35),
    "island": ("#2E7FC4", "#4CB86B", "#F2D49B", 0.45),
    "tundra": ("#E8F0FF", "#9CC7E8", "#5BAE7A", 0.40),
    "mountain": ("#7D7290", "#5D5470", "#4A9C60", 0.45),
}


def planet(theme: str) -> Image.Image:
    main, second, detail, share = PLANETS[theme]
    main_c, second_c, detail_c = hex_rgba(main), hex_rgba(second), hex_rgba(detail)
    noise = ValueNoise(f"planet-{theme}", cells=5, period=32)
    fine = ValueNoise(f"planet-fine-{theme}", cells=10, period=32)

    size, cx, cy, radius = 32, 15.5, 15.5, 13.6
    grid: list[list[str | None]] = [[None] * size for _ in range(size)]
    colors: dict[tuple[int, int], RGBA] = {}
    lx, ly, lz = -0.55, -0.6, 0.58

    for y in range(size):
        for x in range(size):
            dx, dy = (x - cx) / radius, (y - cy) / radius
            d2 = dx * dx + dy * dy
            if d2 > 1:
                continue
            nz = math.sqrt(1 - d2)
            lit = dx * lx + dy * ly + nz * lz

            n = noise(x, y)
            if n < share:
                color = second_c
            elif fine(x, y) > 0.8:
                color = detail_c
            else:
                color = main_c

            if lit > 0.72:
                color = light(color)
            elif lit < 0.05:
                color = dark(dark(color))
            elif lit < 0.3:
                color = dark(color)
            grid[y][x] = "x"
            colors[(x, y)] = color

    # Brilho especular no canto iluminado.
    for x, y in ((9, 8), (10, 8), (9, 9)):
        colors[(x, y)] = (255, 250, 235, 255)

    image = render(grid, {"x": "#000000"})
    for (x, y), color in colors.items():
        image.putpixel((x, y), color)
    return image


def planet_sprites() -> dict[str, Image.Image]:
    return {f"planets/planet_{theme}": planet(theme) for theme in THEMES}


# ---------------------------------------------------------------------------
# Ícones de recurso (16x16)
# ---------------------------------------------------------------------------
ICONS: dict[str, tuple[list[str], Palette]] = {
    "energy": (
        [
            "................",
            "........YYY.....",
            ".......YYY......",
            "......YYY.......",
            ".....YYYY.......",
            "....YYYYYYYY....",
            "....YYYYYYYY....",
            "........YYY.....",
            ".......YYY......",
            "......YYY.......",
            ".....YYY........",
            "....YY..........",
            "...Y............",
            "................",
            "................",
            "................",
        ],
        {"Y": Shaded("#FFC94A", texture=False)},
    ),
    "oxygen": (
        [
            "................",
            "............oo..",
            ".....OOOOOO.oo..",
            "....OOOOOOOO....",
            "...OhhOOOOOOO...",
            "..OOhOOOOOOOOO..",
            "..OOOOOOOOOOOO..",
            "..OOOOOOOOOOOO..",
            "..OOOOOOOOOOOO..",
            "..OOOOOOOOOOOO..",
            "..OOOOOOOOOOOO..",
            "...OOOOOOOOOO...",
            "....OOOOOOOO....",
            ".....OOOOOO.....",
            "................",
            "................",
        ],
        {"O": Shaded("#2EC4B6", texture=False), "h": "#E6FFFB", "o": "#8FF0E6"},
    ),
    "points": (
        [
            "................",
            ".......SS.......",
            ".......SS.......",
            "......SSSS......",
            "......SSSS......",
            ".SSSSSSSSSSSSSS.",
            "..SSSSSSSSSSSS..",
            "...SSSSSSSSSS...",
            "....SSSSSSSS....",
            "....SSSSSSSS....",
            "...SSSSSSSSSS...",
            "...SSSS..SSSS...",
            "..SSS......SSS..",
            "..SS........SS..",
            "................",
            "................",
        ],
        {"S": Shaded("#FF5D8F", texture=False)},
    ),
}


def icon_sprites() -> dict[str, Image.Image]:
    return {f"icons/{name}": sprite(rows, palette) for name, (rows, palette) in ICONS.items()}


# ---------------------------------------------------------------------------
# Saída
# ---------------------------------------------------------------------------
def all_sprites() -> dict[str, Image.Image]:
    images: dict[str, Image.Image] = {}
    for builder in (lumi_sprites, tree_sprites, tile_sprites, planet_sprites, icon_sprites):
        images.update(builder())
    return images


def write_preview(images: dict[str, Image.Image], folder: Path, scale: int = 6) -> Path:
    """Prancha ampliada sobre o azul-marinho do céu, agrupada por pasta."""
    groups: dict[str, list[Image.Image]] = {}
    for name, image in images.items():
        groups.setdefault(name.split("/")[0], []).append(image)

    pad, columns = 12, 10
    cell = 32 * scale
    rows = sum(math.ceil(len(group) / columns) for group in groups.values())
    sheet = Image.new(
        "RGBA",
        (pad + columns * (cell + pad), pad + rows * (cell + pad)),
        (0x0B, 0x16, 0x30, 255),
    )
    row = 0
    for group in groups.values():
        for index, image in enumerate(group):
            big = image.resize((image.width * scale, image.height * scale), Image.NEAREST)
            x = pad + (index % columns) * (cell + pad)
            y = pad + (row + index // columns) * (cell + pad)
            sheet.alpha_composite(big, (x + (cell - big.width) // 2, y + (cell - big.height) // 2))
        row += math.ceil(len(group) / columns)

    folder.mkdir(parents=True, exist_ok=True)
    path = folder / "sprites_preview.png"
    sheet.save(path)
    return path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", type=Path, help="pasta para a prancha ampliada")
    args = parser.parse_args()

    images = all_sprites()
    for name, image in images.items():
        path = OUT_DIR / f"{name}.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path)
    print(f"{len(images)} sprites em {OUT_DIR.relative_to(ROOT)}")

    if args.preview:
        print("preview", write_preview(images, args.preview))


if __name__ == "__main__":
    main()
