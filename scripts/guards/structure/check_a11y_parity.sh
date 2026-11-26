#!/usr/bin/env bash
#
# Gate: a component exposed to assistive technology on one platform is
# exposed on the other — AND a component that exposes nothing on either
# platform is one this guard has actually looked at, not one that slipped
# past because a count stayed flat.
#
# `cross-platform/api.md` already settles the principle — mechanisms may
# differ per framework, but the *capability* has to exist on both sides.
# Screen-reader exposure is a capability; `Semantics` (Flutter) and
# `role`/`aria-*` (Web) are its two mechanisms. So this is not a new policy,
# it is the existing one made enforceable.
#
# It needs enforcing because the failure is invisible from the side that
# works: the component renders identically, passes its widget test, and
# looks right in a screenshot. The only symptom is that a screen-reader user
# on one platform cannot reach a control that users on the other can.
#
# Detection is deliberately generous about *how* each side expresses it —
# Web writes attributes as map literals, `attributes.add(...)`, `addAria(...)`
# and `alt:`, and an earlier narrower pattern reported five components as
# missing a11y that in fact had it. A guard that over-reports gets muted.
#
# A native semantic element counts too, and that is the second instance of
# the same over-report. A text block renders `<h2>`; the browser puts it in
# the document outline with no attribute involved. Demanding a redundant
# `aria-level` beside it would be the duplication the paragraph below
# rejects — and reporting the component as Web-missing would say the
# opposite of what is true, since Web is the side that had the heading all
# along.
#
# The native form controls are named as tags rather than as attributes, so
# they are matched where the tag is written — either inline at the element
# or through the constant a component declares for it. Matching the bare
# word anywhere in the file would also catch the DOM event of the same
# name, which is not exposure to anything.
#
# Composition counts. Flutter components built on `Clickable` / `Button`
# inherit button semantics from those primitives, exactly as their Web twins
# inherit `role="button"` from the Web `Clickable`. Demanding a redundant
# local `Semantics` would be asking for duplication, not accessibility.
#
# --- What this guard cannot see ---------------------------------------
#
# It greps for the *presence* of the exposure, never its *reachability*.
# A `Semantics` node behind a branch no real usage takes reads here
# exactly like one every user gets — and one did: a scrollbar's node sat
# behind an early return taken whenever no scroll controller was in play,
# which off mobile is the ordinary case, so the guard reported a closed
# gap over a component that announced nothing.
#
# So a green run here says the exposure is written on both platforms, not
# that it arrives. What can say that is a widget test that pumps the
# component the way callers write it — including the shape its own
# dartdoc shows — and reads the semantics tree back. Wiring a component's
# a11y is not finished until such a test exists beside it; removing a
# name from KNOWN_GAPS below on the strength of this grep alone is how
# the false green above got declared.
#
# It also cannot see *which parameter* changes what gets emitted, and
# that is a second, distinct blind spot rather than a corner of the
# first. Presence is a property of the file; per-parameter symmetry is a
# property of every value a shared behavioural field can take. The same
# scrollbar showed both halves: its `visibility: hidden` returned before
# the bar was built, so Flutter emitted no node in that one mode while
# Web emitted its usual one — and its `interactive` gated the Flutter
# node's increase/decrease actions while the Web markup came out
# byte-identical either way. Both platforms grepped as exposed
# throughout, because both were, for the *other* values.
#
# Widening this script to see that would mean deciding, per component,
# which contract fields are supposed to reach assistive technology and
# then reading emission out of Dart source — a static analysis, not a
# grep, and one that fails open on every component whose field names it
# guessed wrong. The mechanism that does catch it is a test on each
# platform that pumps every value of the field and asserts on the a11y
# output, the same instrument the paragraph above already names. Green
# here means "written on both", never "written the same for every value
# of every flag".
#
# --- Silent-on-both pairs: two named lists, not a ratchet --------------
#
# A pair silent on both platforms used to be absorbed into a numeric
# baseline that only printed when it grew. That hid two different things
# under one green check: a pure layout wrapper with nothing to announce
# (correct), and an interactive control nobody wired up (a bug). 45 pairs
# were audited by hand — reading both platform entry files, not guessing
# from the name — and sorted into exactly two lists below:
#
#   LAYOUT_ALLOWLIST — silence here is correct and permanent (pure layout/
#   decorative, or accessible via composition of an already-wired child).
#   Reported, never blocks.
#
#   KNOWN_GAPS — silence here is a real bug, each already filed as its own
#   issue (#3497 divider). Reported as a warning so CI stays green while
#   those are fixed on their own schedule, but the count and names stay
#   visible on every run instead of vanishing into a baseline nobody
#   rereads.
#
# A silent-both pair in NEITHER list fails, unconditionally — no baseline
# to slip into. A new interactive component landing with zero semantics is
# a same-PR failure instead of a number nobody watches. Fixing a KNOWN_GAPS
# entry means deleting it from that list here, in the same PR that adds the
# real Semantics/role/aria-* — leaving it listed after the fix would silently
# re-hide a working component behind a stale warning.
set -uo pipefail

