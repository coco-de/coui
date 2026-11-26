#!/usr/bin/env bash
#
# 플러그인 번들에 **공유 소스 해시가 실제로 박혀야** 한다. **net-new 0** (ratchet 아님).
#
# 무엇을 막는가: 코드를 고쳤는데 캔버스가 안 바뀌고, 로그는 전 엔트리를
# `⏭ skipped — unchanged` 로 보고하는 상태.
#
# per-entry 해시는 `fnv1a(빌더 소스 + 그 컴포넌트의 v3 데이터 + 공유 소스 해시)` 다.
# 앞의 두 조각만으로는 부족하다 — `Function.prototype.toString` 은 **그 함수 자신의
# 텍스트**만 돌려주고 그것이 호출하는 것의 본문은 담지 않는다. 그래서 144 개 빌더가
# 전부 통과하는 공유 그리기 코드(chrome 적용 · focus ring · 라벨 · pad/radius 바인딩)를
# 고치면 144 개 해시가 전부 그대로이고, 다음 실행이 전부 skip 한다. 수정은 실재하고,
# 캔버스는 옛 그림을 유지하며, 아무도 그렇게 말하지 않는다.
#
# 이 실패는 사용자가 "고쳤다고 했는데 안 바뀌었다" 로 만나고, 그때 의심하는 것은
# 해시가 아니라 수정 자체다.
#
# 해시는 `npm run build` 가 계산해 `--define` 으로 주입한다. 플러그인 VM 에는
# 파일시스템이 없으니 구울 수밖에 없고, 그래서 **주입이 빠진 번들은 조용히 `dev` 로
# 떨어진다** — 상수 하나가 고정값이 되어 무효화가 통째로 죽는다. 이 가드가 보는 것이
# 정확히 그 상태다.
#
# 하네스는 `tsx` 로 돌아 define 이 없고 `dev` 를 받는다. 그게 옳다 — 하네스는 매번
# 새 double 에 빌드하므로 오염될 skip 경로가 없다. 그래서 이 가드는 **번들만** 본다.
#
# Usage: check_shared_source_hash.sh

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly TOOL="tools/figma-token-sync"
readonly PKG="$TOOL/package.json"
readonly BUNDLE="$TOOL/code.js"
readonly SRC="$TOOL/src/build-hash.ts"

for f in "$PKG" "$SRC"; do
  if [ ! -f "$f" ]; then
    echo "❌ $f 없음 — 경로가 바뀌었으면 이 가드도 따라가야 한다."
    exit 1
  fi
done

# ── 1. 해시가 per-entry 해시에 실제로 섞이는지 ──────────────────────────────
# 상수만 있고 아무도 안 읽으면 이 전체가 장식이다 — 이 레포에서 선언만 되고 소비처가
# 없는 값이 반복적으로 문제였다.
#
# generate.ts 자신의 텍스트에 없어도 위반은 아니다 — per-entry 해시 레시피가
# 순환 import 를 피해 별도 모듈(예: content-hash.ts)로 빠지고 generate.ts 는
# 그 모듈의 함수만 부르는 리팩터가 이미 한 번 있었다. 그래서 generate.ts 자신과,
# generate.ts 가 상대경로로 import 하는 로컬 모듈까지 함께 본다 — 상수가
# 정의(build-hash.ts)와 소비처 둘 중 어디에도 없는 파일들만 걸러진다.
consumer_files=("$TOOL/src/generate.ts")
while IFS= read -r rel; do
  candidate="$TOOL/src/${rel#./}.ts"
  [ -f "$candidate" ] && consumer_files+=("$candidate")
done < <(grep -oE "from '\./[a-zA-Z0-9_-]+'" "$TOOL/src/generate.ts" | sed -E "s/from '//;s/'\$//")
if ! grep -q 'kSharedSourceHash' "${consumer_files[@]}"; then
  echo "❌ generate.ts (또는 그것이 로컬 import 하는 모듈) 가 kSharedSourceHash 를 읽지 않는다."
  echo "   per-entry 해시에 섞이지 않으면 이 상수는 아무것도 무효화하지 않는다."
  echo "   확인한 파일: ${consumer_files[*]}"
  exit 1
fi

