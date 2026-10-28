# paddock

AI 작업 흐름을 프로젝트에 맞게 설계해 깔아 주는 Claude Code 플러그인.

규칙·역할·스킬·사용자 승인 게이트·harness 매핑·출고까지, 한 프로젝트에서 다듬은 작업 흐름의 **뼈대는 그대로** 가져가고
**프로젝트마다 달라야 하는 부분**(실행 확인 방법, 테스트 계층, 리뷰 관점, 쓰는 도구, 출고 산출물)은 LLM 이 코드베이스를 보고 설계한다.

> 상태: `0.2.0` — 적용 스킬 `adopt` 와 L0·L1·L2 자산. 갱신 스킬(`sync`)·L3 출고·같은 레포 산출물 모드는 아직 없다.

## 설치

```sh
claude plugin marketplace add byun618/paddock
claude plugin install paddock@paddock
```

## 쓰기

대상 레포에서 `/paddock:adopt` (또는 「이 레포에 paddock 적용해줘」). 감사 → 분석 → 설계 → **승인 게이트** → 생성 → 검증 순으로 가고,
승인 전에는 대상 레포에 아무것도 쓰지 않는다. 커밋은 하지 않는다 — diff 를 보고 직접 한다.

## 층

| 층 | 내용 | 켜는 조건 |
| --- | --- | --- |
| L0 기본 | `AGENTS.md` 지도 틀 · `CLAUDE.md` · `.agents/` 원본 + `.claude/` 심링크 · rules 스텁 · learnings·ADR 형식 · 시크릿 훅 | 항상 |
| L1 작업 흐름 | 분석 → 기준 → 구현 → 독립 리뷰 → 판정 → PR, 사용자 승인 게이트 3단 | 기본 켬 |
| L2 harness | 터미널·에이전트 제어 도구 매핑 (쓰는 도구 하나만) | 기본 켬 |
| L3 출고 | release 브랜치·태그·릴리즈 노트·산출물 | 선택 |

고정 뼈대는 `assets/` 에 있고, 표기 규약과 변수는 [`assets/README.md`](assets/README.md) 에 있다.

## 라이선스

MIT
