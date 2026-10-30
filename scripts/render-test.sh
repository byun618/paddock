#!/usr/bin/env bash
# bin/paddock-render 시험. 임시 폴더에서만 돈다. 사용법: scripts/render-test.sh
# 각 케이스는 기대 결과(종료코드·파일 내용)를 단언한다. 하나라도 어긋나면 exit 1
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
R="$ROOT/bin/paddock-render"
T=$(mktemp -d "${TMPDIR:-/tmp}/paddock-render-test.XXXXXX")
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
no() { echo "  ✗ $1"; fail=$((fail+1)); }
check() { if eval "$2"; then ok "$1"; else no "$1"; fi; }

cfg() { # $1 파일 $2 모듈
  cat > "$1" <<EOF
PADDOCK_VERSION=0.0.0-test
PADDOCK_MODULES="$2"
PADDOCK_HARNESS=
PROJECT_NAME=demo
WORKTREE_DIR=.claude/worktrees
EOF
}
tree_hash() { (cd "$1" && find . \( -type f -o -type l \) | LC_ALL=C sort | while read -r f; do if [ -L "$f" ]; then echo "$f -> $(readlink "$f")"; else echo "$f $(shasum -a 256 < "$f" | cut -c1-64) $( [ -x "$f" ] && echo x)"; fi; done) | shasum -a 256 | cut -c1-64; }

echo "R1 결정성 — 같은 입력 두 번"
cfg "$T/c0.sh" ""
"$R" render --config "$T/c0.sh" --out "$T/a" >/dev/null; "$R" render --config "$T/c0.sh" --out "$T/b" >/dev/null
check "두 출력 트리 해시가 같다" '[ "$(tree_hash "$T/a")" = "$(tree_hash "$T/b")" ]'

echo "R2 변수 치환·심링크·실행 비트·.gitkeep"
check "AGENTS.md 제목에 PROJECT_NAME" 'head -n 1 "$T/a/AGENTS.md" | grep -qx "# demo — 공통 지침"'
check "남은 {{VAR}} 0" '! grep -rqE "\{\{[A-Z][A-Z0-9_]*\}\}" "$T/a"'
check ".claude/rules 심링크 유지" '[ "$(readlink "$T/a/.claude/rules")" = "../.agents/rules" ]'
check "pre-commit 실행 비트" '[ -x "$T/a/.githooks/pre-commit" ]'
check ".gitkeep 은 복사 안 하고 폴더만" '[ -d "$T/a/.agents/agents" ] && [ ! -e "$T/a/.agents/agents/.gitkeep" ]'
check "manifest 에 seed·link·dir 종류" 'grep -q "^.agents/rules/writing.md	seed	" "$T/a/.paddock/manifest.tsv" && grep -q "	link	" "$T/a/.paddock/manifest.tsv" && grep -q "	dir	" "$T/a/.paddock/manifest.tsv"'

echo "R3 모듈 — 끄면 구간째 빠지고 마커도 남지 않는다"
check "모듈 마커가 출력에 없다" '! grep -rq "paddock:module" "$T/a"'
check "설계 슬롯 마커는 남는다" 'grep -q "<!-- paddock:design D1 -->" "$T/a/AGENTS.md"'
mkdir -p "$T/fx/assets/l0"; cp -R "$ROOT/bin" "$ROOT/.claude-plugin" "$T/fx/"
printf 'a\n<!-- paddock:module l1 -->\nL1줄\n<!-- /paddock:module -->\n<!-- paddock:module bundle -->\nB줄\n<!-- /paddock:module -->\nz\n' > "$T/fx/assets/l0/m.md"
printf '# x\n' > "$T/fx/assets/README.md"
cfg "$T/c1.sh" "l1"
"$T/fx/bin/paddock-render" render --config "$T/c1.sh" --out "$T/m1" >/dev/null
check "l1 켬·bundle 끔 → a L1줄 z" '[ "$(cat "$T/m1/m.md" | tr "\n" " ")" = "a L1줄 z " ]'