FLUTTER_ROOT='packages/coui_flutter/lib/src/components'
WEB_ROOT='packages/coui_web/lib/src/components'

for r in "$FLUTTER_ROOT" "$WEB_ROOT"; do
  if [ ! -d "$r" ]; then
    echo "❌ Component root not found: $r (update this guard's paths)."
    exit 1
  fi
done

# Entry file of a component is <name>/<name>.dart.
entry_files() {
  find "$1" -type f -name '*.dart' \
    | while read -r f; do
        [ "$(basename "$f")" = "$(basename "$(dirname "$f")").dart" ] && echo "$f"
      done
}

# `SemanticsService.` joins the list because announcing is exposure this
# grep previously could not see: a component that speaks through
# `SemanticsService.sendAnnouncement` puts a sentence in front of a screen
# reader exactly as a `Semantics` node does, and the Web twin expresses the
# same capability as an `aria-live` region. Without this the drag scope
# reported as Web-only while both platforms announced — the guard was
# reading one mechanism and calling it the capability.
FLUTTER_A11Y='Semantics\(|MergeSemantics\(|ExcludeSemantics\(|semanticLabel:|SemanticsService\.'
# `TextField(` joins `Clickable(`/`Button(` here for the same reason: it is
# a CoUI primitive built on Flutter's native `EditableText`, which the
# framework always wires with real text-field Semantics regardless of what
# the caller does — composing it is never "silent" in truth, only silent to
# this script's pattern list. `formatted_input` (single real `<input>` on
# Web) surfaced the gap: composing this Flutter primitive is not itself the
# difference between the two platforms, but Web's own new native
# `tag: 'input'` render now makes Web non-silent while Flutter, still
# composing `TextField`, stayed silent under the old pattern — reporting a
# real cross-platform gap that was not there.
FLUTTER_INFRA='\bClickable\(|\bButton\(|\bTextField\('
WEB_A11Y="['\"](role|aria-[a-z-]+)['\"]|addAria\(|\balt:|ElementTag\("
WEB_A11Y="$WEB_A11Y|(tag:|=)[[:space:]]*['\"](textarea|input|select)['\"]"
# `<dl>`/`<dt>`/`<dd>` join the native form controls above for the reason the
# header already gives: a native semantic element is exposure, and demanding a
# redundant attribute beside it would be the duplication this guard rejects.
# The definition list is the sharpest case of it — the pairing a screen reader
# announces ("사업자등록번호: 000-00-00000") comes from the elements themselves,
# and `role="term"`/`role="definition"` written over them would state twice what
# the tag already states once. Matched where the tag is written, same as the
# form controls, so the bare word in prose or a DOM event cannot count.
WEB_A11Y="$WEB_A11Y|(tag:|=)[[:space:]]*['\"](dl|dt|dd)['\"]"
# `<details>`/`<summary>` join them for the same reason, and more sharply
# than any of the others: the browser exposes the pair as a disclosure
# widget — a button that reports its own expanded state — with no attribute
# involved. Writing `aria-expanded` over it would not merely duplicate the
# tag, it would *lie*: nothing updates that attribute, so it would announce
# the section as closed after the browser opened it. The component exists
# precisely because the native element needs no script to stay truthful.
WEB_A11Y="$WEB_A11Y|(tag:|=)[[:space:]]*['\"](details|summary)['\"]"
# `<h1>`–`<h6>` join them as the native answer to Flutter's
# `Semantics(header: true)`: the element is the heading role and carries its
# level, so `role="heading"` written over a `<div>` would only restate it —
# and `heading` is not a value `CoreSemanticRole` maps, which the role-parity
# guard rejects. Matched where the tag is written, like the others.
WEB_A11Y="$WEB_A11Y|(tag:|=)[[:space:]]*['\"]h[1-6]['\"]"

