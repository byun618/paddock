---
name: adopt
description: 레포(신규·기존)에 paddock AI 작업 흐름 — AGENTS.md 지도, .agents 규칙·역할·스킬, 사용자 승인 게이트가 있는 task 흐름(분석→구현→독립 리뷰→판정→PR), harness 매핑 — 을 그 프로젝트에 맞게 설계해 깐다. 코드베이스와 기존 CLAUDE.md·AGENTS.md·규칙·스킬을 감사하고, 네이티브 실행·테스트 계층·리뷰 관점·경로 기준·harness 도구를 설계해 승인받은 뒤 생성·검증한다. 「paddock 적용」「adopt」「이 레포에 작업 흐름 깔아줘」「corral 흐름을 이 프로젝트에도」「AGENTS.md 체계 세팅」에 쓴다. 이미 깐 레포의 설계 변경(모듈·harness 바꾸기)에도 쓴다. paddock 새 버전 반영(sync), CLAUDE.md·AGENTS.md 한 파일만 쓰거나 고치는 일, 에이전트 팀 구성, 코드 리뷰 요청에는 쓰지 않는다.
---

# adopt — 프로젝트에 paddock 작업 흐름 깔기

뼈대(고정 자산)는 paddock 이 **결정적으로 렌더**해 그대로 깐다. LLM 이 하는 일은 셋뿐이다 —
대상 프로젝트를 읽고, **설계 슬롯**과 `.agents/defaults.md` 를 쓰고, 기존 파일을 어디로 옮길지 정한다.
고정 문장을 다시 쓰거나 다듬지 않는다. 마음에 안 들면 paddock 레포에 되돌려 보낸다.

- 자산 계약(층·모듈·변수·슬롯·표기 규약): `${CLAUDE_PLUGIN_ROOT}/assets/README.md` — **0단계 전에 읽는다**
- 도구: `paddock-render`(render·apply·sync), `paddock-check` — 플러그인 `bin/` 이라 Bash 에서 바로 부른다
- 세부 절차: `${CLAUDE_SKILL_DIR}/references/` 의 `audit.md`(0단계) · `design.md`(1~2단계) · `record.md`(`.paddock/design.md` 형식)

## 지키는 것

- **승인 전에는 대상 레포에 아무것도 쓰지 않는다.** 렌더·초안은 대상 밖 작업 폴더(`STAGE`)에서 한다
- 대상 레포의 기존 내용은 지우지 않고 **옮긴다**. 옮길 곳이 없는 것은 그대로 둔다. 무엇을 어디로 옮기는지는 승인 게이트에서 diff 로 보인다
- 설계 슬롯 안과 `defaults.md` 에는 **대상에서 확인한 사실과 사용자 답만** 쓴다(같은 기계의 다른 레포에서 베끼지 않는다). 명령은 실제로 있는 것(스크립트·Makefile·CI·README)에서 가져오고, 추측이면 「확인 필요」라고 쓴다
- 산출물·문장은 한국어(paddock 자산이 한국어 고정). 기존 파일 내용을 옮길 때는 원문 언어 그대로
- 원격에 닿는 일(레포 생성·push)은 따로 묻는다

## 단계

| 단계 | 하는 일 | 대상에 쓰나 |
| --- | --- | --- |
| 0 감사 | 신규/기존/재적용 판정, 기존 산출물 4분류, 재사용 판정 | 아니오 |
| 1 분석 | 스택·명령·테스트·실행·배포·쓰는 도구 | 아니오 |
| 2 설계 | 모듈·harness·변수·슬롯 내용·역할 기본값·옮기는 계획 | 아니오 (STAGE 에만) |
| ⛔ 승인 | 설계 요약 + 생성 목록 + 옮기는 diff + 충돌 | 아니오 |
| 3 생성 | 렌더 → 슬롯 채움 → 기존 내용 옮김 → apply | 예 |
| 4 검증 | paddock-check, capability-check, 훅 | 예 (검증만) |
| 5 보고 | 결과·남은 일. 커밋은 사용자 확인 뒤 | — |