mkdir -p "$T/fx/assets/bundle/x"; printf 'b\n' > "$T/fx/assets/bundle/x/only-bundle.md"
"$T/fx/bin/paddock-render" render --config "$T/c1.sh" --out "$T/m5" >/dev/null
check "모듈 폴더 — bundle 끔이면 파일 없음" '[ -f "$T/m5/m.md" ] && [ ! -e "$T/m5/x/only-bundle.md" ]'
cfg "$T/c2.sh" "l1 bundle"
"$T/fx/bin/paddock-render" render --config "$T/c2.sh" --out "$T/m4" >/dev/null
check "모듈 폴더 — bundle 켬이면 파일 생김" '[ -f "$T/m4/x/only-bundle.md" ]'

echo "R4 실패 — 미정의 변수·안 닫힌 모듈·빈 아닌 --out"
printf '{{NOPE_VAR}}\n' > "$T/fx/assets/l0/v.md"
"$T/fx/bin/paddock-render" render --config "$T/c1.sh" --out "$T/m2" >/dev/null 2>"$T/err"; rc=$?
check "미정의 변수 → exit 4, 출력 폴더 없음" '[ $rc = 4 ] && [ ! -e "$T/m2" ] && grep -q "미정의 변수 {{NOPE_VAR}}" "$T/err"'
rm "$T/fx/assets/l0/v.md"; printf '<!-- paddock:module l1 -->\nx\n' > "$T/fx/assets/l0/u.md"
"$T/fx/bin/paddock-render" render --config "$T/c1.sh" --out "$T/m3" >/dev/null 2>"$T/err"; rc=$?
check "안 닫힌 모듈 → exit 4" '[ $rc = 4 ] && grep -q "안 닫힘" "$T/err"'
"$R" render --config "$T/c0.sh" --out "$T/a" >/dev/null 2>&1; rc=$?
check "비어 있지 않은 --out → exit 2" '[ $rc = 2 ]'

echo "R5 apply — 새 레포, 재실행, 충돌, seed 보존, .gitignore"
mkdir -p "$T/repo"; printf 'node_modules/\n' > "$T/repo/.gitignore"
"$R" apply "$T/a" "$T/repo" >/dev/null; rc=$?
check "새 레포에 apply → exit 0, AGENTS.md 생김" '[ $rc = 0 ] && cmp -s "$T/a/AGENTS.md" "$T/repo/AGENTS.md"'
check ".gitignore 에 조각 덧붙임, 기존 줄 유지" 'grep -qx "node_modules/" "$T/repo/.gitignore" && grep -qx ".claude/worktrees/" "$T/repo/.gitignore"'
before=$(shasum -a 256 < "$T/repo/.gitignore")
"$R" apply "$T/a" "$T/repo" >/dev/null; rc=$?
check "두 번째 apply → exit 0, .gitignore 중복 없음" '[ $rc = 0 ] && [ "$(shasum -a 256 < "$T/repo/.gitignore")" = "$before" ]'
echo "내 규칙" >> "$T/repo/.agents/rules/coding.md"
"$R" apply "$T/a" "$T/repo" >/dev/null; rc=$?
check "seed 를 고친 뒤 apply → 충돌 아님, 고친 내용 유지" '[ $rc = 0 ] && grep -qx "내 규칙" "$T/repo/.agents/rules/coding.md"'
echo "기존 내용" > "$T/repo2.md"; mkdir -p "$T/repo2"; cp "$T/repo2.md" "$T/repo2/AGENTS.md"
"$R" apply "$T/a" "$T/repo2" > "$T/out" 2>&1; rc=$?
check "내용 다른 기존 AGENTS.md → exit 3, 아무것도 안 씀" '[ $rc = 3 ] && grep -q "AGENTS.md (내용이 다른 기존 파일)" "$T/out" && [ "$(ls -A "$T/repo2")" = "AGENTS.md" ] && grep -qx "기존 내용" "$T/repo2/AGENTS.md"'
"$R" apply "$T/a" "$T/repo2" --dry-run >/dev/null 2>&1; rc=$?
check "dry-run 도 충돌이면 exit 3" '[ $rc = 3 ]'

