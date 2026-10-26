"""GitHub Actions 도우미 — gh CLI 없이 REST. 토큰은 Git Credential Manager 에서 받고 화면 · 파일에 남기지 않는다.

    py -3.12 tools/ci.py runs [N]                 최근 run N개 (번호 · id · 브랜치 · 상태 · 결과)
    py -3.12 tools/ci.py status [RUN_ID]          run 의 잡 · 단계별 결과 (없으면 가장 최근 run)
    py -3.12 tools/ci.py watch RUN_ID [초]        끝날 때까지 기다렸다가 status 를 찍는다 (성공 0 · 실패 1)
    py -3.12 tools/ci.py fetch RUN_ID 폴더 [이름..] 아티팩트를 받아 풀기 (이름 없으면 20MB 넘는 APK 는 뺀다)
    py -3.12 tools/ci.py log JOB_ID 파일           잡 로그(글) 저장
    py -3.12 tools/ci.py dispatch [브랜치]          workflow_dispatch 로 다시 돌리기 (기본 impl-draft1)
    py -3.12 tools/ci.py cancel RUN_ID [--force]   취소 (!cancelled() 가 아닌 always() 단계는 --force 라야 멈춘다)

Git Bash 에서 부를 때는 경로 바뀜을 막는다: MSYS_NO_PATHCONV=1. 아티팩트 · 로그 내려받기는 GitHub 가 돌려주는
서명된 주소로 다시 받으며, 그때는 토큰을 붙이지 않는다.
"""
import io
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile

REPO = "hipiboy7/castle_M3D"
WORKFLOW = "android.yml"
API = "https://api.github.com"
_tok = None


def token():
    global _tok
    if _tok is None:
        p = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n",
                           capture_output=True, text=True, timeout=60)
        _tok = next((ln[9:] for ln in p.stdout.splitlines() if ln.startswith("password=")), None)
        if not _tok:
            sys.exit("git credential fill 에서 토큰을 못 받았다")
    return _tok


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def call(method, path, body=None):
    req = urllib.request.Request(API + path, method=method,
                                 data=None if body is None else json.dumps(body).encode())
    req.add_header("Authorization", "Bearer " + token())
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            c = r.read()
            return r.status, (json.loads(c) if c else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")[:300]


def download(path):
    """302 로 돌려주는 서명된 주소를 토큰 없이 받는다."""
    req = urllib.request.Request(API + path)
    req.add_header("Authorization", "Bearer " + token())
    try:
        return urllib.request.build_opener(_NoRedirect).open(req, timeout=120).read()
    except urllib.error.HTTPError as e:
        if e.code not in (301, 302, 303, 307, 308):
            raise
        with urllib.request.urlopen(e.headers["Location"], timeout=600) as r:
            return r.read()


def latest_run():
    st, js = call("GET", f"/repos/{REPO}/actions/runs?per_page=1")
    return js["workflow_runs"][0]["id"]


def runs(n=5):
    st, js = call("GET", f"/repos/{REPO}/actions/runs?per_page={n}")
    for r in js["workflow_runs"]:
        print(f"#{r['run_number']} id={r['id']} {r['head_branch']} {r['head_sha'][:7]} {r['event']} "
              f"{r['status']}/{r['conclusion']} {r['created_at']}")


def status(run_id):
    st, r = call("GET", f"/repos/{REPO}/actions/runs/{run_id}")
    print(f"run #{r['run_number']} id={run_id} {r['head_branch']} {r['head_sha'][:7]} {r['status']}/{r['conclusion']}")
    print(f"  {r['html_url']}")
    st, js = call("GET", f"/repos/{REPO}/actions/runs/{run_id}/jobs?per_page=50")
    for j in js["jobs"]:
        print(f"  잡 {j['name']} {j['status']}/{j.get('conclusion')} id={j['id']} "
              f"{(j.get('started_at') or '')[11:19]} → {(j.get('completed_at') or '')[11:19]}")
        for s in j["steps"]:
            if s.get("conclusion") not in ("success", "skipped") or s["status"] != "completed":
                print(f"    {s['number']:2d} {s['status']}/{s.get('conclusion')} {s['name']}")
    st, js = call("GET", f"/repos/{REPO}/actions/runs/{run_id}/artifacts")
    for a in js.get("artifacts", []):
        print(f"  아티팩트 {a['name']} {a['size_in_bytes'] / 1e6:.1f}MB "
              f"https://github.com/{REPO}/actions/runs/{run_id}/artifacts/{a['id']}")
    return r


def watch(run_id, every=40):
    while True:
        st, r = call("GET", f"/repos/{REPO}/actions/runs/{run_id}")
        if st == 200 and r["status"] == "completed":
            status(run_id)
            return 0 if r["conclusion"] == "success" else 1
        time.sleep(every)


def fetch(run_id, out, names):
    st, js = call("GET", f"/repos/{REPO}/actions/runs/{run_id}/artifacts")
    for a in js.get("artifacts", []):
        if (names and a["name"] not in names) or (not names and a["size_in_bytes"] > 20_000_000):
            continue
        d = os.path.join(out, a["name"])
        os.makedirs(d, exist_ok=True)
        with zipfile.ZipFile(io.BytesIO(download(f"/repos/{REPO}/actions/artifacts/{a['id']}/zip"))) as z:
            z.extractall(d)
            print(f"{a['name']} → {d} ({len(z.namelist())}개)")


def main(a):
    cmd = a[0] if a else "runs"
    if cmd == "runs":
        runs(int(a[1]) if len(a) > 1 else 5)
    elif cmd == "status":
        status(a[1] if len(a) > 1 else latest_run())
    elif cmd == "watch":
        return watch(a[1], int(a[2]) if len(a) > 2 else 40)
    elif cmd == "fetch":
        fetch(a[1], a[2], a[3:])
    elif cmd == "log":
        with open(a[2], "wb") as f:
            f.write(download(f"/repos/{REPO}/actions/jobs/{a[1]}/logs"))
        print("저장", a[2])
    elif cmd == "dispatch":
        st, _ = call("POST", f"/repos/{REPO}/actions/workflows/{WORKFLOW}/dispatches",
                     {"ref": a[1] if len(a) > 1 else "impl-draft1"})
        print("HTTP", st, "(204 = 시작함 — 몇 초 뒤 runs 로 id 확인)")
    elif cmd == "cancel":
        st, _ = call("POST", f"/repos/{REPO}/actions/runs/{a[1]}/{'force-cancel' if '--force' in a else 'cancel'}", {})
        print("HTTP", st)
    else:
        print(__doc__)
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
