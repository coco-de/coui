/// Catalog slugs of the components whose Web `_style.dart` writes
/// the surface marker onto their own root element — Flutter is symmetric.
///
/// What this set is for: the tier policy (`tier1_policy.dart` — a
/// component that owns a surface is tier 1), and the record of *why* each
/// component marks or marks conditionally, which lives in the comments
/// below and nowhere else.
///
/// What this set is **not** for: deciding which preset rows the parity
/// matrix may skip. It was, and that is what kept the nightly red — a
/// material reaches a component through any marker in its rendered
/// example, its own or a composed child's, and `gap`'s example is two
/// `Button`s. The matrix now measures that directly from the server render
/// (`material_reach.dart`); this list describes call sites, not reach.
///
/// The count is deliberately not written down here. It was, and the
/// sentence went stale the first time a component joined the set — a
/// number in prose is a second source for something the set below already
/// states, and the one that rots is always the prose.
///
/// A literal set, kept honest by `surface_marker_registry_test.dart`, which
/// re-greps `packages/coui_web/lib/src/components/` for `webSurfaceMarkerFor`
/// call sites on every test run and fails if this set drifts — a
/// *verified* assertion, not an unchecked list left to rot
/// (`core/theme-axis-composition.md` — "match-status 를 정적 목록으로
/// 단언하지 마라").
const Set<String> kSurfaceMarkerComponentSlugs = {
  'outlined-container',
  'popup',
  'card',
  'dock',
  'scaffold',
  'navigation-bar',
  // Floating app chrome publishes the functional material on its root.
  'app-bar',
  // The action bar a shell pins over a scrolling body. It draws its own
  // box — the fill, the hairline above it and the padding are all on the one
  // root `<div>` — rather than composing `OutlinedContainer`, so it restates
  // the functional marker there, as `dock` does. Marked unless the fill
  // paints nothing: a material behind no fill would frost a band with
  // nothing to explain the tint. Its Flutter twin reads the same functional
  // material from the theme and wraps its fill in `SurfaceBlur`.
  'bottom-action-bar',
  // A sheet over the page — its panel marks itself (#5874).
  'bottom-sheet',
  'dialog',
  'tooltip',
  // Draws its own box rather than composing `OutlinedContainer`, so the
  // marker is restated on that box. Its Flutter twin gets the same
  // treatment by composition — without this the same alert was glass on
  // one platform and an opaque rectangle on the other.
  'alert',
  // The floating-panel group. Each draws its own panel rather than
  // composing one, so each restates the marker on that panel; their
  // Flutter twins wrap the same panel in `SurfaceBlur`.
  'drawer',
  'toast',
  'command',
  // In-flow rather than floating, but the same reasoning as `card`: it
  // draws its own box, so what shows through it is the page it is laid
  // on rather than a parent panel.
  'item-picker',
  // Container chrome rather than an overlay: floats over the page while
  // being dragged, and draws its own box rather than composing `Card`.
  // Marks conditionally — a variant may state no fill, and a material
  // behind nothing draws a band around a box that is not there.
  'draggable-panel',
  // #4365 — both compose `OutlinedContainer` on Flutter but restate the
  // marker on Web instead of a DOM restructure (the pattern `alert`
  // already set). Marked conditionally, same reasoning as
  // `draggable-panel`: only the state that actually has a fill — the
  // active page pill — carries the marker. The hover / idle states are
  // transparent or a `:hover` pseudo-class the marker class cannot gate,
  // so marking them would blur the page behind a box with nothing in it.
  'pagination',
  // The floating pull-to-refresh indicator. Always has a real fill (no
  // transparent rest state to guard against), so it marks
  // unconditionally like `toast`.
  'refresh-trigger',
  // #4362 — draws its own box on both platforms (the `alert` pattern),
  // not just on Web: the left accent is a single-edge border
  // `CoreOutlinedContainerStyle` has no field for, so neither platform
  // can compose `OutlinedContainer` without growing a border on the
  // other three edges. Always has a real fill, so it marks
  // unconditionally.
  'banner',
  // #4362 — Flutter composes `OutlinedContainer` for the pill; Web
  // restates the marker instead (the `alert` pattern) for a different
  // reason than the border-shape ones above: `OutlinedContainer`'s Web
  // resolver always emits an inline `box-shadow` (even for an
  // explicit-empty override, it folds to the rim reference rather than
  // omitting the property), and an inline declaration out-ranks the
  // `kControlShadowRestMarker`/`kControlShadowPressMarker` classes this
  // pill already owned for its press/hover cast — composing would have
  // silently killed that pre-existing mechanism. Marked conditionally,
  // same reasoning as `draggable-panel`/`pagination`: the custom-seed
  // unselected state and a caller override can both resolve to
  // `CoreColor.transparent`, and a chip with no fill never declared
  // itself a surface.
  'chip',
  // #4361 — composes `OutlinedContainer` on Flutter (the box), restates
  // the marker on Web (a single `<div>`, no DOM restructure). Marked
  // conditionally, same reasoning as `pagination`: only the resting
  // (unchecked) state has no glyph riding on its fill, so only that
  // branch carries the marker — checked / indeterminate / disabled keep
  // an opaque fill so the check glyph stays legible.
  'checkbox',
  // #4361 — the track composes `OutlinedContainer` on Flutter, restates
  // the marker on Web (a `<span>`, no DOM restructure). Marked on both
  // enabled states (active + inactive) — unlike `checkbox`/`pagination`,
  // this one is not fill-vs-transparent: the thumb (never marked, always
  // opaque) already carries the on/off distinction on an axis material
  // cannot dim, so both track fills are safe to glass. Disabled is never
  // marked. The thumb itself never carries the marker.
  'toggle',
  // #4361 — the ring composes `OutlinedContainer` on Flutter, restates
  // the marker on Web (a `<div role="radio">`, no DOM restructure).
  // Marked on both enabled states (selected + unselected) — the ring's
  // fill does not change on selection (only the border colour and the
  // separately-drawn, fixed-colour inner dot do), so there is no
  // glyph-contrast risk either state. Disabled is never marked.
  'radio-group',
  // #4361 — composes `OutlinedContainer` on Flutter (the panel box),
  // restates the marker on Web (a single `<div>`, no DOM restructure).
  // Marked conditionally on `hasFill` — the `outlined` and `plain` variants
  // state the token-less transparent sentinel (only `filled` states a
  // token), and `backdrop-filter` does not key off the fill var, so
  // marking a fill-less fieldset would frost a box with nothing to
  // explain the tint.
  'fieldset',
  // #4361 — composes `OutlinedContainer` on Flutter (the card box),
  // restates the marker on Web (a single `<div>`, no DOM restructure).
  // Marked unconditionally across all three states (idle / hover /
  // selected) — every fill is a real, opaque design token and no glyph
  // rides on it, only caller-supplied text/content that already
  // carries its own colour, so there is no fill-less-box / glyph-
  // contrast risk in any state.
  'multi-answer-card',
  // #4361 — composes `OutlinedContainer` on Flutter (the outer box
  // around the single real `<input>`), restates the marker on Web (a
  // single `<div>`, no DOM restructure). Marked unconditionally across
  // both focus states — the fill is a real, opaque design token and no
  // glyph rides on it, only the input's typed text / caret (already
  // carrying its own colour), so there is no fill-less-box risk in
  // either state.
  'formatted-input',
  // #4361 — composes `OutlinedContainer` on Flutter (the outer box
  // around the per-field `TextField`s + separator text), restates the
  // marker on Web (a single `<div>`, no DOM restructure). Marked
  // unconditionally across both focus states — the fill is a real,
  // opaque design token and no glyph rides on it, only the per-field
  // inputs' typed text / caret and the separator text (already
  // carrying their own colour), so there is no fill-less-box risk in
  // either state.
  'object-input',
  // #4363 — composes `OutlinedContainer` on Flutter (the panel box
  // around the item column), restates the marker on Web (a single
  // `<div>`, no DOM restructure). Marked conditionally on
  // `merged.backgroundColor != null` — `CoreAccordionStyle
  // .backgroundColor` has no design-system default (absence is the
  // shipped design), so an accordion with no caller override draws no
  // box at all, and marking it anyway would frost a fill-less panel
  // with nothing to explain the tint.
  'accordion',
  // #4363 — composes `OutlinedContainer` on Flutter (the full-bleed
  // band), restates the marker on Web (the existing `<footer>` root, no
  // DOM restructure). Marked unconditionally — the background always
  // resolves to a real, opaque design token
  // (`CoreFooterStyle.defaultBackgroundColor`), never a transparent
  // sentinel, so there is no fill-less-band risk in any state.
  'footer',
  // #4363 — composes `OutlinedContainer` on Flutter (the solid-colour
  // path only), restates the marker on Web (the existing root `<div>`,
  // no DOM restructure). Marked conditionally on `imageUrl == null` —
  // `OutlinedContainer` has no image slot, so a picture hero has
  // nothing defined for a material to compose atop of and keeps its
  // hand-drawn `background-image` box instead.
  'hero',
  // #4363 — steps 가 세운 기준(내용 없는 dot-indicator 가 아니라
  // 번호·체크를 담는 badge 형 면)으로 함께 결정됐다. Each per-step
  // indicator circle composes `OutlinedContainer` on Flutter, restates
  // the marker on Web (the existing per-step `<div>`, no DOM
  // restructure). Marked unconditionally on both states — the active
  // (`primary`) and inactive (`surfaceContainer`) fill tokens always
  // resolve to a real, opaque design token, so there is no
  // fill-less-circle risk in either state.
  'stepper',
  // #4363 — the twin of `stepper` (no `Clickable`, otherwise identical
  // indicator treatment — decided together per the issue's own "steps
  // sets the standard" note). Same unconditional marking on both
  // states.
  'steps',
  // #4363 — the floating window frame. Composes `OutlinedContainer` on
  // Flutter (fill / border / radius; the frame's own drop-shadow stays
  // painted separately — see `ResolvedWindowPanel.boxShadow`'s doc),
  // restates the marker on Web (the existing root `<div>`, no DOM
  // restructure). Marked unconditionally — the fill always resolves to
  // a real, opaque design token (`CoreWindowPanelStyle
  // .defaultSurfaceColor`), never a transparent sentinel. Role
  // `functional` — a window is the floating-panel case the axis
  // documents.
  'window-panel',
  // #4363 — the drag-to-snap bar (the frame itself is delegated to
  // `window-panel`, already registered above). Already composed
  // `OutlinedContainer` on Flutter pre-#4363 (this issue adds
  // `role: .functional`); restates the marker on Web (the existing
  // snap-bar container `<div>`, no DOM restructure). Marked
  // unconditionally — the fill always resolves to a real, opaque
  // design token (`CoreWindowStyle.defaultSnapBarBackgroundColor`).
  // The snap-preview / snap-tile overlays stay out of scope — the
  // preview's `snapPreviewBlurSigma` is an always-on frost baked into
  // this component's own design (default 8, not gated on any preset),
  // and folding it into `OutlinedContainer`'s preset-driven
  // `surfaceBlur` would either double-blur under a glass preset or
  // drop the frost entirely under a non-glass one — exactly the risk
  // the survey flagged. Left as its own hand-drawn `BackdropFilter`.
  'window',
  // The swatch button composes `OutlinedContainer` on Flutter, restates the
  // marker on Web (a single `<div>` per swatch, no DOM restructure). Marked
  // only while its fill paints: the default swatch is a ring with no body, and
  // a material behind no fill would frost the page around a circle with
  // nothing to explain the tint. A caller who gives the button a fill gets the
  // material on both states (selected / unselected) — the fill does not change
  // with selection, only the border does. Flutter forces `surfaceBlur: 0` and
  // an empty cast for the same bodiless ring, so the two platforms draw the
  // same thing under every preset.
  'theme-controller',
  // `toggle-group`: the track composes `OutlinedContainer` on Flutter and
  // restates the marker on Web (the outer `<div role="radiogroup">`); the chosen
  // face is deliberately never marked — it lerps through alpha 0 on every
  // change, and a material marker class cannot follow a lerp. `filter` is not
  // listed: it composes `ToggleGroup`, so the marked track is the group's.
  'toggle-group',
  // `fab` is deliberately absent. It used to be here for one reason: the
  // speed-dial's action **label pill** was a bare `<div>` that had to
  // restate the marker itself. That pill is gone — the actions are now a
  // `Popup` panel holding one `Button(variant: .menu)` row each, and the
  // main circle is a composed `Button`. Both of those are marked at their
  // own call sites, so the FAB now receives material through composition;
  // re-marking it here would stack a second backdrop pass over surfaces
  // that already have one (`core/theme-axis-composition.md`).
  // In-flow, like `item-picker`: draws its own CSS Grid box rather than
  // composing `OutlinedContainer`. Marks conditionally — the table states
  // no fill by design, so an instance with no `backgroundColor` override
  // has nothing for a preset to make translucent (#4359).
  'table',
  // Its root already resolves hover × focus × disabled × selected as a
  // `WidgetStateProperty`, and its Web twin is the native `<button>`
  // element itself — it cannot compose `OutlinedContainer`, so it
  // restates the marker on its own root instead (#4360).
  'button',
  // The form-field group (#4356 — restate-marker/form). Each draws its
  // own box directly on the native input/textarea element rather than
  // composing `OutlinedContainer` — wrapping would move the framed body
  // to a different element than the one `FocusOutline` rings. Unlike
  // `table`, these always state a fill by design; the marker only drops
  // once a caller explicitly overrides `backgroundColor` to transparent.
  'text-field',
  'text-area',
  'phone-input',
  'chip-input',
  // Unlike its siblings above, marks conditionally — the idle state
  // states no fill of its own by design (the dashed border alone reads
  // as a drop zone), so an instance with no `backgroundColor` override
  // has nothing for a preset to make translucent. Its drag-active state
  // always states one.
  'file-input',
  // Each row draws its own box on its own `<div role="listitem">` rather
  // than composing `OutlinedContainer`. Always states a fill by design
  // (idle token or hover token), so the pair applies unconditionally
  // like text-field/text-area/phone-input/chip-input above.
  'sortable',
  // functional — the bar mounts its dropdown through
  // `OverlayPositioner`/`PopoverOverlayHandler`, so content passes behind
  // it; the bar draws its own box (border-gated) rather than composing
  // `OutlinedContainer` (#4357).
  'menubar',
  // content — re-verified after an earlier survey misread it as
  // functional: zero sticky/fixed/absolute/`OverlayPortal` evidence on
  // either platform, an in-flow segmented rail like `filter`. Marks
  // conditionally (`pill` variant only — `underline` paints no fill).
  // `tab_pane_style.dart` lives in this same directory and marks only
  // its content panel, not the boxed-tab affordance, so the derived slug
  // set below sees one entry — `tabs` — for both (#4357).
  'tabs',
  // The display group (#4358). `badge` / `validation-badge`'s Web root
  // is a fixed `<span>` — wrapping either in `OutlinedContainer`'s
  // `<div>` breaks the inline flow they are meant to sit in. `chat`
  // (its `ChatBubble` panel) cuts a concave tail path against the same
  // fill, a shape the container has no slot for. `kbd` marks each key
  // cap (also a fixed `<span>`), not its row container. All four
  // restate the content-role marker+fill pair directly, the same
  // "can't compose" reasoning `button` (#4360) and `table` (#4359) use.
  'badge',
  // `tag` restates the same pair on its `<span>` root for the same reason
  // as `badge` — an inline label part that a `<div>` wrapper would break.
  'tag',
  'validation-badge',
  'chat',
  'kbd',
};
