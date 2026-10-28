#!/usr/bin/env bash
# assets/l1/scripts/task-finish.sh (+ task-pr.sh) 시험 — paddock 레포 자체 시험(대상 레포에는 깔리지 않는다).
# 일회용 bare origin + clone(= 「본체」 B, fixture 의 .paddock/config.sh 를 쓴다) + 가짜 gh(이 폴더의 fake-gh.sh) 로 케이스별로 돈다.
# scripts/l1-tests/task-finish-test.sh [--script <task-finish.sh 사본>] [--out <원자료 폴더>] [케이스 …]   (케이스 생략 = 전부, 목록은 ALL)
#   --script : 시험할 스크립트(기본: assets/l1/scripts/task-finish.sh). 옛 판과 결과를 비교할 때 `git show <커밋>:assets/l1/scripts/task-finish.sh` 로 꺼낸 파일을 준다
#              P 케이스(task-pr.sh)는 같은 폴더의 task-pr.sh 를 쓴다
#   --out    : 케이스마다 <케이스>.txt(정규화한 출력·종료코드·실행 뒤 상태)를 남긴다 — 두 판의 --out 을 diff 하면 회귀 비교가 된다
# 실제 GitHub·본체 checkout·사용자 환경 무접촉: PATH 앞에 가짜 gh 를 둔다. 세션 정리 훅은 본체 fixture 안의 가짜 훅이다.
# 사용자 git 설정은 끊는다(하네스 전용 전역 설정). 커밋 시각을 고정해 두 판의 해시가 같게 한다.
# fixture 의 일감 ID 접두는 TASK(시험값일 뿐), config 는 케이스가 CFG_PREFIX·CFG_MODULES·CFG_FOOTER 로 바꾼다(기본: 접두 TASK · 모듈 "l1 l2 specs-repo bundle").
# 양성 대조: TF_MUTANT=<가드 이름> 이면 B 의 사본에서 「# guard:<이름>」 줄의 die 를 true 로 바꾼다 — 그 가드의 케이스가 FAIL 해야 한다.
#   die 가 아닌 장치(f-up 자식 upstream 신호 · f-release release/* 제외 · f-lease --force-with-lease · f-prune 등록 치우기 · f-no-force remove 에 --force 없음 ·
#   s-hook 세션 정리 훅 호출)는 아래 mutate() 의 줄별 sed 로 끈다.
#   변이가 사본을 바꾸지 못하면(표지·식이 어긋남) 시험을 돌리지 않고 exit 2.
#   가드 이름 전부는 `grep -o 'guard:[a-z-]*' assets/l1/scripts/task-finish.sh`. 멈춤 케이스는 사유 문구까지 본다 — 다른 가드나 git 의 거절이 같은 모양으로 대신 막으면 변이가 산다.
# 이름에 LIMIT 이 든 케이스는 알려진 한계의 현 동작을 고정한다(기대 = 못 막음). 한계가 풀리면 그 케이스를 멈춤 케이스로 바꾼다.
# 임시 폴더는 /tmp/tft.XXXXXX(짧은 고정 접두), 끝나면 지운다. 종료코드 0 = 전부 PASS.
set -uo pipefail

ALL="C1a C1b C1c C1c-other-bundle C1c-integration C1d C1e
C1c-release-gathered
C2a C2b C2b-nolocal C2c C2d C2e C2f C2f-merged C2f-variant C2f-variant-only C2f-pushu C2f-notrack C2f-localstart C2f-detached
C2f-empty-feature-block C2f-throwaway-wt C2f-LIMIT-notrack-before-first-commit C2f-LIMIT-pushu-before-first-commit
C2g C2g-empty-feature-block C2h-root C2h-sub C2h-elsewhere C2-main-checkout C2-wt-detached-head C2i C2j C2k
C2-fetch-fail C2-gh-fail C2-base-open-missing C2-base-merged-missing
C3a C3b-lock C3b-delete C3-lsremote-fail C3-late-commit C3-late-dirty C3-merged-remote-ahead C3-push-race
C4a C4b C4b-prunable C4b-prunable-main-ahead
C5a C5b C5c C5d
C6a C6a-into C6b C6c
C7a C7b C7c C7d C7e
C8a C8b C8c
C9a C9b C9c
P1 P2 P3 P4 P5 P6 P7"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
SCRIPT="$ROOT/assets/l1/scripts/task-finish.sh"; OUT=""; CASES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --script) SCRIPT="${2:?--script 값 없음}"; shift 2 ;;
    --out) OUT="${2:?--out 값 없음}"; shift 2 ;;
    -*) echo "모르는 옵션: $1" >&2; exit 2 ;;
    *) CASES="$CASES $1"; shift ;;
  esac
