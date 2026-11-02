<!-- paddock:fixed -->
## 『게이트 알림』

### 명령
```bash
# 보내는 쪽 — 코디 pane 의 셸에서, 멈추기 직전에 한 번
afplay /System/Library/Sounds/Glass.aiff
# 대체 경로 — 본체 세션에서. 본체는 기록된 코디 handle 을 쓴다
corral terminal wait --terminal <handle> --for agent-idle --timeout-ms 120000 --json
corral terminal read --terminal <handle> --screen --json
# 사용자가 그 pane 을 보여 달라고 할 때만
corral terminal switch --terminal <handle> --json
```

### 보장 수준
**재생 요청은 관측, 들었는지는 공백이다.** `afplay` 의 exit 0 은 재생을 마쳤다는 뜻이고, 음소거거나 자리를 비웠으면 아무도 못 듣는다.
소리는 어느 pane 이 멈췄는지 알려 주지 않는다 — 사용자는 corral 에서 멈춘 코디를 찾는다. corral CLI 에는 알림 명령이 없어 macOS 를 직접 부른다(corral 터미널 백엔드도 macOS 전용이다).
OS 알림(`osascript`)은 쓰지 않는다 — 권한이 없으면 exit 0 인 채 아무것도 뜨지 않아 실패가 가려진다.
대체 경로의 `agent-idle` 도 **턴이 끝났다는 관측**이지 게이트라는 뜻이 아니다 — 화면을 읽어 무엇을 묻는지 확인해야 한다.
알림은 승인 경로도 판정 근거도 아니다. 승인은 코디 pane 에서 받는다.

### 상황 → 행동
- **차단 화면**: 코디가 차단 화면에 막히면 코디는 알림을 보낼 수 없다. 대체 경로의 `corral terminal wait` 는 차단 화면과 미검증 manifest 에서 곧바로 만족 안 됨을 돌려준다 — 어느 쪽인지는 `…agent.evidence` 로 가르고, 차단 화면은 사람이 치운다.
- **타임아웃·빈 결과**: `corral terminal wait` 의 타임아웃은 코디가 아직 일하고 있다는 뜻이다(120초 상한). 다시 기다린다.
  이미 멈춘 pane 은 곧바로 만족을 돌려주므로, `…agent.evidence.stateChangeSeq` 가 지난번과 같으면 새로 멈춘 것이 아니다 — 잠시 두고 다시 본다.
- **부분 실패**: `afplay` 가 0 이 아니면(없음·샌드박스 거절) 게이트 보고 끝에 그 사실을 한 줄 적고 그대로 멈춘다. **알림 실패로 게이트 흐름을 바꾸지 않는다.**
- **복구**: 소리가 안 들린다고 사용자가 말하면 음량·출력 장치를 안내하거나, 본체 세션이 대체 경로로 코디를 지켜본다. 코디 모델은 그대로 둔다.
- **하지 말 우회**: 알리려고 `corral terminal switch` 로 사용자의 포커스를 뺏지 않는다. 소리가 났다는 것을 승인이나 판정의 근거로 쓰지 않는다.