재적용(이미 `.paddock/config.sh` 가 있음)은 0단계 표에서 필요한 단계만 고른다 — `audit.md` 「재적용」.
paddock **버전 갱신**은 이 스킬이 아니라 `sync` 스킬이다.

## 0. 감사

`audit.md` 를 따른다. 결과는 STAGE 의 `audit.md` 에 남긴다.

1. 대상 = 현재 git 레포 루트(`git rev-parse --show-toplevel`). git 레포가 아니면 멈추고 묻는다. 작업 트리가 더럽면 멈추고 알린다 — 3단계의 변경이 한 덩어리 diff 로 보여야 한다
2. 판정: `.paddock/config.sh` 있음 → **재적용** · 추적 파일이 거의 없음(README·LICENSE·설정 정도) → **신규** · 그 밖 → **기존**
3. 기존 산출물 목록과 4분류(소개·규칙·절차·그대로), paddock 역할·스킬과의 재사용/확장/신규 판정
4. STAGE 를 만든다: `STAGE=$(mktemp -d "${TMPDIR:-/tmp}/paddock-adopt.XXXXXX")`

## 1. 분석

`design.md` 「분석」 표의 항목을 채운다 — 스택, 패키지 매니저, 빌드·실행·테스트·린트 명령(출처 파일과 함께), CI, 배포 산출물,
사용자가 실제로 쓰는 실행 경로, 로컬 데이터·런타임 자원, 외부 의존(API·CLI), 이미 쓰는 에이전트 도구(Claude Code·Codex 등)와
터미널 제어 도구(`corral`·`tmux` 실행 파일 유무), git 훅(`core.hooksPath`·husky·`gitleaks` 유무). 명령은 「있다고 적힌 것」과 「이 세션에서 돌려 본 것」을 구분해 적는다.

## 2. 설계

`design.md` 「설계 항목」을 하나씩 정한다. 결과는 둘:

- `STAGE/config.sh` — `PADDOCK_MODULES`, `PADDOCK_HARNESS`, `PADDOCK_SKIP`(깔지 않을 경로),
  자산 변수들(assets/README 「변수」 표 전부), `VARIANT_SUFFIXES`, `PR_FOOTER`. `PADDOCK_VERSION` 은 render 가 쓴다
- `STAGE/design.md` — `record.md` 형식. 항목마다 값·근거·출처. 옮기는 계획(파일·구간 → 목적지)과 슬롯 초안 전문 포함

기본 모듈은 `l1 l2 specs-repo`. `bundle`·`l3` 는 근거가 있을 때만 제안한다. `specs-inrepo` 는 v0 미구현 —
작업 산출물을 둘 별도 레포가 없으면 만들지 물어본다(이름 제안: `<레포>-specs`, private). 사용자가 원하지 않으면 `l1` 을 끄고 L0 만 깐다.

렌더해 본다 — 충돌을 미리 알기 위해서다:

```sh
paddock-render render --config "$STAGE/config.sh" --out "$STAGE/out"
paddock-render apply "$STAGE/out" "<대상>" --dry-run   # exit 3 이면 충돌 목록 = 옮기는 계획이 다뤄야 할 파일
```

충돌 파일마다 옮기는 계획에 처리(내용을 어디로 옮기고 원본 파일을 어떻게 바꾸는지)가 있어야 한다.

## ⛔ 승인 게이트

여기서 멈추고 보고한다. 보고 항목:

1. 판정(신규/기존/재적용)과 근거 한 줄
2. 켤 모듈·harness 도구, 변수 값 표
3. 설계 슬롯마다 한두 줄 요약(D1·D3·D5…) + `defaults.md` 역할 표
4. 생성할 파일 목록(manifest 기준 개수 + 주요 경로)
5. **기존 파일 처리** — 파일·구간마다 「→ 목적지」, 바뀌는 기존 파일은 diff 요지. 그대로 두는 것도 적는다
6. 원격 작업이 필요하면(specs 레포 생성 등) 따로 표시
7. STAGE 경로 — 사용자가 초안 전문을 볼 수 있다