echo "R6 paddock-check — 대상 레포 검사"
C="$ROOT/bin/paddock-check"
mkdir -p "$T/k"; "$R" apply "$T/a" "$T/k" >/dev/null
"$C" "$T/k" >/dev/null; rc=$?
check "apply 직후 → 통과" '[ $rc = 0 ]'
"$C" "$T/k" --require-filled > "$T/out"; rc=$?
check "--require-filled, D1 비었음 → 실패" '[ $rc = 1 ] && grep -q "슬롯 D1 이 비었다" "$T/out"'
awk '/<!-- paddock:design D1 -->/{print; print "demo 는 시험용 프로젝트다."; next} {print}' "$T/k/AGENTS.md" > "$T/x" && cat "$T/x" > "$T/k/AGENTS.md"
"$C" "$T/k" --require-filled >/dev/null; rc=$?
check "D1 채운 뒤 → 통과 (슬롯 안 변경은 drift 아님)" '[ $rc = 0 ]'
echo "덧붙임" >> "$T/k/.agents/learnings/README.md"
"$C" "$T/k" > "$T/out"; rc=$?
check "고정 파일 수정 → drift 실패" '[ $rc = 1 ] && grep -q "고정 부분이 바뀜: .agents/learnings/README.md" "$T/out"'
cp "$T/a/.agents/learnings/README.md" "$T/k/.agents/learnings/README.md"
sed -i.bak "s/## 어디를 고치나/## 어디를 고칠까/" "$T/k/AGENTS.md" && rm "$T/k/AGENTS.md.bak"
"$C" "$T/k" > "$T/out"; rc=$?
check "managed 파일의 슬롯 밖 수정 → drift 실패" '[ $rc = 1 ] && grep -q "AGENTS.md (설계 슬롯 밖)" "$T/out"'
sed -i.bak "s/## 어디를 고칠까/## 어디를 고치나/" "$T/k/AGENTS.md" && rm "$T/k/AGENTS.md.bak"
echo "# x" > "$T/k/.agents/agents/reviewer.md"
"$C" "$T/k" > "$T/out"; rc=$?
check "역할 파일만 있고 toml 없음 → 실패" '[ $rc = 1 ] && grep -q "reviewer.toml 없음" "$T/out"'
printf 'developer_instructions = """\n.agents/agents/reviewer.md 를 먼저 읽는다\n"""\n' > "$T/k/.codex/agents/reviewer.toml"
"$C" "$T/k" >/dev/null; rc=$?
check "toml 을 짝지으면 → 통과" '[ $rc = 0 ]'
rm "$T/k/.claude/rules"
"$C" "$T/k" > "$T/out"; rc=$?
check "심링크 지움 → 실패" '[ $rc = 1 ] && grep -q "심링크 없음: .claude/rules" "$T/out"'

echo "R7 파생 변수 — ID 접두 있음·없음 (l1 l2 bundle specs-repo, bare)"
for p in LIFE ''; do
  d="$T/id-${p:-none}"
  cfg "$d.sh" "l1 l2 bundle specs-repo"
  printf 'PADDOCK_HARNESS=bare\nISSUE_PREFIX=%s\nSPECS_ROOT=../demo-specs\nBASE_BRANCH=main\nBUNDLE_PREFIX=feature/\nMAX_FIX_ROUNDS=3\n' "$p" >> "$d.sh"
  "$R" render --config "$d.sh" --out "$d" >/dev/null 2>"$T/err"; rc=$?
  check "ISSUE_PREFIX='$p' 렌더 → exit 0, 남은 {{VAR}} 0" '[ $rc = 0 ] && ! grep -rqE "\{\{[A-Z][A-Z0-9_]*\}\}" "$d"'
done
check "접두 있음 → 작업 이름 LIFE-NNN-<슬러그>" 'grep -rq "LIFE-NNN-<슬러그>" "$T/id-LIFE"'
check "접두 없음 → 문서에 -NNN·-MMM 조각 0, 작업 이름 <슬러그>" '! grep -rqE --include="*.md" "(^|[^A-Za-z])-(NNN|MMM)" "$T/id-none" && grep -rq "demo-specs/<슬러그>/" "$T/id-none"'

