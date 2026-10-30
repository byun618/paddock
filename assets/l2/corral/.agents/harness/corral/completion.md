<!-- paddock:fixed -->
## 『완료 감지』

### 명령
```bash
corral orchestration check --block --types worker_done,escalation,question \
  --timeout-ms 600000 --run <run_id> --json
corral orchestration check --ack <delivery_id> --block --types … --run <run_id> --json
corral orchestration worker-show --dispatch <ctx_id> --json    # 유실 의심 시 현재 상태 조회
corral orchestration dispatch-show --task <task_id> --json     # 시도 상태·reconcile 기록

# 워커 쪽(preamble 이 주는 형태) — 이 명령이 없으면 완료 감지 자체가 성립하지 않는다
corral orchestration send --type worker_done --subject "<상태>" --body "<3문장>" \
  --task-id <task_id> --dispatch-id <ctx_id> --outcome succeeded|failed --json
corral orchestration send --type heartbeat --subject alive \
  --task-id <task_id> --dispatch-id <ctx_id> --phase "<단계>" --json
corral orchestration send --type escalation --subject "Blocked: <이유>" --body "<상세>" \
  --task-id <task_id> --dispatch-id <ctx_id> --json
corral orchestration inbox --run <run_id> --json               # 배치를 놓쳤을 때 Run 전체 조회
corral orchestration request-show --id <request_id> --json     # 응답 유실 시 영수증 조회
```

### 보장 수준
**증명(보고가 왔을 때). 보고가 없는 상태는 "완료가 아니다" 가 아니라 "모른다" 다** — 그 칸은 공백으로 적는다.
완료는 그 Task·그 Dispatch 의 `worker_done` 이다. `succeeded`/`failed` 모두 종료 보고이고
(`failed` 를 성공으로 처리하지 않는다), 메시지 저장과 시도 정산이 **한 번의 원자적 쓰기**라 둘이 어긋날 수 없다.
Run 은 미확인 Delivery 를 **하나만** 갖고, `--ack` 전까지 같은 배치를 `deliveryReplayed: true` 로 계속 돌려준다
(배치 최대 50건, 그 사이 도착한 메시지는 섞이지 않는다). 파일 존재·TUI idle·프로세스 종료는 완료가 아니다.

### 상황 → 행동
- **차단 화면**: **provider 차단 화면은 `question` 이 아니다** — `question` 은 워커의 『질의응답』만 만든다.
  차단은 기동이 `agent_blocked` 로 거절하거나 대기가 즉시 `satisfied: false` 로 돌아오는 것으로 나타난다.
- **타임아웃·빈 결과**: `--block` 의 마감은 `count: 0`·`timedOut: true` 로 오는 **정상 답**이다.
  **타임아웃·`count: 0` 은 새 워커를 만드는 근거가 아니다.** 응답 유실이 의심되면
  `request-show`·`worker-show`·`dispatch-show` 로 기존 요청·시도를 확인한다.
- **부분 실패**: 배치의 **모든 메시지를 처리한 뒤** 각 종료 워커의 재사용/보존/회수를 결정하고 나서 `--ack` 로
  이어간다. `--ack` 는 대기 시작 **전에 한 번만** 적용된다. 같은 Run 의 check 를 중복 실행하지 않는다.
  시도가 `unknown` 으로 정산됐다면 이유는 `pane_gone|pty_replaced|epoch_changed` 이고 Task 는 다시 기동
  가능한 상태로 남는다 — `unknown` 은 실패가 아니다.
- **복구**: `--peek` 로 다음 배치를 만들지 않고 들여다볼 수 있다. **중간에 취소된(Ctrl-C·타임아웃으로 죽인)
  `corral orchestration check --block` 은 `--ack` 를 이미 적용했을 수 있다** — 응답은 `request_cancelled`("accepted effects may
  already have occurred")로 오고, 같은 id 로 다시 `--ack` 하면 `delivery_stale` + `deliveryState: acknowledged`
  다. 그때의 복구는 **`--ack` 를 떼고 `check` 를 다시 부르는 것**이다.
  취소를 배달 실패로 읽지 않는다. Run 메시지 상한은 10000건·본문 65536바이트이고
  한계에 닿으면 `message_capacity` 다 — corral 은 자리를 만들려고 메시지를 지우지 않는다.
- **ack 만 하고 싶을 때**: `--ack` 는 **대기 시작 전에 한 번** 적용되므로, 확인만 하려면 **아주 짧은 대기를
  연다** — `corral orchestration check --ack <delivery_id> --block --timeout-ms 3000`. 답은 `acknowledged: <그 delivery>` ·
  `count: 0` · `timedOut: true` 이고 **이것이 정상이다**(빈 배치는 실패가 아니다). ack 없는 조회는 `inbox` 다.
- **하지 말 우회**: 화면에 "다 했다" 가 보인다는 이유로 완료로 적지 않는다. `DONE.md` 같은 파일은 감사 기록이지
  완료 신호가 아니다. 두 번째 `worker_done` 은 `illegal_transition` 이므로 워커에게 다시 보내게 하지 않는다.
