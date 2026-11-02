<!-- paddock:fixed -->
## 『세션 기동』

### 명령
```bash
orca terminal create [--worktree <selector>] [--title <name>] [--command "<provider 실행 명령>"] [--focus] --json
orca orchestration worker-start --task <task_id> --agent <agent> [--model <id>] [--effort <level>] \
  [--worktree <current|selector|new-child|new-top-level>] [--run <run_id>] --json
orca terminal show [--terminal <handle>] --json     #
```

### 보장 수준
**관측.** `terminal create` 에는 `--agent` 가 **없다** — provider 는 `--command` 로 띄운다(계약이 명시적으로
"기존 체크아웃에 새 에이전트를 띄울 때는 `orca terminal create --worktree active --command "codex"` 를 쓰라" 고 적는다).
모델·effort 는 `orca orchestration worker-start --model/--effort` 로만 주고 **`--effort` 는 `--model` 을 요구하며 둘 다 `--terminal`
과 함께 쓸 수 없다.** **advisor 를 지정하는 플래그는 어디에도 없다 — advisor 지정은 공백이다.**

### 상황 → 행동
- **차단 화면**: 계약에 차단 화면 개념이 없다 — 기동이 차단을 이유로 거절된다는 문장이 없다. 차단은
  『화면 관측』으로 사람이 본다.
- **타임아웃·빈 결과**: `worker-start` 는 **ready 일 때만 exit 0** 이고, 실패·`outcome_unknown` 은 exit 1 로
  `stage`/`failedStage`·`setup`·`effects`·`residualResources`·복구 명령을 함께 낸다.
- **부분 실패**: 새 worktree 는 에이전트 우선 생성이고 `--setup` 기본이 run 이다. 기존·현재 worktree 에는
  생성 플래그(`--name`·`--repo`·`--base-branch`·`--display-name`·`--comment`·`--setup`)가 **거절된다.**
- **복구**: `--retry-of <dispatch_id>` 는 `--task` 와 함께 쓴다. 단 **배치를 물려받지 않으므로**
  의도한 `--on`/worktree/`--agent`/`--terminal` 선택을 다시 적어야 한다.
  `orca terminal create` 가 `runtime_error: Timed out waiting for terminal handle after creation` 을 내도 터미널은 늦게 생길 수 있다. **시간 초과 뒤의 빈 목록은 부재의 근거가 아니다** — 다시 만들지 않고 `orca terminal list` 를 반복해 worktree 로 찾고, 화면으로 새 세션인지 확인한다(1.4.198 관측). `--title` 이 적용되지 않은 적이 있어 제목으로 찾지 않는다. 끝내 안 나타나면 사람에게 보고하고, 다시 만들 수밖에 없으면 다른 session id 로 띄운다.
- **하지 말 우회**: 모델 별칭을 그대로 기록하지 않는다 — 계약이 "불투명한 provider 모델 id" 라고만 적으므로
  해소 결과는 관측으로 확인한다. Claude·Codex·Cursor 등 지원 도구 밖은 자기 설정의 모델로 뜬다.
