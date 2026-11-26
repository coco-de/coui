#!/usr/bin/env bash
# main 이 움직이면 Figma 플러그인 번들을 다시 굽는다 — 남의 체크아웃은 건드리지 않고.
#
# 왜: 플러그인은 이 컴퓨터의 `code.js` 한 파일(manifest 가 가리키는 경로)을 읽는다.
# 머지는 그 파일을 바꾸지 않으므로, 머지 뒤 누군가 다시 빌드하기 전까지 캔버스는 옛
# 코드를 그린다. 그런데 "main 체크아웃에서 빌드" 는 그 체크아웃이 다른 브랜치·미저장
# 상태일 때 위험하고, `checkout main` 이 거부된 뒤 이어진 pull 이 남의 브랜치를 옮긴
# 사고도 있었다. 그래서 이 스크립트는 **전용 빌드 워크트리**(origin/main detached)에서
# 굽고 `code.js` 만 목적지로 복사한다 — 목적지 워크트리의 git 상태는 0 만큼도 안
# 움직인다.
#
# 사용:
# 적재 후 승격 (#4909): 굽는 것과 갈아끼우는 것을 나눈다.
#
# Figma 의 dev 플러그인은 `code.js` 가 **다시 쓰이면** 핫리로드로 샌드박스를 죽인다
# — 내용이 바이트 단위로 같아도 그렇다(2026-09-15 실측: 위젯북만 건드린 머지로 구운
# 번들의 공유소스 해시가 이전과 동일했는데도 돌던 Generate 가 로그 없이 죽었다).
# 그래서 무인으로 도는 쪽은 `code.js` 를 절대 건드리지 않는다: 새 번들은
# `code.js.next` 로 적재되고, 사람이 플러그인을 닫은 뒤 `--promote` 가 갈아끼운다.
# 느린 부분(fetch · npm ci · esbuild)은 그대로 무인이고, 위험한 1바이트만 사람이 쥔다.
#
# 실패 방향이 뒤집히는 것이 요점이다 — 잘못돼도 번들이 낡을 뿐이고, 그건
# `--check` 한 줄과 플러그인의 `낡은 세트 K / 전체 N` 이 이미 말해 준다. 반대로
# 지금까지의 실패는 무로그 사망이었고, 긴 실행을 통째로 날렸다.
#
#   scripts/figma/rebuild_bundle_from_main.sh            # 굽고 code.js.next 로 적재만 (기본)
#   scripts/figma/rebuild_bundle_from_main.sh --promote  # 적재된 것을 code.js 로 승격
#   scripts/figma/rebuild_bundle_from_main.sh --now      # 적재 + 승격 (Generate 가 안 돌 때만)
#   scripts/figma/rebuild_bundle_from_main.sh --check    # 할 일이 있으면 0, 없으면 1 (오르카 precheck 용)
#   scripts/figma/rebuild_bundle_from_main.sh --force    # 목적지 번들이 남의 것이어도 덮는다
#
# 환경변수:
#   COUI_BUNDLE_DEST      번들 목적지 디렉터리 (기본 $HOME/orca/coui/tools/figma-token-sync)
#   COUI_BUNDLE_WORKTREE  빌드 전용 워크트리 (기본 $HOME/orca/coui-bundle)
#
# 오르카 자동화 등록 예 (main 카드에서, 머지 뒤 한 번):
#   orca automations create --name "CoUI 번들 자동 재빌드" --trigger "*/15 * * * *" \
#     --workspace path:$HOME/orca/coui --workspace-mode existing --reuse-session --provider claude \
#     --precheck "bash scripts/figma/rebuild_bundle_from_main.sh --check" \
#     --prompt "bash scripts/figma/rebuild_bundle_from_main.sh 를 실행하고 마지막 줄을 그대로 보고하라. 실패하면 원인 한 줄."
#
# 자동화는 플래그 없이 부른다 — 기본이 적재라, 무인 실행이 `code.js` 를 건드릴
# 경로가 아예 없다. `--now` 를 자동화 프롬프트에 넣지 마라: 그게 이 수정이
# 되돌리는 바로 그 동작이다.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="${COUI_BUNDLE_DEST:-$HOME/orca/coui/tools/figma-token-sync}"
BUILD_WT="${COUI_BUNDLE_WORKTREE:-$HOME/orca/coui-bundle}"
TOOL_REL="tools/figma-token-sync"
MODE="stage"
FORCE="${COUI_BUNDLE_FORCE:-0}"
for a in "$@"; do
  case "$a" in
    --check) MODE="check" ;;
    --promote) MODE="promote" ;;
    --now) MODE="now" ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,44p' "$0"; exit 0 ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done

