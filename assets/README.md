# assets — 대상 레포에 까는 자산의 계약

paddock 이 대상 레포에 복사하는 고정 뼈대다. 층·표기 규약·변수·복사 규칙의 원본은 이 파일 한 곳이다.
자산을 고치는 커밋은 이 파일을 같이 고치고, 커밋 전에 `scripts/check.sh` 를 돌린다.

## 층

| 층 | 폴더 | 켜는 조건 | 내용 |
| --- | --- | --- | --- |
| L0 기본 | `l0/` | 항상 | AGENTS.md 지도 틀, CLAUDE.md, `.agents/` 원본 + `.claude/` 심링크, `.codex/agents/`, rules 스텁, learnings·ADR 형식, gitleaks 훅 |
| L1 작업 흐름 | `l1/` (예정) | 기본 켬 | 게이트 흐름·판정표·리뷰어·에이전트 도구 가용성 확인·task 스킬(시작·진행·머지 뒤 마무리)과 스크립트 |
| L2 harness | `l2/common/` + `l2/<도구>/` | 쓰는 도구 하나만 | 능력 계약(공통) + 도구 매핑 (아래 「L2 매핑 형식」) |
| L3 출고 | `l3/` (예정) | 선택 | release 스킬·스크립트 |

`l<층>/` 은 **대상 레포 루트를 그대로 비춘다** — `l0/.agents/rules/writing.md` 는 대상의 `.agents/rules/writing.md` 가 된다.
역할마다 찍어내는 틀은 레포 루트 `templates/` 에 둔다.

### L2 매핑 형식

코디네이터가 시작할 때 읽는 양을 줄이려고 나눈다 — 읽은 문서는 세션 끝까지 비용이 된다.

| 대상 경로 | 누가 읽나 | 내용 |
| --- | --- | --- |
| `.agents/harness/capabilities.md` | 코디네이터(시작 때) | 매핑 선택 · 보장 어휘 · 능력 목록 표(능력 ↔ 파일) · 판정표 반영 |
| `.agents/harness/contract.md` | 매핑을 쓰는 사람·리뷰어, 절차 문서가 `contract.md H<n>` 으로 가리킬 때 | 네 증명 대상 · 선언 규칙 · 표기 허용 목록 · 도구 무관 사실 H1~H8 |
| `.agents/harness/<도구>/00-mapping.md` | 코디네이터(시작 때) | 전제 · 보장 요약 · (응답 필드 경로) · 능력 → 파일 목차 |
| `.agents/harness/<도구>/<능력>.md` | 코디네이터(그 능력을 쓸 때만) | 능력 하나 — `## 『능력』` 절 하나 아래 명령 · 보장 수준 · 상황 → 행동 |
| `.agents/harness/<도구>/commands.md` | `capability-check.mjs` 만 | `required-commands` · `mentioned-commands` 선언 |

- 능력 파일 이름의 정본은 `capabilities.md` 능력 목록 표의 「파일」 칸이다. 능력을 더하면 표의 행과 도구마다 파일을 같이 더한다.
- 매핑의 근거(실측 원문·경위)는 자산에 넣지 않는다 — 자산은 실행에 쓰는 규칙만 담는다.

## 표기 규약

| 표기 | 뜻 | sync 동작 |
| --- | --- | --- |
| 첫 줄 `<!-- paddock:fixed -->` (셸·설정 파일은 `# paddock:fixed`) | 통째로 고정 | 덮어쓴다 |
| 마커가 하나도 없는 파일 | 고정과 같다 (front matter 처럼 첫 줄을 쓸 수 없는 파일) | 덮어쓴다 |
| 첫 줄 `<!-- paddock:seed -->` | 처음 한 번만 깐다. 이후 내용은 프로젝트 소유 | 건드리지 않는다 |
| `<!-- paddock:design <ID> -->` … `<!-- /paddock:design -->` | 설계 슬롯. adopt 가 대상 프로젝트를 보고 채운다 | 구간 안은 보존, 밖은 덮어쓴다 |
| `<!-- paddock:module <이름> -->` … `<!-- /paddock:module -->` | 선택 모듈 구간. 이름은 `l1`·`l2`·`l3`·`bundle` 등 | 렌더할 때 켜면 안의 내용만 남기고(마커는 지운다), 끄면 구간째 뺀다 |
| `{{VAR}}` | 변수. 대문자 스네이크 | 렌더할 때 값으로 바꾼다 (LLM 판단 없음) |

