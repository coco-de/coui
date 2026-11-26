#!/usr/bin/env bash
#
# A surface's declaration and its wiring have to say the same word.
#
# `surface_role_audit.py` reports which material role each surface
# receives and where the answer comes from. This holds the invariants
# that must be true at every commit:
#
#   R1  a surface whose code reaches a role declares the same role
#   R2  a surface whose code reaches a role declares one at all
#   R3  a role declared on one platform is declared on the other, same word
#
# R2 is the one that keeps the axis honest. `webSurfaceMarkerFor(role)`
# already makes Web's *wiring* a compile error to omit, but nothing made
# the wiring say so in prose — and a role that only exists inside a
# resolver is a role nobody finds when they add the next surface. On
# Flutter there is not even the compile error: `surfaceFor(...)` takes
# the role positionally and a wrong one is a running program.
#
# R3 is what "한쪽만 하면 반쪽이다" costs when it is not checked. The two
# platforms wire the material through different mechanisms — a marker
# class on one, a resolver fold on the other — so a role changed on one
# side is invisible from the other until someone puts the two renders
# next to each other.
#
# WHAT THIS DELIBERATELY DOES NOT CHECK: that a declared role is *wired*.
# It is not, for most of the catalog, and asserting it would make this
# red for the whole epic and it would be turned off rather than fixed —
# the same reason `check_surface_eligibility.sh` runs one-directionally.
# The gap is the remaining work and `--gap` prints it.
#
# Nor does it check that the material reaches pixels. A role that resolves
# correctly and is then painted under an opaque fill passes here. That is
# a render test's job; #4218 measured what a name-matching guard is worth
# against a cut wire.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

AUDIT='scripts/audit/surface_role_audit.py'

if [ ! -x "$AUDIT" ]; then
  echo "❌ $AUDIT missing or not executable — the rule lives there and this"
  echo "   guard is only its invariant. Nothing was checked."
  exit 1
fi

rows="$("$AUDIT" --tsv)"

if [ -z "$rows" ]; then
  echo "❌ the audit produced no rows — treat as failure, not as a clean run:"
  echo "   a rule that classifies nothing cannot be satisfied."
  exit 1
fi

status=0

# Fields: platform, component, declared, direct, inherited, via.
# `-` means absent in every column.

# R1 — the code says one word, the doc says another.
mismatch=$(printf '%s\n' "$rows" |
  awk -F'\t' '$3!="-" && $4!="-" && $3!=$4 {
    printf "  %-8s %-34s declared %s, code reaches %s\n", $1, $2, $3, $4 }')
if [ -n "$mismatch" ]; then
  echo "❌ Declared role and wired role disagree. One of them is wrong, and"
  echo "   the screen follows the wiring:"
  printf '%s\n' "$mismatch"
  status=1
fi

# R2 — wired without a declaration.
undeclared=$(printf '%s\n' "$rows" |
  awk -F'\t' '$3=="-" && $4!="-" {
    printf "  %-8s %-34s code reaches %s, declares nothing\n", $1, $2, $4 }')
if [ -n "$undeclared" ]; then
  echo "❌ Reaches a role in code but never says so. Add one line to the"
  echo "   component's own class doc, next to its \`surface:behind\`:"
  printf '%s\n' "$undeclared"
  echo "     /// surface:functional — <what the code shows floats it>"
  echo "     /// surface:content — <why it sits in the content layer>"
  status=1
fi

# R3 — declared on one platform only, or with a different word.
#
# Compared on the component path, which is identical across the two
# packages by construction. A component that exists on one platform only
# is not a parity failure — it is a missing component, and that is what
# the component-parity checks are for.
cross=$(printf '%s\n' "$rows" |
  awk -F'\t' '$3!="-" {print $2"\t"$1"\t"$3}' |
  sort |
  awk -F'\t' '
    { if ($1 == prev) {
        if ($3 != prevrole)
          printf "  %-34s %s says %s, %s says %s\n", $1, prevplat, prevrole, $2, $3;
        seen[$1] = 2;
      } else { seen[$1] = 1 }
      prev=$1; prevplat=$2; prevrole=$3 }')
if [ -n "$cross" ]; then
  echo "❌ The two platforms declare different roles for the same surface:"
  printf '%s\n' "$cross"
  status=1
fi

if [ "$status" -eq 0 ]; then
  declared=$(printf '%s\n' "$rows" | awk -F'\t' '$3!="-"' | wc -l | tr -d ' ')
  wired=$(printf '%s\n' "$rows" | awk -F'\t' '$4!="-"' | wc -l | tr -d ' ')
  echo "✅ surface roles: $declared declarations, $wired wired, all agreeing"
  echo "   (declared-but-unwired is the remaining reach — \`$AUDIT --gap\`)"
fi

exit "$status"
