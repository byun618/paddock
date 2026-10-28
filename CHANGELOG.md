# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [SemVer](https://semver.org/lang/ko/).
0.x 동안은 minor 가 깨는 변경을 포함할 수 있다.

## [0.2.0] - 2026-10-29

### Added

- `adopt` 스킬 — 감사(신규·기존·재적용) → 분석 → 설계 → 승인 게이트 → 생성 → 검증. 기존 지침은 지우지 않고 옮긴다. 설계 기록 `.paddock/design.md`
- `bin/paddock-render`(render·apply) · `bin/paddock-check` — 결정적 렌더·들이기(기존 파일을 덮지 않음, seed 보존)·drift 검사. 대상 상태 `.paddock/`(config·manifest·design)
- 자산 표기 `paddock:module` 구간·모듈 폴더, 설계 슬롯 D1~D15, 파생 변수 `TASK_NAME`·`TASK_REF`·`BUNDLE_NAME`·`BUNDLE_REF`(일감 ID 없는 프로젝트 지원)
- L1 자산 — task-start·task-coordinate 스킬, 리뷰어 역할, `defaults.rules.md` + seed `defaults.md`, `scripts/task-pr.sh`·`task-finish.sh`, 모듈 `bundle`
- L2 자산 — harness 능력 계약 `capabilities.md`·`capability-check.mjs`, 매핑 `bare`·`corral`, corral 세션 정리 훅(후보 출력만)
- 시험 `scripts/render-test.sh`·`scripts/l1-tests/`, 트리거 eval `evals/`

## [0.1.0] - 2026-10-28

### Added

- 플러그인·마켓플레이스 매니페스트 (`paddock@paddock`)
- L0 자산: `AGENTS.md` 지도 틀, `CLAUDE.md`, `.agents/` 원본 + `.claude/` 심링크, rules 스텁(writing·coding)과 완료 원칙(validation), learnings·ADR 형식, gitleaks pre-commit 훅, `.gitignore` 조각
- `templates/codex-agent.toml` — 역할 포인터 틀
- 자산 계약 `assets/README.md` — 층, 표기 규약(`{{VAR}}`·fixed·seed·design·module), 변수 표, 복사 규칙
- `scripts/check.sh` — 자산 계약·공개 안전 검사
