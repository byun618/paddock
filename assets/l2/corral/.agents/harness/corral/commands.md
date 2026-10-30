<!-- paddock:fixed -->
# corral 매핑 — 요구 명령 선언

`capability-check.mjs` 가 읽는 파일이다. 작업 중에는 열 필요가 없다 — 명령은 능력 파일에 있다.

## 이 매핑이 요구하는 명령 — 선언

`capability-check runtime --tool corral` 이 이 블록을 읽어 **런타임 광고와 대조한다.**
블록이 없거나 비어 있으면 대조가 통과가 아니라 **불일치(exit 1)** 다 — "요구가 0개" 는
"다 있다" 가 아니라 **아직 안 적었다** 는 뜻이다. 본문이 쓰는데 여기 없는 명령도 불일치다.

```required-commands
status                              # 『전제 점검』 — 런타임 생존·광고 명령 목록
agent-context                       # 『전제 점검』 — 공개 계약(시그니처·주의사항). --socket 을 받지 않는다
orchestration run-create            # 『제어 문맥 격리』
orchestration run-use               # 『제어 문맥 격리』 — 복원
orchestration run-current           # 『제어 문맥 격리』 — 복원 확인
orchestration task-create           # 『감독 워커 기동』
orchestration worker-start          # 『감독 워커 기동』 + 『본문 주입』(한 호출)
orchestration dispatch-show         # 『감독 워커 기동』 — 타임아웃 뒤 시도 상태
orchestration check                 # 『완료 감지』 — 코디네이터가 배치를 받는다
orchestration inbox                 # 『완료 감지』 — 확인 없이 들여다본다
orchestration send                  # 『완료 감지』 — **워커가** worker_done·heartbeat·escalation 을 보낸다
orchestration request-show          # 『완료 감지』 — 영수증으로 중복 여부를 가른다
orchestration ask                   # 『질의응답』 — 워커가 묻는다 (--run 을 받지 않는다)
orchestration reply                 # 『질의응답』 — 코디네이터가 답한다
orchestration worker-show           # 『회수·정리』·『화면 관측』 — pane 생존·메시지 수
orchestration worker-read           # 『회수·정리』 — 원자료 회수
orchestration worker-retain         # 『회수·정리』 — 보존 의사 (한 번만 먹는다)
orchestration worker-release        # 『회수·정리』 — 정리
orchestration worker-stop           # 『회수·정리』 — 수렴하지 않는 시도 끝내기
orchestration worker-abandon        # 『회수·정리』 — 아무 조치 없이 포기
terminal create                     # 『세션 기동』
terminal wait                       # 『준비 대기』
terminal prompt                     # 『본문 주입』 — 배달 증명
terminal read                       # 『화면 관측』
terminal show                       # 『세션 기동』 관측 — 실제 argv
terminal list                       # 『회수·정리』 — 세션 목록
terminal send                       # 『본문 주입』 우회 경로 (증명 없음 — 쓰지 않는다고 적기 위해 선언)
terminal close                      # 『회수·정리』 — 빌린 pane 을 따로 닫는다
terminal switch                     # 『세션 기동』 — 포커스 전환
worktree set                        # 『감독 워커 기동』 — git 으로 만든 구현·리뷰 worktree 의 상위를 지정(표시용)
```

```mentioned-commands
orchestration task-list        # 「Run 명시 규칙」 목록에만 나온다 — 이 매핑은 호출하지 않는다
open                           # H7 설명(foundation 명령 예시)에만 나온다 — 앱 기동은 사용자 몫, 이 매핑은 호출하지 않는다
orchestration task-update      # 같은 위
orchestration dispatch         # 같은 위 (문맥 전용 Dispatch — 이 매핑의 순환에 쓰지 않는다)
orchestration worker-list      # 같은 위
orchestration run-list         # 같은 위
orchestration run-show         # 같은 위
worktree create                # 광고에는 있다. 이 매핑은 실행하지 않는다 — 구현 worktree 는 git 으로 만든다(『감독 워커 기동』)
worktree rm                    # 같은 위
worktree list                  # 같은 위
worktree current               # 같은 위
worktree show                  # 같은 위
worktree ps                    # 같은 위
```

`mentioned-commands` 는 **이름만 나오고 호출하지 않는 명령**의 칸이다. 사유 주석이 없으면 『전제 점검』이 멈춘다 —
"없는 명령·폐기된 별칭·쓰지 말라" 를 적을 자리를 주되, 아무 이름이나 조용히 통과하지는 못하게 한다.

**『세션 기록 오라클』은 corral 명령을 쓰지 않는다** — 그래서 이 목록에 없다. 대신 `jq` 로 기록을 직접 읽는다.
