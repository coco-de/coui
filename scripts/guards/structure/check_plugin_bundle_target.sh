#!/usr/bin/env bash
#
# 플러그인 번들이 `async/await` 를 네이티브로 실어야 한다 — generator 로
# 다운컴파일되면 안 된다. **net-new 0** (ratchet 아님).
#
# 무엇을 막는가: `InternalError: stack underflow (op=..., pc=...)`. 플러그인을
# **열 때** 터지고, 터지면 아무것도 안 뜬다 — 컴포넌트 하나가 빠지는 게 아니라
# 플러그인 자체가 죽는다.
#
# 원인은 esbuild 타깃이었다. `--target=es2016` 은 async 를 네이티브로 두지 않고
# 상태머신으로 바꾼다 — 번들에 `__async` 헬퍼 18 개와 `function*` 17 개가 생기고,
# 소스에는 generator 가 하나도 없다. Figma 의 VM(QuickJS 계열)은 그 큰 generator
# 본문에서 스택 크기 계산을 틀린다. es2017 부터는 `async` 가 그대로 남아
# 변환 자체가 없어지고, 번들은 200KB 작아진다.
#
# 임계값이 있는 실패라 특히 나쁘다: 같은 타깃으로 오래 문제없이 빌드되다가,
# async 함수 하나가 커지는 순간 넘어간다. 실제로 그렇게 왔다 — `verifyFidelity`
# 에 코드가 붙으면서. 그래서 "전에는 됐다" 가 반증이 되지 않는다.
#
# 왜 Node 로는 못 잡았나: 번들을 Node 에서 평가해보는 검사가 이미 있었고 통과했다.
# Node 는 async 를 네이티브 지원하므로 다운컴파일된 상태머신도 잘 돈다 — 그 검사는
# 이 실패 모드에 **구조적으로 눈이 멀어 있다**. 플러그인 VM 과 같은 엔진에서
# 돌리는 것만이 본다.
#
# 이 가드가 보는 것과 못 보는 것:
#   본다     — async 다운컴파일(이 실패의 원인), 타깃 회귀
#   못 본다  — VM 이 거부하는 다른 문법. 그건 QuickJS 로 실제 평가해야 보이고,
#              그러려면 의존성이 필요하다(quickjs-emscripten). 이 가드는 의존성 0
#              으로 원인을 직접 막는 쪽을 고른 것이고, 그 한계를 여기 적어둔다.
#
# Usage: check_plugin_bundle_target.sh

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly TOOL="tools/figma-token-sync"
readonly PKG="$TOOL/package.json"
readonly BUNDLE="$TOOL/code.js"

if [ ! -f "$PKG" ]; then
  echo "❌ $PKG 없음 — 경로가 바뀌었으면 이 가드도 따라가야 한다."
  exit 1
fi

# ── 1. 빌드 스크립트의 타깃 ──────────────────────────────────────────────────
# `es2016` 이하를 이름으로 거부한다. 목록이 아니라 숫자 비교 — `es5`/`es6`/
# `es2015` 같은 다른 스펠링도 같은 다운컴파일을 한다.
#
# awk 로 판정한다 — `case` 의 패턴 `)` 는 `$( )` 안에서 닫는 괄호로 읽혀
# 파서를 깨뜨린다. `es5`/`es6` 도 숫자 비교에 자연히 걸린다(5 < 2017).
bad_targets=$(grep -oE '\-\-target=(es[0-9]+|esnext)' "$PKG" | sed 's/--target=//' | sort -u \
  | awk '$0 != "esnext" { n = $0; sub(/^es/, "", n); if (n + 0 < 2017) print }')

if [ -n "$bad_targets" ]; then
  echo "❌ 플러그인 빌드 타깃이 async 를 다운컴파일한다: $(echo "$bad_targets" | tr '\n' ' ')"
  echo
  echo "   es2017 이상으로 올려라. es2016 이하는 async 를 generator 상태머신으로"
  echo "   바꾸고, Figma 의 VM 은 그 큰 generator 에서 스택 계산을 틀려"
  echo "   \`InternalError: stack underflow\` 로 **플러그인이 열리지 않는다**."
  exit 1
