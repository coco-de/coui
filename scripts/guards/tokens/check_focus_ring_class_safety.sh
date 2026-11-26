#!/usr/bin/env bash
#
# Gate: a focus ring drawn with Tailwind `outline-*` classes must be gated
# on the ring being expressible as classes, and must name its colour as a
# token; the gap band beside it must never be painted in a literal colour.
#
# The ring is an outline — its offset is a real, unpainted gap, so the
# background behind a control shows through between the control and the
# ring. A class-path outline is three things a caller can set and a class
# cannot always say: a width and an offset, which only exist at the
# integer steps the scale defines, and a colour, which only exists for a
# token that has a class. Emit the class anyway and every failure is
# silent in the same way — the ring renders, at the wrong width or in no
# colour at all, and nothing throws.
#
# Both have happened here, and neither was found by reading the ring.
#
#   Width — a resolver interpolated `width.toInt()` straight into the
#   width step. A caller asking for 2.5 got 2, and the derived offset 1.5
#   got 1. The request was halfway honoured, which looks like a design
#   decision rather than a drop.
#
#   Colour — a resolver interpolated a `CoreColor` into the class with
#   no conversion, so `toString()` ran. For a token that yields the token
#   name and the class exists; for a raw colour it yields a hex string
#   and the class does not, so the ring loses its colour entirely. The
#   two cases are one character apart in the source and produce the same
#   green analyzer.
#
# The gate the first failure calls for already exists —
# `focusRingIsClassSafe` / `focusRingOutlineIsClassSafe` — and the
# components that use it fall back to the scoped `focusRingScopedRule`
# when the ring goes off-scale. The second is `.tailwindColor`, which
# throws on a raw colour instead of emitting a dead class.
#
# What this checks:
#
#   1. Every file that emits a focus-ring outline class — written out
#      under a focus prefix, or composed from a `WebPseudo.classPrefix`,
#      or built through `focusRingClassName(` — names a class-safety gate
#      (`focusRingIsClassSafe`, `focusRingOutlineIsClassSafe`, or a local
#      predicate at least as strict: `pseudoOverridden`, which routes
#      *every* deviation from the default to the scoped rule).
#   2. Every value interpolated into such a class goes through `.toInt()`
#      (a scale step) or `.tailwindColor` (a token class key). Anything
#      else is either a raw colour emitting a class that does not exist or
#      a width hoisted into a local where this check cannot see whether
#      it was gated.
#   3. The gap band — a `box-shadow` layer, painted only where a component
#      states that its background is unknown — never carries a literal
#      colour. The band exists to give the ring a contrasting partner on
#      every theme; a hard-coded `#fff` / `white` / `rgb(255, …)` band is
#      the white strip over a dark surface the band was invented to
#      avoid. Band colours come from a `CoreColor` through `.toValue()` /
#      the triplet helpers, so the theme reaches them.
#
# The outline's own resting state (`outline-none`, `2px solid
# transparent`) and an arbitrary-value outline that is not a CoUI focus
# ring (`outline-[…]`) are not targets — neither interpolates a scale step
# or a colour.

set -euo pipefail

cd "$(dirname "$0")/../../.."

readonly scope='packages/coui_web/lib'

