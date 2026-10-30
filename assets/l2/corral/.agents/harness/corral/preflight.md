<!-- paddock:fixed -->
## 『전제 점검』

### 명령
```bash
corral status --json                      # runtime.state·reachable·capabilities(명령 이름 목록)
node .agents/harness/capability-check.mjs runtime --tool corral   # 매핑 요구 능력 ↔ 광고 대조
corral agent-context --json               # 명령별 시그니처·주의사항 (--socket 거절)
```

### 보장 수준
**증명(이 프로필·이 셸의 광고에 한정).** 아래 「이 점검이 보지 않는 것」 두 줄이 자격의 이유다 — 자식 pane 의
PATH 와 다른 프로필(`--socket`·`--instance`)은 이 점검 밖이다. `status` 의 `runtime.capabilities` 는 **명령 이름 집합**이다(`terminal prompt`,
`orchestration worker-start` …). 대조 스크립트가 이 매핑이 요구하는 명령 이름을 그 집합과 차집합으로 비교하고
빠진 것이 있으면 0 이 아닌 종료로 멈춘다. `status` 가 exit 1 이면 런타임이 꺼진 것이다.

### 상황 → 행동
- **차단 화면**: 해당 없음 — 점검 명령은 pane 을 열지 않는다.
- **타임아웃·빈 결과**: `status` 가 응답하지 않거나 `reachable: false` 면 런타임이 없다. 다른 도구로 몰래
  대체하지 않고 원인을 보고한다. `capabilities` 가 비어 오는 것은 **광고 부재**이지 통과가 아니다.
- **부분 실패**: 광고에는 있는데 실제 호출이 거절되면 광고가 아니라 **실제 응답을 믿는다** — 거절 원문을 원자료로
  남기고 이 매핑을 고친다.
- **복구**: 런타임이 꺼져 있으면 사용자가 데스크톱 앱을 띄운다. 런타임·backend 는
  `CLAUDE_CODE_*`·`CLAUDECODE`·`CLAUDE_PID`·`CLAUDE_EFFORT`·`ORCA_AGENT_HOOK_*` 를 **제거한 env** 로 띄운다.
  pane 이 backend 에서 env 를 상속하므로 마커가 남으면 provider 가 세션
  기록을 쓰지 않아 『본문 주입』의 배달 판정이 조용히 무력화된다 — `record.unavailableReason` 이 null 이 아니면
  마커 상속부터 의심한다.
- **이 점검이 보지 않는 것 — 자식 pane 의 PATH.** `capability-check` 와 `status` 는 **내 셸**에서 corral 이
  보이는지만 본다. 워커가 완료 보고를 치려면 **그 pane 의 셸에서도** corral 이 보여야 하는데(H7),
  그것을 미리 재는 수단은 없다 — **공백이다.** 워커가 조용히 보고를 못 하면 이 자리를 의심한다
  (워커 preamble 이 소켓 경로까지 박아 주므로 보통은 찾는다).
- **이 점검이 보지 않는 것 — 다른 프로필·인스턴스.** `capability-check runtime` 은 `--socket`·`--instance` 를
  **그대로 넘겨 주지만**(그 인자를 주지 않으면) **기본 프로필**을 본다. 다른 프로필로 일하면서 이 점검을
  기본으로 돌리면 **쓰지 않는 런타임을 점검하고 통과를 준다** — 그 경우 점검 명령에도 같은 `--socket`·`--instance`
  를 붙인다. 붙이지 않았다면 그 판정 칸은 **다른 런타임의 것**이다.
- **이 점검이 보지 않는 것 — "없다" 고 적은 문장.** 대조는 *요구 ⊆ 광고* 한 방향이다. 매핑이 **광고에 있는
  명령을 없다고 적어도** 어느 방향에도 걸리지 않는다 — `mentioned-commands` 는 사유만 요구하고 사유의 사실
  여부는 보지 않는다. **역방향 대조는 공백이다** — 매핑에 "없다·못 한다" 를 적을 때는 광고 목록을 그 자리에서 눈으로 대조한다.
- **하지 말 우회**: 시작 세션에서 됐다는 이유로 이 점검을 생략하지 않는다. 대조 불일치를 "아마 될 것" 으로
  넘기지 않는다.
