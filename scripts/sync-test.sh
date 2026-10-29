#!/usr/bin/env bash
# paddock-render sync 시험. 임시 폴더에서 픽스처 플러그인 두 벌(v1·v2)로 돈다. 사용법: scripts/sync-test.sh
# 기준선: v1 렌더를 apply 하고 슬롯을 채운 대상. 시나리오마다 그 사본을 고친 뒤 v2(또는 바뀐 config)로 sync 한다.
# 양성 대조: SY_MUTANT=<가드 이름> 이면 v2 bin 사본의 「# guard:<이름>」 줄을 망가뜨린다 — 그 가드의 케이스가 FAIL 해야 한다.
#   가드 이름 전부는 `grep -o 'guard:s-[a-z-]*' bin/paddock-render`.
# SY_KEEP=1 이면 임시 폴더를 남긴다(디버그).
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d "${TMPDIR:-/tmp}/paddock-sync-test.XXXXXX")
trap '[ -n "${SY_KEEP:-}" ] || rm -rf "$T"' EXIT
pass=0 fail=0 failed=""
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
no() { echo "  ✗ $1"; fail=$((fail+1)); failed="$failed $2"; }
# check <이름> <케이스 id> <조건>
check() { if eval "$3"; then ok "$1"; else no "$1" "$2"; fi; }
tree_hash() { (cd "$1" && find . \( -type f -o -type l -o -type d \) | LC_ALL=C sort | while read -r f; do if [ -L "$f" ]; then echo "$f -> $(readlink "$f")"; elif [ -d "$f" ]; then echo "$f/"; else echo "$f $(shasum -a 256 < "$f" | cut -c1-64) $( [ -x "$f" ] && echo x)"; fi; done) | shasum -a 256 | cut -c1-64; }

mk_plugin() { # $1 폴더 $2 버전
  mkdir -p "$1/.claude-plugin" "$1/assets/l0" "$1/assets/extra"; cp -R "$ROOT/bin" "$1/"
  printf '{ "name": "paddock", "version": "%s" }\n' "$2" > "$1/.claude-plugin/plugin.json"
}
slot() { printf '<!-- paddock:design %s -->\n<!-- %s 힌트 -->\n<!-- /paddock:design -->\n' "$1" "$2"; }

V1="$T/v1"; V2="$T/v2"; mk_plugin "$V1" 1.0.0; mk_plugin "$V2" 2.0.0
# v1 자산
A="$V1/assets/l0"
printf '<!-- paddock:fixed -->\nA v1\n' > "$A/a.md"
printf '<!-- paddock:fixed -->\n같음\n' > "$A/same.md"
{ printf '# {{PROJECT_NAME}}\n'; slot D1 첫; printf 'y\n'; slot D2 둘; slot D2 둘; printf 'z v1\n'; } > "$A/m.md"
{ printf 'o\n'; slot D9 아홉; printf 'o v1\n'; } > "$A/o.md"
printf '<!-- paddock:fixed -->\n사라질 파일\n' > "$A/gone.md"
{ printf 'g\n'; slot D8 여덟; } > "$A/gonem.md"
printf '<!-- paddock:seed -->\nseed v1\n' > "$A/s.md"
ln -s same.md "$A/lk"
mkdir -p "$A/d" "$A/old"; : > "$A/d/.gitkeep"; : > "$A/old/.gitkeep"; printf '<!-- paddock:fixed -->\n빈 폴더 안의 지난 파일\n' > "$A/d/was.md"
printf 'a/\n' > "$A/gitignore.fragment"
printf '<!-- paddock:fixed -->\n모듈 파일\n' > "$V1/assets/extra/e.md"
# v2 자산: a 바뀜 · same 같음 · m 고정부 바뀜+D3 새 슬롯 · o 의 D9 없어짐 · gone·gonem·old/ 빠짐 · seed 바뀜 · 새 실행 파일·링크·.gitignore 줄
A="$V2/assets/l0"
printf '<!-- paddock:fixed -->\nA v2\n' > "$A/a.md"
printf '<!-- paddock:fixed -->\n같음\n' > "$A/same.md"
{ printf '# {{PROJECT_NAME}}\n'; slot D1 첫; printf 'y\n'; slot D2 둘; slot D2 둘; slot D3 셋; printf 'z v2\n'; } > "$A/m.md"
printf 'o\no v2\n' > "$A/o.md"
printf '<!-- paddock:seed -->\nseed v2\n' > "$A/s.md"
printf '#!/bin/sh\n# paddock:fixed\necho new\n' > "$A/new.sh"; chmod +x "$A/new.sh"
ln -s same.md "$A/lk"; ln -s a.md "$A/lk2"
mkdir -p "$A/d"; : > "$A/d/.gitkeep"
printf 'a/\nb/\n' > "$A/gitignore.fragment"
printf '<!-- paddock:fixed -->\n모듈 파일\n' > "$V2/assets/extra/e.md"

