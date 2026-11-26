# liquid_glass_widgets 1.15.1 → 1.17.4 — what applies to CoUI

Reference: [sdegenaar/liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets), published `1.17.4`
(source commit `5bad197a`; the pub.dev archive is byte-identical to it for `lib/`, `shaders/`, `pubspec.yaml` and
`CHANGELOG.md`), inspected on 2026-11-17. The window starts where the previous audit stopped, `v1.15.1`
(`6478c02`): [1.14.1 → 1.15.1](2026-10-28-liquid-glass-widgets-1-15-delta.md). GitHub tags stop at `v1.17.3`;
three later commits on the default branch (#488, #489, #491) are unreleased and were not read as part of the window.

CoUI has its own glass (Core contract, Flutter seat, Web seat) and does not depend on the package. The package is a
behavioural reference: each upstream change was read, the CoUI path that answers the same question was located on both
platforms, and the result is one of **applied**, **already handled**, **not applicable** (the structure that produced
the upstream defect does not exist here) or **designer decision** (a look or feel call, not a defect). No upstream code
was copied.

## Reading the result

The release that matters most is the smallest. `1.17.4` found that Flutter 3.50's shader compiler warns about a
fragment shader whose `main()` returns early while it also samples a texture, and the release reports HLSL compile
failures for the same shape on Windows Direct3D and Chrome ANGLE. CoUI's refraction shader had exactly that shape, so
it applies here and is fixed (and guarded).

Most of the rest is look calibration for iOS 26/27 (new default style, 320 pt dialog platter, premium defaults,
morph physics, lens contours), which is a designer's call, and navigation-shell / page-transition work for
components CoUI does not have. What the window did surface in shared behaviour: a switch row that looked enabled
with no callback, a dialog that was not named, a dialog that ignored the keyboard, a time picker panel with no name,
an obscured field that still capitalised, and a swipe row that ran its first action on the very pixel that opened it.

The same request asked for Flutter 3.50.0. It is applied on the Jaspr 0.24 beta line the owner approved, in a commit of
its own, and written up on its own with the measurements and what it costs outside the repository:
[Flutter 3.50.0 — what the bump took](2026-11-17-flutter-3-50-toolchain.md).

## Disposition of the upstream window

"Pinned" means a test reads the rendered result and fails if the behaviour is removed. "Read" means the code was
read on both platforms and judged to answer the question, without a new test.

| Upstream | CoUI |
| --- | --- |
| 1.17.4 shader `main()` single exit (flutter/flutter#190809); shader CI guards | **Applied** — `surface_refraction.frag` has one exit; a new guard checks the shape statically and compiles every shader for the five target sets (see below) |
| 1.17.4 `GlassSwitch` disabled by `onChanged: null` (#485, #486) | `Toggle` already did this (`enabled ?? onChanged != null`), now **pinned** on both platforms. `SwitchField`, which composes it, did not — **applied** (behaviour change, see decisions) |
| 1.17.4 corner radii kept per corner in the standard renderer (#487) | Not applied — the refraction band reads one radius; see "Not applied" |
| 1.17.3 disabled dialog actions (#480) | Already handled — a dialog action with no handler keeps its place and announces disabled. `Button` already pinned that; now **pinned inside a dialog** on both platforms |
| 1.17.3 text capitalisation on text fields (#477) | Already handled (`textCapitalization` exists on both). Found on the way: Flutter capitalised an **obscured** field — **applied** (see below) |
| 1.17.3 dialog scroll, keyboard avoidance, route semantics, AX-scale wrapping (#479) | Scroll and AX wrapping already handled. Keyboard avoidance **applied** (Flutter; the browser owns it on Web). Dialog naming **applied** on both. `MaterialApp` text style not applicable |
| 1.17.3 menu/popover modal barrier semantics (#470) | Already handled — Flutter `BlockSemantics` on the barrier, Web `inert` on the app subtree (read) |
| 1.17.3 pinned chrome behind page-menu barriers (#476), picker sheet result (#474) | Not applicable (no navigation shell, no picker sheet) |
| 1.17.3 lens contours / tab-bar platter physics (#481) | Designer decision (calibration) |
| 1.17.2 solid-surface `GlassChip` | Not applied — per-instance `surfaceStyle`, see "Not applied" |
| 1.17.2 standard-quality visual parity; segmented-control resting look | Designer decision (calibration) |
| 1.17.2 pinned chrome over fullscreen dialogs (#466); linear back-swipe parallax (#468) | Not applicable (no navigation shell, no page route transitions) |
| 1.17.1 `semanticsChecked` on menu rows (#462) | Already handled — checkbox/radio rows announce role and checked state on both platforms (Flutter pinned, Web pinned). The Context Menu page said the opposite; that line is removed |
| 1.17.1 rounded page clipping during transitions (#451) | Not applicable |
| 1.17.1 morph parity for menu / pull-down / popover (#453) | Designer decision (motion) |
| 1.17.0 default style `ios27`, 320 pt platter, premium defaults, tab-bar sizing | Designer decision; CoUI's surface styles are chosen by the app |
| 1.17.0 `semanticsSelected` (#455), `semanticLabel` (#461) on menu rows | `semanticsSelected` already handled. A per-row spoken-label override is a possible addition (low priority) |
| 1.17.0 `menuSemanticLabel` (#458) | Open — see "Not applied" |
| 1.17.0 `opaqueColor` / `border` on menus (#460) | Already handled by the global reduce-transparency and high-contrast axes (read) |
| 1.17.0 switch On/Off labels, RTL mirroring (#459) | Labels: no browser signal exists and the look needs a design. Mirroring: see decisions |
| 1.17.0 `pressLightColor` (#457) | Not applicable |
| 1.16.1 swipe actions, long labels (#449) | Full-swipe overshoot **applied**. The squeeze the upstream fix removes does not exist here (no `FittedBox`), so its 75 % cap is not applicable; letting a long label widen its action into a capsule is a designer decision and is documented |
| 1.16.1 `menuSettings` on bar/group menus | Already handled |
| 1.16.0 solid surface style for inputs, pickers, disclosure | Not applied for inputs/chips — see "Not applied". Disclosure already handled |

## What changed

### Shader: one exit, and a guard that compiles it

`surface_refraction.frag` read the middle sample, returned early when no dispersion was requested, and otherwise
read two more. Under Flutter 3.50 the compiler warns about that shape (`texture samplers alongside multiple
'return' statements in main()`); the warning does not fail the build, so it shows only as a box in the log. The
upstream release also reports HLSL compile failures for this shape on Windows Direct3D and Chrome ANGLE — not
reproduced here; `flutter/flutter#190809` is a crash in the same compiler whose shader was never identified. The
shader now reads the middle sample unconditionally, replaces only the red
and blue channels when dispersion is on, and leaves through a single `fragColor = colour;`. Output is unchanged for
both paths.

`scripts/guards/structure/check_shader_single_exit.sh` has two phases: a static check that every fragment shader has
one exit (runs without an SDK, in the static-guards list), and a compile of every shader for the five target sets
Flutter's tool uses, failing on any warning (runs in the `flutter` job; `--require-compiler` makes a missing compiler
a runner failure, exit 3, rather than a skipped green). Measured with 3.50.0's `impellerc`: the old shader warns on all
five target sets, the new one on none; with 3.47.9's `impellerc` neither warns, so the fix is neutral on the pinned SDK.
The guard was failed on purpose against the old shader (both phases fail) and has a self-test.

### `SwitchField` follows its callback

`SwitchField(onChanged: null)` drew and behaved as enabled: `enabled` defaulted to `true` and the field handed that to
the `Toggle` it composes. `CoreSwitchFieldContract.enabled` is now `bool?` and both platforms resolve
`enabled ?? (onChanged != null)`, the same rule `Toggle` and the other controls use (`cross-platform/api.md`).
**This is a behaviour change, and the owner approved it on 2026-11-17** (the cross-platform API rule asks for approval
before merge): a field that was given no callback and relied on looking enabled now looks disabled. Pinned on Flutter
(semantics: enabled flag and tap action) and on Web (`aria-disabled`, `tabindex`), with the explicit `enabled` still
overriding either way.

### Obscured fields capitalise nothing (Flutter)

The Web fields drop `autocapitalize` when obscured; the Flutter `TextField` and `TextArea` passed the caller's
`textCapitalization` to the editable regardless, so a password field with `.words` capitalised. They now pass `none`
while obscured and give back the stated value when revealed. `check_obscure_text_parity.sh` lists the capitalisation
service so the two platforms cannot drift again.

### Swipe actions: a full swipe is reachable

On a row whose actions were already as wide as the full-swipe threshold, the full-swipe distance equalled the open
width, so the pixel that reached the open pose also ran the first action — opening and running were one gesture.
`CoreSwipeActionsContract.defaultFullSwipeOvershoot` (24) makes the distance `open width + overshoot` when the open
width is at or past the threshold. The vector table both platforms read was extended: on a 100 px row with a 132 px
platter a pull of 133 settles open and 156 runs the action; on a 300 px row with a 252 px platter, 275 settles open and
276 runs it. The Figma export gained one row, `fullSwipeOvershoot`, regenerated from Core (no allowlist or baseline
change).

### Dialog: keyboard, and a name

- **Keyboard (Flutter).** The route centred the panel in the whole window, and the keyboard covers part of the window.
  The panel is now padded by the bottom inset and the inset is removed for descendants, so it centres in what the
  keyboard leaves and a tall body still scrolls with the actions pinned. On the Web the browser owns the keyboard.
- **Name (both).** The title is the dialog's name; no new string. Flutter marks the title as naming the route and the
  panel states the `dialog` role; Web points the panel's `aria-labelledby` at the title element (a per-instance id) and
  takes the role from `CoreSemanticRole.dialog`. A caller-supplied `aria-label` / `aria-labelledby` wins. A dialog
  with no title has no name.

### Time picker panel names itself (Flutter)

The Web panel content has `role="dialog"` and the locale's `timePickerPopoverLabel`; the Flutter content had neither,
in any locale. It now states the same role and label (Korean pinned against the locale table, so a literal fails).

### Pins and a doc line that contradicted the code

- Flutter `Menu`: the existing `exposes ariaLabel through Semantics` test only checked that a `Menu` exists. It now
  reads the rendered node (role `menu`, named), the unnamed menu, and the horizontal `menubar`.
- Flutter `Toggle`: `does not call onChanged when null` asserted a constant `false`. It now reads the rendered
  enabled flag and tap action with and without a callback, and with an explicit `enabled`.
- Web `Toggle`: the rendered `aria-disabled` / `tabindex` for the same three cases.
- `context-menu.md` said the Flutter panel has no menu structure and does not expose checked state; the same page
  (and the code) say the opposite. The line is removed. `time-picker.md` and `dialog.md` now describe the current
  accessible names.

## Verification

The changes were first verified on Flutter 3.47.9, the SDK the repository was pinned to: full suites Core 7,780, Web
8,962, Flutter 11,900 (+5 skipped), all passing. They were then run again on 3.50.0 together with the toolchain change
set — every package the CI test commands cover, all 101 guards, the repository-wide format and analyze gates and
`jaspr build`; the commands and numbers are in [the toolchain note](2026-11-17-flutter-3-50-toolchain.md) (Core 7,775,
Web 8,964, `coui_flutter` 11,855 plus 47 golden and parity tests, …).
Docs gates (`docs_plain_words`, `docs_section_contract`, `catalog_single_source`, `llms_txt_sync`, `docs_api_sync`,
`guide_catalog_single_source`) pass. Structure guards run and passing: `check_obscure_text_parity`,
`check_shader_single_exit` (+ self-test), `check_localization_parity`, `check_ci_guard_deps_order`,
`check_dead_widget_param`, `check_chrome_passthrough`, `check_deprecation_policy`, `check_name_collisions`,
`check_figma_unread_fields`, `verify_contracts`, `check_design_tokens --phase 6/7`. The exporter's output for
`components.json` equals the working copy, whose only difference from the committed file is the one new row.
`dart format` has no drift and `dart analyze --fatal-infos` reports nothing on any line changed here (the files also
carry older findings that were not touched; on 3.50.0 `text_field.dart` and `text_area.dart` also carry the Material
import deprecation, see the toolchain note). The Figma plugin's `npm ci`, `typecheck` and full `selftest` run exit 0
with the new `components.json` row.

Each new or rewritten test was mutation-checked: the behaviour was removed, the named test failed, and the code was
restored. That covers the shader shape, the `SwitchField` default on both platforms, obscured capitalisation, the
overshoot formula, the dialog padding, both dialog names, the disabled dialog action on both platforms (through a
change to `Button`'s derivation), the time picker label and its locale wiring, the menu role, and both `Toggle` pins.

### Not verified

- No real screen reader (VoiceOver, TalkBack, NVDA) and no real on-screen keyboard were used. Naming and keyboard
  behaviour are read from the semantics tree, the DOM attributes, and a simulated bottom inset.
- The Web dialog name is read from the attributes a component test renders, not from a browser's accessibility
  tree.
- The shader was compiled with `impellerc` for the five target sets, not run on Windows or in a browser.

## Open decisions

1. **`SwitchField` default.** Decided on 2026-11-17: approved, as recommended — every other control resolves from its
   callback.
2. **Full-swipe overshoot.** CoUI uses 24 (the 4 pt grid); upstream pulls about 25 past the open width.
3. **Toggle mirroring in RTL.** `Toggle` thumbs travel in physical directions on both platforms while the Core docs
   describe logical ones. Mirroring means a logical thumb position on Flutter (`AnimatedPositionedDirectional`), a
   direction variable in the Web transform, a shared vector table, and a browser probe. It is a design call whether a
   switch mirrors in RTL at all (the system switch does).
4. **Per-instance `surfaceStyle`.** Whether an input or chip inside an enclosing solid `Card` should inherit its
   style is a designer decision (recommended: it does not; the instance states it).
5. **Menu panel naming.** `Menu` has `ariaLabel`; `DropdownMenu`, `ContextMenu` and `Menubar` do not expose it, and the
   Flutter `Select` panel is unnamed. Naming the slot (`ariaLabel`, the Web term, versus `semanticLabel`, upstream's)
   comes first because the name must be the same on both platforms.

## Found on the way, not changed

- **Time picker segments (Flutter).** The hour, minute and second inputs have no accessible name; Web labels them
  with `aria-label`. The visible caption is a sibling `Text`. Closing it needs a name route into the internal
  `TextField`.
- **Toggle group items (Flutter).** In the open time picker the AM/PM items' semantics labels read twice ("AM", newline,
  "AM") in the tree. Not investigated.
- **Committed probe.** `packages/coui_flutter/test/zz_scratch_hidden_subtree_probe_test.dart` is tracked, prints with
  `print`, and says "TEMPORARY … delete after measuring". It has been in the tree since an earlier release.
- **Web Space-hold marker.** A held-Space class marker on `Clickable` is lost when the component re-renders during the
  hold (pre-existing; upstream's press-hold item is about a different structure).
- **Web stacked modals.** The app subtree gets one `inert`; whether a modal opened over another modal leaves the lower
  one reachable was not measured (outside this window).
- **Flutter drawer and keyboard.** `Drawer` has the same keyboard gap the dialog had. Not measured.
- **Chip glass gate.** The default outlined chip may draw glass on Flutter where Web draws none; not verified.
- **`dart analyze . --fatal-warnings` is red on `main`.** Three `prefer_k_prefixed_global_constant` warnings in
  `tool/parity` (`fixedTimeCaptureComponents`, `loadingBarMotionCases`, `loadingBarMotionPhases`, added by the
  parity work of 2026-11-16) appear identically at the pre-change `HEAD` on 3.47.9. Per-package analysis does not
  look at `tool/`, which is why the package runs are clean.
- **Weak tests found.** The two vacuous tests named above. A repository-wide search for tests whose only assertion is
  a type lookup or a constant has not been done.

## Not applied, and why

- **Per-corner radii in the refraction band (#487).** CoUI's band uses one radius (`radius.topLeft.x` on Flutter,
  `border-top-left-radius` for the Web displacement map). It matters where a surface has unequal corners — a bottom
  sheet (top 24, bottom square) — and the difference is about 124 px² per corner. A fix needs extra uniforms
  appended after the existing ones (a vector of radii), the Web map to read all four corners, a Core reference and new
  parity vectors.
- **Per-instance `surfaceStyle` on text fields, pickers, chips and autocomplete (1.16.0, 1.17.2).** Core has the field
  on the component styles with deliberately no default; Flutter would resolve it with `resolveSurfaceTheme` at the five
  places a field draws its material (and the chip at both of its sites), Web would emit the surface marker per instance
  and widen the alpha-reset rule, autocomplete needs a nested text-field slot, and `components.json` and the docs tables
  change. Large, and gated on decision 4.
- **Menu panel names (#458).** See decision 5.
- **Switch On/Off labels (#459).** Needs a browser signal (none exists) and a design.
- **Look calibrations.** The iOS 26/27 defaults, the 320 pt dialog platter, premium quality defaults, morph physics,
  lens contours and standard-quality rim shading are surface-style decisions the app makes through the style axis; none
  of them is a defect.
- **Navigation shell, page-route transitions, picker sheet, `pressLightColor`.** No such components or no equivalent
  structure.

## Next pass

Start after `1.17.4` (`5bad197a`). The unreleased commits #488, #489, #491 are the first things to read — and were
read: [1.17.4 → 1.17.5](2026-11-17-liquid-glass-widgets-1-17-5-delta.md) continues from here.