사용자가 고치라는 것을 반영해 2단계를 다시 하고 다시 보고한다. **승인 없이 3단계로 가지 않는다.**

## 3. 생성

승인된 설계 그대로 한다. 설계에 없는 판단이 필요해지면 멈추고 묻는다.

1. (승인됐으면) specs 레포를 만들고 `SPECS_ROOT` 위치에 둔다. 그 레포에도 `STAGE/out/.githooks/pre-commit` 을 같은 경로로 복사하고 `core.hooksPath .githooks`
2. `STAGE/out` 을 지우고 다시 렌더한다(설계가 바뀌었을 수 있다)
3. `STAGE/out` 안에서 설계 슬롯을 채운다 — `<!-- paddock:design Dn -->` 과 닫는 줄 **사이만** 고친다. 안내 주석은 지운다.
   `.agents/defaults.md` 는 seed 라 파일째 쓴다. 다른 줄은 손대지 않는다
4. 기존 내용 옮기기 — 옮기는 계획대로 STAGE 의 목적지 파일(슬롯 안·`rules/*.md`·`learnings/`·스킬)에 넣고,
   대상 레포의 충돌 파일은 계획대로 바꾼다(예: 기존 `CLAUDE.md` 를 지우고 렌더본으로, 기존 `.claude/skills/<x>` 를 `.agents/skills/<x>` 로 `git mv` 한 뒤 빈 `.claude/skills` 를 `rmdir`).
   깔지 않기로 한 항목(서브에이전트 정의가 있는 `.claude/agents` 등)은 2단계에서 `PADDOCK_SKIP` 에 넣었어야 한다 — manifest 를 손으로 고치지 않는다(다음 sync 가 되살린다)
5. `paddock-render apply "$STAGE/out" "<대상>"` — exit 3 이면 남은 충돌을 보고하고 멈춘다(덮어쓰지 않는다)
6. `STAGE/design.md` 를 `<대상>/.paddock/design.md` 로 복사한다(변경 이력 표에 이번 적용 한 줄)
7. 훅 — 승인된 계획대로. 기존 `core.hooksPath`·husky 가 없으면 `git -C <대상> config core.hooksPath .githooks` (이 클론에만 적용됨을 보고에 적는다).
   있으면 덮지 않는다 — 계획이 합침이면 기존 훅에서 `.githooks/pre-commit` 을 부르게 한다

## 4. 검증

```sh
paddock-check "<대상>" --require-filled      # l1 을 끈 레포는 --require-filled 없이
```

- 훅: `git -C <대상> config core.hooksPath` 가 계획과 같은지, `command -v gitleaks` — 없으면 「첫 커밋이 막힌다, 설치 필요」를 보고 맨 위에
- `l2` 를 켰고 그 도구가 설치돼 있으면 `node .agents/harness/capability-check.mjs runtime --tool <도구>` 도 돌린다. 없으면 「공백」으로 보고
- 실패하면 고친다 — 고정 부분 drift 면 그 파일을 렌더본으로 되돌리고, 슬롯이 비었으면 채운다. 같은 실패가 두 번이면 멈추고 보고
- 대상 레포 테스트를 돌릴 필요는 없다(코드를 바꾸지 않았다). 단 옮긴 스킬이 스크립트를 가리키면 경로가 살아 있는지 본다

## 5. 보고

- 판정·모듈·harness, 생성/옮김/그대로 둔 파일 수, 검증 결과(명령 출력 요지)
- 사람이 할 일: 커밋(제안 메시지 포함), 다른 클론의 `core.hooksPath`, specs 레포 push 여부
- 공백·미확인으로 남긴 설계 항목(「확인 필요」)과 다음에 볼 곳
- **커밋하지 않는다** — 사용자가 diff 를 보고 정한다. 요청받으면 그때 한다