if [ -n "${SY_MUTANT:-}" ]; then
  f="$V2/bin/paddock-render"
  case "$SY_MUTANT" in
    s-slot-keep) sed -i '' '/# guard:s-slot-keep$/ s/if ((k in has) \&\& filled(tb\[k\]))/if (0)/' "$f" ;;
    s-missing) sed -i '' '/# guard:s-missing$/ s/else conflict "\$rel" 만듦 "대상에서 지워졌다"/else plan 만듦 "$rel" x/' "$f" ;;
    s-orphan) sed -i '' '/# guard:s-orphan$/ s/if \[ -s "\$orph" \]; then/if false; then/' "$f" ;;
    s-exists) sed -i '' '/# guard:s-exists$/ s/elif \[ "\$ok" = - \]; then conflict/elif false; then conflict/' "$f" ;;
    s-touched) sed -i '' '/# guard:s-touched$/ s/else conflict "\$rel" 갱신 "고정부를 프로젝트가 고쳤다"/else plan 갱신 "$rel" x/' "$f" ;;
    s-orphan-del) sed -i '' '/# guard:s-orphan-del$/ s/if \[ -s "\$W\/orph" \]; then/if false; then/' "$f" ;;
    s-touched-del) sed -i '' '/# guard:s-touched-del$/ s/else conflict "\$rel" 지움 "새 구성에서 빠지는 파일을 프로젝트가 고쳤다"/else plan 지움 "$rel" x/' "$f" ;;
    s-atomic) sed -i '' '/# guard:s-atomic$/ s/if \[ "\$n_conf" != 0 \]; then/if false; then/' "$f" ;;
    s-dirs) sed -i '' '/# guard:s-dirs$/ s/mkdir -p "\$target\/\$rel"/true/' "$f" ;;
    s-link) sed -i '' '/# guard:s-link$/ s/plan 충돌 "\$rel" "심링크 자리에/plan 링크 "$rel" "/' "$f" ;;
    *) echo "모르는 SY_MUTANT: $SY_MUTANT" >&2; exit 2 ;;
  esac
  cmp -s "$f" "$ROOT/bin/paddock-render" && { echo "변이가 적용되지 않았다: $SY_MUTANT" >&2; exit 2; }
fi

printf 'PADDOCK_VERSION=0.0.9\nPADDOCK_MODULES="extra"\nPADDOCK_HARNESS=\nPROJECT_NAME=demo\n' > "$T/c.sh"
printf 'PADDOCK_VERSION=1.0.0\nPADDOCK_MODULES=""\nPADDOCK_HARNESS=\nPROJECT_NAME=demo\n' > "$T/c-noextra.sh"
"$V1/bin/paddock-render" render --config "$T/c.sh" --out "$T/r1" >/dev/null
"$V2/bin/paddock-render" render --config "$T/c.sh" --out "$T/r2" >/dev/null
"$V1/bin/paddock-render" render --config "$T/c-noextra.sh" --out "$T/r1x" >/dev/null
mkdir -p "$T/base"; printf 'node_modules/\n' > "$T/base/.gitignore"; printf '프로젝트 파일\n' > "$T/base/p.txt"
"$V1/bin/paddock-render" apply "$T/r1" "$T/base" >/dev/null
# 슬롯 채우기: D1 · D2 첫째 · D2 둘째 (같은 ID 둘)
awk '/paddock:design D1 -->/{print; print "내 D1"; next} /paddock:design D2 -->/{print; n++; print "내 D2-" n; next} {print}' "$T/base/m.md" > "$T/m" && mv "$T/m" "$T/base/m.md"

fresh() { rm -rf "$T/t"; cp -R "$T/base" "$T/t"; }
mkdir -p "$T/tmp"
sync2() { TMPDIR="$T/tmp" "$V2/bin/paddock-render" sync "$T/r2" "$T/t" "$@" > "$T/out" 2>&1; }

echo "S0 렌더가 버전을 plugin.json 에서 쓴다"
check "config 에 0.0.9 를 줘도 렌더본 PADDOCK_VERSION=1.0.0" S0 'grep -qx "PADDOCK_VERSION=1.0.0" "$T/r1/.paddock/config.sh" && [ "$(grep -c "^PADDOCK_VERSION=" "$T/r1/.paddock/config.sh")" = 1 ]'
check "manifest 머리줄도 1.0.0" S0 'head -n 1 "$T/r1/.paddock/manifest.tsv" | grep -q "paddock 1.0.0 manifest"'
check "version 하위 명령" S0 '[ "$("$V2/bin/paddock-render" version)" = 2.0.0 ]'

