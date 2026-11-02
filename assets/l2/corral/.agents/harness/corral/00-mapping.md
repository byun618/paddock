<!-- paddock:fixed -->
# corral 매핑 — 능력 → 명령

능력 이름과 보장 어휘(증명/관측/공백)의 정본은 [capabilities.md](../capabilities.md). 이 폴더는 그 능력을
corral CLI 로 어떻게 수행하고, **무엇까지 증명되는지**를 적는다. 명령별 시그니처·주의사항의 정본은
`corral agent-context --json` 이다 — 이 폴더에 없는 세부는 그것을 본다.
이 파일은 모든 능력에 걸치는 것(전제·보장 요약·응답 필드 경로)과 능력 → 파일 목차다.

## 이 도구를 쓰기 위한 전제

- **H7 — `corral` 은 두 갈래로 풀린다. foundation 명령은 셸 node 와 무관하다.**
  설치본 앱이 있으면 PATH 의 `corral` 은 앱이 두는 shim(`~/.local/bin/corral`)이고 앱 내장 Node 로 CLI 를 돌린다 —
  `--version`·`open`·`status` 등 foundation 명령은 셸 node 버전·유무와 무관하다. 설치본 CLI 의 terminal·orchestration 은
  **앱 동봉 backend 로 돈다** — 앱이 backend 를 스스로 띄우고, 런타임은 명시 바인딩이 없으면 GUI 가 지금 붙은 그 서버를
  쓴다(앱이 실행 중이어야 한다). PATH 등록은 앱 메뉴 「Install 'corral' Command in PATH…」. 설치본이 없는 기계에서는
  npm-link 된 CLI 에 풀리고, 그 node bin 이 PATH 에서 `~/.local/bin` 보다 앞이면 설치본 shim 을 가린다.
  `command -v corral` 이 비거나 엉뚱한 쪽이면 도구 부재가 아니라 PATH 문제로 먼저 의심한다. 필요하면
  `node <경로>/corral.mjs` 절대경로 호출형으로 부른다 — **이 대체 호출형도 표기 허용 목록에 있다**(A3). 그렇게 적은 명령줄도
  접두사 표기와 똑같이 플래그·선언 대조를 받는다. 전역옵션(`--socket`·`--instance` …)을 명령 앞에 두는
  표기도 허용 목록에 있고 같은 검사를 받는다.
- 모든 명령은 로컬 Unix 소켓 클라이언트다. `--socket` 을 생략하면 기본 프로필 소켓
  (`~/Library/Application Support/corral/runtime/rpc.sock`)에 붙는다. 다른 프로필·인스턴스를 쓸 때만
  `--socket`·`--instance` 를 명시한다.
  **예외: `agent-context` 는 순수 로컬 레지스트리 읽기라 `--socket` 을 거절한다**(`invalid_argument`).
- **계약을 알 수 있는 곳은 `corral agent-context` 다**(기계용 시그니처·주의사항). 이 매핑에 없는 세부를 찾을 때 그것을 본다.
- **`--run` 은 orchestration 명령 전부가 받는 플래그가 아니다** — 받지 않는 9개는 『제어 문맥 격리』에
  목록으로 적었다. 없는 명령에 붙이면 `invalid_argument` 로 튕긴다.
- 공통 플래그는 `--json`·`--timeout-ms`·`--request-id`. **`--timeout-ms` 상한은 `orchestration check` ·
  `orchestration ask` 만 600000 이고 나머지는 120000 이다** (초과는 `--timeout-ms must be 1..120000` 거절).