echo "R8 독립 리뷰 r1 지적 — 끝 개행 없는 .gitignore · 값 없는 인자 · l2 단독"
mkdir -p "$T/nl"; printf 'node_modules' > "$T/nl/.gitignore"
"$R" apply "$T/a" "$T/nl" >/dev/null; rc=$?
check "끝 개행 없는 .gitignore → 마지막 줄 보존" '[ $rc = 0 ] && grep -qx "node_modules" "$T/nl/.gitignore" && grep -qx ".claude/worktrees/" "$T/nl/.gitignore"'
( "$R" render --config & p=$!; sleep 3; kill $p 2>/dev/null && exit 99; wait $p ) >/dev/null 2>&1; rc=$?
check "--config 값 없음 → 3초 안에 exit 2" '[ $rc = 2 ]'
cfg "$T/l2only.sh" "l2"; printf 'PADDOCK_HARNESS=bare\n' >> "$T/l2only.sh"
"$R" render --config "$T/l2only.sh" --out "$T/l2only" > "$T/err" 2>&1; rc=$?
check "l2 만 켬 → 거절(l1 전제), 출력 없음" '[ $rc != 0 ] && grep -q "l1 을 전제" "$T/err" && [ ! -e "$T/l2only/AGENTS.md" ]'

echo "R9 corral 매핑 렌더 → apply → paddock-check(harness 포함) · defaults 채움 검사"
cfg "$T/cor.sh" "l1 l2 specs-repo"
printf 'PADDOCK_HARNESS=corral\nISSUE_PREFIX=\nSPECS_ROOT=../demo-specs\nBASE_BRANCH=main\nBUNDLE_PREFIX=feature/\nMAX_FIX_ROUNDS=3\n' >> "$T/cor.sh"
"$R" render --config "$T/cor.sh" --out "$T/cor" >/dev/null && mkdir -p "$T/cor-r" && "$R" apply "$T/cor" "$T/cor-r" >/dev/null; rc=$?
check "corral 렌더·apply → exit 0, session-cleanup.sh 실행 비트" '[ $rc = 0 ] && [ -x "$T/cor-r/.agents/harness/session-cleanup.sh" ]'
"$C" "$T/cor-r" > "$T/out" 2>&1; rc=$?
check "paddock-check → 통과(capability-check names·shape 포함)" '[ $rc = 0 ] && grep -q "capability-check shape" "$T/out"'
"$C" "$T/cor-r" --require-filled > "$T/out" 2>&1; rc=$?
check "--require-filled, defaults.md 역할 표 비었음 → 실패" '[ $rc = 1 ] && grep -q "defaults.md 역할 표에 빈 행" "$T/out"'

