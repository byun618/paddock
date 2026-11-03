# `.paddock/design.md` 형식

adopt 가 대상 레포에 남기는 설계 기록이다. 다음 재적용과 sync 의 재감사가 이것을 읽는다 — **값보다 근거가 중요하다.**

```markdown
# paddock 설계 — <PROJECT_NAME>

- paddock: <버전> · 판정: 신규|기존|재적용 · 날짜: YYYY-MM-DD
- 모듈: <PADDOCK_MODULES> · harness: <PADDOCK_HARNESS 또는 없음>

## 분석

| 항목 | 값 | 출처 |
| --- | --- | --- |
| 스택 | … | package.json |
| 테스트(빠른) | `…` | package.json scripts.test — 이 세션에서 실행함/안 함 |
| … | | |

## 결정

| 항목 | 값 | 근거 |
| --- | --- | --- |
| l1 | 켬 | 기본 |
| harness | bare | corral·orca 미설치 |
| ISSUE_PREFIX | (빈 값) | 트래커 없음 — 사용자 확인 |
| … | | |

## 설계 슬롯

| ID | 요약 | 근거·출처 | 확인 필요 |
| --- | --- | --- | --- |
| D5 | 프로덕션 빌드를 로컬에서 띄워 브라우저로 1회 | README 「배포」 | — |
| … | | | |

## 기존 파일 처리

| 출처 | 목적지 | 처리 |
| --- | --- | --- |
| CLAUDE.md 「Commands」 | D7 · D15 | 옮김 |
| .claude/skills/deploy | .agents/skills/deploy | git mv · 그대로 |
| .agents/skills/notes 산출물 경로 | 별도 레포 | 돌림 — 지난 산출물은 그대로 |
| 공개 위험(홈 경로 2건) | — | 고침 |
| … | | |

## 변경 이력

| 날짜 | 변경 | 대상 | 사유 |
| --- | --- | --- | --- |
| YYYY-MM-DD | 최초 적용 | 전체 | — |
```

- 이력 행은 지우지 않는다. 재적용마다 한 줄 더한다.
- 비밀 값·홈 경로·사용자 이름을 적지 않는다. 공개 위험은 위치(파일:줄)도 적지 않는다 — 이 기록이 레포에 남는다.