STAGED="$DEST/code.js.next"
STAGED_SIDECAR="$DEST/code.js.next.owner.json"

read_sha() { [ -f "$1" ] && python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("sha",""))' "$1" || printf ''; }

# 승격 — 적재된 번들을 `code.js` 로 갈아끼운다. 같은 디렉터리 안 `mv` 라 원자적이고,
# 플러그인이 반쯤 쓰인 파일을 읽을 창이 없다.
promote() {
  if [ ! -f "$STAGED" ]; then
    log "적재된 번들이 없다 — 먼저 플래그 없이 실행해 구워라."
    return 1
  fi
  # 스탬프 없이 승격하면 `code.js` 는 새것인데 사이드카는 옛 sha 를 말한다 —
  # `--check` 가 영원히 "재빌드 필요" 를 내고 `status` 가 거짓을 보고한다.
  if [ ! -f "$STAGED_SIDECAR" ]; then
    log "⛔ 적재된 번들에 출처 스탬프가 없다 ($STAGED_SIDECAR)."
    log "   승격하면 code.js 와 사이드카가 어긋난다. 플래그 없이 다시 구워라."
    return 1
  fi
  # 내용이 같으면 파일을 다시 쓰지 않는다. mtime 만 움직여도 핫리로드가 돈다.
  if [ -f "$DEST/code.js" ] && cmp -s "$STAGED" "$DEST/code.js"; then
    mv -f "$STAGED_SIDECAR" "$DEST/code.js.owner.json"
    rm -f "$STAGED"
    echo "번들 내용 동일 — code.js 를 다시 쓰지 않았다 (출처 스탬프만 갱신, 플러그인 재시작 불필요)"
    return 0
  fi
  mv -f "$STAGED" "$DEST/code.js"
  mv -f "$STAGED_SIDECAR" "$DEST/code.js.owner.json"
  echo "번들 출처 = main $(read_sha "$DEST/code.js.owner.json") · $(date -u +%Y-%m-%dT%H:%M:%SZ) · $DEST/code.js (플러그인을 닫았다 다시 열어야 반영)"
}

log() { printf '%s\n' "$*" >&2; }

# 1. origin/main 의 현재 sha
git -C "$REPO_ROOT" fetch -q origin main
MAIN_SHA="$(git -C "$REPO_ROOT" rev-parse --short=9 origin/main)"

# 2. 목적지에 깔린 번들의 출처 (사이드카)
DEST_SIDECAR="$DEST/code.js.owner.json"
dest_sha=""; dest_ref=""; dest_wt=""
if [ -f "$DEST_SIDECAR" ]; then
  dest_sha="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("sha",""))' "$DEST_SIDECAR")"
  dest_ref="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("ref",""))' "$DEST_SIDECAR")"
  dest_wt="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("worktree",""))' "$DEST_SIDECAR")"
fi

staged_sha="$(read_sha "$STAGED_SIDECAR")"

if [ "$MODE" = "check" ]; then
  if [ "$dest_sha" = "$MAIN_SHA" ] && [ "$dest_ref" = "main" ]; then
    log "번들 출처 = main $MAIN_SHA — 재빌드 불필요"; exit 1
  fi
  # 이미 구워 적재해 뒀으면 다시 굽지 않는다 — 승격은 사람의 일이고, 그때까지
  # 15분마다 같은 번들을 다시 굽는 것은 낭비다.
  if [ "$staged_sha" = "$MAIN_SHA" ] && [ -f "$STAGED" ]; then
    log "main $MAIN_SHA 가 이미 적재돼 있다 ($STAGED) — --promote 대기 중, 재빌드 불필요"; exit 1
  fi
  log "main $MAIN_SHA ≠ 깔린 번들(${dest_ref:-없음} ${dest_sha:-}) — 재빌드 필요"; exit 0