# --- The allowlist itself ----------------------------------------------
#
# One name per line, optionally followed by `# why`. Matching reads only
# the first field, so the comment is free-form documentation, not part of
# the match. Every name here was read (both platform entry files) at
# audit time, not inferred from what it sounds like.
LAYOUT_ALLOWLIST=$(cat <<'EOF'
aspect_ratio_box    # AspectRatio-equivalent ratio wrapper, no callbacks
basic               # pure slot layout (Row/Column of Align+Text), no callbacks
breakpoint          # non-widget value accessor, renders no UI at all
chat                # static Row/Column/div message layout, no onTap/onChange
chip_group          # composes Chip -> Clickable, which carries real button semantics
code_diff           # static line-by-line diff viewer, no callbacks
context_menu        # composes Menu, which carries role=menu/menuitem/aria-* itself
drag_overlay        # explicitly non-interactive: IgnorePointer / pointer-events:none
drag_scope          # context/runtime provider, attaches no gesture handler itself
draggable_panel     # composes DragItem, which carries role=application + keydown itself
fade_scroll         # edge-fade wrapper around a natively-scrollable child
fieldset            # non-native <div>/<span> grouping, no interactive affordance
focus_outline       # pure ring-painting wrapper, IgnorePointer, caller owns focus
form                # bare layout wrapper; native <form> submit is browser-native, not custom
formatter           # pure logic (TextInputFormatter / CoreInputFormatter), builds no widget
gap                 # pure spacer leaf, no callbacks besides passthrough
hover               # pure MouseRegion/mouseenter state wrapper; the ExcludeSemantics it does hold is suppression-only, see SUPPRESSION_ONLY_ALLOWLIST below
icon                # purely visual glyph; actionable icons get semantics from their Button wrapper
image_properties    # pure data-model glue (Rect conversion), builds no widget
indexed_switcher    # shows one of the caller's views, each exposed by itself; the hidden ones are suppression-only, see SUPPRESSION_ONLY_ALLOWLIST below
indicator           # pure Stacks/Position overlay, no gesture handlers
mask                # pure decorative ClipPath/CSS-mask clipper, no callbacks
mockup_browser      # decorative browser-chrome frame, no interactive callbacks
mockup_code         # static code-editor frame rendering fixed text, no interactivity
mockup_device       # decorative device-frame chrome, no callbacks
number_ticker       # animated numeric display, no user-facing tap/change affordance
object_input        # composes TextField per field, which carries Semantics/aria-label
outlined_container  # decorative chrome around a caller's child, which carries its own exposure; the dash svg's aria-hidden is suppression-only, see WEB_SUPPRESSION_ONLY_ALLOWLIST below
responsive_container # pure ConstrainedBox/Padding/div max-width wrapper, no callbacks
responsive_grid     # pure responsive grid layout, no callbacks
responsive_row_column # pure Flex/div layout swap by breakpoint, no owned interaction
scroll_area         # composes Scrollbar + native overflow:auto, no hand-rolled thumb
stacks              # pure Stack/CSS-grid overlay positioning, no interaction
stage_container     # pure responsive padding container, no click/drag/keyboard of its own
stat                # static label/value/change metric card, no callbacks
tag                 # static category label; its child Text is the exposure, no callbacks / focus
timeline            # static sequence of dot/connector/title/description, no per-item control
validated           # pure presentational wrapper propagating state via inherited scope
overflow_marquee    # auto-scrolling display text; only MouseRegion pause, no tap/keyboard
EOF
)

# Real gaps, each already tracked as its own issue. Silence here still
# prints on every run — it does not fail the build, and it does not fail
# silently either. An entry leaves the list when the pair stops being silent
# on a platform.
KNOWN_GAPS=$(cat <<'EOF'
step_item  # TRACKER PENDING — file the issue with this PR, then put its number
           # here as the other entries did. The status reaches a reader only as
           # the glyph's shape and colour — no spoken status label yet (it needs
           # chrome localisation members on both platforms plus generator JSON).
           # Inside Steps(variant: list) the row is a listitem (current:
           # aria-current="step" / selected); on its own it is text.
EOF
)

