<!-- paddock:fixed -->
## 『본문 주입』

### 명령
```bash
corral terminal prompt --terminal <handle> (--text "<본문>" | --file <경로> | --stdin) \
  --wait accepted --json
```

### 보장 수준
**증명(이 pane 이 소유한 세션 기록이 있을 때) — 없거나 둘 이상이면 그 판정은 `unknown` 이고 그때는 공백이다.**
`--wait accepted` 가 만족된 `outcome: completed` + `record.matchCount: 1` 이 "정확히 한 번 도착" 이다.
배달과 대기는 **따로 보고된다**: `record.matchCount`/`unavailableReason` 이 배달을, `wait.requested/satisfied/reason`
이 대기를 답한다. `--wait` 없는 주입은 **큐에 들어간 것이지 완료가 아니다.** 응답의 `requestId` 형식은
`r1.<13자리 ms>.<UUID>` 이고, corral 은 **이 pane 이 소유했음을 증명할 수 있는 세션 기록만** 읽는다
(claude·grok 은 민팅한 세션 id, codex 는 cwd·시각이 맞는 rollout 하나). 그런 기록이 없거나 둘 이상이면
matchCount·resolvedModel·record.path 가 모두 unknown 이다 — **다른 세션 파일에서 읽어오지 않는다.**

### 상황 → 행동
- **차단 화면**: 주입은 fail-closed 이고 효과가 없다 — `agent_blocked`(차단 화면),
  `detect_manifest_unverified`(가드 manifest 불일치), `agent_not_ready`(준비 관문 또는 제출 직전
  `state_change_seq` 검사 실패), `prompt_already_delivered`(이미 기록에 그 본문이 있음).
- **타임아웃·빈 결과**: 마감·차단·종료로 대기가 끝나면 `wait.reason` 이 `deadline|agent_blocked|agent_exited` 다.
  `outcome` 은 만족한 대기에서만 `completed` 이고, 그 밖은 `outcome: unknown` 이며 **자동 재제출되지 않는다** —
  이때도 확인된 배달은 함께 보고된다. 그 보고를 먼저 읽고, `matchCount: 1` 이면 다시 넣지 않는다.
- **부분 실패**: `matchCount` 가 2 이상이면 **한 입력 규칙이 이미 깨진 것**이다. 통과로 승격하지 않고 사람에게
  보고한다. `unavailableReason` 이 null 이 아닌 `matchCount: 1` 은 **어느 쪽으로도 증거가 아니다**(커서가 무효화된
  1건과, 기록을 아직 쓰지 않은 provider 의 0건이 같은 모양으로 온다).
- **복구**: 큐 수락(`queued`)·`outcome_unknown` 에서 **중복 주입하지 않는다.** 같은 `--request-id` 로 재전송해
  영수증을 replay 하거나, `corral orchestration request-show --id <request_id>` 로 무엇이 일어났는지 먼저 본다.
- **하지 말 우회**: `terminal send` 는 raw 입력이라 배달 판정이 없다 — managed 에이전트에 지시를 넣는 정본은
  `terminal prompt` 다. **`--text`·`--file`·`--stdin` 의 상한은 모두 65536 UTF-8 바이트로 같다 — `--file` 로
  상한을 넘기지 못한다**(H1'). 넘으면 상세를 파일로 저장하고 짧은 지시에 그 경로를 적는다. NUL 은 거절된다.