# ── 2. 빌드 스크립트가 주입하는지 ───────────────────────────────────────────
inject_count=$(grep -c '__SHARED_SOURCE_HASH__' "$PKG")
if [ "$inject_count" -lt 2 ]; then
  echo "❌ $PKG 에 --define:__SHARED_SOURCE_HASH__ 이 ${inject_count}건 — build/watch 둘 다 필요하다."
  echo "   watch 로 만든 번들이 dev 로 떨어지면 개발 중에는 무효화가 죽는다."
  exit 1
fi

# ── 3. 빌드된 번들에 실제 값이 박혔는지 ─────────────────────────────────────
# `code.js` 는 gitignore 대상이라 없을 수 있다 — 결정론적 산출물이므로 만든다
# (`check_plugin_bundle_target.sh` 와 같은 근거).
if [ ! -f "$BUNDLE" ]; then
  echo "ℹ️  $BUNDLE 없음 — 빌드한다 (결정론적 산출물, gitignore 대상)."
  if ! (cd "$TOOL" && npm run build >/dev/null 2>&1); then
    echo "❌ 번들 빌드 실패 — cd $TOOL && npm run build 를 직접 돌려 확인해라."
    exit 1
  fi
fi

# define 이 먹으면 `typeof "…" === 'string'` 이 상수 접힘되어 `true ? "<hash>" : "dev"`
# 형태로 남는다. 16 자리 hex 가 그 자리에 있는지를 본다.
if ! grep -qE 'kSharedSourceHash = true \? "[0-9a-f]{16}"' "$BUNDLE"; then
  echo "❌ 번들의 kSharedSourceHash 가 실제 해시가 아니다 (dev 로 떨어졌거나 형태가 바뀌었다)."
  echo
  echo "   현재 값:"
  grep -oE 'kSharedSourceHash[^;]{0,70}' "$BUNDLE" | head -2 | sed 's/^/     /'
  echo
  echo "   npm run build 로 다시 만들어라. dev 로 굳은 번들은 공유 코드를 고쳐도"
  echo "   144 개 컴포넌트 전부를 \`⏭ skipped — unchanged\` 로 보고한다."
  exit 1
fi

hash=$(grep -oE 'kSharedSourceHash = true \? "[0-9a-f]{16}"' "$BUNDLE" | grep -oE '[0-9a-f]{16}')

# ── 4. 그 해시가 현재 소스와 일치하는지 ─────────────────────────────────────
# 낡은 번들은 "박혀 있으니 통과" 로 지나갈 수 있다 — 그 번들은 지금 소스가 아니라
# 빌드 시점 소스를 무효화 기준으로 들고 있다.
expected=$(cd "$TOOL" && find src code.ts -name '*.ts' -not -path 'src/data/*' | sort | xargs cat | shasum -a 256 | cut -c1-16)
if [ "$hash" != "$expected" ]; then
  echo "❌ 번들의 해시가 현재 소스와 다르다 — 번들이 낡았다."
  echo "   번들: $hash"
  echo "   소스: $expected"
  echo "   npm run build 로 다시 만들어라."
  exit 1
fi

# ── 5. 엔트리 소스 해시 표 — 주입이 빠지면 조용히 옛 레시피(전체 해시)로 돌아간다 ─────────
# 엔트리별 해시는 번들 단계가 import 그래프에서 계산해 `--define:__ENTRY_SOURCE_HASHES__` 로 굽는다.
# 이 주입이 빠진 번들은 표가 `null` 이 되어 모든 엔트리가 `kSharedSourceHash` 로 되돌아간다 —
# 틀린 방향의 오류는 아니지만(과잉 무효화) 정밀도가 소리 없이 사라진다.
entry_inject_count=$(grep -c '__ENTRY_SOURCE_HASHES__' "$PKG")
if [ "$entry_inject_count" -lt 2 ]; then
  echo "❌ $PKG 에 --define:__ENTRY_SOURCE_HASHES__ 이 ${entry_inject_count}건 — build/watch 둘 다 필요하다."
  exit 1
fi
if ! grep -qE "kEntrySourceHashes = true \? JSON\.parse\(" "$BUNDLE"; then
  echo "❌ 번들의 kEntrySourceHashes 에 표가 박혀 있지 않다 — 모든 엔트리가 전체 해시로 되돌아간다."
  echo "   npm run build 로 다시 만들어라."
  exit 1
fi

echo "✅ 공유 소스 해시 주입 확인 — 번들 $hash · 소스와 일치 · generate 가 소비 (하드 0)."
