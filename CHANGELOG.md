# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [SemVer](https://semver.org/lang/ko/).
0.x 동안은 minor 가 깨는 변경을 포함할 수 있다.
`### 재감사` 절은 대상 레포에서 판단이 필요한 변경(새 슬롯·새 변수·바뀐 원칙·바뀐 seed·이름 바뀜)만 적는다 — sync 스킬이 이 절을 읽는다.

## [0.7.0] - 2026-11-02

### Added

- **L2 새 능력 『게이트 알림』(`notify.md`, corral·bare)** — 코디가 사용자에게 묻고 멈추기 직전에 효과음을 낸다. 들었는지 확인할 수 없어 승인 경로도 판정 근거도 아니다. OS 알림은 권한이 없으면 exit 0 인 채 안 떠 쓰지 않는다.
  corral 대체 경로는 본체의 `terminal wait --for agent-idle` + 화면 읽기
- corral 『전제 점검』에 레포 등록 확인(`repo show --repo path:`). 미등록이면 멈추고 `repo add` 를 안내, 사용자 승인 뒤 등록

### Changed

- **task-start 6단계 배달 영수증 → 새 파일 `delivery.md`** — 본체가 전달 뒤 쓰고 커밋하지 않는다. 코디가 §0 에서 읽어 요약을 `00-start.md` 에 옮기고 작업 폴더 커밋에 같이 넣는다
- task-coordinate §0: 사용자 입력을 기다리며 멈추는 모든 자리에서 『게이트 알림』(게이트 ⓪①②·bundle 게이트에는 표시도)
- adopt 보고: 레포 등록 결과·알림 시험 안내

### 재감사

- corral 을 쓰는 레포: 등록돼 있는지 `corral repo show` 로 본다. 미등록이면 사용자가 정해 등록한다
- corral·bare 모두 `notify.md` 가 새로 깔린다 — 그 명령을 한 번 돌려 소리가 들리는지 본다
- `00-start.md` 에 배달 확인값을 기대하는 프로젝트 스킬·문서가 있으면 `delivery.md` 로 바꾼다

## [0.6.0] - 2026-11-02

### Added

- **L1 스킬 `task-close` — 머지 뒤 마무리(본체 세션).** 상태 파악 → 머지(사용자 확인 뒤, merge commit) → 머지 뒤 확인(새 슬롯 `D16`) →
  인계 필수 항목 → 회고(learnings·ADR 채택) → 트래커 완료 → `task-finish.sh` 재실행·코디 pane 정리 → `close.md` 기록·보고.
  게이트 ② 뒤를 맡는 절차가 없어 사용자가 코디네이터에게 머지·배포 확인을 시키던 빈칸을 메운다. l3 를 켠 레포는 머지·회고·완료를 release 에 맡긴다
- 설계 슬롯 `D16`(task-close 3단계) — 머지 뒤 단계: 빌드 게이트·머지로 도는 CI/배포 확인·수동 배포·마이그레이션·라이브 확인·프로젝트 함정, 되돌릴 수 없는 단계 표시

### Changed

- **코디네이터는 머지하지 않는다** — task-coordinate §8: 머지 지시를 받으면 본체 `task-close` 로 넘긴다고 답한다. 정리 보고에 그 안내
- 회고(learnings·ADR 채택)가 l3 와 무관하게 `task-close` §5 에서 일어난다 — learnings README·ADR README·task-coordinate 의 「채택 = 출고 회고(release §4)」를
  l1 문장 + l3 구간(「출고를 쓰면 release §4」)으로 나눴다. 완료 전이도 같은 방식(task-coordinate 머리·bundle.md)
- `handoff-main.md` 에 「머지 뒤 확인할 것」·「필수 후속 항목」 — task-close 3·4단계가 읽는다
- `task-pr.sh`: l3 를 끈 레포는 마지막 안내에 「머지와 머지 뒤 마무리는 본체 세션의 task-close」
- AGENTS.md 지도: 작업 흐름 표에 8 「머지 뒤 마무리」, 스킬 파일·「어디를 고치나」에 task-close. l3 의 출고 줄은 번호 없이
- adopt: 기존 머지·배포·마무리 스킬은 task-close 와 겹침 — 프로젝트 단계는 D16 으로, 기존 스킬은 「대체됨」

