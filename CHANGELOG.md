# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [SemVer](https://semver.org/lang/ko/).
0.x 동안은 minor 가 깨는 변경을 포함할 수 있다.

## [0.1.0] - 2026-10-28

### Added

- 플러그인·마켓플레이스 매니페스트 (`paddock@paddock`)
- L0 자산: `AGENTS.md` 지도 틀, `CLAUDE.md`, `.agents/` 원본 + `.claude/` 심링크, rules 스텁(writing·coding)과 완료 원칙(validation), learnings·ADR 형식, gitleaks pre-commit 훅, `.gitignore` 조각
- `templates/codex-agent.toml` — 역할 포인터 틀
- 자산 계약 `assets/README.md` — 층, 표기 규약(`{{VAR}}`·fixed·seed·design·module), 변수 표, 복사 규칙
- `scripts/check.sh` — 자산 계약·공개 안전 검사