done
CASES="${CASES:-$ALL}"
[ -f "$SCRIPT" ] || { echo "스크립트 없음: $SCRIPT" >&2; exit 2; }
FAKE_GH="$HERE/fake-gh.sh"
PR_SCRIPT="$(dirname "$SCRIPT")/task-pr.sh"
[ -f "$PR_SCRIPT" ] || { echo "task-pr.sh 없음: $PR_SCRIPT" >&2; exit 2; }
[ -f "$FAKE_GH" ] || { echo "가짜 gh 없음: $FAKE_GH" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq 필요(가짜 gh)" >&2; exit 2; }
[ -z "$OUT" ] || { mkdir -p "$OUT" && OUT="$(cd "$OUT" && pwd)"; } || exit 2
MUT="${TF_MUTANT:-}"
WORK="$(mktemp -d /tmp/tft.XXXXXX)" || exit 2
WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/gitconfig" <<EOF
[user]
	name = tft
	email = tft@example.invalid
[commit]
	gpgsign = false
[init]
	defaultBranch = main
[advice]
	detachedHead = false
EOF
export GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_DATE="2026-10-28T00:00:00+0000" GIT_COMMITTER_DATE="2026-10-28T00:00:00+0000"
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
echo "# task-finish-test $(date '+%F %T') · $(git --version) · /bin/bash $(/bin/bash -c 'echo $BASH_VERSION') · script sha1 $(shasum < "$SCRIPT" | cut -c1-12) · work $WORK${MUT:+ · 변이 $MUT}"

# 케이스마다 루프가 되돌리는 기본값(ID 접두 모드)
default_names() { CFG_PREFIX=TASK; CFG_MODULES="l1 l2 specs-repo bundle"; CFG_FOOTER=""; F=feature/TASK-900-x; FN=TASK-900-x; }
default_names

mutate() { # 표준입력 → 변이 사본
  case "$1" in
    noid-variant) sed '/# guard:noid-variant$/ s/is_throwaway "\$v" \&\& KEPT/KEPT/' ;;
    s-hook) sed '/# guard:s-hook$/ s/"\$HOOK" "\$TASK" ||/true ||/' ;;
    f-up) sed '/# guard:f-up$/ s/\[ "\$up" = "refs\/remotes\/origin\/\$TASK" \] ||/false ||/' ;;
    f-release) sed '/# guard:f-release$/ s/|release\/\*//' ;;
    f-no-force) sed 's/git worktree remove "\$w" ||/git worktree remove --force "$w" ||/' ;;
    f-prune) sed '/# guard:f-prune$/ s/git worktree prune/true/' ;;
    f-lease) sed '/# guard:f-lease$/ s/--force-with-lease=refs\/heads\/\$TASK:\$ROID/--force/' ;;
    *) sed "/# guard:$1\$/ s/die \"/true \"/" ;;
  esac
}
if [ -n "$MUT" ] && mutate "$MUT" < "$SCRIPT" | cmp -s - "$SCRIPT"; then echo "변이 미적용: $MUT — 표지나 mutate() 식이 어긋났다" >&2; exit 2; fi
setup() { # 새 fixture: origin(bare) · B(본체) · H(도우미 clone) · bin(가짜 gh)
  W="$WORK/$CASE"; mkdir -p "$W/bin" "$W/gh/pr"
  O="$W/origin.git"; B="$W/B"; H="$W/H"; WT="$B/.claude/worktrees"; FWT="$WT/$FN"
  git init -q --bare "$O"
  git clone -q "$O" "$B" 2>/dev/null
  printf '.claude/worktrees/\nspecs/\n' > "$B/.gitignore"
  echo a > "$B/a"
  git -C "$B" add -A; git -C "$B" commit -qm init; git -C "$B" push -q origin HEAD:main
  # 시험 대상 사본·설정은 커밋하지 않는다(info/exclude) — 판이 달라도 fixture 해시가 같아야 --out 비교가 된다
  mkdir -p "$B/scripts" "$B/.paddock"; printf '/scripts/\n/.paddock/\n/.agents/\n' >> "$B/.git/info/exclude"
  if [ -n "$MUT" ]; then mutate "$MUT" < "$SCRIPT" > "$B/scripts/task-finish.sh"
  else cp "$SCRIPT" "$B/scripts/task-finish.sh"; fi
  cp "$PR_SCRIPT" "$B/scripts/task-pr.sh"
  write_config
  git clone -q "$O" "$H" 2>/dev/null
  cp "$FAKE_GH" "$W/bin/gh"; chmod +x "$W/bin/gh"
  N=0
}
write_config() { # 본체의 .paddock/config.sh — CFG_* 가 값. SPECS_ROOT 는 P 케이스의 산출물 레포(본체 옆 specs)
  {
    echo "PADDOCK_VERSION=0.0.0-test"
    echo "PADDOCK_MODULES=\"$CFG_MODULES\""
    echo "ISSUE_PREFIX=$CFG_PREFIX"
    echo "BASE_BRANCH=main"
    echo "WORKTREE_DIR=.claude/worktrees"
    echo "BUNDLE_PREFIX=feature/"
    echo "SPECS_ROOT=../specs"
    [ -z "$CFG_FOOTER" ] || echo "PR_FOOTER='$CFG_FOOTER'"
  } > "$B/.paddock/config.sh"
}
# 세션 정리 훅(L2 매핑이 제공하는 자리) 가짜 — mk_hook [fail]: 받은 인자를 hook-calls.txt 에 남긴다. fail 이면 exit 1
mk_hook() {
  mkdir -p "$B/.agents/harness"
  printf '#!/bin/sh\necho "hook $*" >> "%s/hook-calls.txt"\nexit %s\n' "$W" "$([ "${1:-}" = fail ] && echo 1 || echo 0)" > "$B/.agents/harness/session-cleanup.sh"
  chmod +x "$B/.agents/harness/session-cleanup.sh"
}
gh_() { ( cd "$B" && env PATH="$W/bin:$PATH" FGH_STATE="$W/gh" FGH_ORIGIN="$O" gh "$@" ); }
pr() { printf 'state=%s\nbase=%s\nhead=%s\n' "$2" "${4:-main}" "$3" > "$W/gh/pr/$1"; } # pr <번호> <상태> <head> [base]
commit_in() { echo "$2" > "$1/$2"; git -C "$1" add -A; git -C "$1" commit -qm "$2"; }   # commit_in <worktree> <파일>
# 체크포인트 시작(task-start 2단계 체크포인트 블록): origin feature + feature worktree + 커밋 1개 push + OPEN PR #1
mk_feature() {
  git -C "$B" branch -q --no-track "$F" origin/main; git -C "$B" push -q -u origin "$F" 2>/dev/null
  git -C "$B" worktree add -q "$FWT" "$F"
  commit_in "$FWT" f1; git -C "$FWT" push -q origin "$F"
  pr 1 OPEN "$F"
}
# 자식(task-start 2단계 블록, origin/feature 에서): mk_child <이름> — 커밋 1개(push 안 함)
mk_child() { git -C "$B" fetch -q origin; git -C "$B" worktree add -q "$WT/$1" -b "$1" "origin/$F" 2>/dev/null; commit_in "$WT/$1" "c-$1"; }
mk_indep() { git -C "$B" worktree add -q "$WT/$1" -b "$1" main 2>/dev/null; commit_in "$WT/$1" "i-$1"; }   # 독립 작업(main 에서)
mk_release() { git -C "$B" worktree add -q --no-track -b release/v0.0.1 "$WT/release-v0.0.1" origin/main; }
merge_feature_to_main() { # 출고 흉내: origin main 에 feature 를 merge commit 으로(가짜 gh 가 간접 머지로 PR 을 MERGED 로 본다)
  git -C "$H" fetch -q origin; git -C "$H" checkout -q -B main origin/main
  git -C "$H" merge -q --no-ff -m "Merge $F" "origin/$F"; git -C "$H" push -q origin main
}

# 상태 스냅샷 — 무변경 판정과 --out 비교용. 경로는 <W> 로 정규화
snap() {
  {
    echo "## worktrees"; git -C "$B" worktree list --porcelain | grep -E '^(worktree|branch|detached|locked)'
    echo "## local heads"; git -C "$B" for-each-ref refs/heads --format='%(refname) %(objectname)'
    echo "## origin heads"; git --git-dir="$O" for-each-ref refs/heads --format='%(refname) %(objectname)'
    echo "## PR"; gh_ pr list --state all --json number,state,headRefName,headRefOid --jq '.[] | "\(.number) \(.state) \(.headRefName) \(.headRefOid)"'
  } 2>&1 | sed "s#$W#<W>#g"
}
# run [--cwd <폴더>] <인자…> — B 의 사본(RUN_SCRIPT, 기본 task-finish.sh)을 /bin/bash(3.2)로 실행. RC·LAST(출력)
RUN_SCRIPT=task-finish.sh
run_pr() { RUN_SCRIPT=task-pr.sh; run "$@"; RUN_SCRIPT=task-finish.sh; }
run() {
  local cwd="$B"
  [ "$1" = --cwd ] && { cwd="$2"; shift 2; }
  N=$((N + 1)); LAST="$W/run-$N.txt"
  snap > "$W/before-$N.txt"
  ( cd "$cwd" && env PATH="$W/bin:$PATH" FGH_STATE="$W/gh" FGH_ORIGIN="$O" /bin/bash "$B/scripts/$RUN_SCRIPT" "$@" ) > "$LAST" 2>&1
  RC=$?
  snap > "$W/after-$N.txt"
  { echo "\$ $RUN_SCRIPT $* (cwd ${cwd#$W/})"; sed "s#$W#<W>#g" "$LAST"; echo "exit=$RC"; } >> "$LOG"
}

