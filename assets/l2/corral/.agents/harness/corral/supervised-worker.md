<!-- paddock:fixed -->
## 『감독 워커 기동』

### 명령
```bash
corral orchestration task-create --spec "<일감 명세>" [--title "<제목>"] --run <run_id> --json
corral orchestration worker-start --task <task_id> \
  --agent claude|codex|grok --model <id> --effort <등급> [--advisor fable] \
  --worktree path:<구현 worktree 절대경로> [--spec-file <경로>] --run <run_id> --timeout-ms 120000 --json
corral orchestration worker-start --task <task_id> --terminal <handle> --run <run_id> --json   # pane 재사용
```

corral 에는 repo setup/archive hook 이 아직 없다 — **기다릴 setup 단계가 없다는 뜻**이고,
worktree 준비 확인은 git worktree 생성 결과로 한다. `--worktree` 에 주는 경로는 git worktree 경로 그대로다.

**전용 worktree 가 필요 없는 과제도 있다.** 스모크·검증 순환처럼 저장소를 고치지 않는 짧은 일감은
**지금 서 있는 worktree 절대경로를 그대로 `--worktree path:` 에 준다** — 새로 만들지 않는다. 기동은 그것으로
성립한다.
**구현 작업은 다르다** — 브랜치가 갈려야 하므로 아래대로 전용 worktree 를 만든다.

**그 worktree 를 만드는 방법 — 두 길이 있고, 이 매핑이 쓰는 길은 git 이다.**
corral 광고에는 worktree 계열 명령이 **있다**: `worktree create` · `worktree rm` · `worktree set` ·
`worktree list` · `worktree current` · `worktree show` · `worktree ps` (『전제 점검』 응답의 능력 목록에서 확인된다).
다만 이 매핑은 생성 계열(`worktree create`·`worktree rm`)을 쓰지 않는다 — **이 절의 worktree 생성 보장 수준은 공백이다.**
그래서 구현 worktree 는 절차 문서(`.agents/skills/task-coordinate/references/implementation.md` §2)의
git 명령으로 만든다. `worktree create` 로 만드는 길은 원자료가 없으니 여기서 짐작하지 않는다.

**git 으로 만든 worktree 의 상위 표시.** git 으로 만든 worktree 는 레지스트리에 부모가 없어 사이드바에서
다른 worktree 아래로 중첩되지 않는다. 중첩해 보이게 하고 싶을 때만, worktree 를 만든 직후 코디네이터가 한 번 친다:

```bash
corral worktree set --worktree path:<구현 worktree 절대경로> --parent-worktree path:<작업 worktree 절대경로> --json
```

- **bundle 을 쓸 때**: 묶음 자식의 작업 worktree 를 feature worktree 아래로 보이게 하려면 같은 명령을
  `--worktree path:<자식 작업 worktree>` `--parent-worktree path:<feature worktree>` 로 친다. 독립 작업은 상위를 지정하지 않는다(루트).
- **리뷰 worktree 를 만드는 경우도 같은 규칙이다** — `--worktree path:<리뷰 worktree>` 로 바꿔 한 번 더 친다.
- **실패는 경고만 남기고 워커 기동을 막지 않는다.** 부모는 사이드바 표시용 메타일 뿐 제어 순환(Task·Dispatch·완료 감지)은 이 값을
  읽지 않는다. 거절 원문(예: 순환 거절 `Lineage cycle is not allowed`)을 원자료에 남기고 진행한다.
- 보장 수준: 표시용 메타라 증명 대상이 아니다 — 응답을 원자료에 남기고 진행한다.

**`--spec-file` 을 생략하면 그 Task 의 `--spec` 본문이 배달된다** — 일감 명세를 `corral orchestration task-create --spec` 에만
담아도 pane 에 들어간다. 두 곳에 나눠 담지 않는다. (『세션 기록 오라클』로 배달 본문을 읽어 확인할 수 있다.)

