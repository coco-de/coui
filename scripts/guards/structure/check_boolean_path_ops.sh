#!/usr/bin/env bash
#
# `Path.combine` does not survive the web build, and nothing else in this
# repo can tell you that.
#
# The injected cast is painted outside its box by clipping to "everything
# except the box". That knock-out was written the obvious way —
# `Path.combine(PathOperation.difference, outer, box)` — and it worked in
# `flutter test`, which is where every pixel assertion in this repo runs.
# In the browser it did not: the clip came back without the subtraction,
# so a hard opaque cast painted straight over the surface it belongs
# behind, and every unfilled surface under neo-brutalism rendered as a
# solid black block. Table, Fieldset, Chip, Badge/outline, Tabs/underline
# and EmptyState all at once, on Flutter only.
#
# The reason it went unnoticed is worth stating plainly, because it is
# the part that repeats: the test rasteriser and the shipping renderer
# disagree about this call. A pixel test proved the fix under one of them
# while the other stayed broken, so passing tests were evidence of
# nothing. Isolated by swapping only the path construction and leaving
# the `clipPath` call untouched — that fixed it, which puts the fault on
# the boolean op rather than on the clip.
#
# The replacement needs no boolean op at all: put both rings in ONE path
# and let `PathFillType.evenOdd` do the subtraction. A fill rule travels
# with the path, so both rasterisers read it the same way.
#
# The other boolean ops need no browser verdict either, because nothing
# needs them: a union is one outline drawn as a single path, and an
# intersection is nested clips (each clip narrows the last on every
# rasteriser). So the baseline below is zero across the three packages.
#
# WHAT THIS DOES NOT COVER: whether a replacement draws the same shape.
# That is the component's own tests' job, and `flutter test` can answer it
# for these constructions because they leave no boolean op for the two
# rasterisers to disagree about.

set -euo pipefail

# ratchet 기준값은 파일에 산다 — 이 스크립트 안의 상수가 아니다.
# 상수였을 때는 한 글자(`=0` → `=1`)가 위반 한 칸을 열었고, 그 한 글자가
# 통과 여부를 결정하는 **바로 그 PR 안에** 있었다. 파일이면 CODEOWNERS 의
# `/scripts/guards/**/*baseline*` 과 check_codeowners_ratchet_coverage.sh 가
# 그 diff 를 본다. 읽기 실패는 fail-closed 다 (lib/ratchet.sh 참조).
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"


REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

BASELINE_COUNT=$(ratchet_int "$_GUARD_DIR/boolean_path_ops_baseline.txt") || exit 1

hits="$(grep -rn 'Path\.combine' \
  packages/coui_flutter/lib packages/coui_core/lib packages/coui_web/lib \
  --include='*.dart' 2>/dev/null | grep -v '^\s*//' || true)"

# Comment lines that merely name the API (the doc comment on the fix
# explains why not to use it) are not uses.
hits="$(printf '%s\n' "$hits" | grep -v '//.*Path\.combine' || true)"

count=0
report=""

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  count=$((count + 1))
  report+="✗ ${line}"$'\n'
done <<< "$hits"

if (( count > BASELINE_COUNT )); then
  printf '%s' "$report"
  echo
  echo "    Path.combine does not perform its operation in the web build."
  echo "    Knock-out: put both rings in one path with PathFillType.evenOdd"
  echo "    (packages/coui_flutter/lib/src/util/injected_cast.dart)."
  echo "    Union: draw one outline. Intersection: nest clips."
  echo
  echo "boolean path ops: ${count} use(s), baseline ${BASELINE_COUNT}."
  exit 1
fi

echo "✅ boolean path ops: ${count} Path.combine use(s) (baseline ${BASELINE_COUNT})."