check() { # check <설명> <명령…>
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "  ok   $d" >> "$LOG"; else echo "  FAIL $d" >> "$LOG"; CASE_FAIL=1; fi
}
has() { grep -qF -- "$1" "$LAST"; }
not() { ! "$@"; }
unchanged() { cmp -s "$W/before-$N.txt" "$W/after-$N.txt"; }
rc_is() { [ "$RC" = "$1" ]; }
rc_fail() { [ "$RC" != 0 ]; }
no_wt() { [ ! -d "$1" ] && ! git -C "$B" worktree list --porcelain | grep -qx "worktree $1"; }
is_wt() { git -C "$B" worktree list --porcelain | grep -qx "worktree $1"; }
no_local() { ! git -C "$B" rev-parse -q --verify "refs/heads/$1" >/dev/null; }
is_local() { git -C "$B" rev-parse -q --verify "refs/heads/$1" >/dev/null; }
remote_oid() { git --git-dir="$O" rev-parse -q --verify "refs/heads/$1" 2>/dev/null; }
pr_state() { [ "$(gh_ pr list --state all --head "$2" --json state --jq '.[0].state')" = "$1" ]; }
no_success() { ! grep -q '^✔' "$LAST"; }
last_line_next() { tail -1 "$LAST" | grep -q '^□ 다음'; }
stopped() { check "exit ≠ 0" rc_fail; check "사유 줄(✖)" has "✖"; check "✔ 없음" no_success; check "무변경" unchanged; }

# ---- 묶음 경로 정상 ----
case_C1a() { setup; mk_feature; local oid; oid="$(remote_oid "$F")"
  run "$F"
  check "exit 0" rc_is 0; check "feature worktree 사라짐" no_wt "$FWT"; check "로컬 feature 사라짐" no_local "$F"
  check "원격 feature 그대로" [ "$(remote_oid "$F")" = "$oid" ]; check "PR OPEN" pr_state OPEN "$F"; check "✔" has "✔ $F 정리 완료"
  check "branch.<feature> 설정 지움" not git -C "$B" config --get-regexp "^branch\\.$F\\."; }
case_C1b() { setup; mk_feature  # 자식이 --into 로 origin feature 를 앞으로 보냈고 로컬 feature 는 뒤
  git -C "$H" fetch -q origin; git -C "$H" checkout -q -B "$F" "origin/$F"; commit_in "$H" child-merged; git -C "$H" push -q origin "$F"
  local oid; oid="$(remote_oid "$F")"
  run "$F"
  check "exit 0" rc_is 0; check "feature worktree 사라짐" no_wt "$FWT"; check "로컬 feature 사라짐" no_local "$F"
  check "원격 feature 그대로" [ "$(remote_oid "$F")" = "$oid" ]; check "PR OPEN" pr_state OPEN "$F"; }
case_C1c() { setup; mk_feature; mk_indep TASK-901-i; mk_release
  local i r; i="$(git -C "$B" rev-parse TASK-901-i)"; r="$(git -C "$B" rev-parse release/v0.0.1)"
  run "$F"
  check "exit 0" rc_is 0; check "feature worktree 사라짐" no_wt "$FWT"; check "로컬 feature 사라짐" no_local "$F"
  check "독립 worktree 남음" is_wt "$WT/TASK-901-i"; check "독립 브랜치 그대로" [ "$(git -C "$B" rev-parse TASK-901-i)" = "$i" ]
  check "release worktree 남음" is_wt "$WT/release-v0.0.1"; check "release 브랜치 그대로" [ "$(git -C "$B" rev-parse release/v0.0.1)" = "$r" ]; }
case_C1c-other-bundle() { setup; mk_feature   # 다른 묶음의 자식은 세지 않는다
  git -C "$B" branch -q --no-track feature/TASK-901-y origin/main; git -C "$B" push -q -u origin feature/TASK-901-y 2>/dev/null
  git -C "$B" fetch -q origin; git -C "$B" worktree add -q "$WT/TASK-902-k" -b TASK-902-k origin/feature/TASK-901-y 2>/dev/null; commit_in "$WT/TASK-902-k" kk
  run "$F"; check "exit 0" rc_is 0; check "feature worktree 사라짐" no_wt "$FWT"; check "다른 묶음 자식 worktree 그대로" is_wt "$WT/TASK-902-k"; }
case_C1c-integration() { setup; mk_feature   # origin/feature 에서 딴 throwaway(고유 커밋 없음, worktree 없음) — 안내만 하고 정리한다
  git -C "$B" fetch -q origin; git -C "$B" branch -q throwaway-x-20261028 "origin/$F"
  run "$F"; check "exit 0" rc_is 0; check "feature worktree 사라짐" no_wt "$FWT"; check "integration 브랜치 그대로" is_local throwaway-x-20261028; check "남은 브랜치 안내" has "throwaway-x-20261028 가 남아 있다"; }
case_C1c-release-gathered() { setup; mk_feature; mk_release   # 출고 중 수정 뒤 재정리: release 브랜치가 feature 를 gather 해 feature 고유 커밋을 품는다 — 세지 않는다
  git -C "$WT/release-v0.0.1" merge -q --no-ff -m gather "origin/$F"; local r; r="$(git -C "$B" rev-parse release/v0.0.1)"
  run "$F"; check "exit 0" rc_is 0; check "feature worktree 사라짐" no_wt "$FWT"; check "release worktree 남음" is_wt "$WT/release-v0.0.1"; check "release 브랜치 그대로" [ "$(git -C "$B" rev-parse release/v0.0.1)" = "$r" ]; }
case_C1d() { setup; mk_feature; merge_feature_to_main
  run "$F"
  check "exit 0" rc_is 0; check "PR MERGED" pr_state MERGED "$F"; check "feature worktree 사라짐" no_wt "$FWT"
  check "로컬 feature 사라짐" no_local "$F"; check "원격 feature 지움" [ -z "$(remote_oid "$F")" ]; }
