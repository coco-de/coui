#!/usr/bin/env bash
#
# The rule and the wiring have to agree.
#
# `surface_eligibility_triage.sh` answers "is this a surface?" from two
# questions rather than from a list, because a list goes stale as
# components are added (`core/theme-axis-composition.md`). This guard
# holds the one invariant that must be true at every commit:
#
#   every component wired for the material is ELIGIBLE under the rule
#
# It is deliberately one-directional. The reverse — every eligible
# component is wired — is *not* true today and is the work S3/S4 carry;
# asserting it here would make this guard red for the whole epic and it
# would be turned off rather than fixed.
#
# The second check is narrower and catches the shape #4231 measured: a
# component that declares `surface:behind` but draws no fill. A material
# is a pair. Handed to a fill-less panel it stacks a backdrop pass inside
# the pass already running and draws a squared band around a box that
# isn't there — visible, and green under every test that only asks
# whether the axis was read.
#
# WHAT THIS DOES NOT CHECK: that the material actually reaches pixels.
# The rule is about eligibility. #4218 measured that a name-matching
# guard passed while the wiring was cut and only a render-value test
# failed — this guard is structural for the same reason and inherits the
# same blindness. The reach itself is fixed by tests, not here.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

TRIAGE='scripts/audit/surface_eligibility_triage.sh'

if [ ! -x "$TRIAGE" ]; then
  echo "❌ $TRIAGE missing or not executable — the rule lives there and"
  echo "   this guard is only its invariant. Nothing was checked."
  exit 1
fi

# One source for the rule. Re-implementing the classification here is how
# the guard and the audit would come to disagree about the same word.
rows="$("$TRIAGE" --tsv)"

if [ -z "$rows" ]; then
  echo "❌ the triage produced no rows — treat as failure, not as a clean"
  echo "   run: a rule that classifies nothing cannot be satisfied."
  exit 1
fi

status=0

# Read the machine mode, not the human table: its columns are a contract
# and the markdown's are not. Fields: platform, component, class, wiring,
# reason.
drifted=$(printf '%s\n' "$rows" |
  awk -F'\t' '$4=="wired" && $3!="ELIGIBLE" {printf "  %-8s %-34s %s / %s\n", $1, $2, $3, $5}')

if [ -n "$drifted" ]; then
  echo "❌ Wired for the surface material, but the rule does not call it a"
  echo "   surface. Either the wiring is wrong or the rule is:"
  printf '%s\n' "$drifted"
  echo "   A component whose Q2 answer cannot be inferred declares it:"
  echo "     /// surface:behind — <why content passes behind this one>"
  status=1
fi

# A declaration is a claim about what is behind a fill. Without a fill it
# claims nothing and the material has nothing to attach to.
for dir in $(grep -rl 'surface:behind' packages/coui_flutter/lib packages/coui_web/lib \
               --include='*.dart' 2>/dev/null | xargs -n1 dirname | sort -u); do
  if ! find "$dir" -maxdepth 1 -name '*.dart' \
       -exec grep -lqE '[Bb]ackgroundColor|[Ff]illColor' {} + 2>/dev/null; then
    echo "❌ Declares \`surface:behind\` but draws no fill of its own:"
    echo "     $dir"
    echo "   A blur behind nothing is nothing; a sheen around nothing is a"
    echo "   squared band. Drop the declaration or give the panel a fill."
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  eligible=$(printf '%s\n' "$rows" | awk -F'\t' '$3=="ELIGIBLE"' | grep -c . || true)
  wired=$(printf '%s\n' "$rows" | awk -F'\t' '$4=="wired"' | grep -c . || true)

  # Zero is not a clean run. Every green this guard has ever printed came
  # from a repo with wired surfaces in it, so a count of zero means the
  # rows stopped parsing — the same shape as a guard whose pattern was
  # renamed out from under it.
  if [ "$wired" -eq 0 ]; then
    echo "❌ parsed 0 wired surfaces. The repo has some, so this is a"
    echo "   broken read of the triage output, not a clean tree."
    exit 1
  fi

  echo "✔ $wired wired surface(s), every one of them eligible under the"
  echo "  rule; $eligible eligible in total. The difference is the reach"
  echo "  still to build — run $TRIAGE --gap to see it."
fi

exit "$status"
