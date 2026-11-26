#!/usr/bin/env bash
#
# A resolver that hands out the style's injected cast has to be read by
# every widget that calls it — not just the first one.
#
# `ResizableTable` shares `resolveTable` with `Table`. The resolver
# resolved the cast for both; only `Table` read it. The result was a
# resizable table sitting flat beside a plain one under the same style,
# and nothing caught it: analyze was clean, the sweep test listed
# `Table` and passed, and the Web twin carried the cast on that same
# surface so a cross-platform comparison of the *other* widget agreed.
#
# The list of resolvers comes from the source rather than from a table
# kept here — a table would go stale exactly on the components nobody
# has looked at yet, which is the population this is for.
#
# WHAT THIS DOES NOT COVER: a widget that reads the cast in one branch
# and drops it in another (Tabs shipped the cast on its underline
# variant and not on its default one). Reading a field somewhere in a
# file is all this can see. Branch coverage needs a widget test that
# pumps each variant — test/components/cast_branch_coverage_test.dart.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
COMPONENTS="$REPO_ROOT/packages/coui_flutter/lib/src/components"

if [[ ! -d "$COMPONENTS" ]]; then
  echo "components directory not found at $COMPONENTS" >&2
  exit 1
fi

violations=0

# Every resolver file that exposes the cast.
while IFS= read -r style_file; do
  dir="$(dirname "$style_file")"
  base="$(basename "$style_file" _style.dart)"

  # Its entry point, as the callers spell it: resolveFooBar for foo_bar.
  fn="resolve$(printf '%s' "$base" | awk -F_ '{for(i=1;i<=NF;i++) printf toupper(substr($i,1,1)) substr($i,2)}')"

  # Callers living beside it. A resolver used from another directory
  # would be a composition, not a sibling, and those read the cast
  # through the component they compose rather than directly.
  while IFS= read -r caller; do
    case "$caller" in *_style.dart) continue ;; esac
    if ! grep -q "$fn(" "$caller"; then continue; fi
    if grep -q "resolved\.boxShadow\|\.boxShadow," "$caller"; then continue; fi

    rel="${caller#"$REPO_ROOT"/}"
    echo "✗ ${rel}"
    echo "    calls ${fn}(), which resolves the style's injected cast,"
    echo "    but never reads it — this surface stays flat while its"
    echo "    siblings carry the cast."
    violations=$((violations + 1))
  done < <(find "$dir" -maxdepth 1 -name '*.dart')
done < <(grep -rl "resolveInjectedCast(" "$COMPONENTS" --include='*_style.dart')

if [[ $violations -eq 0 ]]; then
  echo "✓ every caller of a cast-resolving resolver reads the cast"
  exit 0
fi

echo
echo "$violations widget file(s) drop the cast their resolver provides."
exit 1
