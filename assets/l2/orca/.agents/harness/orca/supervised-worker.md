<!-- paddock:fixed -->
## 『감독 워커 기동』

### 명령
```bash
orca orchestration task-create --spec "<일감 명세>" [--task-title <text>] [--run <run_id>] --json
orca orchestration worker-start --task <task_id> (--agent <agent> | --terminal <handle>) \
  [--worktree <current|selector|new-child|new-top-level>] [--model <id>] [--effort <level>] \
  [--retry-of <dispatch_id>] [--timeout-ms <n>] [--run <run_id>] --json
orca orchestration dispatch-show --task <task_id> [--preamble] --json
```

### 보장 수준
**관측.** 터미널이 없는 워커도 있다 — 출력은 `orca orchestration worker-read` 로 읽고, 터미널 명령이 그 handle 을 받는다고 가정하지 않는다. 계약이 약속하는 것은 "**ready 일 때만 exit 0**" 까지다. 어떤 값으로 본문 도착을 판정했는지는 **레지스트리에 적혀 있지 않다.** 그래서 이 도구에서 워커 기동은
"거절되지 않았다" 까지가 증명이고, "본문이 정확히 한 번 들어갔다" 는 증명되지 않는다.

### 상황 → 행동
- **차단 화면**: 계약에 차단을 이유로 한 거절이 없다 — 기동 직후 『화면 관측』으로 확인한다.
- **타임아웃·빈 결과**: `outcome_unknown` 은 exit 1 이고 `residualResources`·복구 명령을 낸다. `--timeout-ms`
  상한은 레지스트리에 수치로 적혀 있지 않다 — **공백**, 필요하면 실측해 적는다.
- **부분 실패**: 실패한 단계가 앞 단계를 되돌리지 않고 `residualResources` 에 남는다.
  `--on` 은 **워커 서버만** 고르고 Run 과 이 명령은 현재 호스트에 남는다. 원격에서 `--worktree current`·`--worktree new-child` 는 무효다.
- **복구**: `--retry-of <dispatch_id>` 로 교체 시도를 연결한다 — 배치는 물려받지 않으니 다시 적는다.
  **응답을 잃었을 때**는 `orca orchestration request-show --request <id>` 로 요청이 실행됐는지 묻고(『완료 감지』 참고), 이어서 `orca orchestration dispatch-show --task <task_id>`·`orca orchestration worker-show --dispatch <dispatch_id>` 로 시도와 터미널을 본다. 다시 낼 때는 **보고된 같은 `--retry-request` id** 로 낸다. **가려지지 않으면 새 요청으로 기동하지 않는다** — 같은 Task 의 두 번째 시도가 첫 시도를 밀어낼 수 있다.
- **하지 말 우회**: `dispatch` 로 만든 문맥 전용 Dispatch 를 감독 워커로 세지 않는다 — 계약이 그것을
  `unsupervised`·terminal state `retained` 로 보고한다. 레거시 `orchestration coordinator-start`/`orchestration coordinator-stop` 은
  아무 효과가 없는 명령이다(계약 스스로 그렇게 적는다) — 쓰지 않는다.

### 재사용 인자 규칙 (절차 문서가 가리키는 그 규칙)

**재사용 때 `--terminal <handle>` 과 그 터미널의 `--worktree` 를 함께 준다.** 계약이 그대로 적는다:
"When reusing --terminal, pass --worktree for that terminal; current means the coordinator worktree."
`--worktree current` 는 코디네이터 worktree 를 뜻하므로, **워커 worktree 를 쓰려면 그 selector 를 명시해야 한다.**

**빼면 잘못된 작업 공간으로 붙는다.** 절차 문서는 "매핑의 재사용 인자 규칙을 따른다" 만 적고 실제 인자는 여기서 읽는다.