echo "R9b 매핑 폴더 — capability-check 변이 대조 (능력 파일·제목·선언 파일)"
H=.agents/harness
cc() { (cd "$1" && node "$H/capability-check.mjs" "${@:2}" >/dev/null 2>&1); }
mut() { rm -rf "$T/m" && cp -R "$1" "$T/m"; }
cc "$T/cor-r" names; a=$?; cc "$T/cor-r" shape; b=$?
check "기준선 corral → names·shape 0" '[ $a = 0 ] && [ $b = 0 ]'
mut "$T/cor-r"; rm "$T/m/$H/corral/qa.md"; cc "$T/m" names; rc=$?
check "능력 파일 하나 지움 → names 1" '[ $rc = 1 ]'
mut "$T/cor-r"; printf '<!-- paddock:fixed -->\n## 『없는 능력』\n' > "$T/m/$H/corral/extra.md"; cc "$T/m" names; rc=$?
check "표에 없는 능력 파일 → names 1" '[ $rc = 1 ]'
mut "$T/cor-r"; sed -i.b 's/^## 『질의응답』$/## 『질문』/' "$T/m/$H/corral/qa.md"; cc "$T/m" names; rc=$?
check "능력 파일의 절 제목이 표와 다름 → names 1" '[ $rc = 1 ]'
mut "$T/cor-r"; sed -i.b 's/^- \*\*복구\*\*/- 복구/' "$T/m/$H/corral/inject.md"; cc "$T/m" shape; rc=$?
check "능력 파일에서 상황 항목 하나 빠짐 → shape 1" '[ $rc = 1 ]'
cfg "$T/bare.sh" "l1 l2 specs-repo"
printf 'PADDOCK_HARNESS=bare\nISSUE_PREFIX=\nSPECS_ROOT=../demo-specs\nBASE_BRANCH=main\nBUNDLE_PREFIX=feature/\nMAX_FIX_ROUNDS=3\n' >> "$T/bare.sh"
"$R" render --config "$T/bare.sh" --out "$T/bare" >/dev/null && mkdir -p "$T/bare-r" && "$R" apply "$T/bare" "$T/bare-r" >/dev/null
cc "$T/bare-r" runtime --tool bare; rc=$?
check "기준선 bare runtime → 3 (광고 대조만 공백)" '[ $rc = 3 ]'
mut "$T/bare-r"; awk '/^```required-commands/{print; skip=1; next} /^```/{skip=0} !skip{print}' "$T/m/$H/bare/commands.md" > "$T/x" && mv "$T/x" "$T/m/$H/bare/commands.md"; cc "$T/m" runtime --tool bare; rc=$?
check "선언 파일의 required 비움 → runtime 1" '[ $rc = 1 ]'
mut "$T/bare-r"; printf '\n`tmux kill-server -a`\n' >> "$T/m/$H/bare/screen.md"; cc "$T/m" runtime --tool bare; rc=$?
check "능력 파일이 선언 없는 명령을 씀 → runtime 1" '[ $rc = 1 ]'
mut "$T/bare-r"; printf '\n```mentioned-commands\nkill-server   # 사유\n```\n' >> "$T/m/$H/bare/screen.md"; cc "$T/m" runtime --tool bare; rc=$?
check "선언 블록을 commands.md 밖에 둠 → runtime 1" '[ $rc = 1 ]'

echo "R10 PADDOCK_SKIP — 깔지 않기로 한 경로"
cfg "$T/skip.sh" ""; printf 'PADDOCK_SKIP=".claude/agents .agents/agents"\n' >> "$T/skip.sh"
"$R" render --config "$T/skip.sh" --out "$T/skip" >/dev/null; rc=$?
check "링크·폴더 둘 다 안 깔고 manifest 에도 없음, 다른 링크는 그대로" '[ $rc = 0 ] && [ ! -e "$T/skip/.claude/agents" ] && [ ! -L "$T/skip/.claude/agents" ] && [ ! -e "$T/skip/.agents/agents" ] && ! grep -qE "^\.(claude|agents)/agents	" "$T/skip/.paddock/manifest.tsv" && [ -L "$T/skip/.claude/rules" ]'

cfg "$T/skip2.sh" ""; printf 'PADDOCK_SKIP="./.claude/agents/"\n' >> "$T/skip2.sh"
"$R" render --config "$T/skip2.sh" --out "$T/skip2" >/dev/null; rc=$?
check "앞 ./ 와 끝 / 는 떼고 같은 경로로 본다" '[ $rc = 0 ] && [ ! -L "$T/skip2/.claude/agents" ] && [ -L "$T/skip2/.claude/rules" ]'
for bad in "../x" "/abs" ".claude/*" "a/../b"; do
  cfg "$T/skip3.sh" ""; printf 'PADDOCK_SKIP="%s"\n' "$bad" >> "$T/skip3.sh"; rm -rf "$T/skip3"
  "$R" render --config "$T/skip3.sh" --out "$T/skip3" > "$T/err" 2>&1; rc=$?
  check "PADDOCK_SKIP=\"$bad\" → 거절 exit 2" '[ $rc = 2 ] && grep -q "쓸 수 없는 경로" "$T/err"'
done

echo "통과 $pass · 실패 $fail"
[ "$fail" = 0 ]
