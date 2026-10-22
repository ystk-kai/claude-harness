#!/usr/bin/env python3
"""OKLCH の前景色と背景色について、WCAG 2.x のコントラスト比と、彩度を落とさずに通す候補を出す。

使い方:
  chroma-check.py FG BG [--target 4.5]
  FG / BG は "L C H" (L は 0-100 の %、例: "58 0.16 35") か #rrggbb。
  FG を #rrggbb で渡すと比だけを出す (候補の探索は OKLCH で渡したときだけ)。

出力:
  - 現在の比と、FG の C が sRGB で取れる最大 C の何割か
  - 色相 H を保ったまま、目標比を満たす L のうち C を最大にできる候補 (sRGB 内)
    彩度を下げて比を稼いでいないかを見るための値で、どれを採るかは判断する側が決める
"""
import math
import sys


def oklch_to_lin(L, C, h):
    a, b = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)


def hex_to_lin(x):
    x = x.lstrip("#")
    if len(x) == 3:
        x = "".join(c * 2 for c in x)
    out = []
    for i in (0, 2, 4):
        c = int(x[i:i + 2], 16) / 255
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


def lin_to_hex(rgb):
    def enc(c):
        c = min(max(c, 0.0), 1.0)
        return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
    return "#" + "".join("%02x" % round(enc(c) * 255) for c in rgb)


def in_gamut(rgb):
    return all(-1e-4 <= c <= 1 + 1e-4 for c in rgb)


def lum(rgb):
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]


def ratio(y1, y2):
    hi, lo = max(y1, y2), min(y1, y2)
    return (hi + 0.05) / (lo + 0.05)


def max_c(L, h):
    lo, hi = 0.0, 0.5
    for _ in range(40):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if in_gamut(oklch_to_lin(L, mid, h)) else (lo, mid)
    return lo


def parse(arg):
    if arg.startswith("#"):
        return None, hex_to_lin(arg)
    L, C, h = (float(v) for v in arg.replace(",", " ").split())
    L /= 100
    if not in_gamut(oklch_to_lin(L, C, h)):
        cap = max_c(L, h)
        print(f"warn: oklch({L * 100:g}% {C:g} {h:g}) は sRGB 外。C だけを {cap:.3f} に落として計算する")
        C = cap
    return (L, C, h), oklch_to_lin(L, C, h)


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    target = float(argv[argv.index("--target") + 1]) if "--target" in argv else 4.5
    fg, fg_rgb = parse(argv[0])
    _, bg_rgb = parse(argv[1])
    y_bg = lum(bg_rgb)
    print(f"ratio {ratio(lum(fg_rgb), y_bg):.2f}:1 (target {target}:1)  fg {lin_to_hex(fg_rgb)}  bg {lin_to_hex(bg_rgb)}")
    if fg is None:
        return
    L, C, h = fg
    print(f"fg C {C:.3f} / sRGB 最大 {max_c(L, h):.3f} (L {L * 100:.1f}%, H {h:g})")
    best = None
    for i in range(50, 990, 5):
        Lc = i / 1000
        Cc = max_c(Lc, h)
        if ratio(lum(oklch_to_lin(Lc, Cc, h)), y_bg) >= target and (best is None or Cc > best[1]):
            best = (Lc, Cc)
    if best:
        print(f"同じ H で比を満たし C が最大の候補: oklch({best[0] * 100:.1f}% {best[1]:.3f} {h:g}) "
              f"{lin_to_hex(oklch_to_lin(best[0], best[1], h))}")
    else:
        print("同じ H では目標比を満たせない。役割を入れ替える (この色を面に使い、文字は ink にする)")


if __name__ == "__main__":
    main(sys.argv[1:])
