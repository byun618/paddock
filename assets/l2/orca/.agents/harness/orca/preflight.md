<!-- paddock:fixed -->
## 『전제 점검』

### 명령
```bash
orca status --json          # runtime.capabilities = 기능 토큰 (orchestration.contract.v1 류)
orca agent-context --json   # 명령 레지스트리 — 명령 이름·시그니처
node .agents/harness/capability-check.mjs runtime --tool orca
```

### 보장 수준
**증명.** orca 의 광고는 **명령 이름이 아니라 기능 토큰**이다
(`orchestration.contract.v1`, `terminal.multiplex.v1`, `orchestration.worker-stop-verdict.v1` …).
그래서 대조는 두 갈래다: 매핑이 요구하는 **기능 토큰**은 `status` 의 집합과, 요구하는 **명령 이름**은
레지스트리의 명령 목록과 대조한다. 앱이 꺼져 있으면 `status` 에 기능 토큰이 없어 검사가 exit 2 로 끝난다 — 앱을 띄우고 다시 돌린다.

### 상황 → 행동
- **차단 화면**: 해당 없음 — 점검 명령은 pane 을 열지 않는다.
- **타임아웃·빈 결과**: 레지스트리 읽기는 **앱이 꺼져 있어도 답한다**(계약에 그렇게 적혀 있다) — 그래서
  레지스트리만 보고 "런타임이 살아 있다" 고 판정하면 안 된다. 살아 있는지는 `status` 로 본다.
- **부분 실패**: 기능 토큰은 있는데 명령이 없거나 그 반대일 수 있다 — 둘 다 대조해야 한다.
- **복구**: `status` 가 안 되면 사용자가 앱을 띄운다(`orca open`).
- **이 점검이 보지 않는 것 — 프로필 선택.** **이 도구에는 프로필 인자가 없다.**
  검사기에 `--socket`·`--instance` 를 주면 exit 2 로 거절한다 — 런타임 이상이 아니라 인자가 없는 것이다.
  여러 인스턴스를 가려 보는 축은 이 도구에서 **공백**이고, 원격은 명령별 `--on <saved-environment>` 가 대신한다
  (그건 프로필 선택이 아니라 실행 위치 선택이다).
- **하지 말 우회**: 기능 토큰 이름을 명령 이름처럼 읽지 않는다. `orchestration.contract.v1` 이 있다고
  정확히 한 번 배달을 판정한다는 뜻이 아니다(`00-mapping.md` 보장 요약 첫 줄).