case_C1e() { setup; mk_feature; mk_hook
  run "$F"
  check "exit 0" rc_is 0; check "마지막 줄 □ 다음" last_line_next
  check "gh 는 pr list 만" not grep -vE '^gh pr list ' "$W/gh/calls.txt"
  check "세션 정리 훅 호출 없음(묶음 경로)" [ ! -e "$W/hook-calls.txt" ]; }
# ---- 묶음 경로 멈춤 ----
case_C2a() { setup; mk_feature; rm -f "$W/gh/pr/1"; run "$F"; stopped; }
case_C2b() { setup; mk_feature; pr 1 CLOSED "$F"; run "$F"; stopped; check "사유 = CLOSED" has "상태가 CLOSED"; }
case_C2b-nolocal() { setup; mk_feature; git -C "$B" worktree remove "$FWT"; git -C "$B" branch -q -D "$F"; pr 1 CLOSED "$F"   # 지울 로컬이 없어도 CLOSED 는 멈춘다
  run "$F"; stopped; check "사유 = CLOSED" has "상태가 CLOSED"; }
case_C2c() { setup; mk_feature; commit_in "$FWT" unpushed; run "$F"; stopped; }
case_C2d() { setup; mk_feature; echo changed >> "$FWT/a"; run "$F"; stopped; check "사유 = 미커밋 변경(가드 — git 의 remove 거절 아님)" has "미커밋 변경"; }
case_C2e() { setup; mk_feature; echo u > "$FWT/untracked"; run "$F"; stopped; check "사유 = 미커밋 변경(가드 — git 의 remove 거절 아님)" has "미커밋 변경"; }
case_C2f() { setup; mk_feature; mk_child TASK-901-c; run "$F"; stopped; check "자식 worktree 남음" is_wt "$WT/TASK-901-c"; }
case_C2f-merged() { setup; mk_feature; git -C "$B" fetch -q origin   # 자식 worktree 는 남았고 커밋은 feature 에 다 들어 있다(브랜치 검사로는 못 막는다)
  git -C "$B" worktree add -q "$WT/TASK-901-c" -b TASK-901-c "origin/$F" 2>/dev/null
  run "$F"; stopped; check "사유 = 자식 worktree" has "자식 worktree 가 남아 있다"; }
# 블록 밖에서 딴 자식 — upstream 신호가 없어도 feature 고유 커밋으로 센다
case_C2f-pushu() { setup; mk_feature; mk_child TASK-901-c; git -C "$WT/TASK-901-c" push -q -u origin TASK-901-c 2>/dev/null   # upstream 이 origin/<자식> 으로 바뀜
  run "$F"; stopped; check "사유 = 자식 worktree" has "자식 worktree 가 남아 있다"; }
case_C2f-notrack() { setup; mk_feature; git -C "$B" fetch -q origin; git -C "$B" worktree add -q --no-track "$WT/TASK-901-c" -b TASK-901-c "origin/$F"; commit_in "$WT/TASK-901-c" cc
  run "$F"; stopped; check "사유 = 자식 worktree" has "자식 worktree 가 남아 있다"; }
case_C2f-localstart() { setup; mk_feature; git -C "$B" worktree add -q "$WT/TASK-901-c" -b TASK-901-c "$F" 2>/dev/null; commit_in "$WT/TASK-901-c" cc
  run "$F"; stopped; check "사유 = 자식 worktree" has "자식 worktree 가 남아 있다"; }
case_C2f-variant-only() { setup; mk_feature; mk_child TASK-901-c   # 자식 본 브랜치는 지웠고 구현 변형 worktree 만 남음
  git -C "$B" worktree add -q "$WT/TASK-901-c-claude" -b TASK-901-c-claude TASK-901-c; git -C "$B" worktree remove --force "$WT/TASK-901-c"; git -C "$B" branch -q -D TASK-901-c
  run "$F"; stopped; check "사유 = 자식 worktree" has "자식 worktree 가 남아 있다"; }
case_C2f-detached() { setup; mk_feature; git -C "$B" fetch -q origin; git -C "$B" worktree add -q --detach "$WT/TASK-901-d" "origin/$F"; commit_in "$WT/TASK-901-d" dd
  run "$F"; stopped; check "사유 = 브랜치 없는 worktree" has "브랜치 없는 worktree"; }
mk_empty_feature() { # feature 에 고유 커밋 없음(갓 연 묶음). 가짜 gh 가 head ⊂ main 을 간접 머지로 읽지 않게 FGH_INDIRECT=off
  export FGH_INDIRECT=off; setup; git -C "$B" branch -q --no-track "$F" origin/main; git -C "$B" push -q -u origin "$F" 2>/dev/null; git -C "$B" worktree add -q "$FWT" "$F"; pr 1 OPEN "$F"; git -C "$B" fetch -q origin; }
case_C2f-empty-feature-block() { mk_empty_feature   # 빈 feature + task-start 블록 그대로 딴 자식 — upstream 신호(ⓐ)만으로 막는다
  git -C "$B" worktree add -q "$WT/TASK-901-c" -b TASK-901-c "origin/$F" 2>/dev/null; commit_in "$WT/TASK-901-c" cc
  run "$F"; stopped; check "사유 = 자식 worktree" has "자식 worktree 가 남아 있다"; }
case_C2g-empty-feature-block() { mk_empty_feature   # 같은 자식, worktree 없이 미반영 브랜치만
  git -C "$B" worktree add -q "$WT/TASK-901-c" -b TASK-901-c "origin/$F" 2>/dev/null; commit_in "$WT/TASK-901-c" cc; git -C "$B" worktree remove "$WT/TASK-901-c"
  run "$F"; stopped; check "사유 = 자식 브랜치" has "자식 브랜치 TASK-901-c"; }
case_C2f-throwaway-wt() { setup; mk_feature; git -C "$B" fetch -q origin   # origin/feature 에서 딴 통합 확인용 throwaway worktree — 멈추고 지우라는 안내도 낸다
  git -C "$B" worktree add -q -b throwaway-x-20261028 "$WT/throwaway-x" "origin/$F" 2>/dev/null
  run "$F"; stopped; check "안내 = throwaway 면 지운다" has "통합 확인용 throwaway 면 지운 뒤 다시"; }
# 한계(현 동작 고정): upstream 이 origin/feature 가 아니고 feature 첫 고유 커밋보다 먼저 딴 자식은 못 센다
case_C2f-LIMIT-notrack-before-first-commit() { mk_empty_feature
  git -C "$B" worktree add -q --no-track "$WT/TASK-901-c" -b TASK-901-c "origin/$F"; commit_in "$WT/TASK-901-c" cc
  run "$F"; check "(한계) exit 0 — 멈추지 않는다" rc_is 0; check "(한계) 자식 worktree 는 그대로" is_wt "$WT/TASK-901-c"; check "자식 커밋 무손실" is_local TASK-901-c; }