# Files emitting a focus-ring outline class. Comment lines are excluded:
# a comment describing a ring is not a ring, and several of these files
# explain the class/scoped-rule split in prose right above the code.
#
# A target is a non-comment line with an outline class under a focus
# prefix (`focus-visible:outline-2`), the same class composed from a
# `WebPseudo` prefix (`${pseudo.classPrefix}outline-…`), or a call to
# the shared builder. `outline-none` and `outline-[…]` are excluded —
# neither is a gated scale step or a colour.
#
# `|| true` so an empty match reaches the diagnostic below rather than
# killing the script under `set -e` — a check that finds nothing must say
# so, not exit quietly with the same status as a real failure.
targets=$(
  grep -rlE \
    "^[^/]*((group-)?focus(-visible|-within)?:|classPrefix\}|focusRingClassName\()" \
    "$scope" --include='*.dart' |
    while IFS= read -r file; do
      perl -0777 -ne '
        s{^\s*//.*$}{}mg;
        s{'\''\s*\n\s*'\''}{}g;
        exit 0 if m/(?:(?:group-)?focus(?:-visible|-within)?:|classPrefix\})outline-(?:offset-)?(?!none\b|\[)/;
        exit 0 if m/\bfocusRingClassName\(/;
        exit 1;
      ' "$file" && echo "$file"
    done | sort || true
)

if [ -z "$targets" ]; then
  echo "FAIL: no file emits a focus-ring outline class — the check is"
  echo "      scoped to nothing, which means it would pass whatever"
  echo "      happened. Either the emitters moved or the pattern rotted."
  exit 1
fi

failures=""

for file in $targets; do
  # Gate 1 — the file must name a class-safety predicate.
  if ! grep -qE 'focusRingIsClassSafe|focusRingOutlineIsClassSafe|pseudoOverridden' "$file"; then
    failures="${failures}${file}: emits a focus ring as Tailwind outline classes with no class-safety gate — an off-scale width truncates to a scale step and a raw colour emits a class that does not exist
"
  fi

  # Gate 2 — every value interpolated into such a class must be a scale
  # step or a token class key.
  #
  # Adjacent string literals are joined first. Dart's formatter splits a
  # long class list across lines, and it splits *inside* the class often
  # enough that the interpolation lands on the line below the `outline-`
  # it belongs to. Matching line by line would read those as a class with
  # no interpolation at all and pass them silently — which is the whole
  # failure mode this check exists to catch.
  #
  # Assigned before it is used, so a perl that fails to compile exits the
  # script under `set -e` instead of reading as an empty, passing result.
  bad=$(
    perl -0777 -ne '
      s{^\s*//.*$}{}mg;          # full-line comments are not emissions
      s{'\''\s*\n\s*'\''}{}g;    # join adjacent string literals
      while (m/((?:(?:group-)?focus(?:-visible|-within)?:|classPrefix\})outline-(?:offset-)?)\$\{([^}]*)\}/g) {
        my ($cls, $expr) = ($1, $2);
        next if $expr =~ /\.toInt\(\)/;        # a scale step, not a colour
        next if $expr =~ /\.tailwindColor\b/;  # a token class key
        print "$cls\${$expr}\n";
      }
    ' "$file" | sort -u
  )

  if [ -n "$bad" ]; then
    while IFS= read -r emission; do
      [ -z "$emission" ] && continue
      failures="${failures}${file}: ${emission} interpolates something into an outline class that is neither .toInt() (a scale step) nor .tailwindColor (a token colour) — a raw override colour emits a class that does not exist instead of failing, and a width hoisted into a local hides whether it was gated
"
    done <<<"$bad"
  fi
done

# Gate 3 — no gap band in a literal colour.
#
# Scoped to the files that emit a focus ring at all (the targets above)
# plus every file that builds a band or a scoped ring through the shared
# helpers — the band is a `box-shadow` spread layer (`0 0 0 <gap>
# <colour>`), and the colour slot must be an interpolation, never a
# written-out colour.
band_files=$(
  {
    echo "$targets"
    grep -rlE "focusBandShadow|focusRingScopedRule|focusRingDeclarations|kFocusBandVar" \
      "$scope" --include='*.dart' || true
  } | sort -u
)

if ! grep -qE '^String focusBandShadow\(' "$scope/src/util/core_to_css.dart"; then
  echo "FAIL: core_to_css.dart no longer defines focusBandShadow — the band"
  echo "      check has no emitter to anchor on, so it would pass whatever"
  echo "      happened. Point this gate at the band emitter that replaced it."
  exit 1
fi

for file in $band_files; do
  [ -z "$file" ] && continue
  literal=$(
    perl -0777 -ne '
      s{^\s*//.*$}{}mg;
      s{^\s*///.*$}{}mg;
      s{'\''\s*\n\s*'\''}{}g;
      while (m/(0 0 0 [^,;'\''"]*?\s(?:#[0-9A-Fa-f]{3,8}\b|white\b|black\b|rgba?\(\s*[0-9]|hsla?\(\s*[0-9]))/g) {
        print "$1\n";
      }
    ' "$file" | sort -u
  )
  if [ -n "$literal" ]; then
    while IFS= read -r emission; do
      [ -z "$emission" ] && continue
      failures="${failures}${file}: '${emission}' writes a focus band (a box-shadow spread layer) in a literal colour — the band exists to contrast with whatever theme is active; route its colour from a CoreColor through .toValue()
"
    done <<<"$literal"
  fi
done

if [ -n "$failures" ]; then
  echo "A focus ring rides Tailwind classes it cannot always express, or"
  echo "paints its gap band in a colour the theme cannot reach."
  echo
  printf '%s' "$failures"
  echo
  echo "Gate the class path on focusRingIsClassSafe /"
  echo "focusRingOutlineIsClassSafe and fall back to focusRingScopedRule,"
  echo "name ring colours with .tailwindColor, and build the gap band with"
  echo "focusBandShadow from a CoreColor."
  exit 1
fi

echo "PASS: $(echo "$targets" | wc -l | tr -d ' ') files emit focus-ring outline classes; each gates the class path and names its colours as tokens, and no focus band is painted in a literal colour."
