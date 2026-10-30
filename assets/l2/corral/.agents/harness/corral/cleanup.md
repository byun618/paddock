<!-- paddock:fixed -->
## 『회수·정리』

### 명령
```bash
corral orchestration worker-retain  --dispatch <ctx_id> [--reason user_requested|user_takeover] --run <run_id> --json
corral orchestration worker-release --dispatch <ctx_id> --run <run_id> --json
corral orchestration worker-stop    --dispatch <ctx_id> --run <run_id> --json   # 열린 시도 취소 (--reason 없음)
corral orchestration worker-abandon --dispatch <ctx_id> --run <run_id> --json   # 손대지 않고 정산
corral terminal close --terminal <handle> --json                                # 빌린 pane (H5)
```

### 보장 수준
**증명(닫기 판정에 한정) — 프로세스가 실제로 죽었는지는 관측이다(H5).**
`released` 는 **이 시도가 pane 을 소유하고, 닫기 직전 관측한 pane 이 같은 세대일 때만** 나온다.
그 밖은 전부 `retained` + 이유(`borrowed`·`user_requested`·`user_takeover`·`pane_gone`·`identity_unproven`·
`observation_failed`)이고 프로세스에 손대지 않는다. 소유 판정과 닫기가 같은 lane 안에서 일어나므로
**판정한 pane 이 닫히는 pane 이다.** `worker-retain` 은 **보존 의사 기록일 뿐** 프로세스에 손대지 않고 새 Task
배정도 아니다. **그리고 보존은 다음 회수 한 번만 존중되고 지워진다** — 계약 원문: "The next worker-release
honours the retain once, reports retained with this reason, and clears it; a further worker-release then judges
the pane on its own merits." 즉 **`worker-release` 를 두 번 부르면 두 번째는 pane 을 닫는다.** `worker-abandon` 은 pane 을 보지도 닫지도 않는다.

### 상황 → 행동
- **차단 화면**: 해당 없음 — 정리 명령은 화면을 대답하지 않는다.
- **타임아웃·빈 결과**: `worker-release` 를 열린 시도에 부르면 `dispatch_active` 이고 효과가 없다 — 취소는
  `worker-stop` 이다. 이미 회수된 시도에 다시 부르면 기록에서 답하고 아무것도 쓰지 않는다.
- **부분 실패**: **H5 — 사람이 만든 pane 은 `borrowed` 라 corral 이 닫지 않는다.** 원자료를 회수한 뒤
  `terminal show`·`worker-show` 로 handle·worktree·agent 정체, 활성 Dispatch 없음, 사용자 takeover 없음,
  이번 작업 전용임을 확인한 **경우에만** `terminal close` 로 정리한다. 불확실하면 보존하고 차단 사유를 보고한다.
  재사용된 옛 Dispatch 의 회수로 현재 워커가 정리됐다고 가정하지 않는다 — 최종 Dispatch 와 실제 소유권을 본다.
  작업 정리(`task-finish.sh`)는 마지막에 세션 정리 훅 `.agents/harness/session-cleanup.sh` 를 부른다. 이 훅은 이 작업의
  worktree 아래에 남은 pane 을 **후보로 출력할 뿐 닫지 않는다** — pane 의 소유 증명(Dispatch 단위)은 훅이 가질 수 없고,
  위 확인을 거치는 것은 코디네이터 몫이기 때문이다.
- **복구**: **`release.state: unknown` 은 `corral orchestration worker-show --dispatch <ctx>` 가 복구다.** 두 번째 close 로 우회하지
  않는다 — corral 스스로 그 우회를 권하지 않는다. `worker-stop` 의 닫기가 확인되지 않아도 시도는 정산된다
  (`release.state: unknown` + `worker-show` 복구).
- **하지 말 우회**: 회수가 실제 프로세스를 닫았다고 **가정하지 않는다.** 능력 수명 ≠ 프로세스 수명 —
  정산·중단·포기·회수는 모두 `capabilityRevokedAt` 을 기록하고, pane 이 살아 있어도 그 시도의 보고는 거절된다.
  사용자 확인용 worktree 는 task-coordinate 가 정한 시점까지 유지한다 — **터미널 유지와 worktree 유지의 수명은 다르다.**
