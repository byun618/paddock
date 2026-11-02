<!-- paddock:fixed -->
## 『세션 기록 오라클』

### 명령

**orca 의 1차 수단은 자기 계약의 transcript 다.**

```bash
orca orchestration worker-read --dispatch <dispatch_id> --source transcript --json   # 훅 transcript 가 있을 때만
orca orchestration worker-read --dispatch <dispatch_id> --json                       # auto: transcript 없으면 터미널 출력
```

**provider 기록 파일을 직접 읽어야 하면 경로를 어떻게 얻나 — 여기가 이 도구의 공백이다.**
레지스트리에 세션 기록 파일 경로를 돌려준다는 명령이 없다. 즉 orca 는 "이 pane 이 소유한
기록 파일" 을 값으로 돌려주지 않는다. 그래서 순서는 이렇다:

1. `worker-read` 의 transcript 로 **먼저** 본다. 응답이 transcript 인지 터미널 출력인지 **구분해 적는다.**
2. 그래도 파일을 봐야 하면 H6 의 홈 경로에서 **후보를 좁힌다** — worktree(cwd)와 기동 시각으로 고른다.
   **어느 파일이 이 pane 의 것인지 증명할 수단은 없다.**
   그러므로 이 경로로 얻은 것은 "후보 파일의 관측" 이고, 판정표에는 **공백**으로 적는다.
3. 파일을 골랐으면 이렇게 읽는다:

```bash
# 무엇이 들어갔고(user) 무엇이 응답됐나(assistant) — 경로를 인자로 준다
jq -r 'select(.type=="user" or .type=="assistant")
       | [.type, (.message.role // "-"),
          ((.message.content | if type=="array"
             then (map(.text // ("["+(.type//"?")+"]")) | join(" "))
             else (. // "") end) | tostring | gsub("\\s+";" ") | .[0:80])]
       | @tsv' <세션 기록 .jsonl 절대경로>
jq -r '.type' <세션 기록 .jsonl 절대경로> | sort | uniq -c | sort -rn   # 줄 종류만 세기
```

Codex·Grok 기록은 필드 이름이 달라 **먼저 한 줄을 열어 키를 확인한다.**

### 보장 수준
**관측.** 기본 소스(`auto`)는 "훅이 보고한 정확한 transcript 가 **있을 때** 그것을, 없으면 라벨 붙은 터미널
출력" 을 준다 — **어느 쪽을 받았는지 응답으로 구분해야 한다.** 사람이 기록 파일을 직접 읽는 경로는 H1·H6 그대로
관측이고, 사람 입력과 주입 입력을 가르는 필드는 없다.

### 상황 → 행동
- **차단 화면**: 해당 없음 — 기록 파일을 읽는 것뿐이라 화면을 거치지 않는다.
- **타임아웃·빈 결과**: 기록이 없는 것은 배달 실패의 증거가 아니다(H1).
- **부분 실패**: `source_changed` 면 커서를 버리고 새로 읽는다.
- **복구**: transcript 가 없으면 터미널 출력으로 떨어진다 — 그 사실을 근거 칸에 적는다.
- **하지 말 우회**: transcript 가 있었다는 것을 『본문 주입』의 배달 증명으로 승격하지 않는다.
  이 도구에서 정확히 1회 배달은 증명되지 않는다.
