<!-- paddock:fixed -->
## 『세션 기록 오라클』

### 명령
```bash
# 1) 이 pane 이 소유한 기록의 경로를 응답에서 꺼낸다 (짐작하지 않는다)
#    worker-start → result.input.agent.sessionRecord.path · terminal prompt → result.record.path
# 2) 그 경로를 인자로 주고 읽는다 — jq 블록은 contract.md H6 참조
```

경로는 위 응답 필드에서만 꺼낸다. 읽는 방법(무엇이 들어갔고 무엇이 응답됐나, 줄 종류 세기)과 provider 별 기록 위치·홈 변수는
[contract.md](../contract.md) H6 에 있다. Codex·Grok 기록은 필드 이름이 다르므로 **먼저 한 줄을 열어 키를 확인한 뒤** 같은 요령으로 읽는다.

### 보장 수준
**관측.** corral 은 provider 훅을 설치하지 않는다. `terminal prompt` 의 `record.matchCount` 는 corral 이
**이 pane 이 소유했음을 증명할 수 있는 기록**만 읽어 만든 값이라 증명이지만, 사람이 직접 파일을 읽는 이 경로는
관측이다 — 어느 기록에도 **사람이 친 입력과 주입된 입력을 가르는 필드가 없다**(H1·H2).

### 상황 → 행동
- **차단 화면**: 해당 없음 — 기록 파일을 읽는 것뿐이라 화면을 거치지 않는다.
- **타임아웃·빈 결과**: 기록 파일이 없는 것은 배달 실패의 증거가 **아니다** — provider 가 아직 쓰지 않았거나
  기록을 끄고 있을 수 있다(H1).
- **부분 실패**: 같은 cwd 에 세션이 여럿이면 어느 것이 이 pane 인지 corral 도 unknown 으로 답한다 —
  사람이 짚을 때도 같은 모호함을 안고 짚는 것이다. 짚은 근거를 함께 적는다.
- **복구**: pane 소유 기록이 필요하면 『본문 주입』 응답의 `agent.sessionRecord.path` 를 쓴다.
- **하지 말 우회**: 세션 기록을 『완료 감지』 대용으로 쓰지 않는다. 판정표의 완료 칸에 기록 파일을 근거로 적지 않는다.