**preamble 이 워커에게 무엇을 주는가** (코디네이터가 일감 명세에 안 적어도 되는 것): 워커 쪽 `ask` 와
`corral orchestration send --type worker_done|heartbeat|escalation` 의 명령줄이 **`--task-id`·`--dispatch-id` 가 치환된 채로**,
소켓 경로까지 붙어 preamble 에 들어간다. 그래서 **코디네이터는 일감 명세에 보고 명령을 적지 않는다** —
적으면 중복이고, id 를 손으로 옮기다 틀린다.

### 보장 수준
**증명(단 준비 관문의 자격이 그대로 따라온다 — label 되지 않은 차단 화면은 여기서도 공백이다).**
`worker-start` 는 pane 생성 → Dispatch 기록 → 준비 대기 → preamble+본문 주입을 **한 호출로 묶고
제출을 판정한다**: `state: ready` 는 주입이 `outcome: completed` + 만족한 대기였을 때, 또는 그 본문이 provider
기록에 정확히 1건 있을 때만이다. 그 밖은 전부 `state: incomplete`·`stage: dispatch_input_unconfirmed` 이고
`promptRequestId` 가 null 로 남아 **재개 가능**하다. **pane 에 도달하지 못한 Dispatch 가 ready 로 보고되는
경로는 없다.** preamble 은 Dispatch 당 정확히 한 번 도달한다.

### 상황 → 행동
- **차단 화면**: 차단이면 `worker-start` 가 `agent_blocked` 로 거절한다. **`--agent codex` 는 준비→주입이 한
  호출 안에서 원자적이라 중간 화면을 볼 자리가 없다** —
  기동 전에 사용자 셸에서 codex 를 최신으로 올리거나, `corral terminal create --agent codex` → `terminal read` 확인 →
  같은 pane 에 `--terminal <handle>` 로 붙이는 2단을 쓴다. **trust 화면은 사람 몫이다.**
- **셸 rc 의 대화형 질문**: pane 셸이 rc 에서 질문(업데이트 확인 등)을 띄우면 주입한 기동 줄 첫 글자가 그 답으로 먹혀 provider 이름이 깨지고
  `agent_not_ready`·`incomplete` 로 끝난다. 같은 Task 를 `worker-stop` 으로 멈추고 새로 기동한다 — 반복되면 사용자에게 셸 쪽 질문을 먼저 끝내 달라고 한다.
- **타임아웃·빈 결과**: 대기 예산은 `--timeout-ms` 로 주고 상한은 120000 이다. codex 는 같은 과제에서 Claude 보다
  느리고 타임아웃이 잦으니 예산을 넉넉히 잡는다. 타임아웃은 "안 갔다" 가 아니다 — `corral orchestration dispatch-show --task <t>` 로
  시도 상태를 먼저 본다.
- **부분 실패**: 단계별로 보고되고 **실패한 단계가 앞 단계를 되돌리지 않는다** — 남은 것은
  `residualResources` 에 담긴다. `input_line` 항목은 **이전 실행이 pane 입력줄에 타이핑한 한 줄**이고 corral 은
  그것을 지울 수 없다 — 사람이 치운다(기록 기준, 화면 기준이 아니다). `dispatch_input_unprovable` 은 재개로
  수렴하지 않는다 — 사람이 pane 을 읽고 `corral orchestration worker-stop --dispatch <ctx>` 로 끝낸다.
- **복구**: **`--retry-of` 류 플래그는 없다.** 복구는 2단이다 — `terminal read` 로 화면을 보고 차단이면 정리한 뒤
  **같은 Task 에** `corral orchestration worker-start --task <t> --terminal <handle>` 을 다시 부른다. 주입이 확정되지 않은 시도는 같은
  Dispatch 로 재개되고(`launch: resumed`), **이미 주입된 시도가 열려 있으면 `dispatch_active` 로 거절된다.**
  `launch: reused` 는 열린 시도가 없어 시작 가능한 Task 에 기존 pane 을 배정한 **새 시도**다. 재개는 Dispatch
  생성 시 기록된 본문 digest 를 배달하며, 명령줄에 남은 `--spec-file` 은 `ignoredOptions` 에 들어간다.