- 중첩은 한 겹만 허용한다: `module` 구간 안에 `design` 슬롯. 그 밖의 중첩(design 안의 무엇이든, module 안의 module)은 금지.
- 상위 층이 하위 층 파일에 덧붙일 내용은 그 파일의 `paddock:module <층>` 구간 안에 직접 쓴다. 같은 이름의 구간이 한 파일에 여럿일 수 있다.
  층·모듈 폴더(`l1/`·`bundle/`…)에는 그 이름이 켜졌을 때만 생기는 **파일 전체**를 둔다. 폴더 이름 = 모듈 이름.
- 설계 슬롯 ID 는 adopt 설계 항목 번호(`D1`…)다. 아래 「설계 슬롯」 표에 있어야 한다.

## 변수

`scripts/check.sh` 가 자산 속 `{{VAR}}` 가 전부 이 표에 있는지 본다. 값은 대상의 `.paddock/config.sh` 에 같은 이름으로 둔다.

| 변수 | 뜻 | 예 |
| --- | --- | --- |
| `{{PROJECT_NAME}}` | 대상 프로젝트 이름 | `corral` |
| `{{WORKTREE_DIR}}` | 에이전트 worktree 루트 (레포 상대) | `.claude/worktrees` |
| `{{BASE_BRANCH}}` | 기본 브랜치 | `main` |
| `{{ISSUE_PREFIX}}` | 일감 ID 접두. 비우면 ID 없이 슬러그만 쓴다 | `LIFE` |
| `{{SPECS_ROOT}}` | 작업 산출물 루트 — 문서에 적는 표기 (`specs-repo` 모듈) | `<본체>/../demo-specs` |
| `{{BUNDLE_PREFIX}}` | 묶음 브랜치 접두 (`bundle` 모듈) | `feature/` |
| `{{MAX_FIX_ROUNDS}}` | 수정 라운드 상한 | `3` |
| `{{ROLE}}` | 역할 이름 (`templates/codex-agent.toml`) | `reviewer` |
| `{{ROLE_DESCRIPTION}}` | 역할 한 줄 설명 | `구현 코드 독립 검토` |

파생 변수 — config 에 두지 않는다. `paddock-render` 가 `ISSUE_PREFIX` 로 만든다(아래는 `ISSUE_PREFIX=LIFE` / 빈 값).
자산 문서에서 작업·묶음 이름은 `{{ISSUE_PREFIX}}-NNN-…` 처럼 조립하지 말고 이것을 쓴다 — 빈 접두로 `-NNN-…` 가 렌더되는 것을 막는다.

| 변수 | 뜻 | `LIFE` | 빈 값 |
| --- | --- | --- | --- |
| `{{TASK_NAME}}` | 작업 이름 = 작업 브랜치·worktree·산출물 폴더 이름 | `LIFE-NNN-<슬러그>` | `<슬러그>` |
| `{{TASK_REF}}` | 일감을 가리키는 짧은 이름 | `LIFE-NNN` | `<슬러그>` |
| `{{BUNDLE_NAME}}` | 묶음(체크포인트) 작업 이름 | `LIFE-MMM-<슬러그>` | `<묶음 슬러그>` |
| `{{BUNDLE_REF}}` | 묶음을 가리키는 짧은 이름 | `LIFE-MMM` | `<묶음 슬러그>` |

config 에만 있는 키 — 자산 문서에는 안 나오고 스크립트가 실행 때 읽는다.

| 키 | 뜻 | 기본 |
| --- | --- | --- |
| `PADDOCK_VERSION` | 렌더한 paddock 버전 | (필수) |
| `PADDOCK_MODULES` | 켠 모듈 (아래 「모듈」) | 빈 값 = L0 만 |
| `PADDOCK_HARNESS` | `l2` 를 켰을 때 쓰는 도구 하나 | — |
| `VARIANT_SUFFIXES` | 경쟁 구현 변형 브랜치 접미사 | `-claude -codex` |
| `PR_FOOTER` | `task-pr.sh` 가 PR 본문 끝에 붙이는 서명 | 빈 값 |

## 모듈

| 이름 | 켜면 | 기본 |
| --- | --- | --- |
| `l1` | 작업 흐름 — task 스킬·리뷰어·defaults·에이전트 도구 확인·판정표·task 스크립트 | 켬 |
| `l2` | harness 능력 계약 + `PADDOCK_HARNESS` 매핑 하나. `l1` 을 전제한다(없으면 render 가 거절) | 켬 |
| `l3` | 출고를 가리키는 문장 (release 자산은 v0 에 없음) | 끔 |
| `specs-repo` | 작업 산출물을 별도 레포(`{{SPECS_ROOT}}`)에 두는 문장·점검 | 켬 |
| `specs-inrepo` | 같은 레포 폴더 모드 — v0 미구현 | — |
| `bundle` | 묶음(체크포인트·feature 브랜치·묶음 코디) | 끔 |