case_C2f-LIMIT-pushu-before-first-commit() { mk_empty_feature   # 블록대로 딴 자식 B 가 push -u 로 upstream 을 바꿨고, 그 뒤 다른 자식 A 가 feature 에 첫 커밋을 넣었다
  git -C "$B" worktree add -q "$WT/TASK-901-b" -b TASK-901-b "origin/$F" 2>/dev/null; commit_in "$WT/TASK-901-b" bb; git -C "$WT/TASK-901-b" push -q -u origin TASK-901-b 2>/dev/null
  git -C "$H" fetch -q origin; git -C "$H" checkout -q -B "$F" "origin/$F"; commit_in "$H" a-merged; git -C "$H" push -q origin "$F"
  run "$F"; check "(한계) exit 0 — 멈추지 않는다" rc_is 0; check "(한계) 자식 worktree 는 그대로" is_wt "$WT/TASK-901-b"; check "자식 커밋 무손실" is_local TASK-901-b; }
case_C2f-variant() { setup; mk_feature; mk_child TASK-901-c   # 자식은 지웠는데 자식의 구현 변형 worktree 가 남았다
  git -C "$B" worktree add -q "$WT/TASK-901-c-claude" -b TASK-901-c-claude TASK-901-c; git -C "$B" worktree remove "$WT/TASK-901-c"
  run "$F"; stopped; }
case_C2g() { setup; mk_feature; mk_child TASK-901-c; git -C "$B" worktree remove "$WT/TASK-901-c"; run "$F"; stopped; }
case_C2h-root() { setup; mk_feature; run --cwd "$FWT" "$F"; stopped; check "사유 = 묶음 worktree 안" has "묶음 worktree 안에서 실행 금지"; }
case_C2h-sub() { setup; mk_feature; mkdir -p "$FWT/sub"; touch "$FWT/sub/.keep"; git -C "$FWT" add -A; git -C "$FWT" commit -qm sub; git -C "$FWT" push -q origin "$F"
  run --cwd "$FWT/sub" "$F"; stopped; check "사유 = 묶음 worktree 안" has "묶음 worktree 안에서 실행 금지"; }
case_C2h-elsewhere() { setup; mk_feature; git -C "$B" worktree remove "$FWT"; git -C "$B" worktree add -q "$WT/elsewhere" "$F"; mkdir -p "$WT/elsewhere/sub"   # 기대 경로가 아닌 worktree 하위
  run --cwd "$WT/elsewhere/sub" "$F"; stopped; check "사유 = 체크아웃한 worktree 안" has "체크아웃한 worktree"; check "cwd 그대로" [ -d "$WT/elsewhere/sub" ]; }
case_C2-main-checkout() { setup; mk_feature; git -C "$B" worktree remove "$FWT"; git -C "$B" checkout -q "$F"
  run "$F"; stopped; check "사유 = 본체 checkout" has "본체 checkout"; }
case_C2-wt-detached-head() { export FGH_INDIRECT=off; setup; mk_feature   # feature worktree 자리가 detached(main)이고 거기 커밋이 있다 — 지우면 ref 없는 커밋이 된다
  git -C "$B" worktree remove "$FWT"; git -C "$B" worktree add -q --detach "$FWT" origin/main; commit_in "$FWT" lost
  run "$F"; stopped; check "사유 = HEAD" has "HEAD 가 $F 가 아니고"; }
case_C2-fetch-fail() { setup; mk_feature
  printf '#!/bin/sh\n[ "$1" = fetch ] && { echo "fatal: 흉내 fetch 실패" >&2; exit 128; }\nexec %s "$@"\n' "$(command -v git)" > "$W/bin/git"; chmod +x "$W/bin/git"
  run "$F"; stopped; check "사유 = fetch" has "git fetch 실패"; }
case_C2-gh-fail() { setup; mk_feature; mv "$W/bin/gh" "$W/bin/gh-fake"   # 스크립트의 PR 조회(--head)만 실패, 시험의 상태 조회는 통과
  printf '#!/bin/sh\ncase " $* " in *" --head "*) [ -e "%s/gh-fail" ] && { echo "흉내 gh 실패" >&2; exit 1; } ;; esac\nexec "%s" "$@"\n' "$W" "$W/bin/gh-fake" > "$W/bin/gh"; chmod +x "$W/bin/gh"; touch "$W/gh-fail"
  run "$F"; stopped; check "사유 = gh" has "gh pr list 실패"; }
case_C2-base-open-missing() { setup; mk_feature; pr 1 OPEN "$F" develop; run "$F"; stopped; check "사유 = base 원격" has "base 원격 develop 가 없다"; }
case_C2-base-merged-missing() { setup; mk_feature; pr 1 MERGED "$F" develop; run "$F"; stopped; check "사유 = base 원격" has "base 원격 develop 가 없다"; }
case_C2i() { setup; mk_feature; run "$F" --into "$F"; stopped; }
case_C2j() { setup; mk_feature; mkdir -p "$FWT/specs"; echo r > "$FWT/specs/raw.txt"; run "$F"; stopped; check "사유 = specs" has "specs 에 파일"; }
case_C2k() { setup; mk_feature; local b n=1   # 이름 가드만 막도록 각 이름에 원격 브랜치·열린 PR 을 둔다(없으면 PR 없음 가드가 먼저 막는다)
  for b in feature/foo feature/TASK-x-y feature/TASK-901 feature/TASK-902-a/b; do
    n=$((n + 1)); git -C "$H" checkout -q -B "$b" origin/main; commit_in "$H" "k$n"; git -C "$H" push -q origin "$b"; pr "$n" OPEN "$b"
  done
  for b in feature/foo feature/TASK-x-y feature/TASK-901 feature/TASK-902-a/b; do run "$b"; stopped; check "사유 = 이름 꼴" has "꼴만 받는다"; done; }
# ---- 실패를 성공으로 적지 않는다 ----
case_C3a() { setup; mk_feature  # 옛 판 재현(00-analysis F1): ✔ 와 무변경이 함께 나오면 안 된다
  run "$F"; check "✔ 와 무변경이 함께 나오지 않는다" not eval 'grep -q "^✔" "$LAST" && unchanged'; }
case_C3b-lock() { setup; mk_feature; git -C "$B" worktree lock --reason tft "$FWT"   # 주입: 잠긴 worktree 는 remove 가 거절한다
  run "$F"; check "exit ≠ 0" rc_fail; check "✔ 없음" no_success; }
