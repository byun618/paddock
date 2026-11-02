<!-- paddock:fixed -->
## 『회수·정리』

### 명령
```bash
orca orchestration worker-retain  --dispatch <dispatch_id> --json
orca orchestration worker-release --dispatch <dispatch_id> --json
orca orchestration worker-stop    --dispatch <dispatch_id> --json
orca orchestration worker-abandon --dispatch <dispatch_id> --json
orca orchestration worker-list [--run <run_id>] [--terminal-state <상태>] --json
orca terminal close ([--terminal <handle>] [--tab] | --worktree <selector> --all) --json
```

### 보장 수준
**증명(계약) — 단 "닫아도 되는가" 에 대해서만이다.** 이 칸은 보장 요약의 세대 불변(공백)과 다른 것을 말한다:
계약은 **잘못된 대상을 닫지 않겠다**고 약속하고, **내가 맡긴 pane 이 그대로인지 알려주겠다**고는 약속하지 않는다.
`worker-release` 는 정산된(succeeded/failed) 워커의 **정확히 그 코디네이터 소유 에이전트
터미널만** 닫고, **setup 터미널·설정된 탭·재사용되거나 이미 있던 터미널·사용자가 가져간 터미널·증명되지 않은
신원은 절대 닫지 않는다.** 멱등이고 반복하면 `already_released` 다. **`release_unknown` 만 exit 1** 이고
`retained`·`release_pending`·`already_released` 는 exit 0 이다 — **exit 0 을 "닫혔다" 로 읽으면 틀린다.**
닫기 전에 출력 아카이브가 보존되므로 `worker-read` 가 그 뒤에도 답한다.
`worker-release` 는 `--run` 을 받지 않고, `terminal create` 로 따로 띄운 터미널은 `retained`/`external_terminal` 로 남아 `terminal close` 가 따로 필요하다(1.4.198 관측).

### 상황 → 행동
- **차단 화면**: 해당 없음 — 보존·회수는 구조화된 조회·정리이고 pane 에 입력을 넣지 않는다.
- **타임아웃·빈 결과**: `worker-list` 의 terminal state(`active`·`reclaimable`·`retained`·`release_pending`·
  `release_unknown`·`released`)는 **프로세스 회계이고 Task 상태와 별개다** — 완료된 Task 가 살아 있는 터미널을
  소유할 수 있다.
- **부분 실패**: **H5 — 빌린 pane 은 남는다.** `dispatch` 로 만든 문맥 전용 Dispatch 는 소유한 터미널 자원이
  없어 프로세스 조치 없이 `retained` 로 보고된다. 사람이 만든 pane 은 `terminal close` 로 따로 닫는다.
- **복구**: `worker-abandon` 은 **살아 있을 수 있는 자원을 모두 보존하고 프로세스·파일시스템에 아무 조치도 하지
  않는다** — 손댈 수 없는 워커에 쓴다. `worker-stop` 은 그 Dispatch 만 fence 하고 worktree·setup 터미널·설정된
  탭·무관한 프로세스를 **절대 지우지 않는다.**
- **하지 말 우회**: `orca terminal close --worktree <selector> --all` 은 그 작업 공간의 **모든** 터미널 프로세스를
  멈추고 탭·레이아웃·재개 기록까지 지운다 — 워커 하나 정리하는 데 쓰지 않는다. 나중에 재개할 것이면
  계약이 작업 공간 Sleep 을 쓰라고 적는다. **`--terminal` 값이 비면 호출한 터미널을 닫는다** — 코디 자신이 닫힌 적이 있다(1.4.198 관측). handle 은 리터럴로 쓰고, 비어 있거나 자기 handle(`ORCA_TERMINAL_HANDLE`)이면 닫지 않는다.
