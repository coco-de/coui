#!/usr/bin/env bash
#
# Gate: the shipped components draw from one icon catalogue.
#
# Mixing catalogues is not a tidiness problem. Each set is drawn on its
# own grid with its own stroke weight, so two glyphs asked to render at
# the same size arrive at different optical weights — a checkmark from
# one set beside a chevron from another reads as a rendering bug rather
# than a choice. The difference is small enough per-glyph that nobody
# files it and large enough in a row of controls to look wrong.
#
# What made this worth a gate rather than a sweep is how the last of them
# went. A menu decided whether a toggle was a checkbox by comparing its
# drawn glyph against a specific icon constant:
#
#     item.onChanged!(mark == RadixIcons.check ? !checked : true)
#
# Swapping that glyph — a purely visual decision — made the comparison
# stop matching, and every checkbox silently became a radio that could be
# turned on but never off. The code was not wrong until the catalogue
# changed, which is exactly the kind of coupling a sweep leaves behind.
#
# Scope is the shipped libraries. The catalogues themselves obviously
# name their own icons, the icon browser exists to show every set, and
# the lint fixture needs a counter-example to lint against.

set -euo pipefail

cd "$(dirname "$0")/../../.."

readonly canonical='LucideIcons'

offenders=$(
  grep -rnE '\b(Radix|Hero|Bootstrap)Icons\.' \
    packages/coui_flutter/lib packages/coui_web/lib --include='*.dart' |
    grep -vE '(radix|hero|bootstrap)_icons\.dart' || true
)

if [ -n "$offenders" ]; then
  echo "A shipped component draws from a second icon catalogue."
  echo
  printf '%s\n' "$offenders"
  echo
  echo "Use $canonical. If a glyph genuinely has no equivalent, say so"
  echo "where the icon is used and add it to this guard by name — an"
  echo "exception that is written down stays reviewable, and one that is"
  echo "not becomes the next mixed row."
  exit 1
fi

# The other half of the same failure: behaviour that keys on which glyph
# is drawn. A component may pass an icon around, but nothing may branch
# on its identity — that is what turns a visual swap into a silent
# behavioural change.
#
# Three shapes, because the original bug was one of them and a
# comparison can be written any of the three ways without changing what
# it means:
#   right operand  — `mark == RadixIcons.check`     (the original shape)
#   left operand    — `RadixIcons.check == mark`
#   case / switch   — `case RadixIcons.check:` or the Dart 3 arm form
#                      `RadixIcons.check => ...`
# A check that only sees the first is a check that a rewrite — not even
# an unfriendly one, just a different author's habit — walks straight
# past.
coupled=$(
  {
    grep -rnE '(==|!=)\s*[A-Za-z]+Icons\.[a-zA-Z]' \
      packages/coui_flutter/lib packages/coui_web/lib --include='*.dart'
    grep -rnE '[A-Za-z]+Icons\.[a-zA-Z]+\s*(==|!=)' \
      packages/coui_flutter/lib packages/coui_web/lib --include='*.dart'
    grep -rnE 'case\s+[A-Za-z]+Icons\.[a-zA-Z]+\s*:' \
      packages/coui_flutter/lib packages/coui_web/lib --include='*.dart'
    grep -rnE '[A-Za-z]+Icons\.[a-zA-Z]+\s*=>' \
      packages/coui_flutter/lib packages/coui_web/lib --include='*.dart'
  } | sort -u || true
)

if [ -n "$coupled" ]; then
  echo "Behaviour branches on which glyph is drawn."
  echo
  printf '%s\n' "$coupled"
  echo
  echo "Key the branch on the semantic field that already says it — an"
  echo "item's kind, a variant, a boolean. A glyph is what something"
  echo "looks like, not what it is."
  exit 1
fi

# ── The size ladder ──────────────────────────────────────────────
#
# An icon size comes from the icon ladder, not from the spacing scale.
# The two hold identical numbers, so this is not about the value — it is
# about which ladder a new component reads when it picks a step. The
# default itself was written against the spacing namespace, in a repo
# whose dimension scale documents itself as "for icon sizes, NOT for
# spacing", so the inversion was already contradicting its own tokens.
#
# Matched whitespace-normalised per file, not per line — `grep` never
# lets a pattern span a newline no matter how the character classes are
# written, and the repo's actual shape for this default routinely does:
#
#     static const double defaultArrowIconSize = CoreSpace.space16;
#     ...
#     static const CoreIconStyle defaultIconStyle = CoreIconStyle(
#       size: defaultArrowIconSize,
#     );
#
# The wrong ladder is stated on the constant's own declaration line; the
# call site that would have made a same-line pattern match is one hop
# away, referring to the constant by name. So two passes, both over the
# whole file: the direct form (`CoreIconStyle(...size: CoreSpace.x...)`,
# whatever line count it spans), and the one-hop form — every
# `static const double NAME = Core(Size|Space).x` in the file, kept only
# when that same NAME is what a `CoreIconStyle(...)` in the file states
# for `size:`. A name declared but never fed to an icon isn't this
# check's business; something else may legitimately want a spacing- or
# box-shaped constant with "Icon" in its name.
#
# The gap between `CoreIconStyle(` and `size:` is matched the same way
# the original single-line pattern bounded it — non-paren characters, or
# one fully-balanced level of nested parens (a `CoreColor.token(...)`
# ahead of `size:` in the same call, say) — repeated, non-greedily. That
# is what keeps the match from walking straight through this call's own
# closing paren into the next entry of a `defaultsBySize` map: the
# pattern can only consume a `)` as half of a matched pair, never bare,
# so it cannot step past the one that actually closes this call.
sized=$(
  for f in $(grep -rl 'CoreIconStyle(' \
    packages/coui_core/lib packages/coui_flutter/lib packages/coui_web/lib \
    --include='*.dart'); do
    perl -0777 -ne '
      s{//[^\n]*}{}g;
      while (/CoreIconStyle\((?:[^()]|\([^()]*\))*?size:\s*Core(?:Size|Space)\.\w+/gs) {
        my $hit = $&;
        $hit =~ s/\s+/ /g;
        print "'"$f"': $hit\n";
      }
      my @consts;
      while (/static\s+const\s+double\s+(\w+)\s*=\s*Core(?:Size|Space)\.(?:size|space)\d+/gs) {
        push @consts, $1;
      }
      for my $c (@consts) {
        if (/CoreIconStyle\((?:[^()]|\([^()]*\))*?size:\s*\Q$c\E\b/s) {
          print "'"$f"': $c (declared as Core(Size|Space) but fed to CoreIconStyle size)\n";
        }
      }
    ' "$f"
  done || true
)

if [ -n "$sized" ]; then
  echo "An icon size is stated from the wrong ladder."
  echo
  printf '%s\n' "$sized"
  echo
  echo "Use CoreIconSize. The values are identical; the ladder is what a"
  echo "new component reads when it picks a step."
  exit 1
fi

echo "PASS: components draw from $canonical, size from its own ladder,"
echo "      and no behaviour keys on a glyph."