case_C3b-delete() { setup; mk_feature; merge_feature_to_main   # 주입: origin update 훅이 feature 삭제 push 를 거절한다
  printf '#!/bin/sh\n[ "$1" = "refs/heads/%s" ] && [ "$3" = 0000000000000000000000000000000000000000 ] && { echo "흉내: 삭제 거절" >&2; exit 1; }\nexit 0\n' "$F" > "$O/hooks/update"; chmod +x "$O/hooks/update"
  run "$F"; check "exit ≠ 0" rc_fail; check "✔ 없음" no_success; check "원격 feature 남음" [ -n "$(remote_oid "$F")" ]; }
case_C3-lsremote-fail() { setup; mk_feature; merge_feature_to_main   # ls-remote 만 실패 — 원격 유무를 조회 실패로 「없음」이라 읽으면 ✔ 뒤 원격이 남는다
  printf '#!/bin/sh\ncase " $* " in *" ls-remote "*) echo "fatal: 흉내 네트워크 실패" >&2; exit 128 ;; esac\nexec %s "$@"\n' "$(command -v git)" > "$W/bin/git"; chmod +x "$W/bin/git"
  run "$F"; check "✔ 와 원격 잔존이 함께 나오지 않는다" not eval 'grep -q "^✔" "$LAST" && [ -n "$(remote_oid "$F")" ]'; }
case_C3-late-commit() { setup; mk_feature   # 검사 뒤 삭제 전: 첫 worktree remove 직전 feature worktree 에 커밋이 들어온다
  printf '#!/bin/sh\nif [ "$1 $2" = "worktree remove" ] && [ ! -e "%s/injected" ]; then touch "%s/injected"; echo late > "%s/late"; %s -C "%s" add late; %s -C "%s" commit -qm late; fi\nexec %s "$@"\n' \
    "$W" "$W" "$FWT" "$(command -v git)" "$FWT" "$(command -v git)" "$FWT" "$(command -v git)" > "$W/bin/git"; chmod +x "$W/bin/git"
  run "$F"; check "exit ≠ 0" rc_fail; check "✔ 없음" no_success; check "늦은 커밋이 로컬 feature 에 남음" [ "$(git -C "$B" log -1 --format=%s "$F" 2>/dev/null)" = late ]; }
case_C3-late-dirty() { setup; mk_feature   # 검사 뒤 첫 worktree remove 직전 feature worktree 에 미추적 파일이 생긴다 — --force 없는 remove 가 거절한다
  printf '#!/bin/sh\nif [ "$1 $2" = "worktree remove" ] && [ ! -e "%s/injected" ]; then touch "%s/injected"; echo precious > "%s/precious.txt"; fi\nexec %s "$@"\n' \
    "$W" "$W" "$FWT" "$(command -v git)" > "$W/bin/git"; chmod +x "$W/bin/git"
  run "$F"; check "exit ≠ 0" rc_fail; check "✔ 없음" no_success; check "미추적 파일 보존" [ -f "$FWT/precious.txt" ]; }
case_C3-merged-remote-ahead() { setup; mk_feature; merge_feature_to_main   # MERGED 인데 출고 뒤 origin/feature 에 커밋이 더 올라갔다 — 지우기 전에 멈춘다
  git -C "$H" checkout -q -B "$F" "origin/$F"; commit_in "$H" after; git -C "$H" push -q origin "$F"; pr 1 MERGED "$F"
  run "$F"; stopped; check "사유 = 원격이 보존 위치에 없음" has "다 들어 있지 않다"; }
case_C3-push-race() { setup; mk_feature; merge_feature_to_main   # 검사 뒤 원격 삭제 push 직전에 원격 feature 가 앞으로 간다 — lease 가 막는다
  local g; g="$(command -v git)"
  printf '#!/bin/sh\nif [ "$1" = push ] && [ ! -e "%s/injected" ]; then touch "%s/injected"; %s -C "%s" fetch -q origin; %s -C "%s" checkout -q -B %s origin/%s; echo z > "%s/z"; %s -C "%s" add z; %s -C "%s" commit -qm z; %s -C "%s" push -q origin %s; fi\nexec %s "$@"\n' \
    "$W" "$W" "$g" "$H" "$g" "$H" "$F" "$F" "$H" "$g" "$H" "$g" "$H" "$g" "$H" "$F" "$g" > "$W/bin/git"; chmod +x "$W/bin/git"
  run "$F"; check "exit ≠ 0" rc_fail; check "✔ 없음" no_success; check "원격 feature 남음" [ -n "$(remote_oid "$F")" ]; }
# ---- 멱등 ----
case_C4a() { setup; mk_feature; run "$F"; run "$F"
  check "재실행 exit 0" rc_is 0; check "재실행 무변경" unchanged; check "이미 정리됨 안내" has "이미 정리됨"; }
case_C4b() { setup; mk_feature; git -C "$B" worktree remove "$FWT"   # 반쯤: worktree 는 없고 로컬 feature 만
  run "$F"; check "exit 0" rc_is 0; check "로컬 feature 사라짐" no_local "$F"; check "PR OPEN" pr_state OPEN "$F"; }
case_C4b-prunable() { setup; mk_feature; rm -rf "$FWT"   # 반쯤: feature worktree 폴더만 손으로 지웠다(git 은 prunable 등록으로 안다) — 이어서 정리
  run "$F"; check "exit 0" rc_is 0; check "로컬 feature 사라짐" no_local "$F"; check "worktree 등록 사라짐" no_wt "$FWT"; check "PR OPEN" pr_state OPEN "$F"; }
case_C4b-prunable-main-ahead() { setup; mk_feature; commit_in "$H" m1; git -C "$H" push -q origin HEAD:main; git -C "$B" fetch -q origin; rm -rf "$FWT"   # 같은 상태 + main 이 feature 보다 앞섬
  run "$F"; check "exit 0" rc_is 0; check "로컬 feature 사라짐" no_local "$F"; check "worktree 등록 사라짐" no_wt "$FWT"; }
# ---- 기존 경로 회귀(옛 판과 같은 결과여야 한다 — --out 비교) ----
case_C5a() { setup; local t=TASK-901-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null
  git -C "$B" worktree add -q "$WT/$t-claude" -b "$t-claude" "$t"; pr 1 OPEN "$t"
  run "$t"
  check "exit 0" rc_is 0; check "작업 worktree 사라짐" no_wt "$WT/$t"; check "구현 worktree 사라짐" no_wt "$WT/$t-claude"
  check "로컬 작업 브랜치 사라짐" no_local "$t"; check "로컬 구현 브랜치 사라짐" no_local "$t-claude"; check "원격 작업 브랜치 남음" [ -n "$(remote_oid "$t")" ]; }
