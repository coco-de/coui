#!/usr/bin/env bash
# Horizontal insets that differ are a statement about reading order.
#
# `CoreEdgeInsets.only(left: 24)` says "indented from the left". Almost
# every time, what was meant is "indented from the side the text starts
# on" — the right in Arabic and Hebrew. The two are the same in English,
# so the mistake renders perfectly and stays.
#
# Symmetric insets need nothing: the same value on both sides is already
# direction-invariant, which is why the overwhelming majority of this
# kit's padding never comes up here. This looks only at defaults whose
# left and right actually differ.
#
# Net-new only. There were four when this was written and all four were
# converted; the point is that a fifth cannot arrive as a physical claim
# without someone saying so.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

CONTRACTS='packages/coui_core/lib/src/component/contracts'

physical=$(
  for f in $(find "$CONTRACTS" -name '*_style.dart'); do
    perl -0777 -ne '
      # Each `static const CoreEdgeInsets name = …only|fromLTRB(args);`
      while (/static const CoreEdgeInsets (\w+)\s*=\s*(?:CoreEdgeInsets\.)?(only|fromLTRB)\(([^;]*?)\);/gs) {
        my ($name, $kind, $args) = ($1, $2, $3);
        $args =~ s/\s+/ /g;
        my ($l, $r);
        if ($kind eq "fromLTRB") {
          # Positional: left, top, right, bottom.
          my @a = split /,/, $args;
          next if @a < 4;
          ($l, $r) = ($a[0], $a[2]);
          s/^\s+|\s+$//g for ($l, $r);
        } else {
          $l = ($args =~ /left:\s*([\w.]+)/)  ? $1 : "0";
          $r = ($args =~ /right:\s*([\w.]+)/) ? $1 : "0";
        }
        print "$ARGV:$name (left=$l right=$r)\n" if $l ne $r;
      }
    ' "$f"
  done
)

count=$(printf '%s\n' "$physical" | grep -c . || true)
echo "Physical insets with differing horizontal sides: $count  (baseline 0)"

if [ "$count" -gt 0 ]; then
  printf '%s\n' "$physical" | sed 's|^packages/coui_core/lib/src/component/contracts/||;s/^/     /'
  echo
  echo "❌ A default states different left and right insets."
  echo "   If the difference is about reading order — indented from the"
  echo "   margin, separated from the next item, set in from a rail — use"
  echo "   \`CoreEdgeInsets.directional(start:, end:)\`. Its consumers then"
  echo "   have to emit logical sides, which the conversion helpers force."
  echo
  echo "   If it really is physical (a fixed screen edge, pointer"
  echo "   geometry), say so in a comment on the line above and this"
  echo "   check will still flag it — that is deliberate. A physical"
  echo "   horizontal asymmetry is rare enough to be worth an argument."
  exit 1
fi

echo "✔ every horizontally asymmetric inset default is directional."
