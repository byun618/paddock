---
name: sync
description: paddock 을 이미 깐 레포를 설치된 paddock 새 버전에 맞춘다 — 고정 자산(AGENTS.md 뼈대·규칙·task 스킬·스크립트·harness 매핑)을 갱신하고, 채운 설계 슬롯은 그대로 옮기고, 변경 노트의 「재감사」 항목과 새 슬롯은 그 프로젝트에 맞는 반영안을 써서 승인받는다. 프로젝트가 고친 고정 부분은 멈추고 보고한다. 「paddock 업데이트」「paddock sync」「paddock 새 버전 반영」「고정 자산 갱신」「paddock-check 가 sync 하라는데」에 쓴다. 끝에 프로젝트의 일반적인 배움을 paddock 에 되돌려 보낼 초안을 낸다. 처음 깔기·모듈이나 harness 바꾸기(adopt), 플러그인 설치·업데이트 명령, git·fork 동기화, 의존성 업그레이드에는 쓰지 않는다.
---

# sync — 깐 레포를 paddock 새 버전에 맞추기

고정 부분은 `paddock-render sync` 가 **결정적으로** 맞춘다. LLM 이 하는 일은 셋뿐이다 —
변경 노트를 읽고 대상에 맞는 **재감사 반영안**을 쓰고, **충돌**을 사용자에게 선택지로 보이고, 승인 뒤 새 슬롯을 채운다.
고정 문장을 다시 쓰거나 다듬지 않는다.

- 자산 계약과 sync 판정표: `${CLAUDE_PLUGIN_ROOT}/assets/README.md` 「sync」 — **1단계 전에 읽는다**
- 변경 노트: `${CLAUDE_PLUGIN_ROOT}/CHANGELOG.md` — 버전마다 `### 재감사` 절
- 슬롯마다 무엇을 쓰나: `${CLAUDE_PLUGIN_ROOT}/skills/adopt/references/design.md` 「설계 슬롯 — 무엇을 써야 하나」 — 출처 규칙도 adopt 와 같다
- 되돌려 보내기: `${CLAUDE_SKILL_DIR}/references/upstream.md`

## 지키는 것

- **승인 전에는 대상 레포에 아무것도 쓰지 않는다.** 렌더·초안은 대상 밖 `STAGE` 에서 한다
- 충돌을 `--take-new` 로 푸는 것은 **사용자가 그 경로를 고른 때만**이다. 프로젝트가 고친 내용을 말없이 버리지 않는다
- 슬롯·seed 에는 대상에서 확인한 사실과 사용자 답만 쓴다(같은 기계의 다른 레포에서 베끼지 않는다)
- 커밋·원격 작업(이슈·PR 생성)은 따로 묻는다

## 단계

| 단계 | 하는 일 | 대상에 쓰나 |
| --- | --- | --- |
| 1 확인 | 버전 비교, 작업 트리, 변경 노트 | 아니오 |
| 2 계획 | 렌더 → `sync --dry-run` | 아니오 |
| 3 재감사 | 새 슬롯·바뀐 seed·「재감사」 항목·새 변수의 반영안 | 아니오 (STAGE 에만) |
| ⛔ 승인 | 계획 + 충돌과 선택지 + 반영안 | 아니오 |
| 4 쓰기 | `sync` → 슬롯 채움 → 승인된 반영 | 예 |
| 5 검증·기록 | `paddock-check`, `.paddock/design.md` 이력 | 예 |
| 6 보고 | 결과, 되돌려 보내기 초안 | — |

## 1. 확인

1. 대상 = `git rev-parse --show-toplevel`. `.paddock/config.sh`·`manifest.tsv` 가 없으면 → adopt 를 안내하고 멈춘다
2. 작업 트리가 더러우면 멈추고 알린다 — sync 뒤 `git diff` 가 sync 변경만 보여야 한다
3. `OLD` = 대상 config 의 `PADDOCK_VERSION`, `NEW` = `paddock-render version`.
   같으면 「이미 최신」(drift 는 `paddock-check` 로 본다)으로 멈춘다. `NEW` 가 더 낮으면 플러그인 갱신을 안내하고 멈춘다
4. CHANGELOG 에서 `OLD` 초과 ~ `NEW` 이하 절을 읽는다. `### 재감사` 항목을 목록으로 뽑는다
5. `STAGE=$(mktemp -d "${TMPDIR:-/tmp}/paddock-sync.XXXXXX")`

## 2. 계획

```sh
paddock-render render --config "<대상>/.paddock/config.sh" --out "$STAGE/out"
paddock-render sync "$STAGE/out" "<대상>" --dry-run      # exit 3 = 충돌 있음, 0 = 없음
```

- 렌더가 exit 4 「미정의 변수 {{X}}」면 새 버전이 변수를 더했다 — `assets/README.md` 「변수」 표의 뜻대로 대상에서 값을 찾고,
  못 찾으면 묻는다. `STAGE/config.sh`(대상 config 사본)에 더해 그것으로 렌더한다. 4단계에서 대상 config 는 sync 가 덮는다
