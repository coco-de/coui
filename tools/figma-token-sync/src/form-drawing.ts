/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { VarLookup, bindRadiusN } from './helpers';
import { dimVal, textStyleData, Dim } from './compat/v1';
// ─── The focus pose: a ring outside the box, and a caret inside it ────────────
//
// Both field components wrap their decorated container in
// `FocusOutline(focused: _focusNode.hasFocus, focusOutlineStyle:
// resolved.focusOutlineStyle)` and hand the editable a caret. Those are the two
// things focus adds, and neither had a node here — which is why
// `cursorColor` / `cursorRadius` were carried by `components.json` and reached
// no pixel on either component.
//
// The helpers below are shared by the two builders because the widgets state
// the same shape: the same `FocusOutline` around the same decorated container,
// the same ring geometry, the same three caret fields. What differs is only
// which style the caret's line box comes from (TextField's `valueStyle`,
// TextArea's per-size `baseTextStyle`) and whether a `Disabled` axis exists to
// suppress the caret.

// A radius the way the data states it: bound when the leaf traces to a
// Variable, plain geometry when it does not.
//
// `cursorRadius` is the second kind — its `via` is `defaultCursorWidth`, so the
// number comes from the caret's own width and not from the radius ladder, and
// `ref` is null. Binding it by value anyway would put a `Primitives/radius/2`
// claim on the node that the design system never made — the failure
// `bindAxisSize` was split out of `bindSize` to stop. Read as a branch rather
// than assumed, because the day the reader routes this leaf the corner should
// bind without another edit.
//
// `navigation.ts` carries the identical private helper. It belongs in
// `helpers.ts`; it is duplicated here rather than exported from there because
// that file is not this change's to edit. Exported for NumberInput, which
// draws the caret of the field it composes (see `buildNumberInput`).
export function statedRadius(
  node: FrameNode | RectangleNode,
  lk: VarLookup,
  corner: Dim,
): void {
  if (corner.ref != null) {
    bindRadiusN(node, lk, corner);
    return;
  }
  node.cornerRadius = dimVal(corner);
}

// `makeLabel`'s own fallbacks, mirrored — not a second pair invented here.
//
// A caret whose height came from different defaults than the text it stands in
// would disagree with it exactly when a role arrives without metrics, which is
// the one case nobody would be looking. Neither role either builder reads is
// missing them today, so these are unreachable; they are written to the same
// values `helpers.ts` uses so that staying unreachable is not what makes them
// correct. (`DEFAULT_LINE_HEIGHT_PERCENT` is private there.)
const kFallbackFontSize = 14;
export const kFallbackLineHeight = 1.6;

// The caret's height — `preferredLineHeight`, which for one line is the text's
// own line box.
//
// The only number in this pose that is arithmetic rather than a field, and it
// has to be: no recipe states a caret height because `EditableText` asks the
// paragraph for one. Computed from the SAME `TextStyleData` the value text node
// is built from, so the two cannot disagree — `makeLabel` sets `fontSize` and a
// PERCENT `lineHeight` from those two values, and a single line box is their
// product.
//
// Reading the text node's laid-out height instead would be the obvious move and
// is not available: a Figma text node has no measured height until the file is
// open, so it answers 0 here and the runtime harness would see nothing wrong
// with a zero-height caret that Figma then refuses to resize.
export function caretLineBox(ts: ReturnType<typeof textStyleData>): number {
  return (ts.fontSize ?? kFallbackFontSize) * (ts.lineHeight ?? kFallbackLineHeight);
}

// ─── Toggle ──────────────────────────────────────────────────────────────────

// Data-driven from coui_core TOGGLE. Three axes, none of them `Variant`:
//
//   Size[sm, md, lg, xl, xl2] × State[enabled, hover, focus, pressed, disabled]
//   × On[false, true] = 50
//
// `Variant` is deliberately NOT declared. `defaultsByVariant` has exactly one
// row and always will — a switch has no second colour scheme — and an axis with
// one value is a knob the designer cannot turn: it exists only to be spelled in
// fifty names. The canvas dropped it (2026-09 redesign) and this builder
// follows; the single row is read by key, which `check_figma_axis_collapse`
// accepts for a one-row table.
//
// `Size` comes from the keys of `defaultsBySize`, not from `axes.size`: the
// schema lists every `CoreComponentSize` member, but the ladder has no `xs`
// row (a 24×12 track with an 8px thumb travels 8px — no feedback to read),
// and `CoreToggleStyle.sizeDefaults` clamps `xs` to `sm` in code. Drawing an
// `xs` member here would put on the canvas a switch the code never renders.
//
// `On` is a pose axis. `toggle.axes.state` is null in v3 — the schema keeps the
// switch's on/off as its VALUE — but a switch whose on position is not on the
// canvas is a switch a designer cannot draw an app with.
//
// `State` is declared here, like `Button`'s and `Chip`'s, and its rungs are
// what `toggle.dart` paints (`_ToggleState` selects a bundle by `!_enabled` /
// `_pressed` / `_hovered`; focus is the outline):
//
//   · `enabled` — rest per On.
//   · `hover` — the rest track washed with its own ink (`activeStateLayer` /
//     `inactiveStateLayer`) at `stateLayer.hover`: a `state layer` rectangle
//     pinned over the track, child 0, at that opacity.
//   · `pressed` — the same layer at `stateLayer.pressed`. The Clickable's
//     press shrink is a gesture-time motion with no static picture, so the
//     canvas draws the wash only (decision 2026-09-09).
//   · `focus` — the rest track plus the `FocusOutline` around the TRACK
//     (`toggle.dart` wraps the track, not the row, and turns the Clickable's
//     own ring off). Geometry from `focusOutlineStyle`; corner is the slot's
//     pill.
//   · `disabled` — said by the track: `disabledActiveTrack` (on) /
//     `disabledInactiveTrack` (off). The thumb takes `disabledThumb` (on,
//     = surface) / `disabledInactiveThumb` (off, = disabled content — a
//     surface thumb vanishes into the disabled off track), label
//     `disabledForegroundColor`. The thumb stays at the On pose's
//     offset, because `left:` reads `widget.value` and never `enabled`.
//     `disabledOpacity` is deliberately not applied — it is `opacity100` in
//     the recipe (the generic clickable fade is switched OFF because the
//     toggle paints its own disabled tokens), so fading here would
//     double-count.
//
// The state layer node exists on every member and is hidden on the three
// rungs that do not wash — the canvas keeps it that way so a designer can
// find it, and a hidden node paints nothing.
// The toggle's track node name — shared with any parent that forwards a track
// colour into a composed `Toggle`.
export const kToggleTrackName = 'track';
