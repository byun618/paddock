#!/usr/bin/env bash
# 오프라인 시험용 가짜 gh — 로컬 bare 원격(FGH_ORIGIN) 위에서 task 스크립트(task-pr.sh·task-finish.sh)가 부르는 gh 호출만 흉내 낸다.
# 시험이 이 파일을 <bin>/gh 로 복사해 PATH 앞에 둔다. 상태는 FGH_STATE 폴더의 파일이다(PR 하나 = pr/<번호>).
#   pr/<번호>: state= base= head= draft= fork= oid= mergeCommit= mergedAt= title=   (oid 는 head 브랜치가 원격에 있으면 매번 다시 읽는다)
# GitHub 흉내:
#   - 간접 머지: OPEN PR 의 head 가 base 끝에서 닿으면 MERGED 로 바꾼다 — base 가 FGH_DEFAULT(기본 main)일 때만(GHES 3.12 문서 문장).
#     FGH_INDIRECT=off 면 하지 않는다(간접 머지 미확인 경로)
#   - OPEN PR 의 head 브랜치가 원격에서 사라지면 CLOSED (G4)
#   - pr merge 는 merge-tree 로 merge commit(부모 2개)을 만들어 base 를 옮긴다. --match-head-commit 이 지금 head 와 다르면 거절
# 주입: FGH_MERGEABLE(판정 고정, 예 UNKNOWN) · FGH_MERGE_FAIL=1 · FGH_MERGE_BAD_PARENT=1(둘째 부모 = head^) · FGH_CREATE_FAIL=1 · FGH_RELEASE_FAIL=1 · FGH_ON_RELEASE_CREATE(bash 명령)
#   FGH_MERGED_AFTER=N — PR 마다 `pr view` N 번째 조회부터 간접 머지를 반영(대기 루프를 잠근다)
#   FGH_MERGEABLE_AFTER=N — `pr view --json mergeable` N 번째 조회까지는 UNKNOWN(재시도 루프를 잠근다)
#   FGH_HOOK_ON(인자 줄 glob) + FGH_HOOK_CMD(bash 명령) — 처음 맞는 호출 직전에 한 번 돌린다(예: 판정 조회 때 PR head 이동)
# 실 gh 흉내(gh 2.88.1): --jq 결과의 null 은 빈 줄 · 모르는 --json 필드는 실패 · release create 는 --verify-tag 가 없고 태그가 없으면
#   기본 브랜치 끝에 태그를 만든다(그래서 --verify-tag 가 빠지면 하네스가 잡는다).
# --jq 는 시스템 jq 로 푼다. 호출은 FGH_STATE/calls.txt 에 한 줄씩 남는다.
set -uo pipefail
: "${FGH_STATE:?FGH_STATE}" "${FGH_ORIGIN:?FGH_ORIGIN}"
DEFAULT="${FGH_DEFAULT:-main}"
mkdir -p "$FGH_STATE/pr" "$FGH_STATE/release"
printf 'gh' >> "$FGH_STATE/calls.txt"; for a in "$@"; do printf ' %q' "$a" >> "$FGH_STATE/calls.txt"; done; echo >> "$FGH_STATE/calls.txt"
og() { git --git-dir="$FGH_ORIGIN" "$@"; }
if [ -n "${FGH_HOOK_ON:-}" ] && [ ! -e "$FGH_STATE/hook-done" ]; then
  case "$*" in $FGH_HOOK_ON) touch "$FGH_STATE/hook-done"; bash -c "$FGH_HOOK_CMD" >> "$FGH_STATE/hook.log" 2>&1 || { echo "fake gh: hook 실패" >&2; exit 1; } ;; esac
fi
bump() { local f="$FGH_STATE/count-$1" c; c=$(( $(cat "$f" 2>/dev/null || echo 0) + 1 )); echo "$c" > "$f"; echo "$c"; }
fail() { echo "fake gh: $1" >&2; exit 1; }