case_C5b() { setup; mk_indep TASK-901-t; run TASK-901-t; stopped; }
case_C5c() { setup; mk_feature; local c=TASK-901-c; mk_child "$c"; local tip; tip="$(git -C "$B" rev-parse "$c")"
  run "$c" --into "$F"
  check "exit 0" rc_is 0; check "자식 worktree 사라짐" no_wt "$WT/$c"; check "로컬 자식 사라짐" no_local "$c"
  check "origin feature 에 자식이 들어감" git --git-dir="$O" merge-base --is-ancestor "$tip" "refs/heads/$F"; }
case_C5d() { setup; mk_indep TASK-901-c; run TASK-901-c --into main; stopped; }

# ---- 세션 정리 훅 (훅이 있으면 <작업 이름> 으로 부르고, 없으면 조용히 건너뛰고, 실패는 경고만) ----
case_C6a() { setup; local t=TASK-901-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null; pr 1 OPEN "$t"; mk_hook
  run "$t"
  check "exit 0" rc_is 0; check "훅이 작업 이름으로 호출됨" grep -qx "hook $t" "$W/hook-calls.txt"; check "훅은 한 번" [ "$(wc -l < "$W/hook-calls.txt" | tr -d ' ')" = 1 ]
  check "✔" has "✔ $t 정리 완료"; }
case_C6a-into() { setup; mk_feature; local c=TASK-901-c; mk_child "$c"; mk_hook
  run "$c" --into "$F"
  check "exit 0" rc_is 0; check "훅이 자식 작업 이름으로 호출됨" grep -qx "hook $c" "$W/hook-calls.txt"; }
case_C6b() { setup; local t=TASK-901-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null; pr 1 OPEN "$t"   # 훅 없음 — 조용히 건너뜀
  run "$t"
  check "exit 0" rc_is 0; check "✔" has "✔ $t 정리 완료"; check "경고 없음" not has "⚠"; check "훅 호출 흔적 없음" [ ! -e "$W/hook-calls.txt" ]; }
case_C6c() { setup; local t=TASK-901-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null; pr 1 OPEN "$t"; mk_hook fail   # 훅 실패 — 경고만
  run "$t"
  check "exit 0 — 정리는 끝까지" rc_is 0; check "훅 호출됨" grep -qx "hook $t" "$W/hook-calls.txt"; check "경고 출력" has "⚠ 세션 정리 훅 실패"; check "✔" has "✔ $t 정리 완료"
  check "작업 worktree 사라짐" no_wt "$WT/$t"; check "로컬 작업 브랜치 사라짐" no_local "$t"; }
# ---- ID 없음 모드 (ISSUE_PREFIX 빈 값 — 브랜치 이름 자체가 작업 이름) ----
case_C7a() { CFG_PREFIX=""; F=feature/slug-f; FN=slug-f; setup; mk_feature; local oid; oid="$(remote_oid "$F")"
  run "$F"
  check "exit 0" rc_is 0; check "묶음 worktree 사라짐" no_wt "$FWT"; check "로컬 묶음 브랜치 사라짐" no_local "$F"
  check "원격 묶음 브랜치 그대로" [ "$(remote_oid "$F")" = "$oid" ]; check "✔" has "✔ $F 정리 완료"; }
case_C7b() { CFG_PREFIX=""; F=feature/slug-f; FN=slug-f; setup; mk_feature; local c=slug-c; mk_child "$c"; local tip; tip="$(git -C "$B" rev-parse "$c")"
  run "$c" --into "$F"
  check "exit 0" rc_is 0; check "자식 worktree 사라짐" no_wt "$WT/$c"; check "로컬 자식 사라짐" no_local "$c"
  check "origin 묶음에 자식이 들어감" git --git-dir="$O" merge-base --is-ancestor "$tip" "refs/heads/$F"; }
case_C7c() { CFG_PREFIX=""; F=feature/slug-f; FN=slug-f; setup; mk_feature   # 이름 꼴 가드 — 이름에 원격 브랜치·열린 PR 을 둬 이름 가드만 막게 한다
  git -C "$H" checkout -q -B feature/a/b origin/main; commit_in "$H" k2; git -C "$H" push -q origin feature/a/b; pr 2 OPEN feature/a/b
  run feature/a/b; stopped; check "사유 = 이름 꼴" has "꼴만 받는다"
  run "$F"; check "정상 이름은 통과" rc_is 0; }
case_C7d() { CFG_PREFIX=""; setup; local t=slug-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null
  git -C "$B" worktree add -q "$WT/$t-claude" -b "$t-claude" "$t"; pr 1 OPEN "$t"
  run "$t"
  check "exit 0" rc_is 0; check "작업 worktree 사라짐" no_wt "$WT/$t"; check "구현 worktree 사라짐" no_wt "$WT/$t-claude"
  check "로컬 작업 브랜치 사라짐" no_local "$t"; check "원격 작업 브랜치 남음" [ -n "$(remote_oid "$t")" ]; }
case_C7e() { CFG_PREFIX=""; setup; local t=slug-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null; pr 1 OPEN "$t"
  git -C "$B" worktree add -q "$WT/$t-bar" -b "$t-bar" main 2>/dev/null; echo wip > "$WT/$t-bar/wip.txt"   # 다른 작업 slug-t-bar — 갓 만든 브랜치라 main 조상
  run "$t"
  check "exit 0" rc_is 0; check "작업 worktree 사라짐" no_wt "$WT/$t"
  check "이름이 접두로 겹치는 다른 작업 worktree 남음" [ -f "$WT/$t-bar/wip.txt" ]; check "그 브랜치도 남음" is_local "$t-bar"; }
# ---- bundle 모듈 끔 ----
case_C8a() { CFG_MODULES="l1 l2 specs-repo"; setup; mk_feature; run "$F"; stopped; check "사유 = bundle 모듈" has "bundle 모듈"; check "로컬 묶음 브랜치 그대로" is_local "$F"; }
case_C8b() { CFG_MODULES="l1 l2 specs-repo"; setup; mk_indep TASK-901-c; run TASK-901-c --into "$F"; stopped; check "사유 = bundle 모듈" has "bundle 모듈"; }
case_C8c() { CFG_MODULES="l1 l2 specs-repo"; setup; local t=TASK-901-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null; pr 1 OPEN "$t"
  run "$t"
  check "exit 0" rc_is 0; check "작업 worktree 사라짐" no_wt "$WT/$t"; check "로컬 작업 브랜치 사라짐" no_local "$t"; }
# ---- specs-repo 모듈 끔/켬 — 산출물 잔류 가드 ----
case_C9a() { CFG_MODULES="l1 l2 bundle"; setup; mk_feature; mkdir -p "$FWT/specs"; echo r > "$FWT/specs/raw.txt"   # 끄면 잔류 가드를 건너뛴다(specs/ 는 .gitignore)
  run "$F"; check "exit 0" rc_is 0; check "묶음 worktree 사라짐" no_wt "$FWT"; }
