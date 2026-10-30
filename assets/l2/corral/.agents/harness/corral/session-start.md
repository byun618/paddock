<!-- paddock:fixed -->
## 『세션 기동』

### 명령
```bash
corral terminal create --worktree path:<절대경로> --title "<제목>" \
  --agent claude|codex|grok [--model <id>] [--effort <등급>] [--advisor fable] [--focus] --json
corral terminal show --terminal <handle> --json     # provider 프로세스·argv
corral terminal read --terminal <handle> --screen --json   # 배너
```

### 보장 수준
**세션 기록 경로**: 응답의 `result.agent.sessionRecord.path` — claude 는 세션 id 를 민팅하므로 기동 응답에 있다(파일은 아직 없어 `exists: false`).
codex 는 기동 응답에서 `sessionRecord`·`sessionId` 가 null 이고, 경로는 첫 `terminal prompt` 응답에서야 나오며 소유 판정이 `ambiguous` 일 수 있다.

**관측.** 기동 자체는 계약이지만 **모델·advisor 가 실제로 무엇으로 해소됐는지는 관측이다.** dispatch 스냅샷은
기동 시점 관측이라 갱신되지 않고 `resolvedModel: null` 일 수 있다. argv(`terminal show`)와 배너(`terminal read`)로
기록하고 **요청값과 관측값을 구분해 적는다.** 별칭(`opus`·`fable`)은 버전 고정이 아니다.

### 상황 → 행동
- **차단 화면**: `--prompt` 를 함께 준 경우, 차단이 먼저 뜨면 create 는 거기서 끝나고(complete) 본문을 들고
  있지 않는다 — 별도 `terminal prompt` 로 자기 `--request-id` 아래 다시 넣는다.
- **타임아웃·빈 결과**: `terminal create` 응답 타임아웃은 실패가 아니라 **지연일 수 있다.** 같은 worktree 의
  `corral terminal list` 로 그 도구 터미널을 먼저 찾고, 살아 있으면 그 handle 을 기록해 재사용한다. 확인 없이 재시도해
  중복 세션을 만들지 않는다.
- **부분 실패**: 단계별 상태(`stages` = worktree·terminal·agent·prompt)가 정본이다. 만들어진 git worktree 는
  뒤 단계 실패로 지워지지 않고, 관측되지 않은 단계는 `unknown` 으로 남고 재시도되지 않는다.
- **복구**: `--focus` 때문에 문제가 나면 `--focus` 를 빼고 만든 뒤 `corral terminal switch` 를 쓴다. 헤드리스에서는
  `switch`·`corral terminal create --focus` 가 미지원이다.
- **하지 말 우회**: `--command` 로 provider argv 를 문자열로 조립하지 않는다 — `--command` 와 `--agent` 는
  상호배타이고 위반은 효과 없는 `invalid_request` 다. `--model`·`--effort`·`--advisor`·`--prompt` 는 `--agent`
  필수, `--advisor` 는 `--agent claude` 에만 붙는다. 모델 접근·사용량으로 못 띄우면 **다른 모델로 조용히
  대체하지 않고** 차단을 보고한다.
