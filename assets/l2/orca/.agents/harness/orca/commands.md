<!-- paddock:fixed -->
# orca 매핑 — 요구 명령·토큰 선언

`capability-check.mjs` 가 읽는 파일이다. 작업 중에는 열 필요가 없다 — 명령은 능력 파일에 있다.

## 이 매핑이 요구하는 명령·토큰 — 선언

`capability-check runtime --tool orca` 가 읽어 대조한다. 명령 이름은 **레지스트리**(`agent-context`)와,
기능 토큰은 **`status` 의 광고**와 대조한다. 어느 블록이든 없거나 비어 있으면 **불일치(exit 1)** 다.

```required-commands
status                              # 『전제 점검』
agent-context                       # 『전제 점검』 — 명령 레지스트리
open                                # 『전제 점검』 — 앱 열기
orchestration run-create            # 『제어 문맥 격리』
orchestration run-use               # 『제어 문맥 격리』
orchestration run-current           # 『제어 문맥 격리』
orchestration task-create           # 『감독 워커 기동』
orchestration worker-start          # 『감독 워커 기동』
orchestration dispatch-show         # 『감독 워커 기동』
orchestration request-show          # 『완료 감지』 — 응답 유실 때 영수증 조회
orchestration check                 # 『완료 감지』
orchestration inbox                 # 『완료 감지』 — 확인 없이 들여다본다
orchestration send                  # 『완료 감지』 — 워커가 worker_done 을 보낸다
orchestration ask                   # 『질의응답』
orchestration reply                 # 『질의응답』
orchestration worker-show           # 『회수·정리』·사람 개입
orchestration worker-read           # 『회수·정리』 — 닫은 뒤에도 답한다
orchestration worker-list           # 『회수·정리』
orchestration worker-retain         # 『회수·정리』
orchestration worker-release        # 『회수·정리』 — release_unknown 만 exit 1
orchestration worker-stop           # 『회수·정리』
orchestration worker-abandon        # 『회수·정리』
terminal create                     # 『세션 기동』
terminal wait                       # 『준비 대기』 — --for exit|tui-idle 뿐
terminal read                       # 『화면 관측』
terminal show                       # 『세션 기동』
terminal list                       # 『세션 기동』 — create 시간 초과 뒤 찾기
terminal send                       # 『본문 주입』
terminal close                      # 『회수·정리』
worktree create                     # 『세션 기동』 — --prompt 로 본문을 실을 수 있다
```

```required-tokens
orchestration.contract.v1                 # 『감독 워커 기동』·『완료 감지』·『질의응답』
terminal.multiplex.v1                     # 『세션 기동』·『화면 관측』
orchestration.worker-stop-verdict.v1      # 『회수·정리』
```

```mentioned-commands
terminal prompt                     # orca 에 없다 — 정확히 1회 배달을 증명할 수 없는 근거
orchestration gate-list             # --run 을 받되 바인딩하지 않는 예 — 이 매핑은 호출하지 않는다
orchestration dispatch              # 문맥 전용 Dispatch — 감독 워커로 세지 않는다
orchestration reset                 # Run·Task·메시지를 지운다 — 격리 수단으로 쓰지 말라는 언급
orchestration coordinator-start     # 효과 없는 레거시 별칭 — 쓰지 않는다
orchestration coordinator-stop      # 같은 위
```

**『세션 기록 오라클』은 orca 명령이 아니다** — `jq` 로 기록을 직접 읽는다.
