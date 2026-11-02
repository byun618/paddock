# paddock

AI 작업 흐름을 프로젝트에 맞게 설계해 적용하는 Claude Code 플러그인.

> 대상 레포에서 **「이 레포에 paddock 적용해줘」** 한 문장이면, 코드베이스를 분석해 프로젝트별 설계를 쓰고, 승인을 받은 뒤
> 규칙·역할·스킬·승인 게이트·harness 매핑을 적용한다. 새 버전이 나오면 프로젝트가 채운 설계를 보존한 채 갱신한다.

**상태:** 개발 중(0.x — minor 가 깨는 변경을 포함할 수 있다). 변경 내역은 [CHANGELOG](CHANGELOG.md).
기본·작업 흐름·harness 층과 `adopt`·`sync` 가 있고, **출고 층과 같은 레포 산출물 모드는 아직 없다.** 자산과 산출물 문서는 한국어로 고정돼 있다.

## 무엇을 해결하나

- **「다 됐습니다」인데 안 되어 있다** — 구현 전에 판정 기준을 박고, 구현자와 다른 세션이 리뷰하고, 증거가 있는 것만 통과로 적는다
- **세션이 끝나면 맥락이 사라진다** — 분석·기준·리뷰·판정을 전부 파일로 남기고, 세션 간 조율도 파일로 한다
- **AI 가 혼자 끝까지 달려간다** — 구현 시작 전, 채택 전, PR 생성 전 세 곳에서 반드시 멈추고 사용자 승인을 받는다
- **프로젝트마다 흐름을 처음부터 만든다** — 뼈대는 그대로 복사하고, 달라야 하는 부분만 LLM 이 코드베이스를 보고 쓴다
- **적용하고 나면 템플릿과 갈라진다** — 버전 lock 과 `sync` 로 고정 부분만 갱신하고, 프로젝트가 고친 부분은 덮어쓰지 않고 멈춘다

## 핵심 구조 — 고정 뼈대 + 설계 슬롯

```
paddock 자산 (고정 뼈대)          대상 프로젝트 분석
  게이트 흐름·판정표 형식              스택·명령·테스트
  리뷰어·task 스킬·스크립트             실행·배포·쓰는 도구
  harness 매핑                       기존 규칙·스킬
        │                                │
        │ paddock-render                 │ LLM 이 설계 (승인 게이트)
        │ (결정적 — LLM 판단 없음)           │
        ▼                                ▼
  ┌──────────────────────────────────────────┐
  │ 대상 레포                                  │
  │   고정 부분 ──── sync 가 새 버전으로 덮어쓴다    │
  │   설계 슬롯 ──── 내용을 보존해 옮겨 담는다        │
  │   seed 파일 ──── 처음만 적용하고 프로젝트가 소유   │
  └──────────────────────────────────────────┘
```

LLM 이 하는 일은 대상을 읽고, 설계 슬롯과 역할 기본값을 쓰고, 기존 파일을 어디로 옮길지 정하는 것뿐이다. 고정 문장은 다시 쓰지 않는다.

## 층

| 층 | 내용 | 켜는 조건 |
| --- | --- | --- |
| **기본** | `AGENTS.md` 지도 · `CLAUDE.md` · `.agents/` 원본 + `.claude/` 심링크 · rules · learnings·ADR 형식 · gitleaks 훅 | 항상 |
| **작업 흐름** | task 스킬 3종 · 리뷰어 · 판정표 · 역할 기본값 · 에이전트 도구 확인 · task 스크립트 | 기본 켬. 산출물 레포가 필요하다 |
| **harness** | 도구 무관 능력 계약 + 쓰는 도구 매핑 하나 | 기본 켬. 작업 흐름을 전제한다 |
| **출고** | release 브랜치·태그·릴리즈 노트·산출물 | **아직 없음** |

선택 모듈: `bundle` — 서로 의존하는 작업을 feature 브랜치 하나에 모아 PR 하나로 올린다 (기본 끔).

## 적용 결과

출고를 뺀 세 층을 켜고 harness 로 `bare` 를 고른 대상 레포:

