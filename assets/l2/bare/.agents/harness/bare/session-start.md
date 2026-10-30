<!-- paddock:fixed -->
## 『세션 기동』

### 명령
```bash
# tmux
tmux new-session -d -s <세션명> -c <작업 폴더 절대경로>
tmux new-window -t <세션명> -c <작업 폴더 절대경로>
tmux send-keys -t <대상> '<provider 실행 명령>' Enter
tmux list-panes -a -F '#{pane_id} #{pane_pid} #{pane_current_path} #{pane_current_command}'
# iTerm2 — 사람이 탭을 열고 도구를 실행한다 (Python API: iterm2.Window.async_create_tab)
```

### 보장 수준
**관측.** pane 이 생겼고 그 안에서 어떤 프로세스가 도는지는 볼 수 있다. **모델·effort·advisor 를 지정하는
제어 계층이 없으므로** provider CLI 의 플래그로 직접 지정하고, 실제로 무엇으로 해소됐는지는 배너를 읽어
관측으로 기록한다. 요청값과 관측값을 반드시 구분해 적는다.
iTerm2 쪽은 `async_create_tab` 으로 탭을 열지만 **그 탭이 무엇을 띄웠는지 돌려주지 않는다** — 확인은 화면이다.

### 상황 → 행동
- **차단 화면**: 기동 직후 화면을 읽어 trust·로그인·업데이트 화면인지 사람이 본다 — 가려낼 자동 수단이 없다.
- **타임아웃·빈 결과**: `send-keys` 는 즉시 돌아온다. provider 가 떴는지는 별도로 화면을 읽어 확인한다.
- **부분 실패**: pane 은 만들어졌는데 provider 가 안 뜬 상태가 있을 수 있다 — `#{pane_current_command}` 로 본다.
- **복구**: pane 을 버리고 새로 만든다. 남은 pane 은 사람이 센다.
- **하지 말 우회**: `send-keys` 가 exit 0 이라는 것을 "도구가 떴다" 로 읽지 않는다.
