#!/usr/bin/env bash
#
# Gate: the semantic-role seat stays the only vocabulary.
#
# `CoreSemanticRole` exists because a platform-neutral package was holding
# raw ARIA strings while Flutter emitted no roles at all — 94 role sites on
# one platform and zero on the other. Exhaustive switches in both adapters
# are the first line of defence: adding a value breaks both builds until
# each platform states an answer. This guard is the second line, for the
# two failures a compiler cannot see.
#
#   1. A wildcard arm (`_ =>`) in either adapter switch silently turns the
#      exhaustiveness check off. The next role added would then compile
#      while reaching neither platform.
#   2. A component emitting a role literal that is not in the enum bypasses
#      the seat entirely. That is how the divergence started, and it is
#      invisible: the element renders, the widget test passes, and only a
#      screen-reader user notices.
#
# Web writes roles two ways — a map literal (`'role': 'x'`) and the
# attribute builder (`attributes.add('role', 'x')`). An earlier guard read
# only the first and under-reported for that reason, so both are parsed
# here.
#
# Usage: ./scripts/guards/structure/check_semantic_role_parity.sh
set -uo pipefail

ENUM='packages/coui_core/lib/src/component/contracts/semantics/core_semantic_role.dart'
WEB_ADAPTER='packages/coui_web/lib/src/util/core_to_css.dart'
FLUTTER_ADAPTER='packages/coui_flutter/lib/src/util/core_to_flutter.dart'
WEB_LIB='packages/coui_web/lib'

for f in "$ENUM" "$WEB_ADAPTER" "$FLUTTER_ADAPTER"; do
  if [ ! -f "$f" ]; then
    echo "❌ Not found: $f (update this guard's paths)."
    exit 1
  fi
done

fail=0

# --- The enum's own values -------------------------------------------------
values=$(grep -oE '^  [a-zA-Z]+\(\.(mapped|flagged|absent|deferred)\)' "$ENUM" \
  | sed -E 's/^  //; s/\(\..*//')

if [ -z "$values" ]; then
  echo "❌ No CoreSemanticRole values parsed from $ENUM."
  echo "   The enum's shape changed — this guard reads"
  echo "   '  <name>(.<state>)'."
  exit 1
fi

count=$(printf '%s\n' "$values" | wc -l | tr -d ' ')
echo "CoreSemanticRole: $count values"

# --- 1. Neither adapter may switch on a wildcard ---------------------------
for adapter in "$WEB_ADAPTER" "$FLUTTER_ADAPTER"; do
  # Scope to the role extension by name. Scoping by "lines mentioning
  # CoreSemanticRole" does not work: the arms use the dot shorthand the
  # lints require, so the switch body names the enum nowhere — a first
  # version of this check was dead for exactly that reason and only
  # looked alive because the next check caught the same injection.
  block=$(awk '/^extension CoreSemanticRole/{f=1} f{print} f&&/^\}/{exit}' \
    "$adapter")

  if [ -z "$block" ]; then
    echo "❌ $adapter has no 'extension CoreSemanticRole…' block."
    echo "   This guard reads the role switch out of that extension."
    fail=1
  elif grep -qE '^\s+_ =>' <<<"$block"; then
    echo "❌ $adapter: the role switch has a wildcard arm."
    echo "   A '_ =>' turns off the exhaustiveness check that makes a new"
    echo "   role a compile error on both platforms."
    fail=1
  fi
done

# --- 2. Every value is answered by both adapters ---------------------------
for v in $values; do
  for adapter in "$WEB_ADAPTER" "$FLUTTER_ADAPTER"; do
    # Either spelling — the adapters use the dot shorthand the lints
    # require, but a qualified arm is equally an answer.
    if ! grep -qE "(CoreSemanticRole)?\.$v\s*(=>|\|\|)" "$adapter"; then
      echo "❌ $adapter does not answer CoreSemanticRole.$v"
      fail=1
    fi
  done
done

# --- 3. Web emits no role outside the seat ---------------------------------
# The allowed spellings are whatever the Web adapter maps values onto —
# that switch is the vocabulary, so it is also the allow-list.
allowed=$(grep -oE "\.[a-zA-Z]+ => '[a-z]+'" "$WEB_ADAPTER" \
  | grep -oE "'[a-z]+'$" | tr -d "'" | sort -u)

if [ -z "$allowed" ]; then
  echo "❌ No ARIA spellings parsed from $WEB_ADAPTER."
  exit 1
fi

# Every emit idiom, minus the adapter itself (which is the definition).
#
# Four shapes, and the last two were invisible to this check until a
# component was found emitting `menuitemcheckbox`, `menuitemradio` and
# `listitem` — none of which the seat knew — with the guard reporting
# green. A check that only sees the spelling nobody uses for the
# interesting cases is worse than none: it certifies the gap.
#
#   'role': 'x'                  — map literal
#   add('role', 'x')             — attribute builder
#   'role': cond ? 'x' : 'y'     — a component with two roles
#   _kRoleAttr: _kSomeRole       — hoisted to constants
emitted=$( { grep -rhoE "'role':\s*'[a-zA-Z-]+'" "$WEB_LIB" --include='*.dart' \
              | grep -oE "'[a-zA-Z-]+'$"
             grep -rhoE "add\('role',\s*'[a-zA-Z-]+'\)" "$WEB_LIB" --include='*.dart' \
              | grep -oE "'[a-zA-Z-]+'\)$" | tr -d ')'
             # Ternary — both arms.
             grep -rhoE "'role':\s*[^,]*\?\s*'[a-zA-Z-]+'\s*:\s*'[a-zA-Z-]+'" \
               "$WEB_LIB" --include='*.dart' | grep -oE "'[a-zA-Z-]+'"
             # Constant-backed: the value of any `static const _k…Role`.
             grep -rhoE "static const _k[A-Za-z]*Role[A-Za-z]* = '[a-zA-Z-]+'" \
               "$WEB_LIB" --include='*.dart' | grep -oE "'[a-zA-Z-]+'$"
           } | tr -d "'" | grep -vx role | sort -u)

for role in $emitted; do
  if ! grep -qx "$role" <<<"$allowed"; then
    echo "❌ Web emits role=\"$role\", which no CoreSemanticRole maps to."
    echo "   Add the value to the enum (with its Flutter answer) rather"
    echo "   than widening the literal set."
    grep -rn "'role':\s*'$role'\|add('role', '$role')" "$WEB_LIB" \
      --include='*.dart' | head -3 | sed 's/^/     /'
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo
  echo "❌ Semantic-role parity check failed."
  exit 1
fi

emitted_count=$(printf '%s\n' "$emitted" | grep -c . || true)
echo "✅ Both adapters answer all $count values; $emitted_count Web role"
echo "   literals all resolve through the seat."