```
your-project/
├── AGENTS.md                  # 지도 — 흐름·브랜치 규약·「어디를 고치나」 (슬롯 D1 + 고정)
├── CLAUDE.md                  # @AGENTS.md
├── .agents/                   # 규칙·역할·스킬의 원본
│   ├── rules/                 # writing·coding(seed) · validation(완료 조건·판정표)
│   ├── learnings/             # 작업에서 얻은 배움
│   ├── agents/reviewer.md     # 리뷰어 지침
│   ├── skills/
│   │   ├── task-start/        # 작업 시작
│   │   ├── task-coordinate/   # 분석 → 구현 → 리뷰 → 판정 → PR
│   │   └── task-close/        # 머지 뒤 마무리
│   ├── defaults.md            # 역할별 도구·모델·effort (프로젝트 소유)
│   ├── defaults.rules.md      # 그 값을 쓰는 규칙
│   ├── agent-tools.md         # 도구별 카탈로그·사용량·첫 사용 화면 확인
│   └── harness/
│       ├── capabilities.md    # 능력 계약
│       ├── contract.md        # 매핑을 쓰는 사람·리뷰어용 계약
│       ├── capability-check.mjs
│       └── bare/              # 도구 매핑 — 능력마다 파일 하나
├── .claude/{agents,rules,skills}  # .agents/ 를 가리키는 심링크
├── .codex/agents/reviewer.toml    # Codex 용 역할 포인터
├── .githooks/pre-commit       # gitleaks
├── docs/adr/                  # 결정 기록 형식
├── scripts/                   # task-pr.sh · task-finish.sh
└── .paddock/
    ├── config.sh              # 켠 모듈·변수·버전
    ├── manifest.tsv           # 무엇을 적용했고 고정부가 어땠는지 (해시 — lock)
    └── design.md              # adopt 설계 기록

your-project-specs/            # 별도 레포 — 작업 문서·원자료
```

원본은 `.agents/` 한 곳이고 `.claude/` 는 심링크라서, 같은 규칙을 Claude Code 와 Codex 가 함께 읽는다.

## 설치

```sh
claude plugin marketplace add byun618/paddock
claude plugin install paddock@paddock
```

**필요한 것**

