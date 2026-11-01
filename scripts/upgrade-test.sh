#!/usr/bin/env bash
# 실제 버전 갱신 시험: 지난 태그의 플러그인으로 깔고 슬롯을 채운 대상을 지금 작업 트리로 sync 한다.
# 사용법: scripts/upgrade-test.sh [<지난 태그>]   (기본: 지금 버전과 다른 가장 최근 태그)
# 그다음 같은 대상에서 harness corral → bare, l2 끔도 sync 로 맞춘다. 임시 폴더에서만 돈다.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
NOW=$("$ROOT/bin/paddock-render" version)
TAG=${1:-$(git -C "$ROOT" tag -l 'v*' --sort=-v:refname | grep -vx "v$NOW" | head -n 1)}
[ -n "$TAG" ] || { echo "지난 태그가 없다" >&2; exit 2; }
T=$(mktemp -d "${TMPDIR:-/tmp}/paddock-upgrade-test.XXXXXX")
trap 'rm -rf "$T"' EXIT
pass=0 fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
no() { echo "  ✗ $1"; fail=$((fail+1)); }
check() { if eval "$2"; then ok "$1"; else no "$1"; fi; }
# 대상의 설계 슬롯 내용 전부: 파일 · ID#순번 · 내용 (managed 파일만)
slots() { (cd "$1" && grep -v '^#' .paddock/manifest.tsv | awk -F'\t' '$2 == "managed" {print $1}' | while read -r f; do
  awk -v f="$f" '/<!-- paddock:design [^ ]+ -->/ {id=$0; sub(/.*paddock:design /,"",id); sub(/ -->.*/,"",id); k=id "#" (++n[id]); ins=1; next}
    /<!-- \/paddock:design -->/ {ins=0; next} ins {print f "\t" k "\t" $0}' "$f"; done); }

mkdir -p "$T/old"; git -C "$ROOT" archive "$TAG" | tar -x -C "$T/old"
OLD=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$T/old/.claude-plugin/plugin.json" | head -n 1)
echo "$TAG($OLD) → 작업 트리($NOW)"
cat > "$T/c.sh" <<CFG
PADDOCK_VERSION=$OLD
PADDOCK_MODULES="l1 l2 specs-repo"
PADDOCK_HARNESS=corral
PROJECT_NAME=demo
WORKTREE_DIR=.claude/worktrees
ISSUE_PREFIX=DEMO
SPECS_ROOT=../demo-specs
BASE_BRANCH=main
BUNDLE_PREFIX=feature/
MAX_FIX_ROUNDS=3
CFG
"$T/old/bin/paddock-render" render --config "$T/c.sh" --out "$T/r-old" >/dev/null
mkdir -p "$T/t" && git -C "$T/t" init -q && "$T/old/bin/paddock-render" apply "$T/r-old" "$T/t" >/dev/null
# 슬롯마다 고유한 줄을 채운다 (힌트 주석은 남긴다), defaults.md 역할 표도 채운다
(cd "$T/t" && grep -v '^#' .paddock/manifest.tsv | awk -F'\t' '$2 == "managed" {print $1}' | while read -r f; do
  awk -v f="$f" '{print} /<!-- paddock:design [^ ]+ -->/ {id=$0; sub(/.*paddock:design /,"",id); sub(/ -->.*/,"",id); print "채움 " f " " id "#" (++n[id])}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; done
  awk '/^\|[^|]+\|( *\|){4} *$/ {sub(/( *\|){4} *$/, " 해당 없음 | - | - | - |")} {print}' .agents/defaults.md > d.tmp && mv d.tmp .agents/defaults.md)
"$T/old/bin/paddock-check" "$T/t" --require-filled > "$T/out" 2>&1; rc=$?
check "지난 버전으로 깔고 채움 → --require-filled 통과" '[ $rc = 0 ]'
[ $rc = 0 ] || { sed 's/^/    /' "$T/out"; echo "기준선을 못 만들었다 — 중단"; exit 1; }
git -C "$T/t" add -A && git -C "$T/t" -c user.name=t -c user.email=t@t commit -qm base
slots "$T/t" > "$T/slots-before"

echo "U1 버전 갱신"
"$ROOT/bin/paddock-render" render --config "$T/t/.paddock/config.sh" --out "$T/r-new" >/dev/null
"$ROOT/bin/paddock-render" sync "$T/r-new" "$T/t" > "$T/out" 2>&1; rc=$?
cp "$T/out" "$T/sync-out"
sed 's/^/    /' "$T/out" | tail -n 25
check "sync → exit 0" '[ $rc = 0 ]'
slots "$T/t" > "$T/slots-after"
# 새 버전이 더한 슬롯(파일·ID#순번이 지난 버전에 없던 것)은 비교에서 빼고, sync 가 「새 슬롯」으로 보고했는지 본다
cut -f1,2 "$T/slots-before" | sort -u > "$T/keys-before"
awk -F'\t' 'NR==FNR {k[$1 "\t" $2]=1; next} ($1 "\t" $2) in k' "$T/keys-before" "$T/slots-after" > "$T/slots-after-old"
check "채운 슬롯 전부 바이트 같음 ($(wc -l < "$T/slots-before" | tr -d ' ')줄)" 'cmp -s "$T/slots-before" "$T/slots-after-old"'
NEWSLOTS=$(cd "$T/t" && grep -v '^#' .paddock/manifest.tsv | awk -F'\t' '$2 == "managed" {print $1}' | while read -r f; do
  awk -v f="$f" '/<!-- paddock:design [^ ]+ -->/ {id=$0; sub(/.*paddock:design /,"",id); sub(/ -->.*/,"",id); print f "\t" id "#" (++n[id])}' "$f"; done \
  | awk -F'\t' 'NR==FNR {k[$1 "\t" $2]=1; next} !(($1 "\t" $2) in k)' "$T/keys-before" -)
if [ -n "$NEWSLOTS" ]; then
  check "새 슬롯 $(printf '%s\n' "$NEWSLOTS" | wc -l | tr -d ' ')개 모두 sync 가 「새 슬롯」으로 보고" \
    'printf "%s\n" "$NEWSLOTS" | while IFS="$(printf "\t")" read -r f k; do grep -q "새 슬롯.*$f.*${k%%#*}" "$T/sync-out" || exit 1; done'
  "$ROOT/bin/paddock-check" "$T/t" --require-filled > "$T/out-empty" 2>&1; rc=$?
  check "채우기 전 --require-filled 는 새 슬롯이 비어 실패" '[ $rc != 0 ] && grep -q "비었다" "$T/out-empty"'
  # 재감사를 흉내 내 새 슬롯만 채운다 — 이후 U2·U3 기준선에 넣는다
  printf '%s\n' "$NEWSLOTS" | cut -f1 | sort -u | while read -r f; do
    (cd "$T/t" && awk -v f="$f" -v keys="$(printf '%s\n' "$NEWSLOTS" | awk -F'\t' -v f="$f" '$1==f {printf "%s ", $2}')" \
      '{print} /<!-- paddock:design [^ ]+ -->/ {id=$0; sub(/.*paddock:design /,"",id); sub(/ -->.*/,"",id); k=id "#" (++n[id]); if (index(" " keys, " " k " ")) print "채움 " f " " k}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"); done
  slots "$T/t" > "$T/slots-before"
fi
check "config 버전 = $NOW" 'grep -qx "PADDOCK_VERSION=$NOW" "$T/t/.paddock/config.sh"'
"$ROOT/bin/paddock-check" "$T/t" --require-filled > "$T/out" 2>&1; rc=$?
check "지금 버전 paddock-check --require-filled 통과" '[ $rc = 0 ]'
[ $rc = 0 ] || sed 's/^/    /' "$T/out"
git -C "$T/t" add -A && git -C "$T/t" -c user.name=t -c user.email=t@t commit -qm upgrade
echo "    바뀐 파일: $(git -C "$T/t" diff --name-only HEAD~1 | tr '\n' ' ')"
check "매핑은 도구 폴더 하나 — 옛 corral.md 없음, corral/00-mapping.md·commands.md 있음" '[ ! -e "$T/t/.agents/harness/corral.md" ] && [ -f "$T/t/.agents/harness/corral/00-mapping.md" ] && [ -f "$T/t/.agents/harness/corral/commands.md" ]'

echo "U2 harness corral → bare"
sed 's/^PADDOCK_HARNESS=corral$/PADDOCK_HARNESS=bare/' "$T/t/.paddock/config.sh" > "$T/c-bare.sh"
"$ROOT/bin/paddock-render" render --config "$T/c-bare.sh" --out "$T/r-bare" >/dev/null
"$ROOT/bin/paddock-render" sync "$T/r-bare" "$T/t" > "$T/out" 2>&1; rc=$?
check "sync → exit 0, corral 파일 0, bare 매핑 있음" '[ $rc = 0 ] && [ -z "$(find "$T/t/.agents/harness" -name "*corral*" -o -name session-cleanup.sh)" ] && [ -f "$T/t/.agents/harness/bare/00-mapping.md" ]'
"$ROOT/bin/paddock-check" "$T/t" --require-filled > "$T/out" 2>&1; rc=$?
check "paddock-check 통과 (capability-check 포함)" '[ $rc = 0 ]'
check "슬롯 그대로" 'slots "$T/t" | cmp -s - "$T/slots-before"'

echo "U3 l2 끔"
sed 's/^PADDOCK_MODULES=.*/PADDOCK_MODULES="l1 specs-repo"/; s/^PADDOCK_HARNESS=.*/PADDOCK_HARNESS=/' "$T/t/.paddock/config.sh" > "$T/c-nol2.sh"
"$ROOT/bin/paddock-render" render --config "$T/c-nol2.sh" --out "$T/r-nol2" >/dev/null
"$ROOT/bin/paddock-render" sync "$T/r-nol2" "$T/t" > "$T/out" 2>&1; rc=$?
check "sync → exit 0, .agents/harness 없어짐" '[ $rc = 0 ] && [ ! -e "$T/t/.agents/harness" ]'
"$ROOT/bin/paddock-check" "$T/t" --require-filled > "$T/out" 2>&1; rc=$?
check "paddock-check 통과" '[ $rc = 0 ]'
check "슬롯 그대로" 'slots "$T/t" | cmp -s - "$T/slots-before"'

echo "통과 $pass · 실패 $fail"
[ "$fail" = 0 ]