## 설계 슬롯

| ID | 자리 | adopt 가 쓰는 것 |
| --- | --- | --- |
| `D1` | `AGENTS.md` 머리 | 프로젝트 소개 2~4줄: 무엇을 만드는가, 주요 스택, 방향 문서 위치 |
| `D3` | task-start 1·5단계 | 일감 트래커 연동 — 일감 읽기·상태 전이 방법과 상태 이름 (트래커 없으면 생략 규칙) |
| `D5` | validation 네이티브 관문 | 이 프로젝트의 「네이티브 실행」 정의 — 사용자가 실제로 쓰는 설치·실행 경로 |
| `D6` | validation 원자료 보관 · task-coordinate §3 격리 | 사용자 데이터·런타임 자원 — 건드리지 말 것, 직렬 자원, 커밋하지 않을 사본 |
| `D7` | task-coordinate §2·§5 | 테스트 계층 — 빠른 확인 vs 최종 관문 명령 |
| `D8` | task-coordinate §3 | 경량 범주 닫힌 목록과 「전체로 올리는 것」의 프로젝트 줄 |
| `D9` | task-coordinate implementation.md | 일감 관문 스크립트 작성법 (언어·러너·worktree 경로 받는 법) |
| `D12` | reviewer.md | 리뷰어 관점 — 이 프로젝트에서 특히 볼 것, 외부 사실 대조 대상 |
| `D13` | task-coordinate §1 | 외부 서치 위임 — 도구·조건 (없으면 「없음」) |
| `D15` | task-coordinate §8 | 통합 결과를 사용자가 직접 확인하는 방법 |
| `D16` | task-close 3단계 | 머지 뒤 단계 — 표면별 빌드 게이트·자동 CI/배포 확인·수동 배포·마이그레이션·라이브 확인·프로젝트 함정, 단계마다 트리거(자동/사람)·되돌릴 수 없음 표시 |

`.agents/defaults.md`(역할 기본값 표·선택 근거)는 슬롯이 아니라 seed 파일 통째로 adopt 가 쓴다.

## 렌더·들이기·검사

플러그인 `bin/` 의 도구가 한다 (세션의 Bash PATH 에 오른다). LLM 판단이 들어가지 않는다.

| 도구 | 하는 일 |
| --- | --- |
| `paddock-render render --config <config.sh> --out <빈 폴더>` | 켠 층·모듈·변수로 대상 레포 모양의 트리를 만든다. `.paddock/config.sh` 사본과 `.paddock/manifest.tsv`(경로 · 종류 · 해시)를 같이 둔다 |
| `paddock-render apply <렌더 폴더> <대상> [--dry-run]` | 대상에 들인다. 내용이 다른 기존 파일이 하나라도 있으면 아무것도 쓰지 않고 충돌 목록을 낸다(exit 3) |
| `paddock-render sync <렌더 폴더> <대상> [--dry-run] [--take-new <경로>]…` | 이미 들인 대상을 새 렌더(새 버전·바뀐 config)로 맞춘다 — 아래 「sync」 |
| `paddock-render version` | 플러그인 버전 (`.claude-plugin/plugin.json`) |
| `paddock-check [<대상>] [--require-filled]` | manifest 항목·남은 변수·슬롯 짝(과 채움)·고정 부분 drift·Codex 포인터·capability-check. 플러그인 버전과 다르면 알린다 |

대상의 `.paddock/config.sh` (bash 로 읽는다 — task 스크립트도 이것을 읽는다):

```sh
PADDOCK_VERSION=0.2.0          # render 가 플러그인 버전으로 쓴다 — 손으로 고치지 않는다
PADDOCK_MODULES="l1 l2"        # 켠 모듈. l0 은 늘 켜짐. 층 폴더 l1·l2 도 이 이름으로 켠다
PADDOCK_HARNESS=corral         # l2 를 켰을 때 쓰는 도구 하나 (bare · corral · orca)
PADDOCK_SKIP=".claude/agents"  # 깔지 않을 경로(공백으로 나눔, 그 아래 전부). 레포 상대·끝 / 없이 — 절대 경로·..·글롭은 render 가 거절. sync 도 따른다
PROJECT_NAME=…                 # 아래 「변수」 표의 값들
```

