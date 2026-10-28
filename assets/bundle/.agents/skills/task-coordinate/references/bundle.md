<!-- paddock:fixed -->
# 묶음 코디 절차 (체크포인트 feature worktree 세션에서 실행)

**묶음 코디 절차의 원본은 이 파일 하나다.** task-start(체크포인트 시작·자식 시작)와 task-coordinate(§8 묶음 자식)는 이리로 가리키기만 한다.
묶음 코디 = 서로 의존하는 작업 묶음(체크포인트) 하나를 맡는 코디네이터. feature worktree(`{{WORKTREE_DIR}}/{{ISSUE_PREFIX}}-MMM-<슬러그>`,
`{{BUNDLE_PREFIX}}{{ISSUE_PREFIX}}-MMM-<슬러그>` 체크아웃)에서 돈다. **한 묶음에 묶음 코디는 하나다** — task-start 가 띄우고, 활성 묶음 코디가 있으면 새로 만들지 않는다.
재개된 묶음 코디는 `00-start.md` 이력의 마지막 상태와 feature PR 유무로 이어 갈 절을 정한다.
<!-- paddock:module l3 -->
PR 이 열려 있으면 6 의 「출고 중 수정」으로 간다.
<!-- /paddock:module -->
작업 폴더는 체크포인트 폴더 `{{SPECS_ROOT}}/{{ISSUE_PREFIX}}-MMM-<슬러그>/`(절대경로)다.

**이 문서에는 도구 명령이 없다.** 제어 도구 동작은 능력 이름(겹낫표)으로만 적고 명령은 선택한 하네스 매핑에서 읽는다(`.agents/harness/capabilities.md`).
git 명령 블록은 그대로 쓴다. 아래의 SendMessage(세션 목록 ListAgents)는 하네스 능력이 아니라 AGENTS.md 「세션 간 통신」의 claude↔claude 보조 통로다.

## 1. task-coordinate 중 무엇을 따르나

[task-coordinate](../SKILL.md) 의 절 가운데 묶음 코디가 따르는 것:

| task-coordinate | 묶음 코디 |
| --- | --- |
| §0 실제 세션 확인 | 따른다 — `00-start.md` 는 체크포인트 폴더의 것 |
| §1 분석 · §2 판정 기준 · §3 킥오프 · 게이트 ⓪ | **분해 전이면** 묶음 단위로 따른다(아래 2) — 분해가 끝났으면 하지 않는다 |
| §4 구현 · §5 코드 리뷰 · §6 판정 · §7 게이트 ① | 하지 않는다 — 자식 코디 몫. 묶음 코디는 구현 워커·리뷰어를 띄우지 않는다 |
| §8 게이트 ②·PR·정리 | 자식 몫은 자식 코디가 한다(`task-finish.sh --into`). 묶음 마무리는 아래 6 |
| 경로(경량/전체) | 묶음에는 없다 — 자식마다 그 자식의 게이트 ⓪ 에서 정한다 |

일감 상태 전이(트래커를 쓸 때): 진행 중 전이는 task-start 5단계를 실행한 쪽이 한다 — 체크포인트는 묶음 코디를 띄운 본체, 자식은 그 자식을 시작한 묶음 코디(3 절).
그 뒤 자식의 전이(분석 중·개발 중·검증 중)는 자식 코디가 한다.
<!-- paddock:module l3 -->
체크포인트·자식의 완료 전이는 출고(release §7)다.
<!-- /paddock:module -->
체크포인트 자신은 진행 중에 둔다 — 분해 전이라 §1 을 따를 때도 §1 첫 줄의 분석 중 전이는 하지 않는다.

## 2. 분해 — 분해 전일 때만

- `00-start.md` 의 분해 상태가 `분해 전` 이면 §1~§3 을 묶음 단위로 한다: 체크포인트 본문·자식 후보 분석 → `00-analysis.md`,
  묶음 확인 기준(자식 기준이 아니라 묶음을 합쳤을 때 볼 것) → `01-criteria.md`, 분해 → `02-breakdown.md`
  (자식 목록·의존·순서·겹치는 파일·자식별 코디 도구·네이티브 관문을 쓰는 자식).
- **게이트 ⓪** 에서 분해를 보고하고 멈춘다. 승인 뒤 `00-start.md` 분해 상태를 `분해 끝` 으로 바꿔 커밋한다.
- **자식이 하나뿐이거나 0 이면** 게이트 ⓪ 에서 처리 방식을 제안한다 — 하나: feature 를 접고 독립 작업으로(feature 삭제는 사용자 확인 뒤)
  또는 feature 에서 그대로 진행 / 0(취소·분해 결과 없음): 원격·로컬 feature 와 feature worktree 삭제. 사용자 확인 없이 지우지 않는다.
