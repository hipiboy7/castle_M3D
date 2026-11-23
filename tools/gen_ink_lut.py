"""절차 생성 GPU 화풍 LUT 텍스처(assets/textures/ink_lut.png — 256x256 타일 가능 RGBA8).

채널 배치(src/view/shaders/ink_cel.gdshader 가 샘플링 — 매 픽셀 FBM · 보로노이 루프 대체):
  R: 방향성 붓칠 스트로크(1:3 늘인 다중 옥타브 타일 잡음, 0.5 중심)
  G: 수채화 얼룩 · 풍화 패치(저주파 3옥타브 타일 잡음, 0.5 중심)
  B: 유기적 보로노이 바닥 균열 거리장(d2 - d1, 0 = 균열 위 · 1 = 먼 곳)
  A: 손떨림 웹툰 펜 해칭(타일 가능 대각선 빗금, 0 = 여백 · 1 = 잉크 선)

실행: python3.11 tools/gen_ink_lut.py
"""
import math
import os
from PIL import Image

SIZE = 256
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "textures", "ink_lut.png")


def h2(ix: int, iy: int, seed: int = 0) -> float:
    n = (ix * 374761393 + iy * 668265263 + seed * 1442695041) & 0x7FFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0x7FFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def tile_vnoise(u: float, v: float, px: int, py: int, seed: int = 0) -> float:
    x = u * px
    y = v * py
    ix = math.floor(x)
    iy = math.floor(y)
    fx = x - ix
    fy = y - iy
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)
    x0, x1 = ix % px, (ix + 1) % px
    y0, y1 = iy % py, (iy + 1) % py
    a = h2(x0, y0, seed) * (1.0 - fx) + h2(x1, y0, seed) * fx
    b = h2(x0, y1, seed) * (1.0 - fx) + h2(x1, y1, seed) * fx
    return a * (1.0 - fy) + b * fy


def tile_fbm(u: float, v: float, px: int, py: int, octaves: int = 3, seed: int = 0) -> float:
    val = 0.0
    amp = 0.5
    norm = 0.0
    for o in range(octaves):
        val += amp * tile_vnoise(u, v, px << o, py << o, seed + o * 31)
        norm += amp
        amp *= 0.5
    return val / norm


def voronoi_edge(u: float, v: float, cells: int, seed: int = 17) -> float:
    # 유기적 구불거림(domain warp)을 타일 주기 내에서 가함
    wu = (u + (tile_fbm(u, v, 4, 4, 2, seed + 101) - 0.5) * 0.08) % 1.0
    wv = (v + (tile_fbm(u, v, 4, 4, 2, seed + 211) - 0.5) * 0.08) % 1.0
    gx = wu * cells
    gy = wv * cells
    ix = math.floor(gx)
    iy = math.floor(gy)
    fx = gx - ix
    fy = gy - iy
    d1 = 8.0
    d2 = 8.0
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            cx = (ix + dx) % cells
            cy = (iy + dy) % cells
            ox = h2(cx, cy, seed)
            oy = h2(cx, cy, seed + 73)
            px = dx + ox - fx
            py = dy + oy - fy
            d = math.hypot(px, py)
            if d < d1:
                d2 = d1
                d1 = d
            elif d < d2:
                d2 = d
    return min(1.0, max(0.0, (d2 - d1) * 1.8))


def smoothstep(e0: float, e1: float, x: float) -> float:
    t = min(1.0, max(0.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def main() -> None:
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img = Image.new("RGBA", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        v = y / SIZE
        for x in range(SIZE):
            u = x / SIZE
            # R: 방향성 붓칠 스트로크(가로:세로 = 1:3)
            stroke = tile_fbm(u, v, 6, 18, 3, seed=11)
            # G: 수채화 얼룩 · 풍화 패치
            patch = tile_fbm(u, v, 3, 3, 3, seed=47)
            # B: 유기적 보로노이 균열 거리장(0 = 금, 1 = 멀리)
            crack = voronoi_edge(u, v, cells=5, seed=83)
            # A: 손떨림 웹툰 펜 해칭(타일 주기 32줄 대각선 + 끊김)
            wob = (tile_vnoise(u, v, 8, 8, seed=131) - 0.5) * 0.45
            phase = ((u + v) * 32.0 + wob) % 1.0
            dist = abs(phase - 0.5) * 2.0
            line = 1.0 - smoothstep(0.18, 0.42, dist)
            brk = smoothstep(0.24, 0.44, tile_vnoise(u, v, 10, 10, seed=197))
            hatch = line * (0.25 + 0.75 * brk)
            px[x, y] = (
                int(round(min(1.0, max(0.0, stroke)) * 255)),
                int(round(min(1.0, max(0.0, patch)) * 255)),
                int(round(min(1.0, max(0.0, crack)) * 255)),
                int(round(min(1.0, max(0.0, hatch)) * 255)),
            )
    img.save(OUT, optimize=True)
    print(f"Wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