# `ExcludeSemantics(` is in `FLUTTER_A11Y` above as a broad, deliberately
# generous signal — every current user of it also independently matches a
# real exposure marker (`Semantics(`/`MergeSemantics(`/`semanticLabel:`)
# elsewhere in the same file, so this has never mattered before. `hover` is
# the first exception: its `_DropShadow` mounts the wrapped child once per
# cast layer to emulate CSS's `drop-shadow()` pipeline chaining (Flutter has
# no native primitive to defer to), and wraps every mounted copy but the
# real one in `ExcludeSemantics` purely so a screen reader hears the child
# once, not once per shadow layer — a Flutter-only artifact of reusing a
# widget instance at two tree positions. Web's CSS filter chain never
# duplicates a DOM node, so there is nothing on that side to answer.
#
# The fix is not to drop `ExcludeSemantics(` from `FLUTTER_A11Y` outright —
# doing that once (see this file's history) turned out to reclassify six
# unrelated, unaudited components in the same run, which is exactly the
# kind of same-PR scope creep `process/workflow.md`'s issue-scope rule
# exists to prevent. So this list names only the components verified, by
# reading the file, to use `ExcludeSemantics(` with no accompanying real
# marker of their own — the check below still requires that verification
# to hold on every run, not just at the time an entry was added.
SUPPRESSION_ONLY_ALLOWLIST=$(cat <<'EOF'
hover   # _DropShadow's ExcludeSemantics hides duplicate mounts of the
        # wrapped child from the CSS drop-shadow() pipeline emulation —
        # suppression of a Flutter-only artifact, not new exposure; Web's
        # filter chain has no duplicate DOM node to match it with.
indexed_switcher  # ExcludeSemantics hides the views that are not shown,
                  # and the one still fading out, so only the shown view
                  # is read; the caller's views carry their own exposure.
                  # The Web twin hides the same views with `inert`, which
                  # WEB_A11Y does not read — suppression on both sides.
EOF
)

# The same over-report has a Web side. `aria-[a-z-]+` in `WEB_A11Y` matches
# `aria-hidden`, which hides a node rather than exposing one. A component
# whose only Web marker is `aria-hidden` on its own decoration exposes
# nothing there — and its Flutter twin, whose painters add no semantics
# node of their own, correctly has nothing to match it with. Reading that
# pair as "exposed on Web, nothing on Flutter" asks Flutter to hide the
# decoration explicitly, and the only wrapper that does it there,
# `ExcludeSemantics`, hides the caller's child along with it: that is how
# `outlined_container` hid every dashed container's content from a screen
# reader. As with the Flutter list, the claim (no Web marker but
# `aria-hidden`) is re-checked on every run, not just when an entry is added.
WEB_SUPPRESSION_ONLY_ALLOWLIST=$(cat <<'EOF'
outlined_container  # the dashed/dotted border's svg overlay is aria-hidden;
                    # the content is the caller's child, exposed by itself.
EOF
)

web_suppression_only_allowlisted() {
  grep -Fxq "$1" <<<"$(awk '{print $1}' <<<"$WEB_SUPPRESSION_ONLY_ALLOWLIST")"
}

allowlisted() {
  printf '%s\n' "$LAYOUT_ALLOWLIST" | awk '{print $1}' | grep -Fxq "$1"
}

known_gap() {
  printf '%s\n' "$KNOWN_GAPS" | awk '{print $1}' | grep -Fxq "$1"
}

suppression_only_allowlisted() {
  printf '%s\n' "$SUPPRESSION_ONLY_ALLOWLIST" | awk '{print $1}' | grep -Fxq "$1"
}

missing_flutter=''
missing_web=''
silent_both=''
silent_allowlisted=''
silent_known_gap=''
paired=0