- **다른 자식과 의존이 없는 자식**은 게이트 ⓪ 에서 묶음 밖({{BASE_BRANCH}} 에서 따는 독립 작업 — 본체가 task-start)으로 뺄지 정한다. 뺀 자식 목록은 4 의 묶음 → 본체 통로로 넘긴다. 독립 자식 여럿·혼합이어도 같다 —
  빼고 나서 서로 의존하는 자식이 둘 미만이면 위 「하나뿐이거나 0」 처리로 간다.
- `00-start.md` 분해 상태가 `분해 끝` 이면 누가 분해했든 분석·분해를 다시 하지 않는다 — 「이미 시작된 자식」 항목의 자식과 그 코디 세션을 확인해 3·4 의 대상에 넣는다.
  이미 시작된 자식이 있으면 이 worktree 는 뒤처져 열렸을 수 있다(자식 반영은 origin 에만 push 된다) — 먼저 5 의 첫 줄로 따라온다.
  본체가 이미 시작한 자식은 `00-start.md` 에 묶음 코디 연락처가 없다 — 묶음 코디가 4 의 통로로 자기 연락처를 한 번 알린다(자식 `00-start.md` 는 고치지 않는다).
  `02-breakdown.md` 가 없으면(본체가 분해) 이때 만들어 자식 목록과 「알림」 절만 둔다.
  `01-criteria.md`(묶음 확인 기준)가 없으면 6.1 에서 볼 묶음 기준만 이때 쓴다 — 체크포인트 본문·분해에서만 도출하고 자식 결과를 보고 쓰지 않는다.
  커밋하고 사용자에게 보고해 확인을 받는다(게이트 ⓪ 의 연장). 분해·자식 기준은 다시 하지 않는다.

## 3. 자식 시작

- **자식 task-start 는 묶음 코디가 한다.** task-start 스킬을 이 세션에서 그대로 따른다 — 분기 기준은 `origin/{{BUNDLE_PREFIX}}{{ISSUE_PREFIX}}-MMM-<슬러그>`,
  상위 지정은 이 feature worktree.
- **worktree 는 task-start 2단계 블록 그대로 본체 기준 절대경로로 만든다.** 이 세션의 cwd 는 feature worktree 라
  상대경로 `{{WORKTREE_DIR}}/…` 는 feature worktree 아래로 풀려 중첩된다(AGENTS.md 「중첩 금지」).
- 자식 `00-start.md` 는 시작한 묶음 코디가 쓰고 킥오프 전달 *전* 에 그 자식 폴더만 커밋한다(task-start 3·6단계). 전달 뒤 자식 폴더·자식 `00-start.md` 는
  **자식 코디 것** — 묶음 코디는 고치지 않는다. 묶음 코디가 쓰고 커밋하는 것은 자기 폴더(`02-breakdown.md` 등)와 전달 전 자식 `00-start.md` 뿐이다.
- 자식 `00-start.md` 에 **묶음 코디 연락처**(묶음 코디의 도구·세션 이름·handle)를 적는다 — 자식 코디가 반영 알림(task-coordinate §8)을 보낼 주소다.
- 시작 순서는 `02-breakdown.md` 를 따른다. 겹치는 파일이 있는 자식은 앞 자식이 feature 에 반영된 뒤 시작하거나, 동시면 겹치는 자리를 양쪽 킥오프에 적는다.

## 4. 감독·조율