# PR 파일 읽기·쓰기
load() { # $1 번호 → state base head draft fork oid mergeCommit mergedAt title
  local f="$FGH_STATE/pr/$1"; [ -f "$f" ] || return 1
  state=""; base=""; head=""; draft=false; fork=false; oid=""; mergeCommit=""; mergedAt=""; title="PR $1"
  # shellcheck disable=SC1090
  . "$f"
}
save() {
  { printf 'state=%q\nbase=%q\nhead=%q\ndraft=%q\nfork=%q\noid=%q\nmergeCommit=%q\nmergedAt=%q\ntitle=%q\n' \
      "$state" "$base" "$head" "$draft" "$fork" "$oid" "$mergeCommit" "$mergedAt" "$title"; } > "$FGH_STATE/pr/$1"
}
refresh() { # GitHub 쪽 상태 갱신 — head 끝 다시 읽기·head 삭제로 CLOSED·간접 머지
  local n="$1" live btip
  load "$n" || return 1
  [ "$state" = OPEN ] || return 0
  live="$(og rev-parse -q --verify "refs/heads/$head" 2>/dev/null || true)"
  if [ -z "$live" ]; then state=CLOSED; save "$n"; return 0; fi
  oid="$live"
  btip="$(og rev-parse -q --verify "refs/heads/$base" 2>/dev/null || true)"
  if [ "${FGH_INDIRECT:-on}" = on ] && [ "$base" = "$DEFAULT" ] && [ "${VIEWS:-999999}" -ge "${FGH_MERGED_AFTER:-1}" ] && [ -n "$btip" ] && og merge-base --is-ancestor "$oid" "$btip" 2>/dev/null; then
    state=MERGED; mergedAt="2026-10-26T00:00:00Z"; mergeCommit="$btip"
  fi
  save "$n"
}
mergeable_of() {
  [ -z "${FGH_MERGEABLE:-}" ] || { echo "$FGH_MERGEABLE"; return; }
  [ "${MQ:-999999}" -gt "${FGH_MERGEABLE_AFTER:-0}" ] || { echo UNKNOWN; return; }
  local btip; btip="$(og rev-parse "refs/heads/$base")"
  if og merge-tree --write-tree "$btip" "$oid" >/dev/null 2>&1; then echo MERGEABLE; else echo CONFLICTING; fi
}
pr_json() { # 현재 load 된 PR → JSON
  local n="$1" mc="null"
  [ -z "$mergeCommit" ] || mc="{\"oid\":\"$mergeCommit\"}"
  jq -n --argjson number "$n" --arg state "$state" --arg base "$base" --arg head "$head" --argjson draft "$draft" --argjson fork "$fork" \
    --arg oid "$oid" --argjson mc "$mc" --arg mergedAt "$mergedAt" --arg title "$title" --arg mergeable "$(mergeable_of)" \
    '{number: $number, state: $state, baseRefName: $base, headRefName: $head, isDraft: $draft, isCrossRepository: $fork,
      headRefOid: $oid, mergeCommit: $mc, mergedAt: (if $mergedAt == "" then null else $mergedAt end),
      mergedBy: (if $state == "MERGED" then {login: "fake"} else null end), title: $title, mergeable: $mergeable,
      url: ("https://github.example/o/r/pull/" + ($number | tostring))}'
}
# --json 필드·--jq 적용
PR_FIELDS=",number,state,baseRefName,headRefName,isDraft,isCrossRepository,headRefOid,mergeCommit,mergedAt,mergedBy,title,mergeable,url,"
REL_FIELDS=",tagName,url,isPrerelease,"
emit() { # $1 JSON, $2 필드 목록, $3 jq 식(없으면 필드만 뽑아 출력), $4 허용 필드 목록
  local sel f
  for f in $(echo "$2" | tr ',' ' '); do case "$4" in *",$f,"*) ;; *) fail "Unknown JSON field: \"$f\"" ;; esac; done
  sel="$(echo "$2" | awk -F, '{for (i = 1; i <= NF; i++) printf "%s%s: .%s", (i > 1 ? ", " : ""), $i, $i}')"
  if echo "$1" | jq -e 'type == "array"' >/dev/null; then sel="map({$sel})"; else sel="{$sel}"; fi
  if [ -n "$3" ]; then echo "$1" | jq -c "$sel" | jq -r "$3" | sed 's/^null$//'; else echo "$1" | jq -c "$sel"; fi
}
opt() { # 인자 목록에서 --이름 값
  local want="$1"; shift
  while [ $# -gt 0 ]; do [ "$1" = "$want" ] && { echo "${2:-}"; return 0; }; shift; done
  return 1
}

case "${1:-} ${2:-}" in
  "pr view")
    n="$3"; shift 3
    [ -f "$FGH_STATE/pr/$n" ] || fail "no pull request #$n"
    J="$(opt --json "$@")"
    case ",$J," in *,mergeable,*) MQ="$(bump "mergeable-$n")" ;; *) VIEWS="$(bump "view-$n")" ;; esac
    refresh "$n" || fail "no pull request #$n"
    emit "$(pr_json "$n")" "$J" "$(opt --jq "$@" || true)" "$PR_FIELDS" ;;
  "pr list")
    shift 2
    H="$(opt --head "$@" || true)"; B="$(opt --base "$@" || true)"; S="$(opt --state "$@" || echo open)"
    arr="[]"
    for f in "$FGH_STATE"/pr/*; do
      [ -f "$f" ] || continue
      n="$(basename "$f")"; refresh "$n"; load "$n"
      [ -z "$H" ] || [ "$head" = "$H" ] || continue
      [ -z "$B" ] || [ "$base" = "$B" ] || continue
      case "$S" in open) [ "$state" = OPEN ] || continue ;; merged) [ "$state" = MERGED ] || continue ;; closed) [ "$state" = CLOSED ] || continue ;; all) ;; esac
      arr="$(echo "$arr" | jq -c --argjson p "$(pr_json "$n")" '. + [$p]')"
    done
    emit "$arr" "$(opt --json "$@")" "$(opt --jq "$@" || true)" "$PR_FIELDS" ;;
  "pr create")
    shift 2
    [ "${FGH_CREATE_FAIL:-0}" = 0 ] || fail "흉내 pr create 실패"
    B="$(opt --base "$@")"; H="$(opt --head "$@")"; T="$(opt --title "$@" || echo t)"
    og rev-parse -q --verify "refs/heads/$H" >/dev/null || fail "head $H 가 원격에 없다"
    last="$(ls "$FGH_STATE/pr" | sort -n | tail -1)"; n=$(( ${last:-0} + 1 ))
    state=OPEN; base="$B"; head="$H"; draft=false; fork=false; oid="$(og rev-parse "refs/heads/$H")"; mergeCommit=""; mergedAt=""; title="$T"
    save "$n"; BF="$(opt --body-file "$@" || true)"; [ -z "$BF" ] || cp "$BF" "$FGH_STATE/body-$n"
    echo "https://github.example/o/r/pull/$n" ;;
  "pr edit")
    n="$3"; shift 3
    load "$n" || fail "no pull request #$n"
    title="$(opt --title "$@" || echo "$title")"; save "$n"
    BF="$(opt --body-file "$@" || true)"; [ -z "$BF" ] || cp "$BF" "$FGH_STATE/body-$n" ;;
  "pr merge")
    n="$3"; shift 3
    [ "${FGH_MERGE_FAIL:-0}" = 0 ] || fail "흉내 pr merge 거절"
    refresh "$n" || fail "no pull request #$n"; load "$n"
    [ "$state" = OPEN ] || fail "PR #$n 은 $state"
    M="$(opt --match-head-commit "$@" || true)"
    [ -z "$M" ] || [ "$M" = "$oid" ] || fail "Head branch was modified. Review and try the merge again."
    btip="$(og rev-parse "refs/heads/$base")"
    tree="$(og merge-tree --write-tree "$btip" "$oid")" || fail "merge conflict"
    p2="$oid"; [ "${FGH_MERGE_BAD_PARENT:-0}" = 0 ] || p2="$(og rev-parse "$oid^")"  # 주입: 둘째 부모가 head 가 아닌 머지 커밋
    mc="$(GIT_AUTHOR_NAME=gh GIT_AUTHOR_EMAIL=gh@example GIT_COMMITTER_NAME=gh GIT_COMMITTER_EMAIL=gh@example \
      og commit-tree "$tree" -p "$btip" -p "$p2" -m "Merge pull request #$n from o/$head")"
    og update-ref "refs/heads/$base" "$mc" "$btip" || fail "base 가 그새 움직였다"
    state=MERGED; mergeCommit="$mc"; mergedAt="2026-10-26T00:00:00Z"; save "$n" ;;
  "release view")
    T="$3"; shift 3
    [ -f "$FGH_STATE/release/$T" ] || fail "release not found"
    emit "$(jq -n --arg t "$T" --arg pre "$(cat "$FGH_STATE/release/$T")" '{tagName: $t, url: ("https://github.example/o/r/releases/tag/" + $t), isPrerelease: ($pre == "pre")}')" \
      "$(opt --json "$@" || echo tagName,url,isPrerelease)" "$(opt --jq "$@" || true)" "$REL_FIELDS" ;;
  "release create")
    T="$3"; shift 3
    [ "${FGH_RELEASE_FAIL:-0}" = 0 ] || fail "흉내 release create 실패"
    if ! og rev-parse -q --verify "refs/tags/$T" >/dev/null; then
      case " $* " in
        *" --verify-tag "*) fail "tag $T 가 원격에 없다(--verify-tag)" ;;
        *) og update-ref "refs/tags/$T" "$(og rev-parse "refs/heads/$DEFAULT")" ;;  # 실 gh: 태그가 없으면 기본 브랜치 끝에 만든다
      esac
    fi
    [ ! -f "$FGH_STATE/release/$T" ] || fail "release $T 가 이미 있다"
    F="$(opt --notes-file "$@")"; [ -s "$F" ] || fail "노트 파일 없음"
    pre=full; case " $* " in *" --prerelease "*) pre=pre ;; esac
    echo "$pre" > "$FGH_STATE/release/$T"
    [ -z "${FGH_ON_RELEASE_CREATE:-}" ] || bash -c "$FGH_ON_RELEASE_CREATE" || exit 1
    echo "https://github.example/o/r/releases/tag/$T" ;;
  *) fail "모르는 호출 $*" ;;
esac