case_C9b() { CFG_MODULES="l1 l2 bundle"; setup; local t=TASK-901-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null; pr 1 OPEN "$t"; mkdir -p "$WT/$t/specs"; echo r > "$WT/$t/specs/raw.txt"
  run "$t"; check "exit 0" rc_is 0; check "작업 worktree 사라짐" no_wt "$WT/$t"; }
case_C9c() { setup; local t=TASK-901-t; mk_indep "$t"; git -C "$WT/$t" push -q -u origin "$t" 2>/dev/null; pr 1 OPEN "$t"; mkdir -p "$WT/$t/specs"; echo r > "$WT/$t/specs/raw.txt"   # 켜면 작업 경로도 멈춘다
  run "$t"; stopped; check "사유 = specs" has "specs 에 파일"; check "작업 worktree 남음" is_wt "$WT/$t"; }

# ---- task-pr.sh ----
mk_specs() { # mk_specs <작업 이름> [plain] — 본체 옆 specs 폴더(기본: 산출물 레포, plain 이면 그냥 폴더) + 원고·판정문
  local d="$W/specs"
  if [ "${2:-git}" = git ]; then git init -q --bare "$W/specs-origin.git"; git clone -q "$W/specs-origin.git" "$d" 2>/dev/null; else mkdir -p "$d"; fi
  mkdir -p "$d/$1"; printf '# 제목\n\n본문 줄\n' > "$d/$1/pr.md"; echo v > "$d/$1/verdict.md"
  if [ "${2:-git}" = git ]; then git -C "$d" add -A; git -C "$d" commit -qm specs; fi
}
body_has() { grep -qF -- "$1" "$W/gh/body-1"; }
pr_title() { [ "$(gh_ pr view 1 --json title --jq .title)" = "$1" ]; }
pr_count() { [ "$(gh_ pr list --state all --json number --jq '.[].number' | grep -c .)" = "$1" ]; }
case_P1() { CFG_MODULES="l1 l2 specs-repo bundle l3"; CFG_FOOTER="-- 서명 줄"; setup; local t=TASK-901-t; mk_indep "$t"; mk_specs "$t"
  run_pr "$t"
  check "exit 0" rc_is 0; check "PR 하나" pr_count 1; check "제목에 ID 접두가 붙음" pr_title "TASK-901: 제목"
  check "본문 = 원고" body_has "본문 줄"; check "본문에 판정문 위치" body_has "산출물 레포 \`$t/verdict.md\`"; check "본문 끝 서명" body_has "-- 서명 줄"; check "l3 켬 — 출고 언급" body_has "출고(release)"
  check "작업 브랜치 push 됨" [ -n "$(remote_oid "$t")" ]; check "산출물 레포 push 됨" [ -n "$(git --git-dir="$W/specs-origin.git" rev-parse -q --verify refs/heads/main)" ]
  check "마지막 안내" has "□ 다음: PR 을 머지한 뒤 작업 정리는 scripts/task-finish.sh $t"; }
case_P2() { setup; local t=TASK-901-t; mk_indep "$t"; mk_specs "$t"   # 멱등 — 다시 돌리면 같은 PR 을 갱신한다
  run_pr "$t"; printf '# 제목 둘\n\n본문 둘\n' > "$W/specs/$t/pr.md"; git -C "$W/specs" commit -qam v2
  run_pr "$t"
  check "재실행 exit 0" rc_is 0; check "PR 여전히 하나" pr_count 1; check "기존 PR 재사용 안내" has "기존 PR #1 재사용"; check "제목 갱신" pr_title "TASK-901: 제목 둘"; check "본문 갱신" body_has "본문 둘"; }
case_P3() { CFG_PREFIX=""; CFG_MODULES="l1 l2 specs-repo"; setup; local t=slug-t; mk_indep "$t"; mk_specs "$t"   # ID 없음 + l3 끔 + 서명 없음
  run_pr "$t"
  check "exit 0" rc_is 0; check "제목 그대로(접두 없음)" pr_title "제목"; check "출고 언급 없음" not body_has "release"; check "서명 없음" not body_has "Generated"; check "본문 = 원고" body_has "본문 줄"; }
case_P4() { setup; local t=TASK-901-t; mk_indep "$t"; mk_specs "$t"; echo more >> "$W/specs/$t/pr.md"   # 원고에 커밋 안 된 변경
  run_pr "$t"; stopped; check "사유 = 커밋 안 된 변경" has "커밋 안 된 변경"; check "PR 없음" pr_count 0; }
case_P5() { CFG_MODULES="l1 l2 specs-repo"; setup; run_pr "$F"; stopped; check "사유 = bundle 모듈" has "bundle 모듈"; }
case_P6() { CFG_MODULES="l1 l2"; setup; local t=TASK-901-t; mk_indep "$t"; mk_specs "$t" plain   # specs-repo 끔 — 산출물 폴더는 git 레포가 아니어도 된다(커밋·push 확인 없음)
  run_pr "$t"
  check "exit 0" rc_is 0; check "PR 하나" pr_count 1; check "본문에 판정문 위치(레포 표기 없음)" body_has "- 판정문: \`$t/verdict.md\`"; check "작업 브랜치 push 됨" [ -n "$(remote_oid "$t")" ]; }
case_P7() { setup; mk_feature; rm -f "$W/gh/pr/1"; mk_specs "${F#feature/}"   # 묶음 브랜치 PR
  run_pr "$F"
  check "exit 0" rc_is 0; check "PR 하나" pr_count 1; check "제목 접두 = 묶음 이름의 ID" pr_title "TASK-900: 제목"; check "묶음 정리 안내" has "묶음 정리는 scripts/task-finish.sh $F"; }

TOTAL=0; PASSED=0; FAILED_LIST=""
for CASE in $CASES; do
  LOG="$WORK/$CASE.log"; : > "$LOG"; CASE_FAIL=0; unset FGH_INDIRECT; default_names
  type "case_$CASE" >/dev/null 2>&1 || { echo "FAIL $CASE: 모르는 케이스"; TOTAL=$((TOTAL + 1)); FAILED_LIST="$FAILED_LIST $CASE"; continue; }
  "case_$CASE"
  TOTAL=$((TOTAL + 1))
  if [ "$CASE_FAIL" = 0 ]; then PASSED=$((PASSED + 1)); echo "PASS $CASE"; else FAILED_LIST="$FAILED_LIST $CASE"; echo "FAIL $CASE"; sed 's/^/    /' "$LOG"; fi
  if [ -n "$OUT" ]; then { cat "$LOG"; echo "## 실행 뒤 상태"; snap; } > "$OUT/$CASE.txt"; fi
done
echo "# 결과: PASS $PASSED / $TOTAL${FAILED_LIST:+ · FAIL:$FAILED_LIST}"
[ "$PASSED" = "$TOTAL" ]
