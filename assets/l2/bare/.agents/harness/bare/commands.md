<!-- paddock:fixed -->
# bare 매핑 — 요구 명령 선언

`capability-check.mjs` 가 읽는 파일이다. 작업 중에는 열 필요가 없다 — 명령은 능력 파일에 있다.

## 이 매핑이 요구하는 명령 — 선언

`capability-check runtime --tool bare` 도 이 블록을 읽는다. **대조할 광고가 없으므로 결과는 공백(exit 3)**
이지만, **블록이 없거나 비어 있거나 본문에 없는 죽은 항목이 있으면 불일치(exit 1)** 다.
"광고가 없다" 가 "아무것도 안 적어도 된다" 는 뜻은 아니다.

```required-commands
tmux new-session                    # 『세션 기동』
tmux new-window                     # 『세션 기동』
tmux send-keys                      # 『본문 주입』 — ack 없음
tmux load-buffer                    # 『본문 주입』 — 큰 본문
tmux paste-buffer                   # 『본문 주입』 — 큰 본문
tmux capture-pane                   # 『화면 관측』 — 이 도구의 유일한 관측 수단
tmux list-panes                     # 『전제 점검』·『회수·정리』 — pane_id·pane_pid 쌍
tmux kill-pane                      # 『회수·정리』
tmux kill-session                   # 『회수·정리』
async_create_tab                    # iTerm2 — 『세션 기동』
async_send_text                     # iTerm2 — 『본문 주입』 (None 을 돌려준다 = ack 없음)
async_get_screen_contents           # iTerm2 — 『화면 관측』
```

위 목록에 **『완료 감지』·『질의응답』·『제어 문맥 격리』·『준비 대기』의 명령이 하나도 없다** — 없어서 없는 것이고,
그 사실이 곧 이 매핑의 공백 칸들이다. 『세션 기록 오라클』은 `jq` 로 기록을 직접 읽는다.