- **⚠ 호출자 자신의 타임아웃이 `--timeout-ms` 보다 커야 한다.** 여기 적힌 상한은 corral 쪽 예산이고,
  명령을 실행하는 셸·도구에도 따로 예산이 있다(에이전트의 셸 도구는 보통 120초). 더 짧은 쪽이 먼저 죽으면
  **corral 은 계속 돌고 있는데 호출자만 끊긴다** — 그러면 `request_cancelled`("수락된 효과는 이미 일어났을 수
  있다") 뒤에 `--ack` 를 다시 쳐서 `delivery_stale` 로 가는, 이 매핑의 『완료 감지』 복구가 경고하는 바로 그
  사고다. **두 예산을 함께 정해라**: corral `--timeout-ms N` 이면 호출자 예산은 N + 여유. 호출자 예산을 늘릴 수
  없으면 corral 쪽을 그보다 작게 잡아라 — `corral orchestration check --block --timeout-ms 600000` 을 120초 셸에서 그대로 치지 않는다.
- **거절 응답은 복구 명령을 스스로 알려준다** — `error.resources.recovery` 필드를 먼저 읽는다.
  거절의 `stage`(`preflight`·`receipt`·단계 이름)가 "효과가 시작됐는지" 를 가른다.
- 재시도는 **같은 `--request-id` 를 다시 보내는 것**이다. 별도 retry 플래그는 없다. 같은 id + 다른 입력은
  `request_conflict`, 아직 기록되지 않은 영수증은 `outcome_unknown` 이고 **절대 자동 재실행되지 않는다**.
  영수증 보존은 24시간이다. `absent` 는 "아무 일도 없었다" 가 아니다.
- **H3 — 문서가 시그니처를 적지 않으면 추측한 플래그가 거절된다.** 확인된 세 형태:
  `worker-stop` 에 `--reason` 없음(있는 쪽은 `worker-retain`) · `dispatch-show` 는 `--id`(또는 `--task`),
  `--dispatch` 아님 · `corral terminal wait --timeout-ms` 상한 120000.
- **H1' — 큰 본문은 파일로 넣는다.** `corral terminal prompt --file <경로>` 또는 `corral orchestration worker-start --spec-file <경로>`.
  `task-create` 에는 `--spec-file` 이 **없다**(`--spec` 만).
  **⚠ `--file` 은 상한을 올려 주지 않는다.** `--text`·`--file`·`--stdin` 에 **같은 65536 UTF-8 바이트** 상한이
  걸린다 (초과는 `--file must be NUL-free UTF-8, at most 65536 bytes`). `--file` 의 효용은 argv·따옴표·이스케이프를
  피하는 것뿐이다. **상한을 넘으면 상세를 파일로 저장하고 짧은 지시에 그 경로를 적어 워커가 읽게 한다.**
  `corral orchestration worker-start --spec-file` 의 **TASK 본문 상한은 49152 바이트**이고 이것은 preamble 을 **포함하지 않는**
  본문 단독 값이다 (preamble 몫 16384 바이트는 그 밖에 있다).

## 보장 요약 (네 가지 증명 대상)

| 증명 대상 | 수준 | 무엇이 그것을 돌려주는가 |
| --- | --- | --- |
| 본문이 정확히 한 번 전달됐다 | **증명(소유 증명 가능한 세션 기록이 있을 때)** — 기록이 없거나 둘 이상이면 `unknown`(공백)이다 | `corral terminal prompt --wait accepted` 의 `outcome: completed` + `record.matchCount: 1` + `wait.satisfied`. 제출 창 안에서 정확히 1건 일치일 때만 `stage: confirmed`·`phase: accepted`. 2건 이상은 "확인된 1회" 가 아니라 **한 입력 규칙이 깨진 것**으로 보고된다 |
| 이 pane 이 맡긴 그 pane 이다 (세대 불변) | **증명** | handle 에 프로필·backend 부팅·PTY 세대가 묶여 있고, reconcile 이 `pane_gone`·`pty_replaced`·`epoch_changed` 로 시도를 `unknown` 으로 정산한다. 정리는 닫기 직전 같은 세대를 다시 관측하고 같은 lane 안에서 닫는다 |
| 보고가 오래된 시도에서 온 게 아니다 | **증명** | 워커 보고는 `--task-id`·`--dispatch-id` + pane 신원으로 검사된다. 다른 pane = `sender_mismatch`, 사라진 pane·교체된 시도 = `stale_dispatch`, 두 번째 완료 보고 = `illegal_transition`, 정산·중단·회수된 시도 = `capability_revoked`. **거절은 아무것도 저장하지 않는다** |
| 사람 개입 흔적 | **관측** | `terminal read` 화면뿐(H2). 구조화된 조회는 GUI 직접 입력을 보지 못한다. `corral orchestration worker-retain --reason user_takeover` 는 **사람이 선언하는 기록**이지 감지가 아니다 |

위 수준은 corral 의 공개 계약(`corral agent-context` 의 시그니처·주의사항)이 무엇을 값으로 돌려준다고 적는지를 읽은 것이다.
계약이 값으로 약속하지 않는 것은 관측·공백으로 적었다.

## 응답에서 어디를 읽나 (필드 경로)

식별자와 판정값이 응답의 **어디**에 있는지다. 이걸 모르면 명령은 알아도 다음 명령에 넣을 값을 못 꺼낸다.

| 무엇 | 어느 응답의 어디 |
| --- | --- |
| Run id | `run-current`·`run-create`·`run-use` → `result.run.id` (`run_<12 hex>`) |
| 일감(Task) id | `task-create` → `result.task.id` (`task_<12 hex>`) |
| 시도(Dispatch) id | `worker-start` → `result.dispatchId` (`ctx_<12 hex>`) · `worker-show`·`dispatch-show` → `result.dispatch.id` |
| pane handle | `worker-start` → `result.terminal.handle` (= `result.stages.terminal.handle`) · `terminal create` → `result.terminal.handle` |
| 기동 단계별 상태 | `worker-start` → `result.state`·`result.stage`·`result.launch`·`result.stages.{terminal,dispatch,input}.status`·`result.residualResources`·`result.ignoredOptions` |
| **배달 확인** | `terminal prompt` → `result.stage`(`confirmed`)·`result.wait.satisfied`·`result.record.matchCount`·`result.record.unavailableReason`, 그리고 `_meta.outcome`(`completed`). `worker-start` 는 같은 값을 `result.input.*` 아래에 담는다 |
| 요청 영수증 | `result.requestId`(`r1.<13자리 ms>.<UUID>`)·`result.replayed` |
| 실제 모델·advisor | `worker-start` → `result.input.agent.{requestedModel,requestedEffort,requestedAdvisor,resolvedModel,argv,sessionId,sessionRecord}` · `terminal show` → `result.process.foreground[].argv` · 배너는 `result.input.delivery.screen` 또는 `corral terminal read --screen` |
| 준비 근거 | `terminal wait` / `worker-start` → `…agent.evidence.{agentStatus,launchPending,interactiveReady,stateChangeSeq,samples,detectManifest}` |
| 배치·확인 | `check` → `result.deliveryId`(`delivery_<12 hex>`)·`result.count`·`result.timedOut`·`result.deliveryReplayed`·`result.acknowledged`·`result.peeked` |
| 메시지·질문 id | `check` → `result.messages[].{id,type,subject,body,taskId,dispatchId}` (`msg_<12 hex>`). 질문에 답할 때 그 `id` 를 `corral orchestration reply --id` 에 넣는다 |
| 회수 결과 | `worker-release` → `result.state`(`released`\|`retained`)·`result.reason`(예: `owned_generation_matches`·`borrowed`·`pane_gone`·`identity_unproven`)·`result.processAction`·`result.close.stage` |
| pane 생존 | `worker-show` → `result.observation.{live,observed,reason}`(`pane_live`·`pane_gone`) · `result.messageCounts` |
| 세션 목록 | `terminal list` → `result.terminals[].{paneId,tabId,path,title}` |
| **화면 텍스트 (두 명령의 모양이 다르다)** | `terminal read` → **`result.text`** (형제 필드 `result.{source,truncated,generation,cursor}`) · `worker-read` → **`result.output.text`** (`result` 키는 dispatchId · terminal · source · output). 같은 화면인데 한 단 깊이가 다르다 — `result.screen.text` 는 **어느 쪽에도 없다** |
| 읽기 잘림·이어 읽기 | 두 명령 모두 `…truncated`(bool)·`…cursor`·`…generation`. `--limit` 은 줄이 아니라 **바이트고 상한이 명령마다 다르다** — `terminal read` 1..262144 · **`orchestration worker-read` 1..10000**(계약의 *pass-through* 문구 때문에 262144 로 읽히지만 **실제 상한은 10000**, 넘기면 `invalid_argument: --limit must be 1..10000` · `_meta.outcome: not_started`). `truncated: true` 면 잘린 것이다 |

## 능력 → 파일

능력 절은 **그 능력을 쓸 때 그 파일만** 연다 — 이 폴더를 통째로 읽지 않는다.

| 능력 | 파일 |
| --- | --- |
| 『전제 점검』 | [preflight.md](preflight.md) |
| 『세션 기동』 | [session-start.md](session-start.md) |
| 『준비 대기』 | [ready-wait.md](ready-wait.md) |
| 『본문 주입』 | [inject.md](inject.md) |
| 『감독 워커 기동』 | [supervised-worker.md](supervised-worker.md) |
| 『완료 감지』 | [completion.md](completion.md) |
| 『질의응답』 | [qa.md](qa.md) |
| 『화면 관측』 | [screen.md](screen.md) |
| 『회수·정리』 | [cleanup.md](cleanup.md) |
| 『세션 기록 오라클』 | [session-record.md](session-record.md) |
| 『제어 문맥 격리』 | [isolation.md](isolation.md) |
| 『게이트 알림』 | [notify.md](notify.md) |