- **하지 말 우회**: **기본 경로는 이 한 호출이다** — 따로 pane 을 만들고 `--terminal` 로 붙이는 2단 경로를
  평소에 쓰지 않는다(2단은 아래 차단 화면 복구용이다). `--terminal` 과 `--agent … --worktree` 를 **동시에 쓰지 않는다**(재사용 pane 은 기동 때의
  agent 를 그대로 쓰므로 `--model`·`--effort`·`--advisor`·`--worktree` 가 거절된다). `--agent` 에는 `--worktree`
  가 필수다. **리뷰어 3명은 Task 를 각각 따로 발급한다** — 같은 Task 로 띄우면 미확정 시도만 조용히 재개되거나
  `dispatch_active` 로 거절된다. 실행 중 Dispatch 위에 같은 terminal 의 새 Dispatch 를 겹쳐 기동하지 않는다.
  pane 재사용은 **소유권을 옮긴다** — 이전 시도는 `borrowed` 가 되고 `ownershipTransferredTo` 에 새 시도가 적힌다.

### 재사용 인자 규칙 (절차 문서가 가리키는 그 규칙)

| 경로 | 반드시 준다 | 절대 붙이지 않는다 |
| --- | --- | --- |
| 새 기동 | `--agent` + `--worktree path:<절대경로>` + `--model` + `--effort` (+ 필요하면 `--advisor`) | — |
| pane 재사용 | `--terminal <handle>` 만 | `--agent`·`--model`·`--effort`·`--advisor`·**`--worktree`** |

재사용 pane 은 기동 때의 도구를 그대로 쓴다. 위 인자를 붙이면 거절되거나 `ignoredOptions` 에 담겨 조용히
무시된다 — **무시된 것을 반영됐다고 읽지 않는다.** `--worktree` 는 corral 에서 **새 기동 전용**이다
(같은 이름의 플래그를 재사용 때 **요구하는** 도구가 있다 — 매핑을 갈아 쓸 때 여기서 틀린다).

**`--model`·`--effort` 에 넣을 값은 어디서 오나 — 이 매핑에서는 공백이다.**
열거하는 플래그는 열거한다(`--agent claude|codex|grok`, `corral terminal wait --for ready|output|exit|agent-ready|agent-idle`,
`corral orchestration worker-retain --reason user_requested|user_takeover`). 그런데 **`--model`·`--effort`·`--advisor` 의 유효값 집합은
두 오라클(`--help`·`agent-context`) 어디에도 없다** — `--help` 는 `VALUE`/`<level>`/`<id>` 로만 쓰고
`agent-context` 는 "`--agent` 를 요구한다" 는 제약만 적는다. 값 집합의 원본은 corral 이 아니라 **에이전트 CLI 쪽**이고
이 매핑 밖이다. 역할별 기본값은 `.agents/defaults.md`(값)에 있고 규칙은 `.agents/defaults.rules.md` 다.
- **corral 은 값을 검증하지 않는다.** `--effort bogus-effort` 가 거절되지 않고 argv 로 그대로 넘어가
  pane 이 생긴다(`requestedEffort: "bogus-effort"`, `argv: ["claude","--effort","bogus-effort",…]`).
  즉 잘못된 값은 기동 관문이 아니라 **에이전트 쪽에서** 드러나고, 그때는 이미 pane 이 만들어져 있다 —
  치우는 것은 내 몫이다.
- 그래서 **값은 지시받은 것을 그대로 넘기고, 짐작해서 채우지 않는다.** 지시가 없으면 묻는다(『질의응답』).

### Run 명시 규칙 (절차 문서가 가리키는 그 규칙)

`--run` 을 **받는 명령에만** 붙인다. 받지 않는 명령에 붙이면 `invalid_argument` 로 거절된다 —
받는 15개·받지 않는 9개 목록은 『제어 문맥 격리』에 있다. 바인딩은 **프로필 단위**라
`run-create`·`run-use` 는 그 프로필의 기본 Run 을 바꾼다. 바꿨으면 바꾼 쪽이 `run-use` 로 되돌리고
`run-current` 로 확인한다.
