<!-- paddock:fixed -->
## 『질의응답』

### 명령
```bash
orca orchestration ask (--question "<질문>" | --resume <message_id>) [--run <run_id>] [--options <csv>] \
  [--timeout-ms <n>] --json
orca orchestration reply --id <msg_id> --body "<답>" [--run <run_id>] --json
```

### 보장 수준
**증명(계약).** 계약이 "타임아웃은 질문을 pending 으로 남기고, **원래 메시지 id 로 재개한다**" 고 적는다.
**`ask` 가 `--run` 을 받는다** — 바인딩이 바뀐 구간에서도 질문을 원하는 Run 으로 보낼 수 있다.
활성 Dispatch 에서 새 질문은 기본적으로 그 Dispatch 가 속한 Run 의 mailbox 로 간다.

### 상황 → 행동
- **차단 화면**: 해당 없음 — 질문·답은 구조화된 메시지 경로이고 pane 화면을 거치지 않는다.
- **타임아웃·빈 결과**: 상한 수치가 레지스트리에 적혀 있지 않다 — **공백.** 필요하면 실측해 적는다.
  타임아웃 뒤에는 `--resume <원래 id>` 를 쓴다. 다시 물으면 중복 질문이 된다.
- **부분 실패**: 워커 보고(`worker_done`·`heartbeat`)는 그룹 주소로 보낼 수 없고 `--to` 를 비워 Dispatch 의
  Run mailbox 로 보낸다.
- **복구**: 답을 보낼 때는 **같은 orca 실행 파일**로 `orca orchestration reply --id` 를 쓴다(계약이 명시).
- **하지 말 우회**: `--payload` 로 raw JSON 을 조립하지 않는다 — 계약이 `--task-id`/`--dispatch-id` 류 전용
  플래그를 쓰라고 적는다. 로컬 대화형 프롬프트로 사람에게 묻지 않는다.