while read -r wf; do
  name="$(basename "$(dirname "$wf")")"
  ff="$FLUTTER_ROOT/$(cd "$FLUTTER_ROOT" && find . -type d -name "$name" -print -quit 2>/dev/null)/$name.dart"
  ff="${ff#$FLUTTER_ROOT/./}"
  ff="$FLUTTER_ROOT/${ff#$FLUTTER_ROOT/}"
  [ -f "$ff" ] || continue
  paired=$((paired + 1))

  web_has=0;  grep -qE "$WEB_A11Y" "$wf" && web_has=1
  f_has=0;    grep -qE "$FLUTTER_A11Y" "$ff" && f_has=1
  f_infra=0;  grep -qE "$FLUTTER_INFRA" "$ff" && f_infra=1

  # `\b` matters here, not just style: without it `Semantics\(` matches as
  # a substring of `ExcludeSemantics(` too, so this would never actually
  # distinguish the two. Only components on SUPPRESSION_ONLY_ALLOWLIST get
  # this override, and only when the audited claim (no real marker, only
  # suppression) still holds — everyone else keeps the broad `f_has` above,
  # unchanged.
  if [ "$f_has" = 1 ] && suppression_only_allowlisted "$name" \
      && ! grep -qE '\bSemantics\(|\bMergeSemantics\(|semanticLabel:' "$ff"; then
    f_has=0
  fi

  if [ "$web_has" = 1 ] && web_suppression_only_allowlisted "$name" \
      && ! grep -vq "aria-hidden" <<<"$(grep -E "$WEB_A11Y" "$wf")"; then
    web_has=0
  fi

  if [ "$web_has" = 1 ] && [ "$f_has" = 0 ] && [ "$f_infra" = 0 ]; then
    missing_flutter="${missing_flutter} ${name}"
  fi
  if [ "$f_has" = 1 ] && [ "$web_has" = 0 ]; then
    missing_web="${missing_web} ${name}"
  fi
  if [ "$web_has" = 0 ] && [ "$f_has" = 0 ] && [ "$f_infra" = 0 ]; then
    if allowlisted "$name"; then
      silent_allowlisted="${silent_allowlisted} ${name}"
    elif known_gap "$name"; then
      silent_known_gap="${silent_known_gap} ${name}"
    else
      silent_both="${silent_both} ${name}"
    fi
  fi
done < <(entry_files "$WEB_ROOT")

status=0

allowlisted_count=$(printf '%s\n' $silent_allowlisted | grep -c . || true)
known_gap_count=$(printf '%s\n' $silent_known_gap | grep -c . || true)
echo "Pairs silent on both platforms, allowlisted as layout/composition: $allowlisted_count"
echo "Pairs silent on both platforms, known gaps tracked by issue: $known_gap_count"

if [ -n "$silent_known_gap" ]; then
  echo "⚠️  Tracked but not yet fixed (see KNOWN_GAPS in this script for the"
  echo "   issue number of each — this does not fail the build):"
  for c in $silent_known_gap; do echo "     $c"; done
fi

if [ -n "$silent_both" ]; then
  echo "❌ A component pair exposes nothing to assistive tech on either"
  echo "   platform, and is not on the layout allowlist or the known-gaps"
  echo "   list:"
  for c in $silent_both; do echo "     $c"; done
  echo "   Either wire real Semantics/role/aria-* (Flutter and Web), or —"
  echo "   only if this is genuinely pure layout/decorative with no"
  echo "   interactive affordance, or accessible via composition of an"
  echo "   already-wired child — add it to LAYOUT_ALLOWLIST in this script"
  echo "   with a one-line reason. If it is a real gap you are not fixing"
  echo "   right now, file an issue and add it to KNOWN_GAPS instead."
  status=1
fi

if [ -n "$missing_flutter" ]; then
  echo "❌ Exposed to assistive tech on Web, nothing on Flutter:"
  for c in $missing_flutter; do echo "     $c"; done
  echo "   Add the matching Semantics, or compose Clickable/Button if it is"
  echo "   simply a button."
  status=1
fi

if [ -n "$missing_web" ]; then
  echo "❌ Exposed to assistive tech on Flutter, nothing on Web:"
  for c in $missing_web; do echo "     $c"; done
  echo "   Add the matching role / aria-* attributes."
  status=1
fi

# A guard that pairs nothing would pass silently forever.
if [ "$paired" -lt 100 ]; then
  echo "❌ Only $paired component pairs found — the discovery above is"
  echo "   probably broken rather than the library having shrunk."
  exit 1
fi

if [ "$status" -eq 0 ]; then
  echo "✅ Accessibility exposure is symmetric across $paired component pairs;"
  echo "   every silent-both pair is an accounted-for allowlist or known-gap"
  echo "   entry."
fi

exit "$status"
