"""고정 버전 Godot 받기 (Windows 개발 서버용).

입력: 없음 (버전은 아래 VERSION 한 곳 — CI 는 .github/workflows/android.yml 의 GODOT_VERSION 과 같게 둔다)
출력: .tools/godot/<VERSION>/Godot_v<VERSION>_win64_console.exe (콘솔 출력이 보이는 실행 파일)
멱등: 이미 있으면 다시 받지 않는다. 내보내기 템플릿(약 1.2GB)은 받지 않는다 — APK 는 CI 가 만든다.

    py -3.12 scripts/get_godot.py          # 받고 경로를 찍는다
"""
import os
import sys
import urllib.request
import zipfile

VERSION = "4.7.2-stable"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(ROOT, ".tools", "godot", VERSION)
ZIP_NAME = f"Godot_v{VERSION}_win64.exe.zip"
URL = f"https://github.com/godotengine/godot/releases/download/{VERSION}/{ZIP_NAME}"
EXE = os.path.join(DEST, f"Godot_v{VERSION}_win64_console.exe")


def main():
    if os.path.exists(EXE):
        print(EXE)
        return 0
    os.makedirs(DEST, exist_ok=True)
    zpath = os.path.join(DEST, ZIP_NAME)
    if not os.path.exists(zpath):
        print(f"받는 중: {URL}", file=sys.stderr)
        tmp = zpath + ".part"
        urllib.request.urlretrieve(URL, tmp)
        os.replace(tmp, zpath)
    with zipfile.ZipFile(zpath) as z:
        z.extractall(DEST)
    os.remove(zpath)
    if not os.path.exists(EXE):
        print(f"실행 파일이 없다: {EXE}", file=sys.stderr)
        return 1
    print(EXE)
    return 0


if __name__ == "__main__":
    sys.exit(main())
