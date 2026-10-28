# {{PROJECT_NAME}} — 공통 지침

<!-- paddock:design D1 -->
<!-- adopt 가 쓴다: 무엇을 만드는가, 주요 스택, 방향 문서가 있으면 그 위치. 2~4줄 -->
<!-- /paddock:design -->

<!-- paddock:module l1 -->
<!-- /paddock:module -->

## 어디를 고치나 (증상 → 파일)

| 증상 | 고치는 파일 |
| --- | --- |
| 프로젝트가 뭔지 매번 설명하게 된다 | AGENTS.md |
| 문체·용어·문서 형식이 매번 다르다 | .agents/rules/writing.md |
| 코드 스타일·파일 이름이 제각각이다 | .agents/rules/coding.md |
| "다 됐습니다"인데 안 되어 있다 | .agents/rules/validation.md |
| 같은 다단계 절차를 매번 다시 설명한다 | .agents/skills/<이름>/SKILL.md 신설 |
| 같은 배움을 일감마다 다시 겪는다 | .agents/learnings/<영역>.md (형식·승격은 그 폴더 README) |
| 왜 그렇게 정했는지 매번 다시 묻는다 | docs/adr/ (번호·상태는 그 폴더 README) |

<!-- paddock:module l1 -->
<!-- /paddock:module -->

## 원본 관리

- 규칙·에이전트·스킬 원본은 .agents/ 에만 둔다. .claude/ 의 rules·skills·agents 는 심링크 — 원본 저장 금지
- .agents/agents/ 의 역할 파일은 각 터미널 세션이 시작 시 읽는 지침서다 (서브에이전트 아님)
- codex 는 AGENTS.md 만 읽는다 — 역할은 .codex/agents/<역할>.toml 포인터 경유. .agents/agents/ 를 고치면 포인터가 깨지지 않았는지 확인
- rules 스텁(writing.md·coding.md)은 같은 실수 두 번째에 한 줄씩 — 첫 번째는 .agents/learnings/ 에. 글로벌 스타일과 중복 금지
- 스킬의 로컬 상태(config.json, state/)는 .gitignore — config.example.json 만 커밋
- 시크릿 점검: gitleaks pre-commit 훅(.githooks/). 클론마다 한 번 `git config core.hooksPath .githooks`
- **paddock 이 깐 파일**: 첫 줄이 `paddock:fixed` 인 파일과, `paddock:design` 구간 밖은 paddock sync 가 덮어쓴다 —
  고칠 것은 paddock 레포에 되돌려 보낸다. `paddock:seed` 파일과 `paddock:design` 구간 안은 이 프로젝트 소유다
- **이 파일은 매 세션·매 호출에 실린다** — 매 세션 필요한 사실만 두고, 다단계 절차·한 역할만 쓰는 규칙은 스킬로 뺀다.
  200줄을 넘으면 이미 너무 길다
