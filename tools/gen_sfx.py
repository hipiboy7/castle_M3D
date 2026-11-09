"""이 판이 직접 만드는 효과음(절차 생성 · 표준 라이브러리만) — 같은 시드면 같은 파일.

    python3.11 tools/gen_sfx.py     # assets/sfx/shot.wav (근거리 사격 — 경호대 최후의 4인 t_shot)
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def shot(path):
    random.seed(45)
    sr, n = 22050, int(22050 * 0.32)
    lp, out = 0.0, []
    for i in range(n):
        t = i / sr
        env = math.exp(-t * 22) * (1.0 if t > 0.002 else t / 0.002)
        lp += (random.uniform(-1, 1) - lp) * 0.35          # 거친 소음(낮은 쪽만) + 낮은 '쿵'
        body = math.sin(2 * math.pi * 90 * t) * math.exp(-t * 30)
        v = (0.75 * lp + 0.5 * body) * env
        out.append(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 30000)))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(b"".join(out))


if __name__ == "__main__":
    shot(os.path.join(ROOT, "assets", "sfx", "shot.wav"))
    print("assets/sfx/shot.wav")