- 계획 줄: `갱신`·`만듦`·`지움`·`링크`·`폴더 만듦`·`폴더 지움` 은 도구가 한다. `새 슬롯`·`seed 바뀜`·`seed 남김`·`충돌` 은 3단계와 게이트의 몫

## 3. 재감사

각각 반영안을 `STAGE/plan.md` 에 쓴다. 안마다 무엇을·어디에·근거(대상 파일:줄 또는 사용자 답).

| 입력 | 반영안 |
| --- | --- |
| `새 슬롯 <파일> <ID>#<n>` | 슬롯 내용 초안 — adopt `design.md` 의 그 슬롯 설명대로, 대상 `.paddock/design.md` 의 분석·결정을 근거로 |
| `seed 바뀜 <파일>` | `diff <대상 파일> "$STAGE/out/<파일>"` 에서 새 버전이 더한 규칙만 골라 「넣을지」 제안. 프로젝트가 쓴 줄은 건드리지 않는다 |
| CHANGELOG `### 재감사` 항목 | 대상에서 해당하는 곳을 찾아(grep — 슬롯·rules·프로젝트 스킬·defaults) 고칠 안. 해당 없으면 「해당 없음」과 찾은 방법 |
| 새 변수 | 값과 출처 |

## 충돌

충돌마다 사유와 함께 **프로젝트가 무엇을 바꿨는지** 보인다:

```sh
BASE=$(git -C "<대상>" log -1 --format=%H -- .paddock/manifest.tsv)   # 지난 적용·sync 커밋
git -C "<대상>" diff "$BASE" -- "<경로>"                              # 그 뒤 프로젝트의 수정
diff "<대상>/<경로>" "$STAGE/out/<경로>"                               # 새 버전과의 차이
```

`BASE` 커밋이 없으면(적용 뒤 커밋 전) 둘째 줄은 「알 수 없음」. 사유별 선택지:

| 사유 | 선택지 |
| --- | --- |
| 고정부를 프로젝트가 고쳤다 · 빠지는 파일을 고쳤다 | ① 새 것으로(`--take-new`) — 그 수정이 일반적이면 되돌려 보내기 후보 ② 수정 내용을 슬롯·`.agents/rules/`·learnings 로 옮긴 뒤 새 것으로 ③ 이번 sync 보류 |
| 고아 슬롯 | ① 내용을 새 버전의 다른 슬롯·rules 로 옮긴 뒤 `--take-new` ② 보류 |
| 대상에서 지워졌다 | ① 되살림(`--take-new`) ② 깔지 않기로 — config `PADDOCK_SKIP` 에 더하고 다시 렌더 |
| 심링크·폴더 자리에 실제 파일 | ① 그 파일을 옮긴 뒤 다시 ② `PADDOCK_SKIP` |
| 내용이 다른 기존 파일 (새 파일 자리) | ① 기존 내용을 어디로 옮길지 정하고 `--take-new` ② `PADDOCK_SKIP` |

## ⛔ 승인 게이트

여기서 멈추고 보고한다:

1. `OLD` → `NEW`, CHANGELOG 요지(Added·Changed 한두 줄씩)
2. 계획 — 처리별 개수와 경로(갱신·만듦·지움)
3. 충돌마다 사유·프로젝트 수정 요지·선택지와 추천
4. 재감사 반영안(새 슬롯 초안 요약, seed 제안, 재감사 항목별 안, 새 변수)
5. `STAGE` 경로 — 초안 전문

**승인 없이 4단계로 가지 않는다.** 사용자가 고른 선택지가 대상 파일을 옮기거나 고치는 것이면 그것도 4단계에서 한다.

## 4. 쓰기

1. 승인된 선택지 중 대상 파일을 옮기는 일(②·`PADDOCK_SKIP` 등)을 먼저 한다. config 를 바꿨으면 `STAGE/out` 을 지우고 다시 렌더
2. `paddock-render sync "$STAGE/out" "<대상>" [--take-new <경로>]…` — 사용자가 「새 것으로」를 고른 경로만. exit 3 이면 멈추고 보고
3. 새 슬롯을 채운다 — `<!-- paddock:design Dn -->` 과 닫는 줄 **사이만**, 안내 주석은 지운다
4. 승인된 seed·재감사 반영을 한다

## 5. 검증·기록

```sh
paddock-check "<대상>" --require-filled      # l1 을 끈 레포는 --require-filled 없이
```

- 실패하면 고친다(빈 슬롯 → 채움). 고정 부분 drift 가 남으면 4단계가 틀린 것 — 멈추고 보고. 같은 실패가 두 번이면 멈추고 보고
- `.paddock/design.md` — 머리줄의 paddock 버전을 `NEW` 로, 변경 이력 표에 한 줄(`sync OLD → NEW` · 바뀐 대상 · 사유), 새 슬롯은 「설계 슬롯」 표에 행 추가

## 6. 보고

- `OLD` → `NEW`, 처리별 개수, 충돌 처리, 재감사 반영, 검증 결과(명령 출력 요지)
- 사람이 할 일: 커밋(제안 메시지 포함). **커밋하지 않는다** — 사용자가 diff 를 보고 정한다
- 되돌려 보내기 — `upstream.md` 대로 후보를 훑고, 있으면 초안을 보인다. 없으면 「후보 없음」 한 줄
