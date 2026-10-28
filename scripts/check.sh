#!/usr/bin/env bash
# 자산 계약·공개 안전 검사. 자산을 고친 커밋 전에 돌린다. 규약의 원본은 assets/README.md
#   1 변수   — assets/·templates/ 의 {{VAR}} 가 전부 assets/README.md 에 있다
#   2 마커   — paddock:design / paddock:module 구간이 짝을 이루고 중첩되지 않는다
#   3 슬롯   — paddock:design 의 ID 가 assets/README.md 「설계 슬롯」 표에 있다
#   4 심링크 — assets/ 안의 심링크가 전부 풀린다
#   5 공개   — 레포에 일감 번호·홈 경로·비공개 산출물 레포 이름이 없다
# 종료코드: 0 통과 · 1 하나 이상 실패
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1
README=assets/README.md
fail=0
bad() { echo "  ✗ $*"; fail=1; }

asset_files() { find assets templates -type f ! -name .gitkeep ! -path "$README" | sort; }

echo "1 변수"
declared=$(grep -oE '\{\{[A-Z0-9_]+\}\}' "$README" | sort -u)
used=$(asset_files | xargs grep -ohE '\{\{[A-Z0-9_]+\}\}' 2>/dev/null | sort -u)
missing=$(comm -23 <(echo "$used") <(echo "$declared") | sed '/^$/d')
[ -z "$missing" ] && echo "  ✓ 사용 $(echo "$used" | sed '/^$/d' | wc -l | tr -d ' ')개 전부 선언됨" || bad "선언 안 된 변수: $(echo $missing)"

echo "2 마커"
marker_errors=$(asset_files | while read -r f; do
  awk -v f="$f" '
    /<!-- paddock:(design|module) [^ ]+ -->/ {
      if (open != "") { printf "%s:%d 구간 %s 이 닫히기 전에 다시 열림\n", f, NR, open }
      match($0, /paddock:(design|module)/); open = substr($0, RSTART + 8, RLENGTH - 8); next
    }
    /<!-- \/paddock:(design|module) -->/ {
      match($0, /paddock:(design|module)/); kind = substr($0, RSTART + 8, RLENGTH - 8)
      if (open == "") { printf "%s:%d 열리지 않은 %s 를 닫음\n", f, NR, kind }
      else if (open != kind) { printf "%s:%d %s 를 %s 로 닫음\n", f, NR, open, kind }
      open = ""
    }
    END { if (open != "") printf "%s 끝까지 %s 가 안 닫힘\n", f, open }
  ' "$f"
done)
[ -z "$marker_errors" ] && echo "  ✓ 짝·중첩 이상 없음" || { echo "$marker_errors" | while read -r l; do bad "$l"; done; fail=1; }

echo "3 슬롯"
slot_ids=$(grep -oE '^\| `D[0-9]+`' "$README" | grep -oE 'D[0-9]+' | sort -u)
used_ids=$(asset_files | xargs grep -ohE 'paddock:design D[0-9]+' 2>/dev/null | grep -oE 'D[0-9]+' | sort -u)
missing_ids=$(comm -23 <(echo "$used_ids") <(echo "$slot_ids") | sed '/^$/d')
[ -z "$missing_ids" ] && echo "  ✓ 슬롯 $(echo "$used_ids" | sed '/^$/d' | wc -l | tr -d ' ')개 전부 표에 있음" || bad "표에 없는 슬롯: $(echo $missing_ids)"

echo "4 심링크"
links=$(find assets -type l | sort)
broken=$(find -L assets -type l | sort)
[ -z "$broken" ] && echo "  ✓ 심링크 $(echo "$links" | sed '/^$/d' | wc -l | tr -d ' ')개 전부 풀림" || bad "깨진 심링크: $(echo $broken)"

echo "5 공개"
# 패턴을 쪼개 적어 이 파일 자신도 검사 대상에 남긴다
pat="LIFE""-[0-9]|/Us""ers/|corral""-specs"
hits=$(git ls-files -co --exclude-standard | xargs grep -nE "$pat" 2>/dev/null)
[ -z "$hits" ] && echo "  ✓ 일감 번호·홈 경로·비공개 레포 이름 0건" || { echo "$hits" | while read -r l; do bad "$l"; done; fail=1; }

[ "$fail" = 0 ] && echo "통과" || echo "실패"
exit "$fail"
