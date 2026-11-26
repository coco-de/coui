#!/usr/bin/env bash
#
# A typography role and a size that departs from it cannot both be stated,
# and stating the size in the wrong place hides that from the code.
#
# `textLabelOpts` / `typographyColorOpts` end in `applyRole`, which decides
# whether the label keeps its role: it keeps it only when every field the
# style states — size first among them — is the role's own. The role's
# `font-size/<leaf>` variable is bound ON THE NODE, and a bound variable
# overwrites the literal the builder just wrote, so a label that says
# "bodySmall, but 10px on this rung" rendered at the role's 14 on every rung
# while the number the code stated reached nothing at all (#4760).
#
# Writing
#
#     makeLabel(text, lk, { ...textLabelOpts(lk, style), size: somethingElse })
#
# puts the size OUTSIDE that decision. `makeLabel` judges the role again on
# the opts it draws, so the canvas now gets `somethingElse` either way — but
# the opts carry a role the canvas will not use, and the place a reader goes
# to for the decision (`applyRole`) says the opposite of what happens. When
# `applyRole` was the only judge this shape was the whole defect: Avatar
# carried it for its five diameters (9.6 … 25.6px), all five rendering at the
# role's size, until it was found by tracing why a designer's copy disagreed.
#
# The fix is always the same shape: state the size INSIDE the style so the
# decision can see it —
#
#     makeLabel(text, lk, textLabelOpts(lk, { ...style, fontSize: size }))
#
# Then `applyRole` drops the role when it departs and the role's tracking
# ratio is carried over to the size that actually renders.
#
# WHAT THIS DOES NOT COVER: a size overwritten further away than the window
# below (assigned to the object later, or through a helper). This catches
# the literal shape that has occurred; it is not a proof of absence.

set -uo pipefail
cd "$(dirname "$0")/../../.."

readonly SRC="tools/figma-token-sync/src"
[ -d "$SRC" ] || { echo "SKIP: $SRC 없음"; exit 0; }

# 스프레드된 opts 빌더 호출 뒤 3줄 안에 `size:` 가 오는 자리.
hits=$(grep -rn -A3 -E '\.\.\.(textLabelOpts|typographyColorOpts)\(' "$SRC" --include='*.ts' 2>/dev/null \
  | grep -E '^[^:]+[-:][0-9]+[-:][[:space:]]*size:' || true)

if [ -n "$hits" ]; then
  echo "FAIL: role 을 세운 뒤 size 를 덮어쓴 자리 — applyRole 이 그 크기를 못 보고 역할을 남긴다."
  echo "      makeLabel 이 다시 판정해 크기는 캔버스에 닿지만, opts 가 쓰이지 않을 역할을 들고"
  echo "      다녀 판정이 두 곳에서 갈린다 (#4760 과 같은 형태)."
  echo "      size 를 스타일 안으로 옮겨라: textLabelOpts(lk, { ...style, fontSize: size })"
  echo
  printf '%s\n' "$hits"
  exit 1
fi

echo "PASS: 0 role-then-size override"