| 도구 | 어디에 쓰나 |
| --- | --- |
| Claude Code | 플러그인 실행 |
| git · [GitHub CLI](https://cli.github.com/)(`gh`) | worktree·PR 생성·머지 확인 |
| Node.js | `capability-check.mjs` |
| [gitleaks](https://github.com/gitleaks/gitleaks) | 시크릿 점검 훅 — **없으면 pre-commit 이 모든 커밋을 막는다** |
| Codex · Grok CLI (선택) | 구현자와 다른 도구로 리뷰할 때. `defaults.md` 에서 정한다 |

## 쓰기

### 1. 적용하기 — `adopt`

대상 레포에서 `/paddock:adopt` 또는 「이 레포에 paddock 적용해줘」.

| 단계 | 하는 일 | 대상에 쓰나 |
| --- | --- | --- |
| 0 감사 | 신규/기존/재적용 판정, 기존 규칙·스킬 분류 | 아니오 |
| 1 분석 | 스택·명령·테스트·실행·배포·쓰는 도구 | 아니오 |
| 2 설계 | 모듈·harness·변수·슬롯 내용·역할 기본값·옮기는 계획 | 아니오 |
| ⛔ 승인 | 설계 요약 + 생성 목록 + 옮기는 diff + 충돌 | 아니오 |
| 3 생성 | 렌더 → 슬롯 채움 → 기존 내용 옮김 → 들이기 | 예 |
| 4 검증 | `paddock-check`, capability-check, 훅 | 검증만 |
| 5 보고 | 결과·남은 일 | — |

기존 내용은 지우지 않고 옮긴다. 커밋은 하지 않으니 diff 를 보고 직접 하거나 확인해 준다.

### 2. 작업하기 — `task-*`

본체 세션에서 「ABC-12 시작하자」라고 하면 흐름이 시작된다. 일감 트래커가 없으면 슬러그로 쓴다.

```
본체 세션     task-start     worktree·브랜치 생성, 코디네이터 세션 기동
                │
코디네이터     1 분석           일감 스냅샷, 외부 사실 대조
              2 판정 기준       구현 전에 박는다
              3 킥오프         ── ⛔ 게이트 ⓪ 구현 시작 승인
                │
워커 세션     4 구현           별도 세션, 구현 브랜치
                │
리뷰어 세션    5 코드 리뷰       구현자와 별도 세션, 재리뷰도 새 세션
                │
코디네이터     6 판정           기준 대비 증거 ── ⛔ 게이트 ① 채택 승인
              7 사용자 확인     ── ⛔ 게이트 ② PR 생성 승인
                │
본체 세션     task-close     머지(사용자 확인 뒤)·머지 뒤 확인·회고·완료·정리
```

- 게이트 사이는 자율로 진행하고, 게이트에서는 반드시 멈춰 보고한다. PR 생성 승인 전까지 worktree 를 유지해 직접 실행해 볼 수 있다
- 코디네이터는 판정만 하고 머지하지 않는다. 머지는 본체 세션의 `task-close` 가 사용자 확인 뒤에 한다
- 작업 브랜치는 작업 하나의 수명만 갖고, 기본 브랜치 반영은 merge commit PR 로만 한다
- 회고에서 작업별 배움과 결정 초안을 골라 `.agents/learnings/`·`docs/adr/` 로 채택한다

작업 문서는 `your-project-specs/<작업 이름>/` 에 쌓인다.

```
00-start.md · 00-analysis.md · 01-criteria.md · 02-kickoff.md
raw/review/ · reviews.md · verdict.md
devlog.md · learnings-proposal.md · adr-draft-*.md · handoff-main.md · pr.md · close.md
```

### 3. 갱신하기 — `sync`

```sh
claude plugin update paddock@paddock
```

그 뒤 적용한 레포에서 `/paddock:sync`. 변경 노트의 「재감사」 항목과 새 슬롯은 프로젝트에 맞는 반영안을 써서 승인받고, 끝에 일반적인 배움을 paddock 에 되돌려 보낼 초안을 낸다.

| 대상 상태 | 처리 |
| --- | --- |
| 고정 부분을 안 고침 | 새 버전으로 덮어쓴다 |
| 설계 슬롯 | 내용을 ID + 순번으로 옮겨 담는다. 새 슬롯은 비워 두고 채울 안을 낸다 |
| seed 파일 | 쓰지 않는다. 바뀌었으면 보고만 한다 |
| 고정 부분을 고쳤거나 지움 · 고아 슬롯 | **충돌** — 아무것도 쓰지 않고 선택지를 보인다 |

쓰다가 실패하면 lock 을 바꾸지 않아서, 원인을 고쳐 다시 돌리면 이어진다.

## 프로젝트마다 달라지는 것 — 설계 슬롯

자산 안에 표시된 구간을 adopt 가 대상에서 확인한 사실로 채운다.

```markdown
<!-- paddock:design D7 -->
빠른 확인: pnpm test --filter <패키지>
최종 관문: pnpm build && pnpm test && pnpm e2e
<!-- /paddock:design -->
```

| 슬롯 | 자리 | 내용 |
| --- | --- | --- |
| `D1` | `AGENTS.md` 머리 | 프로젝트 소개 |
| `D3` | task-start | 일감 트래커 읽기·상태 전이 |
| `D5` | validation | 「네이티브 실행」 — 사용자가 실제로 쓰는 설치·실행 경로 |
| `D6` | validation · task-coordinate | 건드리면 안 되는 사용자 데이터·직렬 자원 |
| `D7` | task-coordinate | 테스트 계층 — 빠른 확인과 최종 관문 |
| `D8` | task-coordinate | 경량 경로로 처리할 범주 |
| `D9` | implementation | 일감 관문 스크립트 작성법 |
| `D12` | reviewer | 이 프로젝트에서 리뷰어가 특히 볼 것 |
| `D13` | task-coordinate | 외부 서치 위임 도구·조건 |
| `D15` | task-coordinate | 통합 결과를 사용자가 직접 확인하는 방법 |
| `D16` | task-close | 머지 뒤 단계 — 배포·마이그레이션·라이브 확인 |

역할별 도구·모델(`.agents/defaults.md`)은 슬롯이 아니라 파일 통째로 adopt 가 쓴다.

## harness — 절차와 도구의 분리

task 스킬에는 터미널 명령이 없다. 『세션 기동』·『본문 주입』·『완료 감지』 같은 **능력 이름**으로만 쓰고, 명령은 도구별 매핑에 둔다.
도구를 바꿔도 절차 문서는 그대로다.

목표는 「어디서나 같은 보장」이 아니라 **「어디서나 돌고, 못 하는 것은 판정표에서 공백」** 이다. 판정표에는 근거를 세 수준으로 적고, 약한 보장을 강한 보장처럼 적지 않는다.

| 수준 | 뜻 |
| --- | --- |
| **증명** | 도구의 공개 계약이 그 사실을 값으로 돌려준다 |
| **관측** | 화면·로그로 볼 수는 있으나 계약이 아니다 |
| **공백** | 볼 수단이 없다 |

| 매핑 | 대상 | 보장 |
| --- | --- | --- |
| `bare` | iTerm2 · tmux — 제어 런타임 없음 | 증명 없음. 『완료 감지』가 공백이라 워커 완료는 사람이 화면을 보고 판단하고 그렇게 기록한다 |
| `corral` | 에이전트 제어 데스크톱 앱 | 완료 감지 등을 값으로 돌려준다. **corral 은 아직 공개되지 않았다** |
| `orca` | [Orca](https://github.com/stablyai/orca) 앱의 CLI | 완료 보고는 활성 시도 id 로 증명한다. 본문 전달은 관측, pane 세대는 공백이다 |

## 이 레포 구조

```
.claude-plugin/    plugin.json(버전 원본) · marketplace.json
skills/            adopt · sync
bin/               paddock-render(render·apply·sync) · paddock-check — 결정적 도구
assets/            대상 레포 루트를 비추는 자산 트리 (층·모듈별 폴더)
templates/         역할마다 찍어내는 틀
evals/             스킬 트리거 평가 케이스
scripts/           자산 계약·공개 안전 검사, 렌더·sync·갱신 시험
```

층·표기 규약·변수·복사 규칙·sync 판정표의 원본은 [`assets/README.md`](assets/README.md) 다.
