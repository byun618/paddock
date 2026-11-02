<!-- paddock:fixed -->
# orca 매핑 — 능력 → 명령

능력 이름과 보장 어휘(증명/관측/공백)의 정본은 [capabilities.md](../capabilities.md).
이 파일은 모든 능력에 걸치는 것(근거·보장 요약)과 능력 → 파일 목차다.

## 이 매핑의 근거

**보장 수준은 Orca 1.4.223 의 공개 계약(`orca agent-context --json`)이 무엇을 약속하는지 읽은 결과다.**
「1.4.198 관측」이라고 적은 줄만 실제 사용에서 본 것이고, 지금 버전에서 다시 확인한 것은 아니다.
계약이 약속하지 않은 것을 "아마 된다" 로 올려 적지 않는다. 세부 시그니처의 정본은 `orca agent-context --json` 이다.

앱을 쓰는 사용자의 환경이 전제다 — `orca status --json` 이 런타임을 보여 줘야 한다. 없으면 사용자가 앱을 띄운다(`orca open`).

## 보장 요약 (네 가지 증명 대상)

| 증명 대상 | 수준 | 근거 |
| --- | --- | --- |
| 본문이 정확히 한 번 전달됐다 | **관측** | `orca terminal send --wait-submit` 이 수락과 제출 관측을 나눠 돌려주고 `--retry-request` 가 같은 요청의 중복을 막는다. 세션 기록에 정확히 1건 들어갔다는 값은 없다 |
| 이 pane 이 맡긴 그 pane 이다 (세대 불변) | **공백** | pane 의 세대 값을 돌려주는 명령이 없다. `worker-release` 가 증명되지 않은 신원을 닫지 않는 것은 닫기를 제한하는 정책이고, 호출자가 교체 여부를 가려낼 값이 아니다 |
| 보고가 오래된 시도에서 온 게 아니다 | **증명(활성 task/dispatch id 대조까지)** | `orca orchestration send --type worker_done` 은 활성 task/dispatch id 로, dispatched pane 에서만 Task 를 완료시킨다. 안정적인 pane 신원이 없으면 발신 handle 이 assignee 와 일치해야 한다. **주입 뒤 pane 이 교체된 경우를 가려낼 값은 없다** |
| 사람 개입 흔적 | **관측(+ 계약 한 조각)** | `terminal read` 화면(H2). `worker-show` 의 `observation.agentWait` 가 사람만 답할 수 있는 프롬프트에 멈춘 워커를 근거와 함께 알려 준다. null 은 "보았고 없었다", **필드 부재는 "보지 않았다"** 이다 |

## 능력 → 파일

능력 절은 **그 능력을 쓸 때 그 파일만** 연다 — 이 폴더를 통째로 읽지 않는다.

| 능력 | 파일 |
| --- | --- |
| 『전제 점검』 | [preflight.md](preflight.md) |
| 『세션 기동』 | [session-start.md](session-start.md) |
| 『준비 대기』 | [ready-wait.md](ready-wait.md) |
| 『본문 주입』 | [inject.md](inject.md) |
| 『감독 워커 기동』 | [supervised-worker.md](supervised-worker.md) |
| 『완료 감지』 | [completion.md](completion.md) |
| 『질의응답』 | [qa.md](qa.md) |
| 『화면 관측』 | [screen.md](screen.md) |
| 『회수·정리』 | [cleanup.md](cleanup.md) |
| 『세션 기록 오라클』 | [session-record.md](session-record.md) |
| 『제어 문맥 격리』 | [isolation.md](isolation.md) |