fi

target_count=$(grep -cE '\-\-target=' "$PKG")
if [ "$target_count" -lt 2 ]; then
  echo "❌ $PKG 에 --target= 이 ${target_count}건 — build/watch 둘 다 명시해야 한다."
  echo "   타깃이 없으면 esbuild 기본값(esnext)이라 지금은 안전하지만, 이 가드가"
  echo "   볼 것이 없어진다."
  exit 1
fi

# ── 2. 빌드된 번들에 다운컴파일 흔적이 없는지 ────────────────────────────────
# 타깃만 보면 다른 경로로 빌드된 번들을 놓친다. 산출물 자체를 본다.
#
# `code.js` 는 gitignore 대상이라 없을 수 있다 — 그러면 만든다
# (결정론적 산출물이고 사람의 작업물이 아니다, `check_figma_variable_refs.sh`
# 와 같은 근거).
if [ ! -f "$BUNDLE" ]; then
  echo "ℹ️  $BUNDLE 없음 — 빌드한다 (결정론적 산출물, gitignore 대상)."
  if ! (cd "$TOOL" && npm run build >/dev/null 2>&1); then
    echo "❌ 번들 빌드 실패 — cd $TOOL && npm run build 를 직접 돌려 확인해라."
    exit 1
  fi
fi

# 소스에 generator 가 없다는 것이 이 검사의 전제다. 있으면 `function*` 는 정상
# 산출물이므로 전제를 먼저 확인한다 — 검사가 오탐을 내기 시작하면 읽히지 않는다.
src_generators=$(grep -rlE '^[^/]*\bfunction\s*\*' "$TOOL/src" "$TOOL/code.ts" 2>/dev/null | wc -l | tr -d ' ')
if [ "$src_generators" -ne 0 ]; then
  echo "ℹ️  소스에 generator 가 있다 — \`function*\` 검사는 건너뛰고 \`__async\` 만 본다."
fi

helpers=$(grep -c '__async' "$BUNDLE" || true)
if [ "$helpers" -ne 0 ]; then
  echo "❌ 번들에 esbuild 의 async→generator 헬퍼가 ${helpers}건 있다 (\`__async\`)."
  echo
  echo "   타깃이 es2017 이상인데 이 흔적이 남았다면 다른 경로로 빌드된 번들이다."
  echo "   \`npm run build\` 로 다시 만들어라 — Figma VM 은 이 형태에서"
  echo "   \`stack underflow\` 로 플러그인을 열지 못한다."
  exit 1
fi

if [ "$src_generators" -eq 0 ]; then
  gens=$(grep -o 'function\*' "$BUNDLE" | wc -l | tr -d ' ')
  if [ "$gens" -ne 0 ]; then
    echo "❌ 소스에 generator 가 없는데 번들에 \`function*\` 이 ${gens}건 있다."
    echo "   async 가 상태머신으로 변환된 흔적이다 — 위와 같은 실패로 이어진다."
    exit 1
  fi
fi

# async 가 실제로 네이티브로 실려 있는지. 0 이면 이 가드가 아무것도 보지 않는다는
# 뜻이고(소스에 async 가 20 개 있다), 볼 것이 없는 가드는 통과가 아니다.
native=$(grep -o 'async ' "$BUNDLE" | wc -l | tr -d ' ')
if [ "$native" -eq 0 ]; then
  echo "❌ 번들에 네이티브 \`async\` 가 0건 — 소스에는 있는데 산출물에 없다."
  echo "   추출이 깨졌거나 번들이 낡았다. 어느 쪽이든 이 가드는 판정할 수 없다."
  exit 1
fi

echo "✅ 플러그인 번들 타깃 안전 — async 네이티브 ${native}건 · 다운컴파일 헬퍼 0건 (하드 0)."
