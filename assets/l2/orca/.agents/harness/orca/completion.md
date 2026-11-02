<!-- paddock:fixed -->
## 『완료 감지』

### 명령
```bash
orca orchestration check [--run <run_id>] [--ack <delivery_id>] [--types <type,...>] [--wait] \
  [--timeout-ms <n>] --json
orca orchestration worker-show --dispatch <dispatch_id> --json
orca orchestration inbox [--limit <n>] [--terminal <handle>] [--full] --json   # 확인(ACK) 없이 들여다본다
# ↓ 워커 쪽이 치는 명령. 코디네이터가 "완료 감지" 를 말할 때 반대편에서 이게 돌고 있다
orca orchestration send --type <type> --task-id <task_id> --dispatch-id <dispatch_id> \
  --subject <제목> [--body <본문>] [--outcome succeeded|failed] [--run <run_id>] --json
```

**여기서 틀리면 `invalid_argument` 다**: `inbox` 는 `--run` 을 받지 않는다(`--limit`·`--terminal`·`--full` 뿐이다).
**요청이 실행됐는지 모를 때**는 `orca orchestration request-show --request <request_id> --json` 으로 묻는다. 읽기 전용이다.
`completed` 면 같은 `--retry-request` 가 기록된 결과를 돌려준다. `pending` 이면 원래 명령이 살아 있는지 보고 기다리거나 같은 id 로 다시 낸다. `absent` 는 **아무 일도 없었다는 증거가 아니다.**
메시지 조회(`orchestration inbox`)는 이 질문의 답이 아니다.

### 보장 수준
**증명(계약).** 완료는 `orca orchestration send --type worker_done` 이고 `--outcome succeeded|failed` 가 필수다. 계약이
"활성 task/dispatch id 를 담은 `worker_done` 은 **그 dispatched pane 에서만** 그 Task 를 완료시키고, 안정적인
pane 신원이 없으면 발신 handle 이 dispatch assignee 와 정확히 일치해야 한다" 고 적는다 — 오래된 시도·다른
pane 의 보고를 배제하는 장치가 계약에 있다. `orca orchestration check` 는 바인딩된 Run 의 **가장 오래된 미확인 FIFO 배치**를
돌려주고 `--ack` 전까지 같은 Delivery 를 되돌린다.
판정은 **거절 표식 없음 + `taskId`·`dispatchId` 일치**로만 한다 — 거절된 보고도 큐에 `type: worker_done` 으로 오고 payload 에 `_orcaLifecycleRejection` 이 붙는다. 지난 시도의 보고는 `dispatch_capability_invalid` 로 거부된다(둘 다 1.4.198 관측).

### 상황 → 행동
- **차단 화면**: 완료 감지 경로에서는 보이지 않는다. 차단은 『화면 관측』 또는 `worker-show` 의
  `observation.agentWait` 로 본다.
- **타임아웃·빈 결과**: `--wait` 는 맞는 메시지가 오거나 시간이 다할 때까지 막는다. 대기 중
  **15초마다 stderr 로 JSON keepalive 줄**을 뿜으므로 stdout 과 섞어 파이프할 때 `_keepalive` 를 걸러야 한다.
  `_keepalive` 는 heartbeat 메시지와 무관하다. 빈 배치는 새 워커를 만드는 근거가 아니다. `--types` 는 깨우는 조건일 뿐이라, 돌아온 배치에는 다른 종류도 섞여 있다 — 깬 것을 완료로 읽지 않고 처리한 뒤 ack 하고 다시 기다린다. `--wait --ack` 를 한 호출에 함께 쓸 수 있다.
- **부분 실패**: 바인딩된 Run 은 `--ack` 전까지 같은 Delivery 를 되돌린다 — **확인 전에 배치의 모든 메시지를
  처리한다.** `--ack` 는 직전 배치 전체에만 적용된다.
- **복구**: `orca orchestration inbox --full` 로 수신자별 전체를 본다(옵션은 `--limit`·`--terminal`·`--full` 뿐이다).
  읽음 표시를 남기지 않는 조회는 **같은 명령의 옵션이 아니라 `orchestration check` 쪽**이다 —
  `orca orchestration check --peek` 는 확인 없이, `orca orchestration check --all` 은 그 handle 의 전체를 준다
  (`--unread`·`--peek`·`--all` 은 서로 배타다). 주어를 섞으면 `invalid_argument` 다.
- **하지 말 우회**: `orca terminal wait --for exit` 을 완료로 쓰지 않는다 — provider 가 죽은 것과 일을 끝낸 것은 다르다.
  `--format` 은 로컬 텍스트 렌더일 뿐 **다른 터미널에 아무것도 쓰지 않는다** — 그걸 전달로 착각하지 않는다.
