# 0단계 감사 — 판정·4분류·재사용

## 판정

| 신호 | 판정 | 할 단계 |
| --- | --- | --- |
| `.paddock/config.sh` 있음 | 재적용 | 아래 「재적용」 표 |
| 추적 파일이 README·LICENSE·`.gitignore`·패키지 설정 정도뿐, 에이전트 지침 파일 없음 | 신규 | 0~5 전부. 4분류는 비어 있다 |
| 그 밖 | 기존 | 0~5 전부 |

## 훑을 것 (기존·재적용)

있으면 전부 읽는다. 없으면 「없음」으로 적는다.

- 지침: `CLAUDE.md`·`CLAUDE.local.md`(로컬, 옮기지 않음)·`AGENTS.md`·하위 폴더의 `CLAUDE.md`·`AGENTS.md`·`.cursorrules`·`.cursor/rules/`·`.github/copilot-instructions.md`
- Claude Code: `.claude/rules/`·`.claude/skills/`·`.claude/agents/`·`.claude/commands/`·`.claude/settings*.json`·`.claude/worktrees/`
- 그 밖 에이전트: `.agents/`·`.codex/`·`.grok/`
- 결정 기록: `docs/adr/`·`docs/decisions/`·`CONTRIBUTING.md`
- 훅·스크립트: `.githooks/`·`.husky/`·`core.hooksPath` 설정·`scripts/task-*`
- `.gitignore` 에 이미 있는 에이전트 관련 줄

## 4분류 — 기존 지침 내용을 덩어리(절·불릿 묶음) 단위로

| 분류 | 알아보는 법 | 목적지 |
| --- | --- | --- |
| 소개 | 무엇을 만드는가·스택·폴더 구조·방향 | AGENTS.md D1 슬롯 (길면 요지만. 나머지는 남는 기존 문서를 가리키거나, 그 문서가 교체되는 파일이면 `docs/` 새 문서로 원문 그대로 옮기고 가리킨다) |
| 규칙 | 「~한다/하지 않는다」 문체·스타일·금지 | 코드 → `.agents/rules/coding.md`, 글 → `writing.md`, 완료·검증 → validation D5·D6 슬롯 또는 `coding.md`. 한 번 겪은 덜 검증된 것 → `.agents/learnings/<영역>.md` |
| 절차 | 여러 단계 명령 순서·워크플로 | 스킬 (`.agents/skills/<이름>/`) — 아래 재사용 판정. paddock task 흐름과 겹치면 그쪽 슬롯(D7 테스트 계층·D15 확인 방법)으로 |
| 그대로 | 도구 설정(`settings.json`·`commands/`), 로컬 전용, 판단이 안 서는 것 | 손대지 않는다. 이유를 적는다 |

- 같은 내용이 paddock 고정 문장과 겹치면 옮기지 않고 「고정과 중복 — 버림」으로 적는다(승인 게이트에서 보인다).
- `CLAUDE.md` 는 렌더본(`@AGENTS.md`)으로 바뀐다. **교체되는 파일(apply 충돌 파일) 안의 덩어리는 「그대로」가 될 수 없다** — 전부 목적지가 있어야 한다.
  Claude 전용 내용(도구 권한 등)은 `.agents/rules/<이름>.md`(→ `.claude/rules`)로. 목적지를 못 정하면 멈추고 묻는다.
- 교체 전 원본은 git 이력이 지킨다 — `.paddock/design.md` 「기존 파일 처리」에 `git show <적용 전 HEAD>:<경로>` 를 적는다.
- 하위 폴더의 `CLAUDE.md`·`AGENTS.md` 는 그 폴더 범위의 지침이므로 그대로 둔다.

## 재사용 판정 — 기존 스킬·에이전트 vs paddock 의 task-start·task-coordinate·reviewer

| 기존과의 관계 | 처리 |
| --- | --- |
| paddock 쪽이 기존 역할을 다 포함 | 기존을 지우지 않고 「대체됨」 표시 후 사용자에게 지울지 묻는다 |
| 일부 겹치고, 기존이 프로젝트 특화(배포·데이터 작업 등) | 기존을 `.agents/skills/` 로 옮겨 **그대로 둔다**. paddock 스킬과 description 이 충돌하면 기존 description 에 범위를 적는다 |
| 일부 겹치고, 일반화하면 paddock 쪽 슬롯에 들어감 | 그 내용을 슬롯으로 옮기고 기존 스킬은 위 1행처럼 |
| 범위가 다름 | `.agents/skills/` 로 옮기기만 한다(`.claude/skills` 가 심링크가 되므로) |

`.claude/{rules,skills,agents}` 가 실제 폴더면 내용을 `.agents/` 같은 이름 아래로 `git mv` 하고 남은 빈 폴더를 지우는 것(`rmdir`)이 기본이다 — 그래야 심링크를 깔 수 있다.
에이전트 파일(`.claude/agents/*.md`)은 서브에이전트 정의일 수 있다 — paddock 의 `.agents/agents/` 는 「세션이 읽는 역할 지침서」라 뜻이 다르다. 서브에이전트 정의는 그대로 두고 `.claude/agents` 심링크를 깔지 않는다 — 3단계에서 `STAGE/out/.paddock/manifest.tsv` 의 `.claude/agents` 행을 지우고(apply·paddock-check 가 그 manifest 를 따른다) 설계에 적는다.

## 재적용

| 바꾸려는 것 | 0 | 1 | 2 | 승인 | 3 | 4 |
| --- | --- | --- | --- | --- | --- | --- |
| 슬롯 내용·defaults 만 | 현재 `.paddock/design.md` 읽기 | 필요한 항목만 | 해당 항목 | 필수 | 슬롯만 고침(렌더·apply 없음) | 필수 |
| 모듈·harness 켜고 끄기 | — | — | — | — | v0 미구현 — 채운 슬롯을 지키며 managed 파일의 module 구간만 바꾸는 도구가 없다(다시 렌더해 apply 하면 슬롯을 채운 파일이 충돌). 「미구현 — sync 예정」으로 보고하고 멈춘다 | — |
| paddock 버전 갱신(고정 자산) | — | — | — | — | sync(예정)의 일 — 지금은 「sync 미구현」 으로 보고하고 멈춘다 | — |

재적용 때 슬롯 내용은 대상의 현재 파일이 원본이다 — 렌더본의 빈 슬롯으로 덮지 않는다.