fi

if [ "$MODE" = "promote" ]; then
  promote; exit $?
fi

# 3. 목적지 번들이 남의 것(다른 워크트리 · 비-main 브랜치)이면 멈춘다 — bundle-owner 와 같은 규칙.
#    적재만 할 때는 `code.js` 를 건드리지 않으므로 이 검사가 필요 없다 — 남의 번들을
#    덮는 것은 승격뿐이고, 승격은 `--now` 안에서만 이 경로를 지난다.
if [ "$MODE" = "now" ] && [ -f "$DEST/code.js" ] && [ -n "$dest_wt" ] && [ "$dest_ref" != "main" ] && [ "$dest_wt" != "$BUILD_WT" ] && [ "$FORCE" != "1" ]; then
  log "⛔ 목적지 번들은 다른 세션이 $dest_ref 로 구운 것이다 ($dest_wt). 덮으면 그 세션의 Figma 테스트가 사라진다."
  log "   합의됐으면 --force (또는 COUI_BUNDLE_FORCE=1) 로 다시 실행."
  exit 3
fi

# 4. 빌드 전용 워크트리 준비 (origin/main detached — 어떤 브랜치도 잡지 않는다)
if [ ! -d "$BUILD_WT/.git" ] && [ ! -f "$BUILD_WT/.git" ]; then
  log "빌드 워크트리 생성: $BUILD_WT (origin/main detached)"
  git -C "$REPO_ROOT" worktree add --detach "$BUILD_WT" origin/main -q
else
  git -C "$BUILD_WT" checkout -q --detach origin/main
fi
BUILT_SHA="$(git -C "$BUILD_WT" rev-parse --short=9 HEAD)"

# 5. 의존성 — lock 이 바뀌었거나 node_modules 가 없을 때만 npm ci
cd "$BUILD_WT/$TOOL_REL"
LOCK_HASH="$(shasum -a 256 package-lock.json | cut -c1-16)"
STAMP=".npm-ci.lock-hash"
if [ ! -d node_modules ] || [ ! -f "$STAMP" ] || [ "$(cat "$STAMP")" != "$LOCK_HASH" ]; then
  log "npm ci (lock 변경 또는 node_modules 없음)"
  npm ci --silent
  printf '%s' "$LOCK_HASH" > "$STAMP"
fi

# 6. 빌드 — 빌드 워크트리 안의 번들은 항상 우리 것이므로 FORCE 로 굽는다
COUI_BUNDLE_FORCE=1 npm run build --silent >/dev/null

# 7. 적재 — `code.js` 가 아니라 `code.js.next` 로. 돌고 있는 Generate 가 읽는 파일은
#    이 스크립트가 무인으로 도는 동안 한 번도 쓰이지 않는다.
mkdir -p "$DEST"
cp code.js "$STAGED"
python3 - "$STAGED_SIDECAR" "$BUILT_SHA" "$BUILD_WT" <<'PY'
import json, sys, re, datetime, socket
sidecar, sha, wt = sys.argv[1:4]
# `<x>.owner.json` describes `<x>` — true for both `code.js` and `code.js.next`.
bundle = open(sidecar[: -len('.owner.json')], encoding='utf-8').read()
m = re.search(r'kSharedSourceHash = true \? "([0-9a-f]{16})"', bundle)
json.dump({
  'worktree': wt, 'ref': 'main', 'sha': sha,
  'hash': m.group(1) if m else 'dev',
  'builtAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'host': socket.gethostname(), 'by': 'rebuild_bundle_from_main.sh',
}, open(sidecar, 'w'), indent=2)
PY

if [ "$MODE" = "now" ]; then
  promote; exit $?
fi

echo "적재됨 = main $BUILT_SHA · $(date -u +%Y-%m-%dT%H:%M:%SZ) · $STAGED"
echo "  승격: scripts/figma/rebuild_bundle_from_main.sh --promote  (플러그인을 닫은 뒤)"
echo "  그때까지 캔버스는 지금 깔린 번들(${dest_sha:-없음})을 계속 그린다 — 돌고 있는 Generate 는 안전하다."
