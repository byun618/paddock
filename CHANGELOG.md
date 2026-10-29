# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [SemVer](https://semver.org/lang/ko/).
0.x 동안은 minor 가 깨는 변경을 포함할 수 있다.
`### 재감사` 절은 대상 레포에서 판단이 필요한 변경(새 슬롯·새 변수·바뀐 원칙·바뀐 seed·이름 바뀜)만 적는다 — sync 스킬이 이 절을 읽는다.

## [0.3.0] - 2026-10-29

### Added

- `paddock-render sync` — 이미 들인 대상을 새 버전·바뀐 config 로 맞춘다. 대상 manifest 해시를 지난 렌더로 쓰는 3-way:
  손대지 않은 고정부는 갱신, 설계 슬롯 내용은 ID·순번으로 옮김, 빠진 파일은 지움. 프로젝트가 고친 고정부·고아 슬롯은 충돌로 멈추고 아무것도 쓰지 않는다
- `sync` 스킬 — 버전 비교 → 계획(`sync --dry-run`) → 재감사(새 슬롯·바뀐 seed·CHANGELOG 「재감사」·새 변수) → 승인 게이트 → 쓰기 → 검증·이력.
  충돌은 사유별 선택지로 보이고, 끝에 프로젝트 learnings 중 일반적인 것을 paddock 에 되돌려 보낼 초안을 낸다(생성은 승인 뒤)
- config `PADDOCK_SKIP` — 깔지 않기로 한 경로. render·sync 가 따른다(manifest 를 손으로 고치면 다음 sync 가 되살린다)
- `paddock-render version`, `paddock-check` 의 플러그인 버전 알림
- 시험 `scripts/sync-test.sh`(변이 대조) · `scripts/upgrade-test.sh`(지난 태그 → 작업 트리 실제 갱신)

### Changed

- `PADDOCK_VERSION` 은 render 가 플러그인 버전으로 쓴다 — config 의 값은 지난 렌더의 버전
- 게이트 ② 이름 「출고 승인」 → 「PR 생성 승인」 (번호 ② 는 그대로). 출고(L3)를 켜지 않은 구성에도 맞는 이름
- adopt: 모듈·harness 바꾸기를 sync 도구로 한다(0.2.0 은 「미구현」으로 멈췄다). 깔지 않을 항목은 `PADDOCK_SKIP` 으로

### 재감사

- 게이트 ② 를 「출고 승인」으로 부르는 프로젝트 문서(설계 슬롯·rules·프로젝트 스킬)가 있으면 「PR 생성 승인」으로 맞춘다
- 0.2.0 adopt 가 manifest 에서 행을 지워 깔지 않은 항목(예: `.claude/agents`)이 있으면 config `PADDOCK_SKIP` 에 그 경로를 더한다 — 없으면 sync 가 그 자리를 충돌로 낸다

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
