# assets — 대상 레포에 까는 자산의 계약

paddock 이 대상 레포에 복사하는 고정 뼈대다. 층·표기 규약·변수·복사 규칙의 원본은 이 파일 한 곳이다.
자산을 고치는 커밋은 이 파일을 같이 고치고, 커밋 전에 `scripts/check.sh` 를 돌린다.

## 층

| 층 | 폴더 | 켜는 조건 | 내용 |
| --- | --- | --- | --- |
| L0 기본 | `l0/` | 항상 | AGENTS.md 지도 틀, CLAUDE.md, `.agents/` 원본 + `.claude/` 심링크, `.codex/agents/`, rules 스텁, learnings·ADR 형식, gitleaks 훅 |
| L1 작업 흐름 | `l1/` (예정) | 기본 켬 | 게이트 흐름·판정표·리뷰어·task 스킬과 스크립트 |
| L2 harness | `l2/<도구>/` (예정) | 쓰는 도구 하나만 | 능력 계약 + 도구 매핑 |
| L3 출고 | `l3/` (예정) | 선택 | release 스킬·스크립트 |

`l<층>/` 은 **대상 레포 루트를 그대로 비춘다** — `l0/.agents/rules/writing.md` 는 대상의 `.agents/rules/writing.md` 가 된다.
역할마다 찍어내는 틀은 레포 루트 `templates/` 에 둔다.

## 표기 규약

| 표기 | 뜻 | sync 동작 |
| --- | --- | --- |
| 첫 줄 `<!-- paddock:fixed -->` (셸·설정 파일은 `# paddock:fixed`) | 통째로 고정 | 덮어쓴다 |
| 마커가 하나도 없는 파일 | 고정과 같다 (front matter 처럼 첫 줄을 쓸 수 없는 파일) | 덮어쓴다 |
| 첫 줄 `<!-- paddock:seed -->` | 처음 한 번만 깐다. 이후 내용은 프로젝트 소유 | 건드리지 않는다 |
| `<!-- paddock:design <ID> -->` … `<!-- /paddock:design -->` | 설계 슬롯. adopt 가 대상 프로젝트를 보고 채운다 | 구간 안은 보존, 밖은 덮어쓴다 |
| `<!-- paddock:module <이름> -->` … `<!-- /paddock:module -->` | 선택 모듈 구간. 이름은 `l1`·`l2`·`l3`·`bundle` 등 | 켜면 그 층의 내용으로 채우고, 끄면 구간째 뺀다 |
| `{{VAR}}` | 변수. 대문자 스네이크 | 렌더할 때 값으로 바꾼다 (LLM 판단 없음) |

- 마커는 중첩하지 않는다. 한 구간이 닫히기 전에 다른 구간을 열지 않는다.
- 상위 층이 하위 층 파일에 덧붙일 자리는 빈 `paddock:module <층>` 구간으로 미리 둔다. 같은 이름의 구간이 한 파일에 여럿일 수 있다.
- 설계 슬롯 ID 는 adopt 설계 항목 번호(`D1`…)다. 아래 「설계 슬롯」 표에 있어야 한다.

## 변수

사용 중 — `scripts/check.sh` 가 자산 속 `{{VAR}}` 가 전부 이 표에 있는지 본다.

| 변수 | 뜻 | 예 |
| --- | --- | --- |
| `{{PROJECT_NAME}}` | 대상 프로젝트 이름 | `corral` |
| `{{WORKTREE_DIR}}` | 에이전트 worktree 루트 (레포 상대) | `.claude/worktrees` |
| `{{ROLE}}` | 역할 이름 (`templates/codex-agent.toml`) | `reviewer` |
| `{{ROLE_DESCRIPTION}}` | 역할 한 줄 설명 | `구현 코드 독립 검토` |

예약 — 상위 층이 쓸 이름. 쓰기 시작하면 위 표로 옮긴다.

| 변수 | 뜻 |
| --- | --- |
| `{{SPECS_MODE}}` | 작업 산출물 위치 방식: `separate-repo` · `in-repo` |
| `{{SPECS_ROOT}}` | 작업 산출물 루트 |
| `{{ISSUE_PREFIX}}` / `{{TASK_ID_REGEX}}` | 일감 ID 접두와 정규식 (없으면 슬러그를 ID 로) |
| `{{TRACKER}}` | 일감 트래커 (`none` 포함) |
| `{{BASE_BRANCH}}` | 기본 브랜치 |
| `{{BUNDLE_PREFIX}}` | 묶음 브랜치 접두 (bundle 모듈) |
| `{{HARNESS_TOOL}}` / `{{HARNESS_DIR}}` | 쓰는 harness 도구와 매핑 위치 |
| `{{VARIANT_SUFFIXES}}` | 경쟁 구현 변형 브랜치 접미사 |
| `{{MAX_FIX_ROUNDS}}` | 수정 라운드 상한 |

## 설계 슬롯

| ID | 자리 | adopt 가 쓰는 것 |
| --- | --- | --- |
| `D1` | `l0/AGENTS.md` 머리 | 프로젝트 소개 2~4줄: 무엇을 만드는가, 주요 스택, 방향 문서 위치 |

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
