<!-- paddock:fixed -->
## 『화면 관측』

### 명령
```bash
orca terminal read [--terminal <handle>] [--screen] [--cursor <n>] [--limit <n>] --json
orca orchestration worker-read --dispatch <dispatch_id> [--source auto|transcript|terminal] \
  [--cursor <cursor>] [--limit <n>] --json
orca orchestration worker-show --dispatch <dispatch_id> --json     # observation.agentWait
```

### 보장 수준
**관측(H2).** `worker-show` 의 `observation.agentWait` 는 사람만 답할 수
있는 프롬프트에 멈춘 워커를 **그 근거와 함께** 이름 짓는다. **null = 보았고 없었다, 필드 부재 = 보지 않았다**
(오래된 호스트·증명 불가한 신원·읽을 수 없는 pane·시간 내 응답 없는 탐침) — **필드 부재를 "안 기다린다" 로
읽지 않는다.** 계약이 "기다리는 워커는 건강한 것이고 실패가 아니다" 라고 적는다.

### 상황 → 행동
- **차단 화면**: 이 능력으로 본다. 『준비 대기』가 차단을 가리지 못하므로 **첫 지시 전 화면 읽기가 이 도구에서는
  선택이 아니다.**
- **타임아웃·빈 결과**: 기본 읽기는 **누적 출력**이고 escape 가 제거된 상태라, 줄을 다시 그리는 프로그램은
  조각으로 쌓여 온다(계약의 예: 셸에서 clear 한 번이 `cclclecleaclear` 로 보인다). **렌더된 화면이 필요하면
  `--screen`** 을 쓴다. `--screen` 과 `--cursor` 는 상호배타다.
- **부분 실패**: 응답의 `source` 가 `stream`·`screen`·`screen-unavailable` 을 구분한다. 필드 부재는 오래된
  호스트다. `draft` 는 UI 전용 작성 중 텍스트이니 **출력이나 제출된 지시로 읽지 않는다.**
- **복구**: 명령 응답을 잡을 때는 보내기 전에 한 번 읽고, 기다린 뒤 `--cursor <이전 nextCursor>` 로 새 출력만 읽는다.
  `worker-read` 의 커서는 소스에 고정되므로 `source_changed` 면 새로 읽는다.
- **하지 말 우회**: 화면 문장을 『완료 감지』 대용으로 쓰지 않는다. `--source transcript` 가 있다고 transcript 가
  항상 있는 것은 아니다 — 계약이 "훅이 보고한 transcript 가 **있을 때**" 라고 적는다.
