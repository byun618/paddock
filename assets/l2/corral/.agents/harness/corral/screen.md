<!-- paddock:fixed -->
## 『화면 관측』

### 명령
```bash
corral terminal read --terminal <handle> [--screen] [--cursor <n>] [--limit <바이트>] --json
corral orchestration worker-read --dispatch <ctx_id> [--screen] [--limit <바이트>] --json
```

### 보장 수준
**관측.** 화면 읽기는 본질적으로 관측이다(H2). `--screen` 은 렌더된 화면, 기본값은 누적 출력이다 —
줄을 다시 그리는 프로그램(셸·진행 표시·TUI)은 기본 읽기에서 조각으로 쌓여 온다. `worker-read` 는 그 Dispatch 가
묶인 pane 에 대한 `terminal read` 의 pass-through 이고 **corral 은 provider 훅을 설치하지 않고 transcript 를
읽지 않는다.** 읽기는 아무것도 저장하지 않는다.

**꺼내는 자리가 두 명령에서 다르다**: `terminal read` → `result.text`, `worker-read` → `result.output.text`.
`result.screen.text` 는 어느 쪽에도 없다 — 짐작해서 뒤지지 말고 「응답에서 어디를 읽나」 표를 본다.

### 상황 → 행동
- **차단 화면**: 이것이 차단 화면을 **볼 수 있는 유일한 능력**이다. detect manifest 가 label 하지 않은 모달은
  구조화된 조회로는 보이지 않으므로, codex pane 은 첫 주입 전에 여기서 한 번 본다.
- **타임아웃·빈 결과**: **`--limit` 은 줄 수가 아니라 바이트고, 상한이 명령마다 다르다.**
  `terminal read` 는 1..262144(화면도 262144), **`orchestration worker-read` 는 1..10000** 이다.
  계약은 `worker-read` 를 *a pass-through of terminal read* 라고만 적어 262144 로 읽히는데 **실제 상한은 10000 이다** —
  넘기면 `invalid_argument: --limit must be 1..10000` 이고 `_meta.outcome: not_started` 다(부작용 없음).
  목록(`corral terminal list --limit`)도 1..10000.
  **계약과 실제가 갈리면 실제를 믿는다**(『전제 점검』 부분 실패 규칙).
  빈 출력은 "아무 일도 없었다" 가 아니라 "이 창에서 볼 게 없었다" 다. 보존은 PTY 당 마지막 1048576 바이트다.
- **부분 실패**: `--cursor` 는 바이트 오프셋 + UTF-8 디코더 carry 다. 잘린 문자는 다음 읽기에서 이어진다.
- **복구**: 사람 개입이 의심되면 화면을 읽어 원자료로 남기고, 사람이 잡은 pane 이면
  `corral orchestration worker-retain --dispatch <ctx> --reason user_takeover` 로 **선언**한다(감지가 아니다).
- **하지 말 우회**: 화면에서 읽은 문장을 『완료 감지』·『본문 주입』의 증명 대용으로 쓰지 않는다.
  화면으로 "보냈다/끝났다" 를 판정하지 않는다.