echo "S1 손대지 않은 대상 → 갱신"
fresh; sync2; rc=$?
check "exit 0" S1 '[ $rc = 0 ]'
check "고정 파일 갱신" S1 'grep -qx "A v2" "$T/t/a.md"'
check "같은 ID 슬롯 둘을 순서대로 보존 + 고정부 갱신" S1 '[ "$(grep -E "^내 |^z " "$T/t/m.md" | tr "\n" " ")" = "내 D1 내 D2-1 내 D2-2 z v2 " ]'
check "새 슬롯 D3 은 힌트째 비어 있고 계획에 보고" S1 'grep -q "<!-- 셋 힌트 -->" "$T/t/m.md" && grep -q "새 슬롯	m.md	D3#1" "$T/out"'
check "빠진 파일·빈 폴더 지움" S1 '[ ! -e "$T/t/gone.md" ] && [ ! -e "$T/t/gonem.md" ] && [ ! -e "$T/t/old" ]'
check "빠진 파일을 지워 비게 된 폴더라도 새 manifest 의 폴더(d)는 남는다" S1 '[ ! -e "$T/t/d/was.md" ] && [ -d "$T/t/d" ]'
check "슬롯이 비었던 o.md 는 D9 없이 갱신" S1 '[ "$(cat "$T/t/o.md" | tr "\n" " ")" = "o o v2 " ]'
check "seed 는 그대로, 「seed 바뀜」 보고" S1 'grep -qx "seed v1" "$T/t/s.md" && grep -q "seed 바뀜	s.md" "$T/out"'
check "새 실행 파일·새 링크·.gitignore 새 줄" S1 '[ -x "$T/t/new.sh" ] && [ "$(readlink "$T/t/lk2")" = a.md ] && grep -qx "b/" "$T/t/.gitignore" && grep -qx "node_modules/" "$T/t/.gitignore"'
check "프로젝트 파일 그대로, config·manifest 는 2.0.0" S1 'grep -qx "프로젝트 파일" "$T/t/p.txt" && grep -qx "PADDOCK_VERSION=2.0.0" "$T/t/.paddock/config.sh" && cmp -s "$T/r2/.paddock/manifest.tsv" "$T/t/.paddock/manifest.tsv"'
"$V2/bin/paddock-check" "$T/t" > "$T/chk" 2>&1; rc=$?
check "sync 뒤 paddock-check 통과" S1 '[ $rc = 0 ]'
before=$(tree_hash "$T/t"); sync2; rc=$?
check "두 번째 sync → 바뀔 것 없음, 트리 그대로" S1 '[ $rc = 0 ] && grep -q "바뀔 것 없음" "$T/out" && [ "$(tree_hash "$T/t")" = "$before" ]'

# 충돌 시나리오: exit 3 + 대상 트리 해시 그대로 + 사유 문구
conflict_case() { # $1 id $2 이름 $3 기대 문구
  local before rc want=$3; before=$(tree_hash "$T/t"); sync2; rc=$?
  check "$2 → exit 3, 아무것도 안 씀" "$1" '[ $rc = 3 ] && [ "$(tree_hash "$T/t")" = "$before" ] && grep -q "$want" "$T/out"'
}
echo "S2 프로젝트가 고친 고정부"
fresh; echo "내 수정" >> "$T/t/a.md"; conflict_case S2 "고정 파일 수정" "충돌	a.md	고정부를 프로젝트가 고쳤다"
fresh; sed -i '' 's/^y$/y 고침/' "$T/t/m.md"; conflict_case S2m "managed 슬롯 밖 수정" "충돌	m.md	고정부를 프로젝트가 고쳤다"
fresh; echo "내 수정" >> "$T/t/same.md"; conflict_case S2s "버전 사이 안 바뀐 고정 파일 수정(drift)" "충돌	same.md	고정부를 프로젝트가 고쳤다"
fresh; echo "내 수정" >> "$T/t/a.md"; sync2 --take-new a.md; rc=$?
check "--take-new a.md → 새 것으로, 나머지도 반영" S2t '[ $rc = 0 ] && [ "$(cat "$T/t/a.md" | tr "\n" " ")" = "<!-- paddock:fixed --> A v2 " ] && grep -q "갱신	a.md	고정부를 프로젝트가 고쳤다 (--take-new)" "$T/out"'

