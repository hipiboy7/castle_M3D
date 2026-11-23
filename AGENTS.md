# AGENTS.md — Antigravity Workspace Rule Pointer

이 프로젝트(`castle_M_3D`)의 **유일한 작업 지침서**는 루트의 **[`CLAUDE.md`](./CLAUDE.md)** 입니다.
별도의 규칙 문서를 중복 작성하지 않고, 모든 세션 시작 시 **`CLAUDE.md` 전체를 반드시 읽고 그대로 준수**합니다.

> 참고: `CLAUDE.md` 용량(~40KB)이 Antigravity Rule 인라인 확장 상한(24KB)을 초과하므로 `@[...]` 삽입 대신 직접 `read_file` 로 전문을 읽습니다.

## 즉시 적용 핵심 요약 (`CLAUDE.md` 기준)
- **세션 시작**: `CLAUDE.md` 0-1절 순서대로 확인(사용량 스크립트 유무 · `git fetch` · 최신 `history/` · `scripts/verify.py`).
- **설계 · 검증**: SOLID + TDD(A/B/C 등급, `CLAUDE.md` 2-1절), 커밋 전 `python3.11 scripts/verify.py`, 태그/릴리스 전 `--strict`.
- **로컬 빌드 · 릴리스**: GitHub Actions 무료 분량 소진 시 작업 서버에서 APK 빌드 후 GitHub Releases **Latest** 업로드(`CLAUDE.md` 3절 · `docs/트러블슈팅.md` T-9).
- **응답 양식**: 작업 중 짧은 메모 후, 사용자에게 보이는 최종 글은 구분선(`---`) 아래 `## ✅ 결과` · `## 💬 답변` · `## ❓ 확인 요청` 한국어 한 덩어리로 정리(`CLAUDE.md` 4절).
- **문서 최소화**: 새 문서는 `CLAUDE.md` 5절 허용 목록(`history/`, `docs/폰확인.md`, `assets/ASSETS.md`, `docs/트러블슈팅.md`) 외 생성 금지.
