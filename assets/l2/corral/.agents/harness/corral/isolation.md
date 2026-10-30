<!-- paddock:fixed -->
## 『제어 문맥 격리』

### 명령
```bash
corral orchestration run-current --json                      # 지금 바인딩된 Run
corral orchestration run-create --objective "<목적>" --json   # ⚠ 만든 Run 으로 현재 바인딩을 재설정한다
corral orchestration run-use --id <run_id> --json            # 바인딩 복원
# 그리고 --run 을 받는 orchestration 명령 전부에 --run <run_id> 를 명시한다 (아래 목록 참고)
```

### `--run` 을 받는 명령 / 받지 않는 명령

**받는다 (15개)** — 여기에는 반드시 명시한다:
`corral orchestration task-create` · `corral orchestration task-list` · `corral orchestration task-update` ·
`corral orchestration dispatch` · `corral orchestration worker-start` · `corral orchestration worker-list` ·
`corral orchestration worker-read` · `corral orchestration send` · `corral orchestration reply` ·
`corral orchestration check` · `corral orchestration inbox` · `corral orchestration worker-retain` ·
`corral orchestration worker-release` · `corral orchestration worker-stop` · `corral orchestration worker-abandon`

**받지 않는다 (9개)** — 붙이면 `invalid_argument: Invalid flag for orchestration <명령>: --run` 으로 **튕긴다**:
`corral orchestration run-create` · `corral orchestration run-use` · `corral orchestration run-current` ·
`corral orchestration run-list` · `corral orchestration run-show` · `corral orchestration dispatch-show` ·
`corral orchestration worker-show` · `corral orchestration ask` · `corral orchestration request-show`

(이 목록은 **완전 표기로 적는다** — 이 매핑의 표기 규약이자, 이름이 바뀌면 『전제 점검』이 이 줄에서 멈추게 하는 장치다.)

**이 9개는 전부 현재 바인딩(또는 `--id`/`--task`/`--dispatch` 로 지목한 대상)을 따라간다.**
그중 **복구 국면에서 쓰는 조회 명령(`dispatch-show`·`worker-show`·`request-show`)** 에 `--run` 을 붙이면
복구 중에 거절당한다 — "런타임이 이상하다" 로 오진하기 쉬운 지점이다. `ask` 는 특히 위험하다(아래 하지 말 우회).


### 보장 수준
**증명(단 구멍 하나).** **현재 Run 은 프로필 단위로 바인딩된다 — 부르는 터미널 단위가 아니다.**
`--run <id>` 는 그 한 번의 호출에만 적용되고 바인딩을 바꾸지 않는다. Run 이 없으면 `run_required` 로
효과 이전에 실패한다. **구멍: `corral orchestration ask` 에는 `--run` 이 없다**(`corral orchestration send`·`corral orchestration check`·`corral orchestration reply`·`task-*`·
`worker-*` 에는 있다) — 질문은 현재 바인딩을 따라간다.

### 상황 → 행동
- **차단 화면**: 해당 없음 — Run 바인딩 조회·전환은 화면과 무관하다.
- **타임아웃·빈 결과**: `run-use` 의 모르는 `--id` 는 `run_not_found` 이고 **이전 바인딩을 건드리지 않는다.**
- **부분 실패**: 두 코디네이터(또는 순환 검증 중인 워커)가 한 프로필에서 `run-create` 하면 상대의
  `corral orchestration check`·`corral orchestration send` 가 엉뚱한 Run 으로 간다. **규율: `--run` 을 받는 15개 명령에는 빠짐없이 `--run` 을 명시하고,
  받지 않는 9개를 쓸 때는 지금 바인딩이 무엇인지 먼저 확인한다**(`run-current`).
- **복구**: 바인딩을 바꿨다면 **바꾼 쪽이 복원한다** — `corral orchestration run-use --id <원래 Run>` 뒤 `run-current` 로 확인하고
  그 출력을 원자료로 남긴다. 워커 preamble 의 보고 명령에는 `--run` 이 없어 바인딩에 의존하므로, 바인딩을
  바꾼 구간이 자식 워커의 보고·회수를 덮으면 그 구간이 끝날 때까지 되돌리지 않는다.
- **하지 말 우회**: 남의 Run 에 `run-use` 하거나 남의 Run 의 메시지를 `--ack` 하지 않는다. 잔존 Run 을
  "아무도 안 쓰는 것 같으니" 재사용하지 않는다 — 새로 만들고 끝나면 복원한다.
  **절차 문서의 "기존 Run 을 우선 쓴다" 와 충돌하지 않는다 — 가르는 것은 소유다**: 그 Run 이 **내 작업의 것**
  (내가·내 코디네이터 세션이 이 일감으로 만든 것, `run-show` 의 `objective` 로 확인)이면 재사용한다.
  **남의 것이거나 누구 것인지 모르면 새로 만들고 끝나면 복원한다.** 모르는 채 재사용하면 남의 배치를
  `--ack` 하게 되고 그건 되돌릴 수 없다.