manifest 종류: `fixed` · `seed` · `managed`(설계 슬롯이 있는 파일 — 해시는 슬롯 안을 비우고 잰다) · `link` · `dir`.
`config.sh` 의 `PADDOCK_VERSION` 과 manifest 가 대상의 lock 이다 — 어느 버전의 무엇을 깔았는지, 고정부가 그때 어땠는지(해시).

### sync

대상 manifest 의 해시가 「지난 렌더」다. 고정부 내용은 따로 저장하지 않는다 — 프로젝트는 고정부를 고치지 않는다는 계약이라 「고쳤나」만 알면 된다.

| 지난 manifest | 새 렌더 | 대상 지금 | 처리 |
| --- | --- | --- | --- |
| 있음 | 있음 | 고정부 해시 = 지난 해시 | 갱신. 설계 슬롯 내용은 **ID + 같은 ID 안 순번**으로 옮겨 담는다. 새 슬롯은 빈 채로 「새 슬롯」 보고 |
| 있음 | 있음 | 다름 | 충돌 — 프로젝트가 고정부를 고쳤다 |
| 있음 | 있음 | 없음 | 충돌 — 대상에서 지워졌다 |
| 없음 | 있음 | 없음 / 같음 / 다름 | 만듦 / 그대로 / 충돌 |
| 있음 | 없음 | 고정부 해시 = 지난 해시 / 다름 | 지움(빈 폴더도) / 충돌 |
| seed | | | 쓰지 않는다. 대상에 없으면 만들고, 새 seed 가 지난 것과 다르면 「seed 바뀜」 보고만 |
| 슬롯 | 새 렌더에 그 ID·순번이 없음 | 내용이 있음(주석 빼고) | 충돌 — 고아 슬롯 |

- 충돌이 하나라도 있으면 아무것도 쓰지 않는다(exit 3). 한 경로의 사유는 전부 ` + ` 로 잇는다. `--take-new <경로>` 는 그 경로의 충돌만 새 것으로 푼다(슬롯은 옮김, 고아 슬롯 내용·고친 고정부는 버림).
- 링크도 3-way 다 — 지난 렌더대로인 링크는 새 대상으로 바꾼다.
- 쓰다가 하나라도 실패하면 lock(`.paddock/manifest.tsv`·`config.sh`)을 바꾸지 않고 exit 1 — 원인을 고쳐 다시 돌리면 이어진다.
- 새 렌더 버전이 대상 버전보다 낮으면 거절한다(`--allow-downgrade`). manifest 경로가 절대 경로이거나 `..` 를 품으면 거절한다.
- 모듈·harness 를 바꾸는 것도 sync 다 — 바꾼 config 로 렌더해 같은 표로 맞춘다.
- `.gitignore` 는 새 조각 줄만 덧붙인다. 지난 버전에만 있던 줄은 지우지 않는다.

## 복사 규칙

- `.gitkeep` 은 빈 폴더를 git 에 담기 위한 것이다 — 복사하지 않고 폴더만 만든다.
- 심링크는 심링크로 복사한다 (`l0/.claude/{agents,rules,skills}` → `../.agents/…`).
- 실행 비트를 보존한다 (`l0/.githooks/pre-commit`).
- `l0/gitignore.fragment` 는 대상 `.gitignore` 에 덧붙인다 — 이미 있는 줄은 다시 넣지 않는다.
- 대상에 같은 경로의 파일이 이미 있으면 덮어쓰지 않고 adopt 가 사용자에게 합칠 방법을 묻는다.

## L0 파일

| 대상 경로 | 소유 |
| --- | --- |
| `AGENTS.md` | design 슬롯 + 모듈 구간 (밖은 고정) |
| `CLAUDE.md` | 고정 (`@AGENTS.md`) |
| `.agents/rules/writing.md` · `coding.md` | seed |
| `.agents/rules/validation.md` | 고정 + `l1` 구간 |
| `.agents/learnings/README.md` | 고정 + `l1`·`l3` 구간 |
| `.agents/agents/` · `.agents/skills/` · `.codex/agents/` | 빈 폴더 |
| `.claude/{agents,rules,skills}` | 심링크 |
| `.githooks/pre-commit` | 고정 |
| `docs/adr/README.md` | 고정 + `l1` 구간 |
| `docs/adr/template.md` | 고정 (front matter 때문에 마커 없음) |
| `.gitignore` | `gitignore.fragment` 덧붙임 |
