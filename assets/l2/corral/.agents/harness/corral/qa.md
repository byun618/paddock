<!-- paddock:fixed -->
## 『질의응답』

### 명령
```bash
# 코디네이터: 질문은 『완료 감지』의 check 배치로 받는다 (--types 에 question 포함)
corral orchestration reply --id <msg_id> --body "<답>" [--run <run_id>] --json
# 워커 쪽(preamble 이 주는 형태): corral orchestration ask --question … --task-id … --dispatch-id … --timeout-ms 600000
```

### 보장 수준
**증명.** 질문은 대기 시작 **전에 durable 하게 저장된다** — 타임아웃·클라이언트 취소·런타임 재시작에도 답할 수
있다. 마감은 오류가 아니라 `state: pending` + `messageId` + `resumeCommand` 이고, 재개는 새 질문을 만들지 않는다.
답은 물어본 워커에게 주소된 별도 메시지이고 **check 배치에 섞이지 않는다.** 이미 답이 있는 질문에 두 번째
`reply` 는 `already_answered` 로 아무것도 저장하지 않는다.

### 상황 → 행동
- **차단 화면**: 해당 없음 — 질의응답은 pane 화면을 거치지 않는다.
- **타임아웃·빈 결과**: `corral orchestration ask --timeout-ms` 상한은 600000 이다. 마감이면 워커는 **다시 묻지 않고**
  응답에 담긴 `resumeCommand`(`--resume <msg_id>`)를 실행한다. 다시 물으면 중복 질문이 생긴다.
- **부분 실패**: `corral orchestration reply --id` 가 가리키는 게 질문이 아니면 `not_a_question`, 없는 id 면 `message_not_found` —
  둘 다 아무것도 저장하지 않는다.
- **복구**: 질문을 놓친 것 같으면 `corral orchestration inbox --run <run_id> --json` 으로 Run 의 모든 메시지를 본다.
- **하지 말 우회**: **⚠ `orchestration ask` 에는 `--run` 이 없다.** 질문은 **프로필에 현재 바인딩된 Run** 으로
  간다. 바인딩을 바꿔 둔 구간에서는 `ask` 를 치지 않는다 — 『제어 문맥 격리』를 먼저 복원하고 묻는다.
  워커에게 로컬 대화형 프롬프트로 묻게 하지 않는다(코디네이터가 볼 수 없어 세션이 멈춘다).
