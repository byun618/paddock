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
mkdir -p "$T/fx/assets/l0"; cp -R "$ROOT/bin" "$T/fx/"
printf 'a\n<!-- paddock:module l1 -->\nL1줄\n<!-- /paddock:module -->\n<!-- paddock:module bundle -->\nB줄\n<!-- /paddock:module -->\nz\n' > "$T/fx/assets/l0/m.md"
printf '# x\n' > "$T/fx/assets/README.md"
cfg "$T/c1.sh" "l1"
"$T/fx/bin/paddock-render" render --config "$T/c1.sh" --out "$T/m1" >/dev/null
check "l1 켬·bundle 끔 → a L1줄 z" '[ "$(cat "$T/m1/m.md" | tr "\n" " ")" = "a L1줄 z " ]'

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

echo "통과 $pass · 실패 $fail"
[ "$fail" = 0 ]