- **게이트는 자식 코디가 사용자에게 직접 보고한다** — 묶음 코디는 자식의 게이트 ⓪①② 를 대신하지 않는다.
- 조율 대상: 겹치는 파일·반영 순서·**네이티브 관문 직렬**(task-coordinate §3 격리 규칙의 직렬 자원을 쓰는 관문은 한 번에 한 자식). 순서를 정하면 `02-breakdown.md` 에 적고 해당 자식 코디에게 알린다.
- 자식 코디 세션 상태는 『화면 관측』으로 본다 — 관측일 뿐 처리 여부의 증명은 아니다(관측 외 수단이 없는 매핑에서도 유일한 관측 수단으로 쓸 수 있다).
- **연락**:
  - claude 묶음 코디 ↔ claude 자식 코디: SendMessage. 주소는 세션 이름이다 — 자식 `00-start.md` 의 연락처, 없으면 세션 목록(ListAgents)에서 확인한다.
  - **한쪽이라도 claude 가 아니면 SendMessage 는 공백이다**(claude↔claude 한정). 묶음 → 자식은 알릴 내용을 `02-breakdown.md` 「알림」 절에 번호를 붙여 적어 커밋하고,
    자식 세션이 입력 대기일 때 『본문 주입』으로 그 항목을 읽으라는 한 줄만 넣는다 — 일하는 중인 세션에는 넣지 않는다. 그 한 줄에는 항목 번호·시각을 넣어
    매번 다르게 한다(같은 본문 재주입은 매핑이 거절할 수 있다).
  - **통로가 공백인 방향은 사람이 전달한다** — claude 가 아닌 도구가 낀 자식 → 묶음에는 통로가 없다: 자식 코디는 반영 알림을 게이트 ② 보고에
    「묶음 코디에게 반영 시작을 알려 달라」로 적어 사용자에게 맡긴다. 본체 → 묶음(task-start 2단계 「그 세션에 넘긴다」)은 둘 다 claude 면 SendMessage,
    아니면 묶음 코디가 입력 대기일 때 『본문 주입』, 그것도 공백인 매핑이면 사용자 전달이다.
    묶음 → 본체(2 의 묶음 밖으로 뺀 자식)도 같은 순서다 — 둘 다 claude 면 SendMessage, 아니면 본체가 입력 대기일 때 『본문 주입』, 공백이면 사용자 보고에 적어 전달을 맡긴다.
<!-- paddock:module l3 -->
    6 의 출고 중 수정 반영 통지도 같은 통로다.
<!-- /paddock:module -->
  - 보장 수준: 배달은 매핑의 『본문 주입』 수준을 따른다. 받은 쪽이 읽고 처리했다는 확인은 어느 매핑에서도 공백이다.
- **반영 알림**(task-coordinate §8): 자식 코디는 `task-finish.sh --into` 직전에 알린다 — 반영과 정리가 한 명령이라 알림은 **반영 시작(결과 미확정)** 이다.
  묶음 코디는 원격 feature 가 이 worktree 의 `HEAD` 와 다른 것을 본 뒤에야 반영으로 본다 — 묶음 코디는 자기 커밋을 바로 push 하므로(5)
  다르면 자식이 push 한 것이다. 알림 시점과 무관하게 판정된다. 같으면 아직이다 — 잠시 뒤 다시 보고, 계속 같으면 자식 코디(세션이 남아 있으면)나 사용자에게 확인한다.
  `--into` 가 멈추면(merge 충돌 등) 정리 전이라 자식 세션이 남는다 — 자식 코디가 정정 알림을 보낸다.
  ```bash
  R="$(git ls-remote --exit-code origin refs/heads/{{BUNDLE_PREFIX}}{{ISSUE_PREFIX}}-MMM-<슬러그>)" && [ "$(echo "$R" | cut -f1)" != "$(git rev-parse HEAD)" ]    # exit 0 = 반영됨 · 1 = 아직 · 2 = 원격 feature 없음(반영 아님)
  ```
- 자식 폴더를 고쳐야 할 일이 보이면 고치지 않고 그 자식 코디에게 알린다.

## 5. feature worktree 따라가기

자식이 `task-finish.sh --into` 로 feature 에 반영하면(임시 worktree 에서 merge·push — 이 worktree 는 그대로다) 이 worktree 를 따라 올린다.
{{BASE_BRANCH}} 가 움직였으면 {{BASE_BRANCH}} 를 feature 로 merge 해 push 한다 — **rebase 금지**(자식 worktree 가 살아 있다). merge 가 멈추면 이 worktree 에서 풀고 커밋한다.

```bash
git pull --ff-only origin {{BUNDLE_PREFIX}}{{ISSUE_PREFIX}}-MMM-<슬러그>        # 자식 반영 뒤
git fetch origin {{BASE_BRANCH}} && git merge origin/{{BASE_BRANCH}} && git push origin {{BUNDLE_PREFIX}}{{ISSUE_PREFIX}}-MMM-<슬러그>   # {{BASE_BRANCH}} 가 움직였을 때
```

## 6. 묶음 마무리 — 마지막 자식이 feature 에 반영된 뒤

자식 코디는 자기 정리(`task-finish.sh --into`)까지만 한다. 그 뒤는 묶음 코디다.

1. 5 대로 feature worktree 를 올리고 **묶음 통합 확인** — 이 worktree 에서 빌드·실행해 `01-criteria.md` 의 묶음 기준을 확인하고
   사용자에게 직접 실행·확인을 요청한다(실행 방법 한 줄 — task-coordinate §8 의 통합 결과 확인 방법).
