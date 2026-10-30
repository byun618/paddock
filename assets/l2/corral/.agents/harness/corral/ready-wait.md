<!-- paddock:fixed -->
## 『준비 대기』

### 명령
```bash
corral terminal wait --terminal <handle> --for agent-ready --timeout-ms 60000 --json
# --for 는 ready|output|exit|agent-ready|agent-idle
```

### 보장 수준
**증명(단 label 된 차단에 한정) — label 되지 않은 모달은 공백이고 『화면 관측』이 메운다.**
자격을 붙이는 이유는 이 절 아래 「상황 → 행동」의 반례다: 차단 판정의 유일한 근거가 detect manifest 의
label 이므로, **label 되지 않은 모달은 "준비" 와 같은 값으로 돌아온다**(예: codex 의 업데이트 메뉴).
그래서 이 칸은 무자격 증명이 아니다 — 판정표에 옮길 때도 자격을 함께 옮긴다.
label 된 차단에 대해서는 준비·차단·타임아웃이 서로 다른 값으로 돌아온다. agent-ready 는 750ms 간격 두 관측이 모두
idle/done·interactive_ready·launch 대기 아님이고 같은 `state_change_seq` 를 공유하며, **가드가 그 provider 의
기대 detect manifest 를 보고한 경우**에만 만족이다. 차단 화면과 미검증 manifest 는 **기다리지 않고 즉시**
`satisfied: false` 로 돌아오고 이유가 `agent.evidence` 에 담긴다.

### 상황 → 행동
- **차단 화면**: trust·로그인·업데이트 화면은 corral 이 대답하지 않는다 — **사람이 치운다.** 단
  **차단 판정의 유일한 근거는 detect manifest 의 label 이다.** label 되지 않은 모달은 agent-ready 를
  그냥 통과한다(예: codex 업데이트 메뉴). 그래서 **codex pane 은 첫 주입 전에 `terminal read` 로
  화면을 한 번 본다.**
- **타임아웃·빈 결과**: 타임아웃은 준비 완료가 **아니다.** 차단이었는지 그냥 느렸는지는 `agent.evidence`
  (`samples`·`detectManifest`)로 가른다. 만족하지 못한 대기를 준비로 읽고 주입하지 않는다.
- **부분 실패**: 이전에 ready 가 저장돼 있어도 지금 관문이 성립하지 않으면 `launching` 으로 보고된다 —
  저장된 ready 를 근거로 쓰지 않는다.
- **복구**: 화면을 읽어 차단이면 사람이 GUI 에서 치우거나 `corral terminal send` 로 정리한 뒤 다시 대기한다.
- **하지 말 우회**: `--for exit`·`--for output` 을 준비의 대용으로 쓰지 않는다. `agent-idle` 은 같은 술어를
  **다른 시점에** 묻는 것이라 기동 직후 준비 판정에 쓰지 않는다.