### 재감사

- **새 슬롯 `D16`** — 이 프로젝트의 머지 뒤 단계를 채운다. 기존 마무리·배포 스킬(예: 머지 뒤 빌드·배포·마이그레이션·완료 전이를 하는 프로젝트 스킬)이 있으면
  그 단계를 D16 으로 옮기고 기존 스킬을 지울지 사용자에게 묻는다. 없으면 「머지 뒤 단계 없음 — 4단계로」
- 코디네이터에게 머지를 시키던 습관이 있으면 바뀐다 — 머지는 본체 `task-close` 가 확인 뒤에 한다
- 쌓여 있는 `learnings-proposal.md`·`adr-draft-*.md`(l3 를 끈 레포는 채택 자리가 없었다)는 다음 task-close 회고에서 같이 볼지 정한다
- (bundle) bundle.md 6 의 5 이름이 「출고 중 수정」→「열린 묶음 PR 수정」으로 바뀌었고 l3 와 무관해졌다 — 프로젝트 문서가 옛 이름으로 가리키면 맞춘다.
  묶음 `handoff-main.md` 에 「머지 뒤 확인할 것」·「필수 후속 항목」이 더해졌다
- learnings 90일 재검토 자리가 task-close 회고가 됐다 — 사용자 요청 때 하던 프로젝트는 그대로 해도 된다

## [0.5.0] - 2026-11-01

### Added

- **`.agents/agent-tools.md`(L1, 고정)** — 에이전트 도구(Codex·Grok·Claude)마다 계정 카탈로그 확인·사용량 확인·기동 확인에서 보이는 것·첫 사용 화면.
  「리뷰어 사용 불가 시 자동 전환」·「외부 서치 한도 소진 시 생략」이 「선택한 매핑을 따른다」고 넘기던 명령이 어느 매핑에도 없었다 —
  harness 가 아니라 에이전트 도구에 딸린 명령이라 매핑 대신 이 파일에 둔다. 절이 없는 도구는 「확인 실패」로 다룬다

### Changed

- `defaults.rules.md`: 카탈로그·사용량·외부 서치 한도 확인 방법을 `agent-tools.md` 로 가리킨다
- task-start 3단계: 기동 전 가용성 확인 방법을 `agent-tools.md` 로, 결과를 `00-start.md` 에 한 줄
- adopt: 지정 리뷰어 후보를 계정 카탈로그로 대조해 「없음」이면 제안하지 않는다. 검증 단계에서 도구마다 카탈로그·사용량을 한 번 돌려 보고하고,
  사람이 할 일에 첫 사용 화면(trust) 치우기와 Codex `check_for_update_on_startup = false` 제안
- AGENTS.md 지도: 스킬 파일 줄·「어디를 고치나」 표에 `agent-tools.md`

### 재감사

- `defaults.md` 의 지정 리뷰어(코드 리뷰 ①)와 경쟁 상대 모델이 계정 카탈로그에 있는지 `agent-tools.md` 로 한 번 대조한다 —
  「없음」이면 그 행을 「일시 중지」로 두거나 다른 도구를 ① 로 바꿀지 사용자에게 묻는다
- Codex 를 쓰는 기계면 `~/.codex/config.toml` 에 `check_for_update_on_startup = false` 를 제안한다(사용자 전역 설정 — 쓰지 않는다)
- `defaults.rules.md` 의 카탈로그·사용량 문구가 바뀌었다 — Codex 로그 읽는 법은 `agent-tools.md` 로 옮겼고, 「카탈로그가 확인 실패여도 사용량은 따로 본다」가 규칙에 생겼다
- task-start 3단계에 「가용성 확인 결과를 `00-start.md` 에 한 줄」이 새 절차로 생겼다 — 프로젝트 스킬이 00-start 형식을 따로 정했으면 맞춘다
- 프로젝트 문서가 리뷰어 가용성 확인 명령을 따로 적어 두었으면(설계 슬롯·rules·learnings) `agent-tools.md` 와 겹치는지 보고, 다르면 되돌려 보내기 후보