echo "S3 고아 슬롯"
fresh; sed -i '' 's/^<!-- 아홉 힌트 -->$/내 D9/' "$T/t/o.md"; conflict_case S3 "새 렌더에 없는 슬롯에 내용" "충돌	o.md	고아 슬롯.*D9#1"
fresh; sed -i '' 's/^<!-- 여덟 힌트 -->$/내 D8/' "$T/t/gonem.md"; conflict_case S3d "빠지는 파일의 슬롯에 내용" "충돌	gonem.md	고아 슬롯.*D8#1"

echo "S4 빠지는 파일을 프로젝트가 고침"
fresh; echo "내 수정" >> "$T/t/gone.md"; conflict_case S4 "빠지는 고정 파일 수정" "충돌	gone.md	새 구성에서 빠지는 파일을 프로젝트가 고쳤다"

echo "S5 새 파일 자리에 다른 기존 파일"
fresh; printf 'mine\n' > "$T/t/new.sh"; conflict_case S5 "new.sh 가 이미 있음" "충돌	new.sh	내용이 다른 기존 파일"

echo "S6 대상에서 지운 고정 파일"
fresh; rm "$T/t/same.md"; conflict_case S6 "same.md 지움" "충돌	same.md	대상에서 지워졌다"
sync2 --take-new same.md; rc=$?
check "--take-new same.md → 되살림" S6t '[ $rc = 0 ] && grep -qx "같음" "$T/t/same.md"'

echo "S7 링크 자리에 실제 파일"
fresh; printf 'x\n' > "$T/t/lk2"; conflict_case S7 "lk2 가 실제 파일" "충돌	lk2	심링크 자리에 실제 파일"

echo "S8 dry-run · seed 수정 · 대상 없음"
fresh; before=$(tree_hash "$T/t"); sync2 --dry-run; rc=$?
check "충돌 없는 dry-run → exit 0, 트리 그대로" S8 '[ $rc = 0 ] && [ "$(tree_hash "$T/t")" = "$before" ] && grep -q "갱신	a.md" "$T/out"'
fresh; echo "내 규칙" >> "$T/t/s.md"; sync2; rc=$?
check "고친 seed → 충돌 아님, 고친 내용 유지" S8s '[ $rc = 0 ] && grep -qx "내 규칙" "$T/t/s.md"'
mkdir -p "$T/empty"; "$V2/bin/paddock-render" sync "$T/r2" "$T/empty" > "$T/out" 2>&1; rc=$?
check "manifest 없는 대상 → exit 2 (처음은 apply)" S8n '[ $rc = 2 ] && grep -q "처음 들이는 것은 apply" "$T/out"'

echo "S9 설정 변경 — 같은 버전에서 모듈 끔"
fresh; "$V1/bin/paddock-render" sync "$T/r1x" "$T/t" > "$T/out" 2>&1; rc=$?
check "extra 끔 → e.md 지움, 슬롯 보존, exit 0" S9 '[ $rc = 0 ] && [ ! -e "$T/t/e.md" ] && grep -qx "내 D2-2" "$T/t/m.md" && grep -q "PADDOCK_MODULES=\"\"" "$T/t/.paddock/config.sh"'
"$V1/bin/paddock-check" "$T/t" > "$T/chk" 2>&1; rc=$?
check "모듈 끈 뒤 paddock-check 통과" S9 '[ $rc = 0 ]'

echo "S11 PADDOCK_SKIP 이 sync 에도 이어진다"
fresh; rm "$T/t/lk"; mkdir "$T/t/lk"; printf '서브에이전트\n' > "$T/t/lk/x.md"
conflict_case S11 "skip 없이 링크 자리에 폴더" "충돌	lk	심링크 자리에 실제 파일"
printf 'PADDOCK_SKIP="lk"\n' >> "$T/t/.paddock/config.sh"
"$V2/bin/paddock-render" render --config "$T/t/.paddock/config.sh" --out "$T/r2s" >/dev/null
TMPDIR="$T/tmp" "$V2/bin/paddock-render" sync "$T/r2s" "$T/t" > "$T/out" 2>&1; rc=$?
check "config 에 PADDOCK_SKIP=lk → 충돌 없음, 폴더 그대로, 지움 대상도 아님" S11 '[ $rc = 0 ] && grep -qx "서브에이전트" "$T/t/lk/x.md" && ! grep -q "	lk	" "$T/out" && grep -q "PADDOCK_SKIP=\"lk\"" "$T/t/.paddock/config.sh"'

echo "S10 임시 폴더"
check "성공·충돌·dry-run 어느 쪽이든 sync 임시 폴더가 남지 않는다" S10 '[ -z "$(ls -A "$T/tmp")" ]'

echo "통과 $pass · 실패 $fail"
[ "$fail" = 0 ] || echo "FAIL:$failed"
[ "$fail" = 0 ]