2. 묶음 폴더에 `verdict.md`(자식 판정 링크·묶음 확인 결과 — 판정표는 `.agents/rules/validation.md` 7칸)·`pr.md`(자식들을 묶어 task-coordinate §8 의 PR 원고 방식으로)·
   `handoff-main.md`(PR base `{{BASE_BRANCH}}`, 실린 자식 일감, 트래커 다음 전이)를 쓴다.
<!-- paddock:module l3 -->
   출고 회고(release §4)는 이 `verdict.md` 의 자식 판정 링크로 자식 폴더를 찾는다.
<!-- /paddock:module -->
3. **⛔ 출고 승인 게이트** — 보고하고 멈춘다(PR 생성 전). 승인이 오면 묶음 폴더를 커밋하고
<!-- paddock:module specs-repo -->
   push 한 뒤
<!-- /paddock:module -->
   이 feature worktree 에서 `scripts/task-pr.sh {{BUNDLE_PREFIX}}{{ISSUE_PREFIX}}-MMM-<슬러그>` 로 feature → {{BASE_BRANCH}} PR 하나를 연다.
4. **정리까지 한다.** 정리는 feature worktree 를 지우므로 **묶음 코디 세션의 마지막 실행**이다 — 이후 도구 호출을 하지 않는다.
   `task-finish.sh` 는 feature worktree 안 실행을 거절하므로 본체 경로에서 본체의 스크립트로 돌린다:
   `cd <본체 절대경로> && scripts/task-finish.sh {{BUNDLE_PREFIX}}{{ISSUE_PREFIX}}-MMM-<슬러그>` — PR 이 있고 로컬 feature 가 원격 사본에 다 들어 있고 feature worktree 가 깨끗하고
   남은 자식(자식 worktree·feature 에 안 들어간 자식 브랜치)이 없음을 확인한 뒤 feature worktree 와 로컬 feature 브랜치를 정리한다. feature 는 원격(PR head)에 남는다.
   자식은 upstream 이 원격 feature 이거나 feature 고유 커밋을 품은 브랜치·worktree 로 센다 — **upstream 이 원격 feature 가 아니고(`--no-track` 으로 땄거나 뒤에 `push -u` 로 바뀜)
   feature 의 첫 고유 커밋보다 먼저 딴 자식은 못 센다**. 자식 중 하나라도 `push -u`·`--no-track` 을 썼고 첫 자식 반영 전에 딴 것이면 정리 전에 `git worktree list` 로 자식 worktree 를 직접 본다.
   남은 자식이 있으면 멈춘다 — 그 자식의 `--into` 를 기다리거나 사용자에게 보고한다. 스크립트가 실패하면 멈추고 원문을 보고한다 — 남은 정리는 같은 명령으로 이어 간다(멱등).
   사용자에게 스크립트 출력 원문과 함께 PR 번호·`handoff-main.md` 절대경로를 보고하고 "PR 생성·정리 완료"라고 끝낸다.
<!-- paddock:module l3 -->
   "출고 대기"를 덧붙인다. **묶음 코디의 수명은 여기까지다** — 출고는 본체(release).
<!-- /paddock:module -->
<!-- paddock:module l3 -->
5. **출고 중 수정**(release §2)이 묶음 PR 에 필요하면: 본체가 feature worktree 를 **다시 열고** 묶음 코디를 재기동한다 — task-start 2단계 「체크포인트 시작」의
   feature 가 이미 있는 경우(만들기·push 는 건너뛰고 feature worktree 블록 `git worktree add "$ROOT/{{WORKTREE_DIR}}/{{ISSUE_PREFIX}}-MMM-<슬러그>" {{BUNDLE_PREFIX}}{{ISSUE_PREFIX}}-MMM-<슬러그>` 와 묶음 코디만).
   로컬 feature 가 없어도 원격 feature(PR head)에서 추적 브랜치를 만들어 연다. 재기동된 묶음 코디는 머리의 재개 규칙(열린 PR)으로 이 절에 온다.
   정리(이 절 4)를 마친 옛 묶음 코디 세션은 작업 폴더(feature worktree)가 사라졌으므로 쓰지 않는다 — 남아 있으면 『회수·정리』로 닫고 새로 기동한다.
   묶음 코디는 수정 자식을 feature 에서 시작해(3 절) 반영을 받고(5 절) feature 를 push 하고, 이 절 2 에서 쓴 `verdict.md` 자식 판정 링크와 `handoff-main.md` 실린 자식에 수정 자식을 더해 커밋·push 한 뒤 본체에 알린다(4 절의 묶음 → 본체 통로) — 본체가 같은 PR 을 다시 `gather` 한다.
   알린 뒤 이 절 4 의 정리를 다시 한다(마지막 실행).
<!-- /paddock:module -->