## [0.4.0] - 2026-10-30

### Changed

- **L2 매핑 형식 — 도구마다 폴더 하나, 능력마다 파일 하나.** `.agents/harness/<도구>.md` 한 파일이
  `<도구>/00-mapping.md`(전제·보장 요약·필드 경로·능력 → 파일 목차) · `<도구>/<능력>.md`(능력 11개) · `<도구>/commands.md`(선언)로 나뉜다.
  코디네이터는 시작 때 `capabilities.md` + `00-mapping.md` 만 읽고, 능력 파일은 그 능력을 쓸 때 연다 — corral 기준 시작 때 읽는 양 약 75KB → 약 18KB
- `capabilities.md` 를 둘로 — 코디용(매핑 선택·보장 어휘·능력 목록 표·판정표 반영)과 `contract.md`(네 증명 대상·선언 규칙·표기 허용 목록·도구 무관 사실 H1~H8).
  능력 목록 표에 「파일」 칸이 생겼다
- `capability-check.mjs`: 깔린 매핑 = `00-mapping.md` 가 있는 폴더. `names` 는 표의 행마다 능력 파일과 그 절 제목을, `shape` 는 능력 파일마다 모양을,
  `runtime` 은 `commands.md` 의 선언과 폴더 전체 본문을 대조한다. 선언 블록이 `commands.md` 밖에 있으면 불일치. `--mapping` 뒷문은 폴더를 받는다
- 절차 문서(AGENTS.md·validation·task-coordinate)가 가리키는 매핑 경로를 `<도구>/` 로, 「능력 계약 H<n>」을 `contract.md H<n>` 으로

### 재감사

- 프로젝트 문서(설계 슬롯·rules·프로젝트 스킬·learnings)가 `.agents/harness/<도구>.md`(예: `corral.md`)나 그 안의 절을 가리키면
  `.agents/harness/<도구>/` 의 해당 파일(목차는 `00-mapping.md`)로 맞춘다
- 「능력 계약 H<n>」·`capabilities.md H<n>` 으로 도구 무관 사실을 가리키는 프로젝트 문서가 있으면 `contract.md H<n>` 으로 맞춘다
- 0.3.0 의 `<도구>.md` 를 고친 프로젝트는 sync 가 그 파일을 충돌로 멈춘다 — 고친 내용을 새 능력 파일 자리에 옮길지(되돌려 보내기 후보) 판단한다

## [0.3.0] - 2026-10-29

### Added

- `paddock-render sync` — 이미 들인 대상을 새 버전·바뀐 config 로 맞춘다. 대상 manifest 해시를 지난 렌더로 쓰는 3-way:
  손대지 않은 고정부·링크는 갱신, 설계 슬롯 내용은 ID·순번으로 옮김, 빠진 파일은 지움. 프로젝트가 고친 고정부·고아 슬롯은 충돌로 멈추고 아무것도 쓰지 않는다.
  쓰다가 실패하면 lock 을 바꾸지 않고 exit 1, 버전을 내리는 sync 는 `--allow-downgrade` 로만
- `sync` 스킬 — 버전 비교 → 계획(`sync --dry-run`) → 재감사(새 슬롯·바뀐 seed·CHANGELOG 「재감사」·새 변수) → 승인 게이트 → 쓰기 → 검증·이력.
  충돌은 사유별 선택지로 보이고, 끝에 프로젝트 learnings 중 일반적인 것을 paddock 에 되돌려 보낼 초안을 낸다(생성은 승인 뒤)
- config `PADDOCK_SKIP` — 깔지 않기로 한 경로(레포 상대). render·sync 가 따른다(manifest 를 손으로 고치면 다음 sync 가 되살린다)
- `paddock-render version`, `paddock-check` 의 플러그인 버전 알림(대상이 낮을 때)
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
