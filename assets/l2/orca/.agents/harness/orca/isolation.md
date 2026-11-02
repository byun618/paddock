<!-- paddock:fixed -->
## 『제어 문맥 격리』

### 명령
```bash
orca orchestration run-current [--from <handle>] --json
orca orchestration run-create --objective "<목적>" --json
orca orchestration run-use --id <run_id> [--takeover-legacy] --json
# 그리고 명령마다 --run <run_id> / 필요하면 --from <handle>
```

### 보장 수준
**증명(계약).** 계약이 `run-use` 를 "**이 코디네이터 터미널**을 기존 Run 에 바인딩",
`run-current` 를 "**이 터미널의** 바인딩된 Run" 이라고 적는다 — 바인딩이 터미널 단위다. 더해
**`ask` 도 `--run` 을 받고**, `orchestration gate-list` 는 `--run` 을 받되 바인딩하지 않고 들여다본다. `--from <handle>` 로 호출자
정체를 명시할 수 있다. `run-create` 가 스스로 바인딩하므로 이어서 `run-use` 를 부를 필요가 없었다(1.4.198 관측).

### 상황 → 행동
- **차단 화면**: 해당 없음 — Run 바인딩 조회·전환은 화면과 무관하다.
- **타임아웃·빈 결과**: 바인딩 조회는 로컬 상태라 기다릴 것이 없다. **빈 결과는 "아직 어느 Run 에도 바인딩되지 않았다" 는 뜻**이고 실패가 아니다 — 그 상태에서 `--run` 없이 치면 엉뚱한 곳으로 가지 않고 거절되거나 새로 만든다.
- **부분 실패**: `--takeover-legacy` 는 **바인딩할 실제 코디네이터 에이전트 터미널 안에서** 실행해야 하고
  기존 워커 배정을 보존한다 — 다른 pane 에서 쓰지 않는다.
- **복구**: 바인딩이 의심되면 `orca orchestration run-current --from <handle>` 로 그 handle 기준으로 확인한다.
- **하지 말 우회**: `orchestration reset` 은 Run·Task·메시지를 지우는 명령이다 — **격리 수단으로 쓰지 않는다.**
  격리는 새 Run 과 `--run` 명시로 한다.
