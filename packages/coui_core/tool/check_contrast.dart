// Audits WCAG contrast for the semantic colour pairs the design system
// actually renders, in both light and dark.
//
// The existing token guards stop hardcoded values from getting in; none of
// them look at contrast. So a palette tweak or a semantic-mapping change can
// drop a pair below `1.4.3 Contrast (Minimum)` and nothing notices — the
// build is green and the screen looks plausible until someone with low
// vision cannot read it.
//
// "Actually renders" is a colour source, not just a palette. A palette says
// which colours exist; the mapping that reads it says what each semantic
// slot means. CoUI renders its own fixed palette through its own mapping
// (`CouiColorPresets.source`) — every CoUI seat, `CoreThemePresets`, the
// docs site and Web's `ThemeConfig.defaults()`, reads that one source, so
// that is the one this gate exists to measure. It once measured a
// different mapping instead: four schemes, none of them on any screen, and
// the numbers were about a palette nobody saw. `auditDriftFromCouiTheme`
// fails the run if the audited CoUI schemes ever leave what CoUI renders.
//
// The standard mapping is audited too, under its own `standard` keys: it
// is what every brand on a generated palette inherits when it states no
// mapping, so a regression there reaches all of them, and it costs four
// scheme builds.
//
// What counts as a pair is the M3 contract itself: an `onX` token exists to
// be drawn on `X`, so every such coupling is a real rendered combination
// rather than a guess. Surface foregrounds are checked against every surface
// container tone because a component is free to sit on any of them.
//
// Thresholds follow WCAG 2.2:
//   - body text                     4.5:1  (1.4.3)
//   - UI component boundaries       3.0:1  (1.4.11)
//
// Asserted in CoUI's high-contrast modes only:
//   - `outlineSubtle` — the border of a floating panel. Subtle by design in
//     the normal modes (see below), but a floating panel leans on this line
//     instead of its shadow once high contrast is on, so CoUI's two
//     high-contrast tables state it at 4.5:1 or better on the page and on
//     the panel's own fill (`surface`, `surfaceBright`) — the designer's
//     rule for UI lines in that mode. The standard mapping reads the slot as
//     `outlineVariant`, a hairline, so it is held to no such bar there.
//
// Category colours (`CoreCategoryColor`, nine hues that only tell things
// apart) owe bars of their own, under both mappings:
//   - the strong chip label (`on-category-*` on `category-*`) — 3.5:1 in
//     light, 4.5:1 in dark. The light bar is a named exception the designer
//     narrowed to this one pair in this one mode, and to labels set
//     SemiBold or heavier at 12px or more — a word or a time, never a
//     sentence: held to 4.5:1, white text turned the light fills dark and
//     muddy. It is a constant of its own rather than the 3:1 large-text
//     tier, so a fill drifting under 3.5 still fails.
//   - the soft chip label (`on-category-*-container` on its container), and
//     the same tone as coloured text on the page — 4.5:1.
//   - in high contrast, every category text pair — 7:1 (WCAG 1.4.6), and
//     the outline on the page — 4.5:1, the mode's UI-line bar. Both
//     mappings write their high-contrast category values from one table
//     (`CoreCategoryPalette.applyTo`, inside each raise), which is why these
//     bars hold on the standard mapping too, unlike `outlineSubtle` above.
//     The table was authored to them; held to 4.5:1, a high-contrast tone
//     could fall well short of what it was chosen for and nothing would
//     notice.
//
// Deliberately NOT asserted:
//   - `outlineVariant` — the subtle divider tone. 1.4.11 covers boundaries
//     that convey state or delimit a control, not decorative rules; holding
//     a hairline divider to 3:1 would force it to stop being a hairline.
//   - `outlineSubtle` in the normal modes — a faint line on purpose (light:
//     lighter than `outlineVariant`; dark: the same step as `outlineVariant`,
//     one step above the panel's fill at about 1.4:1). Same reasoning as
//     `outlineVariant`.
//   - anything disabled — 1.4.3 and 1.4.11 both exempt inactive controls.
//     `disabled_tokens_test.dart` still pins those ratios, because we chose
//     to keep disabled legible even though the spec does not demand it.
//   - large-text-only pairs — no semantic token is large-text-only, so a
//     3:1 tier here would just be a weaker check on the same pairs.
//   - a category fill on the page (`category-*` on `surface`) — how visible
//     a chip or a chart mark is. The designer records it against the 3:1 UI
//     bar for reference only: a category is named by its label — the
//     chip's own, or a legend's — and those pairs are held above.
//   - the category outline in light and dark. In light it reads the
//     container tone, so the soft chip has no visible border on purpose; in
//     dark it measures about 2:1 — a tint that settles the chip's edge, not
//     a boundary delimiting a control. High contrast is where the mode
//     promises a visible edge, and there it is held.
//   - category pairs on a card or other container tone. The design states
//     its bars on the page, where a chip sits by default; the high-contrast
//     dark outline measures 3.64:1 on CoUI's `surfaceContainer`, under the
//     4.5:1 it clears on the page. The day a chip is drawn on a container
//     tone in that mode, these pairs have to grow to that tone.
//
// Ratchet: violations present today are frozen in a baseline; net-new fails.
// The baseline only shrinks.
//
// Usage:
//   (from packages/coui_core)
//   dart run tool/check_contrast.dart            # report
//   dart run tool/check_contrast.dart --ci       # fail on net-new
//   dart run tool/check_contrast.dart --update   # rewrite baseline

import 'dart:io';

import 'package:coui_core/coui_core.dart';

const _kBaselinePath = 'tool/contrast_baseline.txt';

const double _kTextMinimum = 4.5;
const double _kComponentMinimum = 3;

/// What a UI line owes in high contrast — the bar a floating panel's border
/// (`outlineSubtle`) and a scrollbar thumb are held to there. Higher than
/// [_kComponentMinimum] (WCAG 1.4.11) because the mode exists to raise
/// contrast and a panel has no shadow to fall back on.
const double _kHighContrastLineMinimum = 4.5;

/// What the light strong category chip's label owes its fill
/// (`on-category-*` on `category-*`) — the designer's named exception, see
/// the header. Not [_kComponentMinimum] or WCAG's 3:1 large-text bar: the
/// exception is 3.5, and a fill sliding toward 3 would pass under either.
const double _kCategoryLightLabelMinimum = 3.5;

/// What every category text pair owes in high contrast, under either
/// mapping — WCAG 1.4.6, the bar the high-contrast category tones were
/// authored to.
const double _kCategoryHighContrastTextMinimum = 7;

/// Decimal places used when reporting a broken self-check.
const int _kDiagnosticPrecision = 3;

/// Column width for the pair identifier in the report table.
const int _kKeyColumnWidth = 58;

/// Column width for the scheme name in the per-scheme scope summary — wide
/// enough for `<mapping prefix> <preset> (<brightness>)`.
const int _kSchemeColumnWidth = 31;

/// Every surface tone a component may sit on — the eight rungs of the
/// container ladder, and `surfaceRaised`, the face a selected segment or a
/// selected pill tab rises to out of its track. A label sits on that face
/// like on any other, so it owes the same bars.
const _kSurfaceTones = [
  'surface',
  'surfaceDim',
  'surfaceBright',
  'surfaceContainerLowest',
  'surfaceContainerLow',
  'surfaceContainer',
  'surfaceContainerHigh',
  'surfaceContainerHighest',
  'surfaceRaised',
];

/// The surface tones an **input field** sits on — the audit scope for
/// `placeholder`, which is narrower than [_kSurfaceTones] on purpose.
///
/// Why not all eight: `placeholder` states "no value has been entered yet",
/// so it has to read as weaker than the value that replaces it. That
/// hierarchy and a 4.5:1 floor against every container tone cannot both
/// hold — one of them has to give, and holding the hierarchy is what makes
/// the slot worth having. Auditing it against tones no input is drawn on
/// would make the guard permanently red for a conflict that exists only in
/// tones the pair never meets.
///
/// Inputs are boxed fields filled with `surface` (the text field and text
/// area variants state it), or bare fields that show the page ground behind
/// them — so the two tones here are the page ground and the one container
/// tone that equals it in light mode. On CoUI's palette the narrowing is
/// what the numbers require, not a convenience:
///
/// - light `placeholder` (neutral/600) is 4.47:1 on `surfaceContainerLow`
///   (neutral/50) and 4.28:1 on `surfaceContainer` / `surfaceDim`
///   (neutral/100) — under 4.5 on tones no input is filled with, and lower
///   still further up the ladder (4.05 on `surfaceContainerHigh`, 3.73 on
///   `surfaceContainerHighest`);
/// - dark `placeholder` (neutral/500) is 4.03:1 on `surfaceContainerHigh`
///   (neutral/850) and 3.36:1 on `surfaceContainerHighest` (neutral/800),
///   while on the dark `surface` (neutral/1000) every input actually sits on
///   it is 5.88:1 — and 4.65:1 on `surfaceBright` (neutral/900).
///
/// Both are recorded design decisions, accepted because the combination is
/// never drawn. The day a filled input — a field whose box is a container
/// tone — is introduced, this list has to grow to that tone, and the guard
/// will then say whether `placeholder` still reads on it.
const _kInputSurfaceTones = [
  'surface',
  'surfaceContainerLowest',
];

/// The surface tones the third text tier (`onSurfaceSubtle` — metadata,
/// line numbers, help text, timestamps) is held to 4.5:1 on.
///
/// The tier exists to read weaker than `onSurfaceVariant`, and CoUI states it
/// at the placeholder's step — the one step below the second tier on its
/// ramp. That hierarchy and a 4.5:1 floor against every container tone cannot
/// both hold, so it is held on the tones the tier's text is actually drawn
/// on, not on all of them:
///
/// - the input tones ([_kInputSurfaceTones]) — help text and metadata on the
///   page ground;
/// - `surfaceBright` — the floating panel's face, where a menu's group title
///   and a command palette's group heading sit;
/// - `surfaceContainerLow` and `surfaceContainer` — the grey container a card
///   subtitle (`Basic`) and a definition list's terms sit on.
///
/// Not every tone that is held is met in light: the tier reads 4.48:1 on
/// `surfaceContainerLow` and 4.29:1 on `surfaceContainer` there. Those are
/// recorded exceptions in the baseline, each with its reason, rather than a
/// reason to narrow this list — a tone the text is drawn on is measured.
const List<String> _kSubtleTextSurfaceTones = [
  ..._kInputSurfaceTones,
  'surfaceBright',
  'surfaceContainerLow',
  'surfaceContainer',
];

/// The tones code is shown on, which the four syntax colours
/// (`syntaxKeyword` · `syntaxType` · `syntaxFunction` · `syntaxString`) owe
/// 4.5:1 on: the page, the chrome and card rungs, the grey control face,
/// and the four status containers a code span lands on inside an alert or
/// a callout.
const _kSyntaxTones = [
  'surface',
  'surfaceContainerLow',
  'surfaceContainer',
  'surfaceContainerHigh',
  'errorContainer',
  'successContainer',
  'warningContainer',
  'infoContainer',
];

/// The tones a floating panel's border lies against: the page behind it and
/// the panel's own fill.
const _kFloatingPanelTones = [
  'surface',
  'surfaceBright',
];

/// The surface tones a **status indicator** (`errorIcon` … `infoIcon`) is
/// held to its bar on — the page and the panel faces that share the page's
/// tone, not every container tone.
///
/// In light mode the indicator sits at the UI-boundary step (`500`), which
/// clears 3:1 on the white page (3.06 to 3.21) by design and no more; on
/// the grey container tones it measures 2.45 to 3.07. A mark that has to
/// sit on a grey container is drawn in the status fill itself (`error` …),
/// the text step, which clears those tones.
const _kStatusIndicatorTones = [
  'surface',
  'surfaceBright',
  'surfaceContainerLowest',
];

/// A tone a scrollbar thumb is drawn on, and whether CoUI's high-contrast
/// tables hold the thumb to [_kHighContrastLineMinimum] on it.
typedef _ScrollbarThumbTone = ({
  CoreColorToken token,
  bool holdsHighContrastBar,
});

/// The surface tones a **scrollbar thumb** is drawn on — the audit scope for
/// `CoreScrollbarStyle.defaultThumbColor` and its hover ink, which is narrower
/// than [_kSurfaceTones] on purpose.
///
/// The thumb is the page ink at half strength, so it reads one step darker
/// than whatever it sits on, and how far that step is depends on the tone:
/// every step up the container ladder is a step toward the ink and costs
/// contrast. Three tones bound what a scroll host is actually filled with:
///
/// - `surface` — the page ground, and the default fill of the outlined card,
///   dialog, drawer and popup that host most scrolling content;
/// - `surfaceBright` — the tone a floating panel leans on in dark (the same
///   page-and-panel pair [_kFloatingPanelTones] states for the panel border);
/// - `surfaceContainerHigh` — the grey container, past the filled card
///   (`surfaceContainer`), that the design decision verifies the thumb on: the
///   weakest of the tones a bar is routinely drawn on.
///
/// Resting ratios on CoUI's palette, thumb composited over the tone:
///
/// | | `surface` | `surfaceBright` | `surfaceContainerHigh` |
/// |---|---|---|---|
/// | light | 3.20 | 3.20 | 3.09 |
/// | dark | 4.94 | 4.45 | 4.10 |
/// | high-contrast light | 3.95 | 3.95 | 3.84 |
/// | high-contrast dark | 5.28 | 4.73 | 4.37 |
///
/// Not audited: the other five tones, because nothing hosts a scroll area on
/// them by default. They are not safe by omission. `surfaceContainerHighest`
/// is the weakest of all (3.02 light, 3.69 dark on CoUI), and on the standard
/// mapping it sits under 3:1 in light (2.88). A host that fills with it and
/// scrolls inside is outside what this gate states, and the day a component's
/// default fill becomes one of those tones, this list has to grow to it.
///
/// The high-contrast bar is held on the page and the panel only, as it is for
/// `outlineSubtle`: a grey container is held to the ordinary 3:1 there, which
/// it clears (3.84 and 4.37), but not to the mode's raised bar.
const List<_ScrollbarThumbTone> _kScrollbarThumbTones = [
  (token: CoreColors.surface, holdsHighContrastBar: true),
  (token: CoreColors.surfaceBright, holdsHighContrastBar: true),
  (token: CoreColors.surfaceContainerHigh, holdsHighContrastBar: false),
];

/// The grounds a component with no fill of its own is drawn on — the audit
/// scope for the couples whose face paints nothing, so the ink sits on
/// whatever is behind the component: an outlined badge's label and line, a
/// badge dot, a plain radio row's description and an outlined chip's key.
/// Narrower than [_kSurfaceTones] on purpose.
///
/// A badge labels something that is already on screen, and a radio row or a
/// chip chooses among it, so each sits where content sits: the page
/// (`surface`), the chrome rung a title bar or a sidebar is filled with
/// (`surfaceContainerLow`), a filled card (`surfaceContainer`) and a
/// floating panel (`surfaceBright`) — the four grounds the design states a
/// badge's outlined and dot ratios on.
///
/// The two rungs above them are faces, not grounds: they are what the
/// neutral badge itself is filled with (`surfaceContainerHigh` tonal,
/// `surfaceContainerHighest` filled) and what a resting filled chip is
/// filled with (`surfaceContainerHigh`), and those fills are audited as the
/// components' own couples. A fill-less component set on one of them is
/// outside what this gate states — not safe by omission — and the day a
/// component draws one there by default, this list has to grow to that
/// tone.
const List<CoreColorToken> _kContentGroundTones = [
  CoreColors.surface,
  CoreColors.surfaceContainerLow,
  CoreColors.surfaceContainer,
  CoreColors.surfaceBright,
];

/// The faces a step list (`StepItem` rows) is drawn on by default — the
/// page, and a card it reports a run inside. A list set on another tone is
/// outside what this gate states.
const List<CoreColorToken> _kStepListFaces = [
  CoreColors.surface,
  CoreColors.surfaceContainer,
];

/// A (foreground, background) coupling the design system renders.
class _Pair {
  const _Pair(this.foreground, this.background, this.minimum);

  final String foreground;
  final String background;
  final double minimum;
}

/// The pairs a scheme in [brightness] owes — [highContrast] when it is one
/// of its source's high-contrast schemes — plus, when
/// [holdsHighContrastLine], the high-contrast floating-panel line (see
/// [_kFloatingPanelTones]).
List<_Pair> _pairs({
  required CoreBrightness brightness,
  bool highContrast = false,
  bool holdsHighContrastLine = false,
}) {
  final pairs = <_Pair>[];

  // Surface foregrounds — free to land on any container tone.
  for (final tone in _kSurfaceTones) {
    pairs.addAll([
      _Pair('onSurface', tone, _kTextMinimum),
      _Pair('onSurfaceVariant', tone, _kTextMinimum),
      // A link is text that can land on any container tone, so — like the
      // surface foregrounds — it owes 4.5:1 on all eight.
      _Pair('link', tone, _kTextMinimum),
    ]);
  }

  // `placeholder` is not free to land anywhere — see [_kInputSurfaceTones].
  for (final tone in _kInputSurfaceTones) {
    pairs.add(_Pair('placeholder', tone, _kTextMinimum));
  }

  // Nor is the third text tier — see [_kSubtleTextSurfaceTones].
  for (final tone in _kSubtleTextSurfaceTones) {
    pairs.add(_Pair('onSurfaceSubtle', tone, _kTextMinimum));
  }

  // Code, on the tones it is shown on — see [_kSyntaxTones].
  for (final tone in _kSyntaxTones) {
    for (final slot in CoreSyntaxSlot.values) {
      pairs.add(_Pair(_syntaxSlotName(slot), tone, _kTextMinimum));
    }
  }

  // `onX` exists to be drawn on `X`.
  for (final role in [
    'primary',
    'secondary',
    'tertiary',
    'error',
    'success',
    'warning',
    'info',
  ]) {
    final capitalised = role[0].toUpperCase() + role.substring(1);
    pairs.addAll([
      _Pair('on$capitalised', role, _kTextMinimum),
      _Pair('on${capitalised}Container', '${role}Container', _kTextMinimum),
    ]);
  }

  // Fixed tones carry two foregrounds and come in two shades.
  for (final role in ['primary', 'secondary', 'tertiary']) {
    final capitalised = role[0].toUpperCase() + role.substring(1);
    for (final shade in ['${role}Fixed', '${role}FixedDim']) {
      pairs.addAll([
        _Pair('on${capitalised}Fixed', shade, _kTextMinimum),
        _Pair('on${capitalised}FixedVariant', shade, _kTextMinimum),
      ]);
    }
  }

  pairs
    // Inverse surface (snackbars and the like).
    ..addAll(const [
      _Pair('inverseOnSurface', 'inverseSurface', _kTextMinimum),
      _Pair('inversePrimary', 'inverseSurface', _kTextMinimum),
    ])
    // Filled-control interaction fills keep the resting foreground — the
    // label does not change colour on hover/press, so every step of the
    // walk has to clear the same bar the resting pair does.
    ..addAll(const [
      _Pair('onPrimary', 'primaryHover', _kTextMinimum),
      _Pair('onPrimary', 'primaryPressed', _kTextMinimum),
      _Pair('onSecondary', 'secondaryHover', _kTextMinimum),
      _Pair('onSecondary', 'secondaryPressed', _kTextMinimum),
      _Pair('onError', 'errorPressed', _kTextMinimum),
    ]);

  // The text-role primary slots exist FOR these two bounds — `primaryText`
  // is primary used as body text (4.5:1, WCAG 1.4.3 normal) and
  // `primaryTextLarge` as large text (3:1) — so the audit states them
  // against every surface tone, same as the surface foregrounds above.
  for (final tone in _kSurfaceTones) {
    pairs.addAll([
      _Pair('primaryText', tone, _kTextMinimum),
      _Pair('primaryTextLarge', tone, _kComponentMinimum),
    ]);
  }

  // The accent *fills* are no longer audited as page text, because the text
  // chain no longer offers them as one.
  //
  // They were, and they passed — 4.63:1 to 7.04:1 against 4.5:1. The reason
  // this stopped being reassuring is written in the sentence that used to
  // justify auditing them: the margin was thin enough that a palette nudge
  // would cross it. An affordance one brand-colour adjustment away from
  // unreadable is not one to keep, and the tone accent-hued text wants
  // already exists — `onXContainer`, audited just below on the same page.
  //
  // Warning went first and for a stronger reason (1.82:1, structurally
  // unfixable — its fill is light by design). The other six followed it.
  //
  // Dropping the pairs is only honest while the affordance is really gone,
  // so that is enforced rather than asserted:
  // `scripts/guards/tokens/check_accent_text_contrast.sh` fails if any of
  // the seven getters comes back — deleted on Web, deprecated on Flutter.
  // Without that guard this exclusion would be a way to delete seven
  // findings instead of fixing them.
  //
  // These were chosen as fills, with an `on*` foreground meant to sit on top
  // of them, so using one as text on a light page inverts the design. Six of
  // the seven survive that inversion anyway — but only just, at 4.63:1 to
  // 7.04:1 against a 4.5:1 line. They are audited here precisely because that
  // margin is thin enough that a palette nudge would cross it, and this is
  // what notices.
  for (final role in [
    'primary',
    'secondary',
    'tertiary',
    'error',
    'success',
    'warning',
    'info',
  ]) {
    // The container foreground, on the page rather than on its container.
    //
    // This is the tone the examples reach for when they need accent-hued
    // text, now that they no longer use the fill for it. Recommending a
    // tone without auditing it on the ground it is recommended for is how
    // the fill ended up recommended in the first place.
    final capitalised = role[0].toUpperCase() + role.substring(1);
    pairs.add(_Pair('on${capitalised}Container', 'surface', _kTextMinimum));
  }

  // Component boundaries — 1.4.11, not text.
  for (final tone in _kSurfaceTones) {
    pairs.add(_Pair('outline', tone, _kComponentMinimum));
  }

  // Status indicators (`errorIcon` …) — an icon, a status dot, a progress
  // bar, a chart mark: non-text, so 1.4.11's 3:1 in the normal modes, and
  // the high-contrast line bar in high contrast. Held on the page tones,
  // see [_kStatusIndicatorTones].
  for (final tone in _kStatusIndicatorTones) {
    for (final role in ['error', 'success', 'warning', 'info']) {
      pairs.add(
        _Pair(
          '${role}Icon',
          tone,
          highContrast ? _kHighContrastLineMinimum : _kComponentMinimum,
        ),
      );
    }
  }

  // A floating panel's border in a high-contrast table that states it.
  if (holdsHighContrastLine) {
    for (final tone in _kFloatingPanelTones) {
      pairs.add(_Pair('outlineSubtle', tone, _kHighContrastLineMinimum));
    }
  }

  // Category colours, with bars that change by mode — see [categoryPairs].
  for (final pair in categoryPairs(brightness, highContrast: highContrast)) {
    pairs.add(_Pair(pair.foreground, pair.background, pair.minimum));
  }

  return pairs;
}

/// The category colour pairs a scheme in [brightness] owes, and the bar on
/// each — [highContrast] when the scheme is one of its source's
/// high-contrast schemes, under either mapping.
///
/// Per hue, named by token name (`on-category-red`), with `surface` for the
/// page:
///
/// | pair | light | dark | high contrast |
/// |---|---|---|---|
/// | strong chip label on its fill | 3.5 | 4.5 | 7 |
/// | soft chip label on its container | 4.5 | 4.5 | 7 |
/// | that label as coloured text on the page | 4.5 | 4.5 | 7 |
/// | outline on the page | — | — | 4.5 |
///
/// Why each bar is what it is, and which category pairs are left out, is in
/// the header.
List<({String foreground, String background, double minimum})> categoryPairs(
  CoreBrightness brightness, {
  required bool highContrast,
}) {
  final strongLabel = switch ((brightness, highContrast)) {
    (_, true) => _kCategoryHighContrastTextMinimum,
    (.light, false) => _kCategoryLightLabelMinimum,
    (.dark, false) => _kTextMinimum,
  };
  final text = highContrast ? _kCategoryHighContrastTextMinimum : _kTextMinimum;

  return [
    for (final hue in CoreCategoryColor.values) ...[
      (
        foreground: hue.onFill.name,
        background: hue.fill.name,
        minimum: strongLabel,
      ),
      (
        foreground: hue.onContainer.name,
        background: hue.container.name,
        minimum: text,
      ),
      (foreground: hue.onContainer.name, background: 'surface', minimum: text),
      if (highContrast)
        (
          foreground: hue.outline.name,
          background: 'surface',
          minimum: _kHighContrastLineMinimum,
        ),
    ],
  ];
}

/// The name a syntax slot carries in [_slots] — `syntaxKeyword` and so on,
/// the field names the other semantic slots are listed by.
String _syntaxSlotName(CoreSyntaxSlot slot) =>
    'syntax${slot.name[0].toUpperCase()}${slot.name.substring(1)}';

// The luminance and ratio maths is the public `CoreContrast` — the same
// numbers an app gets in its own contrast tests, so this audit and theirs
// cannot disagree about what a pair measures.
double _contrast(CoreColor a, CoreColor b) => CoreContrast.ratio(a, b);

Map<String, CoreColor> _slots(ResolvedColorScheme s) => {
  'surface': s.surface,
  'surfaceDim': s.surfaceDim,
  'surfaceBright': s.surfaceBright,
  'surfaceContainerLowest': s.surfaceContainerLowest,
  'surfaceContainerLow': s.surfaceContainerLow,
  'surfaceContainer': s.surfaceContainer,
  'surfaceContainerHigh': s.surfaceContainerHigh,
  'surfaceContainerHighest': s.surfaceContainerHighest,
  'surfaceRaised': s.surfaceRaised,
  'onSurface': s.onSurface,
  'onSurfaceVariant': s.onSurfaceVariant,
  'onSurfaceSubtle': s.onSurfaceSubtle,
  'placeholder': s.placeholder,
  'link': s.link,
  'primary': s.primary,
  'onPrimary': s.onPrimary,
  'primaryContainer': s.primaryContainer,
  'onPrimaryContainer': s.onPrimaryContainer,
  'primaryFixed': s.primaryFixed,
  'primaryFixedDim': s.primaryFixedDim,
  'onPrimaryFixed': s.onPrimaryFixed,
  'onPrimaryFixedVariant': s.onPrimaryFixedVariant,
  'primaryText': s.primaryText,
  'primaryTextLarge': s.primaryTextLarge,
  'primaryHover': s.primaryHover,
  'primaryPressed': s.primaryPressed,
  'secondary': s.secondary,
  'onSecondary': s.onSecondary,
  'secondaryContainer': s.secondaryContainer,
  'onSecondaryContainer': s.onSecondaryContainer,
  'secondaryFixed': s.secondaryFixed,
  'secondaryFixedDim': s.secondaryFixedDim,
  'secondaryHover': s.secondaryHover,
  'secondaryPressed': s.secondaryPressed,
  'onSecondaryFixed': s.onSecondaryFixed,
  'onSecondaryFixedVariant': s.onSecondaryFixedVariant,
  'tertiary': s.tertiary,
  'onTertiary': s.onTertiary,
  'tertiaryContainer': s.tertiaryContainer,
  'onTertiaryContainer': s.onTertiaryContainer,
  'tertiaryFixed': s.tertiaryFixed,
  'tertiaryFixedDim': s.tertiaryFixedDim,
  'onTertiaryFixed': s.onTertiaryFixed,
  'onTertiaryFixedVariant': s.onTertiaryFixedVariant,
  'error': s.error,
  'onError': s.onError,
  'errorContainer': s.errorContainer,
  'onErrorContainer': s.onErrorContainer,
  'errorPressed': s.errorPressed,
  'success': s.success,
  'onSuccess': s.onSuccess,
  'successContainer': s.successContainer,
  'onSuccessContainer': s.onSuccessContainer,
  'warning': s.warning,
  'onWarning': s.onWarning,
  'warningContainer': s.warningContainer,
  'onWarningContainer': s.onWarningContainer,
  'info': s.info,
  'onInfo': s.onInfo,
  'infoContainer': s.infoContainer,
  'onInfoContainer': s.onInfoContainer,
  'errorIcon': s.errorIcon,
  'successIcon': s.successIcon,
  'warningIcon': s.warningIcon,
  'infoIcon': s.infoIcon,
  'outline': s.outline,
  'outlineSubtle': s.outlineSubtle,
  'inverseSurface': s.inverseSurface,
  'inverseOnSurface': s.inverseOnSurface,
  'inversePrimary': s.inversePrimary,
  for (final slot in CoreSyntaxSlot.values)
    _syntaxSlotName(slot): slot.token.read(s)!,
  // Category slots under their token names (`on-category-red`), the names
  // [categoryPairs] states its pairs by, so a finding reads like the CSS
  // variable it is about.
  for (final hue in CoreCategoryColor.values)
    for (final slot in CoreCategorySlot.values)
      hue.token(slot).name: hue.token(slot).read(s)!,
};

/// Stable identifier for a failing pair — no measured ratio, so an entry does
/// not churn every time a palette moves by a hundredth.
/// [fg] laid over [bg] at [alpha] — the composite a screen actually shows.
///
/// The pairs above are slot-vs-slot: both sides opaque, both named by the
/// design system. What renders is not always that. A translucent fill
/// leaves the page showing through, and the label then sits on the blend,
/// not on the token.
CoreColor over(CoreColor fg, double alpha, CoreColor bg) {
  int channel(int f, int b) => (f * alpha + b * (1 - alpha)).round().clamp(
    CoreColorConversion.channelMin,
    CoreColorConversion.rgbMax,
  );

  return CoreColor.fromARGB(
    CoreColorConversion.alphaMax,
    channel(fg.red, bg.red),
    channel(fg.green, bg.green),
    channel(fg.blue, bg.blue),
  );
}

/// One (label, fill) couple a component really paints, with the alpha each
/// carries.
///
/// Why this exists alongside [_pairs]: those are the couples the system
/// *declares*, and a guard built only from declarations cannot construct a
/// couple nobody declared. Two shipped defects were exactly that shape —
/// a label on `outline` (a border colour used as a fill), and a label on a
/// 10% wash of its own accent. Neither pair is in [_pairs], and neither
/// could be: `outline` is never declared as something text sits on, and
/// `warning` on `warning` is a token against itself.
class RenderedCouple {
  const RenderedCouple(
    this.name,
    this.fill,
    this.label,
    this.minimum, {
    this.highContrastMinimum,
    this.base = const CoreColor.token(CoreColors.surface),
  });

  /// `component/variant state` — what a reader needs to find it.
  final String name;
  final CoreColor fill;
  final CoreColor label;
  final double minimum;

  /// What the couple owes in a scheme whose high-contrast table states the UI
  /// line bar (see [AuditedScheme.holdsHighContrastLine]), when that is more
  /// than [minimum]. `null` → the couple owes [minimum] everywhere.
  final double? highContrastMinimum;

  /// What the [fill] is laid over — the page by default. A state wash
  /// (a hover or pressed layer) lands on the face its component stands on,
  /// not on the page, so a floating panel's row states its panel here, and
  /// a pressed row that is already highlighted states the highlight.
  final CoreColor base;

  /// The minimum this couple owes in a scheme that [highContrast] says holds
  /// the raised bar.
  double minimumIn({required bool highContrast}) =>
      highContrast ? highContrastMinimum ?? minimum : minimum;
}

/// `<mode> <couple> (>=<minimum>)` — the minimum in the key is the one the
/// couple owes in that mode, so a couple held to a higher bar in high contrast
/// is a different baseline entry from the same couple in light.
String _renderedKey(String mode, RenderedCouple r, double minimum) =>
    '$mode ${r.name} (>=$minimum)';

/// The ratio [r] measures on [scheme] — its label composited onto its fill,
/// and that fill onto the page — or `null` when the fill paints nothing.
///
/// A fill with no alpha is not a fill: the label sits on whatever is behind
/// the component, which the slot pairs hold. Compositing it would read the
/// sentinel's own zero-alpha black as a background and call every borderless
/// variant unreadable.
double? renderedRatio(ResolvedColorScheme scheme, RenderedCouple r) {
  final fillColor = scheme.resolve(r.fill);
  if (fillColor.alpha == 0 || r.fill.opacity == 0) return null;
  final page = over(
    scheme.resolve(r.base),
    r.base.opacity,
    scheme.resolve(const CoreColor.token(CoreColors.surface)),
  );
  final fill = over(fillColor, r.fill.opacity, page);
  final label = over(scheme.resolve(r.label), r.label.opacity, fill);
  return _contrast(label, fill);
}

/// Whether [color] paints anything, before any scheme reads it — not when
/// its opacity is zero, nor when it is a raw colour with no alpha (the
/// transparent sentinel). The scheme-free half of what [renderedRatio]
/// skips.
bool _paintsSomething(CoreColor color) =>
    color.opacity > 0 && (color.token != null || color.alpha > 0);

/// The (label, fill) couples this design system really paints.
///
/// Sourced from the components' own variant tables rather than a list kept
/// here, so a variant added tomorrow is audited without anyone remembering
/// to add it. A state that restates neither half is the resting couple
/// again and is not re-checked.
///
/// `disabled` is measured and reported but never fails: WCAG exempts
/// inactive controls. The value is still worth printing — exempt is not
/// the same as legible, and a disabled label nobody can read does not say
/// "disabled", it says "broken".
List<RenderedCouple> renderedCouples() {
  final out = <RenderedCouple>[];

  void add(
    String component,
    String variant,
    CoreColor? fill,
    CoreColor? label, {
    required bool exempt,
    String state = 'rest',
  }) {
    if (fill == null || label == null) return;
    out.add(
      RenderedCouple(
        '$component/$variant $state',
        fill,
        label,
        exempt ? 0 : _kTextMinimum,
      ),
    );
  }

  for (final entry in CoreButtonStyle.defaultsByVariant.entries) {
    final v = entry.value;
    final name = entry.key.name;
    add('button', name, v.backgroundColor, v.foregroundColor, exempt: false);
    add(
      'button',
      name,
      v.hoverBackgroundColor,
      v.hoverForegroundColor ?? v.foregroundColor,
      exempt: false,
      state: 'hover',
    );
    add(
      'button',
      name,
      v.selectedBackgroundColor,
      v.selectedForegroundColor ?? v.foregroundColor,
      exempt: false,
      state: 'selected',
    );
    add(
      'button',
      name,
      v.disabledBackgroundColor,
      v.disabledForegroundColor,
      exempt: true,
      state: 'disabled',
    );
  }

  for (final entry in CoreAlertStyle.defaultsByVariant.entries) {
    // The description reads `onSurfaceVariant` on every tone's face.
    add(
      'alert',
      entry.key.name,
      entry.value.backgroundColor,
      entry.value.descriptionColor,
      exempt: false,
    );
    // Each layout states its own title colour — the stacked panel's
    // `onSurface`, the inline strip's `onSurfaceVariant` one tier down —
    // and each is drawn on every tone's face. Sourced from the layout
    // table, so a retuned row or a new layout moves this audit with it.
    for (final layout in CoreAlertStyle.defaultsByLayout.entries) {
      add(
        'alert',
        entry.key.name,
        entry.value.backgroundColor,
        layout.value.titleColor,
        exempt: false,
        state: 'title-${layout.key.name}',
      );
    }
  }

  // Stat's text reads against the card face it sits on: the label, the
  // value and its unit, the empty-value dash, the two change colours (a
  // neutral change reads the label's colour, so it is the label's couple)
  // and the description footnote. Sourced from the component's own
  // defaults, so a retuned figure or a new face moves this audit with it.
  for (final entry in CoreStatStyle.defaultsByVariant.entries) {
    final face = entry.value.backgroundColor;
    for (final (state, ink) in [
      ('label', CoreStatStyle.defaultLabelColor),
      ('value', CoreStatStyle.defaultValueColor),
      ('unit', CoreStatStyle.defaultUnitColor),
      ('empty-value', CoreStatStyle.defaultEmptyValueColor),
      ('change-positive', CoreStatStyle.defaultPositiveColor),
      ('change-negative', CoreStatStyle.defaultNegativeColor),
      ('description', CoreStatStyle.defaultDescriptionColor),
    ]) {
      add('stat', entry.key.name, face, ink, exempt: false, state: state);
    }
  }

  // Progress — every tone's fill on the neutral track it runs over. The
  // fill is a mark, not text, so it owes the component bar (WCAG 1.4.11).
  // Sourced from the tone table, so a new tone or a retuned fill moves this
  // audit with it.
  for (final entry in CoreProgressStyle.defaultsByTone.entries) {
    out.add(
      RenderedCouple(
        'progress/${entry.key.name} fill on track rest',
        CoreProgressStyle.defaultBackgroundColor,
        entry.value.color!,
        _kComponentMinimum,
      ),
    );
  }

  // Progress — the three label cells on the grounds a bar is drawn on: the
  // page, and the face of a filled card (`surfaceContainer`) — a plan card
  // is the bar's commonest home.
  for (final ground in [CoreColors.surface, CoreColors.surfaceContainer]) {
    for (final (cell, ink) in [
      ('label', CoreProgressStyle.defaultLabelStyle.color),
      ('value-label', CoreProgressStyle.defaultValueLabelStyle.color),
      ('caption', CoreProgressStyle.defaultCaptionStyle.color),
    ]) {
      add(
        'progress',
        '$cell on ${ground.name}',
        CoreColor.token(ground),
        ink,
        exempt: false,
      );
    }
  }

  // StepItem — every status's glyph, title and trailing note, read on the
  // two faces a step list is drawn on: the page and a card. Sourced from
  // the status rows the resolvers read (`defaultsByStatus`), so a retuned
  // status moves this audit with it. The glyph is a status mark, not text,
  // so it owes the component bar; the title and the note owe the text bar.
  for (final MapEntry(key: status, value: row)
      in CoreStepItemStyle.defaultsByStatus.entries) {
    for (final face in _kStepListFaces) {
      final ground = CoreColor.token(face);
      out.add(
        RenderedCouple(
          'step-item/${status.name} glyph on ${face.name} rest',
          ground,
          row.iconStyle!.color!,
          _kComponentMinimum,
        ),
      );
      for (final (part, ink) in [
        ('title', row.titleStyle!.color!),
        ('trailing', row.trailingStyle!.color!),
      ]) {
        add(
          'step-item',
          status.name,
          ground,
          ink,
          exempt: false,
          state: '$part on ${face.name}',
        );
      }
    }
  }

  // A numbered step that failed draws a cross on its own fill — a status
  // mark, so it owes the component bar against that fill.
  out.add(
    const RenderedCouple(
      'steps/failed indicator mark rest',
      CoreStepsStyle.defaultFailedIndicatorColor,
      CoreStepsStyle.defaultFailedLabelColor,
      _kComponentMinimum,
    ),
  );

  for (final entry in CoreValidationBadgeStyle.defaultsByState.entries) {
    add(
      'validation-badge',
      entry.key.name,
      entry.value.backgroundColor,
      entry.value.foregroundColor,
      exempt: false,
    );
  }

  // Badge — every tone at every strength, read through the same call the
  // resolvers make (`restingStyleFor`), so a retuned tone, a new tone or a
  // new strength moves this audit with it. A word and a number wear the
  // same colours, so the label form stands for both; the leading status
  // dot and the icons take the label's colour and are held by its couple.
  //
  // A strength whose fill paints something is measured on that fill. One
  // whose fill paints nothing (outlined) leaves its label on whatever is
  // behind the badge, so the label is measured on each ground in
  // [_kContentGroundTones] instead — composited onto the page, the
  // transparent fill would be skipped and the label never measured.
  //
  // The line an outlined badge draws and the dot form are not text: they
  // owe the component bar (WCAG 1.4.11) on each ground, in every mode —
  // the same bar `outline` is held to, not the raised high-contrast line
  // bar, which is for what a user has to find in that mode.
  //
  // Rest only. A pressable badge's hover and pressed wash (its label's
  // colour over the fill, `CoreBadgeStyle.defaultStateLayer`) is not
  // audited here.
  for (final entry in CoreBadgeStyle.defaultsByTone.entries) {
    final tone = entry.key.name;
    final row = entry.value;

    for (final variant in CoreBadgeVariant.values) {
      final rest = row.restingStyleFor(variant, CoreBadgeForm.label);
      final name = '$tone ${variant.name}';
      final fill = rest.backgroundColor;
      if (fill != null && _paintsSomething(fill)) {
        add('badge', name, fill, rest.foregroundColor, exempt: false);
      } else {
        for (final ground in _kContentGroundTones) {
          add(
            'badge',
            '$name on ${ground.name}',
            CoreColor.token(ground),
            rest.foregroundColor,
            exempt: false,
          );
        }
      }

      final line = rest.borderColor;
      if (line == null) continue;
      for (final ground in _kContentGroundTones) {
        out.add(
          RenderedCouple(
            'badge/$name line on ${ground.name} rest',
            CoreColor.token(ground),
            line,
            _kComponentMinimum,
          ),
        );
      }
    }

    // A dot paints the same colour whatever the strength — reading it
    // through the default strength is reading it through all three.
    final dot = row
        .restingStyleFor(CoreBadgeVariant.defaultVariant, CoreBadgeForm.dot)
        .backgroundColor;
    if (dot == null) continue;
    for (final ground in _kContentGroundTones) {
      out.add(
        RenderedCouple(
          'badge/$tone dot on ${ground.name} rest',
          CoreColor.token(ground),
          dot,
          _kComponentMinimum,
        ),
      );
    }
  }

  // The scrollbar thumb is not text, so it owes the component bar (WCAG
  // 1.4.11 — it is operated by dragging it), and in CoUI's high-contrast
  // tables the raised UI-line bar on the page and panel tones. Its ink is
  // read from the component's own defaults, like the tables above, so
  // retuning the strength moves this audit with it. The alpha is the whole
  // reason it is a couple and not a slot pair: what the eye gets is the ink
  // laid over the tone, not the ink.
  for (final tone in _kScrollbarThumbTones) {
    for (final (state, ink) in [
      ('rest', CoreScrollbarStyle.defaultThumbColor),
      ('hover', CoreScrollbarStyle.defaultHoverThumbColor),
    ]) {
      out.add(
        RenderedCouple(
          'scrollbar/thumb on ${tone.token.name} $state',
          CoreColor.token(tone.token),
          ink,
          _kComponentMinimum,
          highContrastMinimum: tone.holdsHighContrastBar
              ? _kHighContrastLineMinimum
              : null,
        ),
      );
    }
  }

  _addFloatingPanelCouples(out);
  _addTableCouples(out);
  _addCodeSurfaceCouples(out);
  _addNavigationBarCouples(out);
  _addCommandSearchCouples(out);
  _addRadioGroupCouples(out);
  _addChipCouples(out);

  return out;
}

/// A fill that is `ink` at `opacity` — a state wash, as a component states it.
CoreColor _wash(CoreColor ink, double opacity) =>
    CoreColor.token(ink.token!, opacity: opacity);

/// The couples a floating panel's rows paint: `MenuItem` (neutral and
/// critical, resting and in each state layer), the menu's group title, and
/// `Command` (rest, hover, the highlighted row, and the highlighted row
/// pressed).
///
/// A state wash lands on the face its row stands on — the panel
/// (`surfaceBright`), or the highlight a `Command` row already carries — so
/// each wash states that face as its base; against the page it would
/// measure a ground nobody draws it on.
void _addFloatingPanelCouples(List<RenderedCouple> out) {
  const panel = CoreColor.token(CoreColors.surfaceBright);

  void couple(
    String name,
    CoreColor fill,
    CoreColor label, {
    CoreColor base = panel,
    bool exempt = false,
  }) {
    out.add(
      RenderedCouple(
        name,
        fill,
        label,
        exempt ? 0 : _kTextMinimum,
        base: base,
      ),
    );
  }

  // MenuItem — every size states its own description and shortcut inks.
  final neutral = CoreMenuItemStyle.defaultsByTone[CoreMenuItemTone.neutral]!;
  final critical = CoreMenuItemStyle.defaultsByTone[CoreMenuItemTone.critical]!;
  const layer = CoreMenuItemStyle.defaultStateLayer;
  final rowInks = <String, CoreColor>{
    'label': neutral.foregroundColor!,
    for (final size in CoreMenuItemSize.values) ...{
      'description ${size.name}':
          CoreMenuItemStyle.defaultsBySize[size]!.descriptionStyle!.color!,
      'shortcut ${size.name}':
          CoreMenuItemStyle.defaultsBySize[size]!.shortcutTextStyle!.color!,
    },
  };
  for (final MapEntry(key: ink, value: color) in rowInks.entries) {
    couple('menu-item/$ink rest', panel, color);
    for (final (state, weight) in [
      ('hover', layer.hover),
      ('focus', layer.focus),
      ('pressed', layer.pressed),
    ]) {
      couple(
        'menu-item/$ink $state',
        _wash(neutral.foregroundColor!, weight),
        color,
      );
    }
  }
  couple('menu-item/critical rest', panel, critical.foregroundColor!);
  // The critical fill keeps every ink at rest unless the tone states one:
  // the label on `error`, the description and the shortcut on their muted
  // colour — each has to read on the fill as well as on the panel.
  final criticalInks = <String, CoreColor>{
    'label': critical.activeForegroundColor ?? critical.foregroundColor!,
    for (final MapEntry(:key, :value) in rowInks.entries)
      if (key != 'label') key: critical.activeForegroundColor ?? value,
  };
  for (final MapEntry(key: ink, value: color) in criticalInks.entries) {
    couple(
      'menu-item/critical $ink hover',
      critical.hoverBackgroundColor!,
      color,
    );
    couple(
      'menu-item/critical $ink pressed',
      critical.pressedBackgroundColor!,
      color,
    );
  }
  couple(
    'menu-item/label disabled',
    panel,
    CoreMenuItemStyle.defaultDisabledForegroundColor,
    exempt: true,
  );
  couple('menu/group title', panel, CoreMenuStyle.defaultLabelTextStyle.color!);

  // Command.
  const commandPanel = CoreCommandStyle.defaultBackgroundColor;
  const highlight = CoreCommandStyle.defaultItemHighlightColor;
  // The couples below state no base of their own: they are measured on the
  // menu panel's face. A palette that stands on another face has to state it.
  if (commandPanel != panel) {
    throw StateError(
      'Command no longer stands on the floating panel face; state its base '
      'on the command couples.',
    );
  }
  final commandInks = <String, CoreColor>{
    'label': CoreCommandStyle.defaultItemForegroundColor,
    'overline': CoreCommandStyle.defaultOverlineStyle.color!,
    'shortcut': CoreCommandStyle.defaultShortcutStyle.color!,
  };
  for (final MapEntry(key: ink, value: color) in commandInks.entries) {
    couple('command/$ink rest', commandPanel, color);
    couple(
      'command/$ink hover',
      CoreCommandStyle.defaultItemHoverColor,
      color,
    );
    couple('command/$ink highlighted', highlight, color);
    couple(
      'command/$ink highlighted pressed',
      CoreCommandStyle.defaultItemPressedColor,
      color,
      base: highlight,
    );
  }
  couple(
    'command/group heading',
    commandPanel,
    CoreCommandStyle.defaultHeadingStyle.color!,
  );
  couple(
    'command/placeholder',
    commandPanel,
    CoreCommandStyle.defaultPlaceholderColor,
  );
  couple(
    'command/footer text',
    CoreCommandStyle.defaultFooterBackgroundColor,
    CoreCommandStyle.defaultFooterStyle.color!,
  );
  couple(
    'command/label disabled',
    commandPanel,
    CoreCommandStyle.defaultItemDisabledForegroundColor,
    exempt: true,
  );
}

/// The couples a table paints: the header's quiet ink resting, under the row
/// hover wash and over a frozen header's base; body ink under the hover wash
/// and on a selected row; the footer.
///
/// The header reads weaker than the body by design (`onSurfaceSubtle`), and
/// the hover wash lands on the same ground as the rest — the page, or a
/// card's face — so the pair that tightens is the header under the wash.
void _addTableCouples(List<RenderedCouple> out) {
  const page = CoreColor.token(CoreColors.surface);
  final header = CoreTableStyle.defaultHeaderTextStyle.color!;
  const body = CoreTableStyle.defaultForegroundColor;

  void couple(
    String name,
    CoreColor fill,
    CoreColor label, {
    bool exempt = false,
  }) {
    out.add(
      RenderedCouple(name, fill, label, exempt ? 0 : _kTextMinimum),
    );
  }

  couple('table/header rest', page, header);
  couple('table/header hover', CoreTableStyle.defaultRowHoverColor, header);
  couple(
    'table/header frozen',
    CoreTableStyle.defaultFrozenCellBackgroundColor,
    header,
  );
  couple('table/cell rest', page, body);
  couple('table/cell hover', CoreTableStyle.defaultRowHoverColor, body);
  couple('table/cell selected', CoreTableStyle.defaultRowSelectedColor, body);
  couple(
    'table/footer',
    CoreTableStyle.defaultFooterBackgroundColor,
    body,
  );
  couple(
    'table/cell disabled',
    page,
    CoreTableStyle.defaultDisabledForegroundColor,
    exempt: true,
  );
}

/// The couples the code and IDE-chrome surfaces paint with their own default
/// colours: a `MockupCode` line's tone ink on the code face, a `TabPane`
/// editor strip's selection bar and close glyph, and a `Tree`'s chevron and
/// file / folder glyphs on the page and on the selected row.
///
/// Read from the components' own defaults, so a retuned tone or glyph colour
/// moves this audit with it. Text owes the text bar; a bar or glyph owes the
/// component bar (WCAG 1.4.11), in every mode.
///
/// What is not here, and why:
/// - `ChatBubble/plain` — its ink is `onSurfaceVariant`, which the declared
///   pairs already hold at the text bar on every surface tone.
/// - `onSurfaceSubtle` as *text* on the selected tree row
///   (`surfaceContainerHigh`) — the glyphs are not text, so they owe only the
///   component bar; the tier reads below 4.5:1 there by design.
/// - `MockupDevice` flat ring / rail (`surfaceContainerHighest` on the page) —
///   decoration around a screen, not the boundary of a UI component, so
///   1.4.11 does not apply and no couple is stated.
void _addCodeSurfaceCouples(List<RenderedCouple> out) {
  void couple(
    String name,
    CoreColor fill,
    CoreColor ink, {
    double minimum = _kTextMinimum,
  }) {
    out.add(RenderedCouple(name, fill, ink, minimum));
  }

  // MockupCode — every tone ink on the code face. A neutral line reads the
  // code's own text colour; there is no neutral slot. The status tones read
  // the container inks (`onSuccessContainer` / `onWarningContainer` /
  // `onErrorContainer`): the same-named slots fall under the text bar on this
  // face in the light schemes, so the couples below hold the inks.
  const codeFace = CoreMockupCodeStyle.defaultBackgroundColor;
  final codeInk = CoreMockupCodeStyle.defaultTextStyle.color!;
  for (final (tone, ink) in [
    ('neutral', codeInk),
    ('muted', CoreMockupCodeStyle.defaultMutedToneColor),
    ('link', CoreMockupCodeStyle.defaultLinkToneColor),
    ('success', CoreMockupCodeStyle.defaultSuccessToneColor),
    ('warning', CoreMockupCodeStyle.defaultWarningToneColor),
    ('error', CoreMockupCodeStyle.defaultErrorToneColor),
  ]) {
    couple('mockup-code/tone $tone', codeFace, ink);
  }

  // TabPane editorStrip — the selection bar sits on the selected tab's face
  // and runs along the strip; the close glyph is on the strip and on the
  // selected tab. Neither is text.
  const strip = CoreTabPaneStyle.editorStrip;
  final stripFace = strip.stripBackgroundColor!;
  final tabFace = strip.backgroundColor!;
  final bar = strip.indicatorColor!;
  final closeInk = CoreTabPaneStyle.editorStripCloseIconStyle.color!;
  couple(
    'tab-pane/editor-strip indicator on selected tab',
    tabFace,
    bar,
    minimum: _kComponentMinimum,
  );
  couple(
    'tab-pane/editor-strip indicator on strip',
    stripFace,
    bar,
    minimum: _kComponentMinimum,
  );
  couple(
    'tab-pane/editor-strip close glyph on strip',
    stripFace,
    closeInk,
    minimum: _kComponentMinimum,
  );
  couple(
    'tab-pane/editor-strip close glyph on selected tab',
    tabFace,
    closeInk,
    minimum: _kComponentMinimum,
  );

  // Tree — chevron and file glyphs (the quieter tier) and the folder glyph,
  // on the page the tree stands on and on its selected row.
  const treePage = CoreColor.token(CoreColors.surface);
  const treeSelected = CoreTreeStyle.defaultNodeSelectedColor;
  for (final (glyph, ink) in [
    ('chevron', CoreTreeStyle.defaultChevronIconStyle.color!),
    ('file glyph', CoreTreeStyle.defaultLeafIconStyle.color!),
    ('folder glyph', CoreTreeStyle.defaultIconColor),
  ]) {
    couple(
      'tree/$glyph on page',
      treePage,
      ink,
      minimum: _kComponentMinimum,
    );
    // A tree also stands on a card or a panel face.
    for (final (faceName, face) in [
      ('card face', const CoreColor.token(CoreColors.surfaceContainerLow)),
      ('panel face', const CoreColor.token(CoreColors.surfaceContainer)),
    ]) {
      couple(
        'tree/$glyph on $faceName',
        face,
        ink,
        minimum: _kComponentMinimum,
      );
    }
    couple(
      'tree/$glyph on selected row',
      treeSelected,
      ink,
      minimum: _kComponentMinimum,
    );
  }
}

/// The couples a navigation bar paints: a destination's label and icon ink
/// on the bar's face, resting and under each state layer, the selected label,
/// a selected row (the label beside the icon) on its face, and the disabled
/// ink.
///
/// The bar's face is `surfaceContainerLow` in every mode, and a state wash
/// lands on that face, so each wash states it as its base. The unselected
/// ink (`onSurfaceVariant`) sets the floor on the pressed fill — it is the
/// secondary text tier under an `onSurface` wash. A selected destination
/// takes the wash too — the layer is laid over the selection — so its label
/// is measured resting and under each wash, on the indicator's selected face
/// (the whole tile, stacked or a row) in the indicator's selected ink.
///
/// The section header (`onSurfaceSubtle` on `surfaceContainerLow`) is the
/// slot pair [_kSubtleTextSurfaceTones] already states; it is not repeated
/// here.
///
/// The face is read per mode the way both resolvers read it — the mode
/// cell's, else the variant's — so the bottom bar's `surface` and the rail's
/// chrome tier are each measured under the inks they carry. The rail's
/// couples keep the plain names; the bottom bar's are prefixed `bar `.
void _addNavigationBarCouples(List<RenderedCouple> out) {
  final variantFace = CoreNavigationBarStyle
      .defaultsByVariant[CoreNavigationBarVariant.defaultVariant]!
      .backgroundColor;
  final fill = CoreNavigationBarStyle
      .defaultsByIndicator[CoreNavigationSelectionIndicator.fill]!;
  // Each mode's own indicator — the rail's `fill`, the bar's `color` — paints
  // its selected face and ink, and lays its own state-layer ramp.
  final indicators = <String, CoreNavigationBarIndicatorStyle>{
    '': CoreNavigationBarStyle
        .defaultsByIndicator[CoreNavigationBarMode.rail.defaultIndicator]!,
    'bar ': CoreNavigationBarStyle
        .defaultsByIndicator[CoreNavigationBarMode.bar.defaultIndicator]!,
  };
  const layer = CoreNavigationBarStyle.defaultStateLayer;
  const washInk = CoreNavigationBarStyle.defaultStateLayerColor;
  final faces = <String, CoreColor>{
    '':
        CoreNavigationBarStyle
            .defaultsByMode[CoreNavigationBarMode.rail]!
            .backgroundColor ??
        variantFace,
    'bar ':
        CoreNavigationBarStyle
            .defaultsByMode[CoreNavigationBarMode.bar]!
            .backgroundColor ??
        variantFace,
  };

  void couple(
    String name,
    CoreColor fill,
    CoreColor label, {
    required CoreColor base,
    bool exempt = false,
  }) {
    out.add(
      RenderedCouple(
        name,
        fill,
        label,
        exempt ? 0 : _kTextMinimum,
        base: base,
      ),
    );
  }

  final inks = <String, CoreColor>{
    'label': CoreNavigationBarStyle.defaultLabelTextStyle.color!,
    'icon': CoreNavigationBarStyle.defaultIconStyle.color!,
  };
  for (final MapEntry(key: prefix, value: face) in faces.entries) {
    for (final MapEntry(key: ink, value: color) in inks.entries) {
      couple('navigation-bar/$prefix$ink rest', face, color, base: face);
      for (final (state, weight) in [
        ('hover', layer.hover),
        ('focus', layer.focus),
        ('pressed', layer.pressed),
      ]) {
        couple(
          'navigation-bar/$prefix$ink $state',
          _wash(washInk, weight),
          color,
          base: face,
        );
      }
    }
    final indicator = indicators[prefix]!;
    // An indicator that paints no face (`color`, #6393) leaves the selected
    // label on the bar's own face, and its layers wash that face.
    final stated = indicator.selectedBackgroundColor;
    final selectedFace = stated == null || stated == CoreColor.transparent
        ? face
        : stated;
    final selectedInk =
        indicator.selectedLabelTextStyle?.color ??
        CoreNavigationBarStyle.defaultSelectedLabelTextStyle.color!;
    final selectedLayer = indicator.stateLayer ?? layer;
    couple(
      'navigation-bar/${prefix}label selected',
      selectedFace,
      selectedInk,
      base: face,
    );
    for (final (state, weight) in [
      ('hover', selectedLayer.hover),
      ('focus', selectedLayer.focus),
      ('pressed', selectedLayer.pressed),
    ]) {
      couple(
        'navigation-bar/${prefix}label selected $state',
        _wash(washInk, weight),
        selectedInk,
        base: selectedFace,
      );
    }
    couple(
      'navigation-bar/${prefix}label disabled',
      face,
      CoreNavigationBarStyle.defaultDisabledLabelTextStyle.color!,
      base: face,
      exempt: true,
    );
    couple(
      'navigation-bar/${prefix}icon disabled',
      face,
      CoreNavigationBarStyle.defaultDisabledIconStyle.color!,
      base: face,
      exempt: true,
    );
  }
  final rowFace = fill.selectedBackgroundColor!;
  final rowInk =
      fill.selectedRowLabelTextStyle?.color ??
      fill.selectedLabelTextStyle!.color!;
  couple(
    'navigation-bar/sidebar label selected',
    rowFace,
    rowInk,
    base: faces['']!,
  );
  for (final (state, weight) in [
    ('hover', layer.hover),
    ('focus', layer.focus),
    ('pressed', layer.pressed),
  ]) {
    couple(
      'navigation-bar/sidebar label selected $state',
      _wash(washInk, weight),
      rowInk,
      base: rowFace,
    );
  }
}

/// The couples the command palette's trigger paints: its glyph and hint on
/// the face, resting and under the hover, focus and pressed wash, and the
/// disabled pair.
///
/// The wash lands on the trigger's own face, so each states it as its base.
/// The Kbd at the trigger's end carries an opaque face of its own, so the
/// wash does not reach it and its pair is the key-cap slot pair above.
void _addCommandSearchCouples(List<RenderedCouple> out) {
  const face = CoreCommandSearchStyle.defaultBackgroundColor;
  const ink = CoreCommandSearchStyle.defaultForegroundColor;
  const layer = CoreCommandSearchStyle.defaultStateLayer;
  const washInk = CoreCommandSearchStyle.defaultStateLayerColor;

  out
    ..add(
      const RenderedCouple(
        'command-search/hint rest',
        face,
        ink,
        _kTextMinimum,
      ),
    )
    ..add(
      const RenderedCouple(
        'command-search/hint disabled',
        CoreCommandSearchStyle.defaultDisabledBackgroundColor,
        CoreCommandSearchStyle.defaultDisabledForegroundColor,
        0,
      ),
    );
  for (final (state, weight) in [
    ('hover', layer.hover),
    ('focus', layer.focus),
    ('pressed', layer.pressed),
  ]) {
    out.add(
      RenderedCouple(
        'command-search/hint $state',
        _wash(washInk, weight),
        ink,
        _kTextMinimum,
        base: face,
      ),
    );
  }
}

/// The couples a radio group's text paints: the description under a plain
/// row's label, and a `card` tile's title and description on each of the
/// tile's faces, resting and under the state layer the tile lays over its
/// face.
///
/// Read from the component's own defaults — the inks from its label and
/// description styles (the size rows state roles, not colours), the faces
/// and the state layer from its tile and halo defaults, the disabled pair
/// from each variant's row — so a retuned ink, face or wash moves this
/// audit with it. A plain row has no face of its own, so its description is
/// measured on each ground in [_kContentGroundTones]; a tile's face is
/// opaque, so the ground behind it does not reach the text.
///
/// The description is measured on a plain row although the declared pairs
/// already hold its slot (`onSurfaceVariant`) on every surface tone: its ink
/// is the second text tier rather than the third (`onSurfaceSubtle`), which
/// reads under the text bar on the tile faces, and reading the ink from the
/// component is what keeps that choice measured.
///
/// What is not here, and why:
/// - a plain row's label — `onSurface`, which the declared pairs hold at the
///   text bar on every surface tone.
/// - the halo around a plain row's indicator — a wash beside the text, not
///   under it.
///
/// The selected tile's description under the wash is measured with the rest
/// and falls under the text bar in CoUI — pressed in light and dark, hovered
/// in dark — because the halo's ink lifts the `primaryContainer` face toward
/// the description's ink. Those couples are recorded exceptions in the
/// baseline, each with its reason, as the command palette's pressed
/// highlight is; the standard mapping and the high-contrast schemes clear
/// them.
void _addRadioGroupCouples(List<RenderedCouple> out) {
  void couple(
    String name,
    CoreColor fill,
    CoreColor label, {
    CoreColor base = const CoreColor.token(CoreColors.surface),
    bool exempt = false,
  }) {
    out.add(
      RenderedCouple(
        name,
        fill,
        label,
        exempt ? 0 : _kTextMinimum,
        base: base,
      ),
    );
  }

  final label = CoreRadioGroupStyle.defaultLabelStyle.color!;
  final description = CoreRadioGroupStyle.defaultDescriptionStyle.color!;

  const plain = CoreRadioGroupVariant.defaultVariant;
  for (final ground in _kContentGroundTones) {
    couple(
      'radio-group/${plain.name} description on ${ground.name} rest',
      CoreColor.token(ground),
      description,
    );
  }
  couple(
    'radio-group/${plain.name} description disabled',
    const CoreColor.token(CoreColors.surface),
    CoreRadioGroupStyle.defaultsByVariant[plain]!.disabledForegroundColor,
    exempt: true,
  );

  // The tile lays the halo's ink at the halo's ramp over its whole face, so
  // each wash states the face it lands on as its base.
  const card = CoreRadioGroupVariant.card;
  const layerInk = CoreRadioGroupStyle.defaultStateLayerColor;
  const layer = CoreRadioGroupStyle.defaultStateLayer;
  for (final (faceName, face) in [
    ('tile', CoreRadioGroupStyle.defaultTileBackgroundColor),
    ('selected tile', CoreRadioGroupStyle.defaultTileSelectedBackgroundColor),
  ]) {
    for (final (inkName, ink) in [
      ('label', label),
      ('description', description),
    ]) {
      final name = 'radio-group/${card.name} $inkName on $faceName';
      couple('$name rest', face, ink);
      for (final (state, weight) in [
        ('hover', layer.hover),
        ('pressed', layer.pressed),
      ]) {
        couple('$name $state', _wash(layerInk, weight), ink, base: face);
      }
    }
  }
  // A disabled tile keeps its face — resting or selected — and its label and
  // description share the disabled ink on either.
  final disabledCard = CoreRadioGroupStyle.defaultsByVariant[card]!;
  for (final (faceName, face) in [
    ('tile', CoreRadioGroupStyle.defaultTileBackgroundColor),
    ('selected tile', CoreRadioGroupStyle.defaultTileSelectedBackgroundColor),
  ]) {
    couple(
      'radio-group/${card.name} text on $faceName disabled',
      face,
      disabledCard.disabledForegroundColor,
      exempt: true,
    );
  }
}

/// The couples a chip's key (`prefixLabel`) paints — at rest, its own ink,
/// [CoreChipColorStyle.unselectedPrefixFg], on every face a resting chip is
/// drawn with: an outlined chip's fill paints nothing, so its key is
/// measured on each ground in [_kContentGroundTones]; a filled chip's key
/// on the one grey that fill is. Disabled, the label's disabled ink on the
/// two faces a disabled chip is drawn with — the surface for the chip that
/// was not picked, a container for the one that was — whatever the
/// variant; exempt, and the label shares the ink, so these couples report
/// the disabled label as well.
///
/// Read from every row of the colour table, so a row that states its own
/// key ink, or a colour added to the table, is audited without anyone
/// remembering to add it; a custom seed's disabled chip drops the seed and
/// reads its own defaults, so it is read from those. One resting couple
/// stands for both emphases: a resting chip's face and its key ink are the
/// same at high and low — the emphasis moves the label and the border, not
/// the key or the fill.
///
/// What is not here, and why:
/// - the key on a selected chip — it takes the label's colour on the
///   selected fill, an `onX`-on-`X` coupling the declared pairs hold
///   (`inverseOnSurface` on `inverseSurface`, `onPrimary` on `primary`, and
///   at low emphasis `onSurface` on `surfaceContainer`, `onPrimaryContainer`
///   on `primaryContainer`). A selected custom seed's key is the label's
///   on-colour, derived from the caller's seed.
/// - the hover, focus and pressed washes — the chip's label is not audited
///   under them either.
void _addChipCouples(List<RenderedCouple> out) {
  void disabled(String color, CoreColor ink, CoreColor face, CoreColor picked) {
    out
      ..add(RenderedCouple('chip/$color key disabled', face, ink, 0))
      ..add(
        RenderedCouple('chip/$color selected key disabled', picked, ink, 0),
      );
  }

  disabled(
    CoreChipColor.custom.name,
    CoreChipStyle.defaultCustomDisabledForegroundColor,
    CoreChipStyle.defaultCustomDisabledUnselectedBackgroundColor,
    CoreChipStyle.defaultCustomDisabledBackgroundColor,
  );
  for (final MapEntry(key: color, value: row)
      in CoreChipStyle.defaultsByColor.entries) {
    disabled(
      color.name,
      row.disabledFg,
      row.disabledBg,
      row.disabledSelectedBg,
    );
    for (final variant in CoreChipVariant.values) {
      final face = variant == CoreChipVariant.filled
          ? CoreChipStyle.defaultFilledUnselectedBackgroundColor
          : row.unselectedBg;
      final name = 'chip/${color.name} ${variant.name} key';
      if (_paintsSomething(face)) {
        out.add(
          RenderedCouple(
            '$name rest',
            face,
            row.unselectedPrefixFg,
            _kTextMinimum,
          ),
        );
        continue;
      }
      for (final ground in _kContentGroundTones) {
        out.add(
          RenderedCouple(
            '$name on ${ground.name} rest',
            CoreColor.token(ground),
            row.unselectedPrefixFg,
            _kTextMinimum,
          ),
        );
      }
    }
  }
}

String _key(String mode, _Pair p) =>
    '$mode ${p.foreground} on ${p.background} (>=${p.minimum})';

class _Finding {
  const _Finding(this.key, this.ratio, this.minimum);

  final String key;
  final double ratio;
  final double minimum;
}

Set<String> _readBaseline() {
  final f = File(_kBaselinePath);
  if (!f.existsSync()) return {};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}

/// A `## header` block from the baseline file, with its `#`-comment
/// lines (the documented reason a category is accepted) and the keys
/// that currently sit under it.
///
/// Exists so `--update` can shrink the baseline without erasing why
/// each surviving entry is there. A plain sorted rewrite (the original
/// `--update` behaviour) treats every entry as equally undocumented
/// debt, which is the exact state #3458 replaced — preserving
/// structure is what keeps a future `--update` from silently reverting
/// to that.
class _Category {
  _Category(this.header) : commentLines = [], keys = [];

  /// The `## ...` line, or null for keys with no category (pre-#3458
  /// entries, or a net-new finding nobody has categorised yet).
  final String? header;

  /// Lines starting with `#` (not `##`) directly under the header —
  /// carried through verbatim, not reparsed into structured data. This
  /// tool's job is to preserve prose, not to understand it.
  final List<String> commentLines;

  final List<String> keys;
}

/// Parses the baseline into its category structure. Blank lines and the
/// two fixed lines at the very top of the file are not part of any
/// category and are re-emitted from the literal header this file
/// writes, not carried through here.
List<_Category> _readCategories() {
  final f = File(_kBaselinePath);
  if (!f.existsSync()) return [];

  final categories = <_Category>[];
  var current = _Category(null);
  categories.add(current);

  for (final raw in f.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('## ')) {
      current = _Category(line);
      categories.add(current);
      continue;
    }
    if (line.startsWith('# ')) {
      // The file's own two top-of-file lines land in the headerless
      // category and are dropped — this tool writes its own fixed
      // header, so carrying old copies through would duplicate it.
      //
      // `current` is a fresh accumulator built and discarded within
      // this single-pass parse — nothing else holds a reference to it
      // while it fills, so mutating it in place is safe.
      if (current.header != null) {
        current.commentLines.add(line);
      }
      continue;
    }
    current.keys.add(line);
  }

  return categories;
}

/// Fails loudly if the luminance maths is wrong.
///
/// A broken formula would not make this guard noisy — it would make it
/// silently permissive, passing every pair and reporting a clean audit. The
/// two anchors below are fixed by the WCAG definition itself.
void _selfCheck() {
  const black = CoreColor(0xFF000000);
  const white = CoreColor(0xFFFFFFFF);
  final extremes = _contrast(black, white);
  final identical = _contrast(white, white);
  const tolerance = 0.01;
  if ((extremes - CoreContrast.maxRatio).abs() > tolerance ||
      (identical - 1).abs() > tolerance) {
    stderr.writeln(
      '❌ Contrast maths is wrong: black/white came out '
      '${extremes.toStringAsFixed(_kDiagnosticPrecision)} (must be '
      '${CoreContrast.maxRatio}) and white/white '
      '${identical.toStringAsFixed(_kDiagnosticPrecision)} (must be 1). '
      'Every result below '
      'would be meaningless, so this fails instead of reporting.',
    );
    exit(2);
  }
}

/// Every surface preset the design system ships.
///
/// Mirrors the roster in `CoreSurfaceA11yContract`. A preset that exists
/// there and not here is a preset nobody audited.
const _kPresetRoster = {
  'neo-brutalism',
  'liquid glass',
  'neumorphism',
  'claymorphism',
};

/// Presets that render the semantic tokens unchanged.
///
/// They restyle the *surface* — borders, shadows, blur — and leave the
/// colour tokens alone, so the four schemes above already audit exactly the
/// pairs they draw. Listing them is what makes that claim reviewable rather
/// than assumed.
const _kPresetsReusingBasePalette = {
  // Claymorphism states only a surface treatment (a softer cast); its
  // pastel accents were dropped because they lowered real contrast.
  'claymorphism',
  // Glass makes no colour statement — it is a surface treatment. Its
  // contrast is undecidable while translucent (it depends on whatever sits
  // behind), and the opaque fallback it drops to under reduce-transparency
  // is the base palette, which is already audited here.
  'liquid glass',
};

/// Prefix every finding under CoUI's own colour source carries.
///
/// `CouiColorPresets.source` is what `CoreThemePresets`, the docs site and
/// Web's `ThemeConfig.defaults()` render — the gate's reason to exist. The
/// prefix names *whose* colours, not *which* palette, so a baseline entry
/// survives the source being swapped under it.
const kCouiSchemePrefix = 'coui';

/// Prefix every finding under the standard mapping carries.
///
/// `CoreSemanticMappingSet.standard` is what a brand on a generated palette
/// inherits when it states no mapping of its own. Nothing CoUI ships
/// renders it, but every such brand does, so a regression there reaches
/// all of them.
const kStandardSchemePrefix = 'standard';

/// The prefix for a brand registered by one colour
/// (`CoreBrand.fromColor`) — CoUI's mapping over a generated palette with
/// the CTA rule for the primary family. Audited on one representative
/// colour, a violet, so a regression in the generator or the rule shows.
const kBrandSchemePrefix = 'brand';

/// The representative colour [kBrandSchemePrefix] is measured on.
const CoreColor kBrandAuditColor = CoreColor(0xFF7A3FD1);

/// The generated palette the `standard` schemes are measured on.
///
/// The standard mapping reads a [PrimitiveColors] palette, so it needs one
/// to be measured at all; these are the seeds the `standard` baseline rows
/// were measured on, kept here so those rows keep meaning the same thing.
/// The stage-tint sweep covers the mapping across every brand hue — this is
/// the one representative palette the full pair table runs on.
final PrimitiveColors _kStandardAuditPalette = PrimitiveColors.generate(
  primaryHSL: (h: 220.0, s: 0.65, l: 0.535),
  secondaryHSL: (h: 260.0, s: 0.60, l: 0.50),
  tertiaryHSL: (h: 272.0, s: 0.75, l: 0.46),
  successHSL: (h: 140.0, s: 0.70, l: 0.30),
  infoHSL: (h: 200.0, s: 0.75, l: 0.38),
  warningHSL: (h: 45.0, s: 0.85, l: 0.50),
  errorHSL: (h: 0.0, s: 0.75, l: 0.50),
  neutralHue: 220,
);

/// The colour sources this audit measures, keyed by the prefix every
/// finding under each carries.
final Map<String, CoreSchemeSource> _kAuditedSources = {
  kCouiSchemePrefix: CouiColorPresets.source,
  kStandardSchemePrefix: CoreSemanticMappingSet.standard.bind(
    _kStandardAuditPalette,
  ),
  kBrandSchemePrefix: CoreBrandSchemeSource.fromColor(kBrandAuditColor),
};

/// The mappings the stage-tint sweep reads a generated palette through.
///
/// A separate list from [_kAuditedSources] because the sweep's free
/// parameter is the brand hue, and only a mapping over a generated palette
/// has one: the sweep builds a palette per hue and binds each of these to
/// it. CoUI's own source is a fixed palette with a fixed hue, so the sweep
/// measures it once, at that hue.
const List<(String, CoreSemanticMappingSet)> _kSweptMappings = [
  (kStandardSchemePrefix, CoreSemanticMappingSet.standard),
];

/// Colour overrides contributed by presets, audited as deltas on each
/// source's own base.
///
/// A preset that ships its own colours is a different palette wearing the
/// same token names, and the base audit cannot see it. Registering here is a
/// merge condition in the preset acceptance gate.
///
/// Translucency is a stated limit, not an omission: a glass surface's
/// effective contrast depends on whatever sits behind it, which no static
/// pair can settle. Such a preset registers the opaque fallback it falls
/// back to under reduce-transparency, and that fallback is what gets
/// audited.
const Map<String, CoreSurfaceStyleId> _kAuditedPresets = {
  'neo-brutalism': CoreSurfaceStyleId.neoBrutalism,
  'neumorphism': CoreSurfaceStyleId.neumorphism,
};

/// One scheme the audit measures, and the base it is a delta of when it is
/// a preset.
class AuditedScheme {
  const AuditedScheme(
    this.key,
    this.scheme, {
    required this.brightness,
    this.base,
    this.highContrast = false,
    this.holdsHighContrastLine = false,
  });

  /// `<source prefix> <mode>` — the namespace every finding under this
  /// scheme carries in the baseline.
  final String key;

  final ResolvedColorScheme scheme;

  /// The page this scheme is drawn for. The light strong category chip
  /// label owes a different bar from the dark one (see [categoryPairs]).
  final CoreBrightness brightness;

  /// Whether this is one of its source's high-contrast schemes, under
  /// either mapping — where category text owes 7:1 and the category outline
  /// 4.5:1 on the page (see [categoryPairs]).
  ///
  /// Separate from [holdsHighContrastLine] on purpose: that bar is stated
  /// by CoUI's high-contrast tables alone, while both mappings write the
  /// high-contrast category values from the same table.
  final bool highContrast;

  /// For a preset delta: the same source's base scheme in the same
  /// brightness. Pairs where neither slot moved resolve to colours already
  /// audited under that base and are skipped — see [auditedSchemes].
  final ResolvedColorScheme? base;

  /// Whether this scheme's high-contrast table states the raised UI-line bar
  /// — CoUI's two high-contrast tables do, the standard mapping's do not —
  /// and so owes [_kHighContrastLineMinimum] to what a user has to find in
  /// that mode:
  ///
  /// - `outlineSubtle`, the border a floating panel leans on instead of its
  ///   shadow, on the panel tones;
  /// - a scrollbar thumb, on the page and panel tones (see
  ///   [_kScrollbarThumbTones]).
  ///
  /// A mapping that states no such bar is held to the ordinary component
  /// minimum for them, which is why this is a flag on the scheme and not a
  /// property of every high-contrast scheme.
  final bool holdsHighContrastLine;

  bool get isPresetDelta => base != null;
}

/// Every scheme the gate measures: the four modes of each source in
/// [_kAuditedSources], then each preset's delta on top of that source.
///
/// The four modes are built from the source's own builders — the same
/// call `CoreThemePresets` makes — rather than through
/// `resolveThemeSchemeFrom`, so what is audited is byte-for-byte what the
/// theme seat puts on screen, and [auditDriftFromCouiTheme] can hold the
/// two together.
///
/// Presets go through `resolveThemeSchemeFrom`, the resolution the app
/// renders, with the same source. A preset resolved from any other source
/// would audit a styled CoUI nothing draws.
List<AuditedScheme> auditedSchemes() {
  final out = <AuditedScheme>[];

  for (final audited in _kAuditedSources.entries) {
    final prefix = audited.key;
    final source = audited.value;
    final light = source.light().resolved(.light);
    final dark = source.dark().resolved(.dark);

    out.addAll([
      AuditedScheme('$prefix light', light, brightness: .light),
      AuditedScheme('$prefix dark', dark, brightness: .dark),
      // The high-contrast sets are audited by the same pairs. They exist
      // to raise contrast, so a violation here is worse than one in the
      // normal set — it means the mode a user turned on specifically for
      // legibility did not deliver it.
      AuditedScheme(
        '$prefix high-contrast light',
        source.highContrastLight().resolved(.light),
        brightness: .light,
        highContrast: true,
        holdsHighContrastLine: prefix == kCouiSchemePrefix,
      ),
      AuditedScheme(
        '$prefix high-contrast dark',
        source.highContrastDark().resolved(.dark),
        brightness: .dark,
        highContrast: true,
        holdsHighContrastLine: prefix == kCouiSchemePrefix,
      ),
    ]);

    for (final preset in _kAuditedPresets.entries) {
      for (final brightness in CoreBrightness.values) {
        out.add(
          AuditedScheme(
            '$prefix ${preset.key} (${brightness.name})',
            resolveThemeSchemeFrom(
              source,
              brightness: brightness,
              surfaceStyle: preset.value,
            ).resolved(brightness),
            brightness: brightness,
            base: brightness == .dark ? dark : light,
          ),
        );
      }
    }
  }

  return out;
}

/// Where the audited CoUI schemes differ from what CoUI's theme presets put
/// on screen, or null when they agree slot for slot.
///
/// The defect this catches is one this file once shipped with: the schemes
/// were built from a mapping no CoUI seat renders, so the gate was green
/// about colours nobody saw and would have said nothing about a change to
/// the real ones.
///
/// It compares against `CoreThemePresets` — the value the app really puts
/// in its `ThemeData` — rather than against `CouiColorPresets.source` a
/// second time.
/// A copy checked against a copy passes whenever the same mistake is made
/// twice; checked against the rendered value, a regression in either the
/// audit or the presets fails here.
String? auditDriftFromCouiTheme(List<AuditedScheme> schemes) {
  final rendered = {
    '$kCouiSchemePrefix light': CoreThemePresets.lightColorScheme,
    '$kCouiSchemePrefix dark': CoreThemePresets.darkColorScheme,
    '$kCouiSchemePrefix high-contrast light':
        CoreThemePresets.highContrastLightColorScheme,
    '$kCouiSchemePrefix high-contrast dark':
        CoreThemePresets.highContrastDarkColorScheme,
  };
  final byKey = {for (final s in schemes) s.key: s.scheme};

  for (final entry in rendered.entries) {
    final audited = byKey[entry.key];
    if (audited == null) return '${entry.key} is not audited at all';
    final onScreen = _slots(entry.value);
    for (final slot in _slots(audited).entries) {
      final expected = onScreen[slot.key];
      if (slot.value != expected) {
        return '${entry.key}: slot ${slot.key} is ${slot.value.toHex()} in '
            'the audit but ${expected?.toHex()} on screen';
      }
    }
  }

  return null;
}

/// Names presets carry in the recipe container, so a rename there surfaces
/// here rather than silently emptying the audit.
const Map<String, CoreSurfaceStyleId> _kPresetIds = {
  'neo-brutalism': CoreSurfaceStyleId.neoBrutalism,
  'liquid glass': CoreSurfaceStyleId.liquidGlass,
  'neumorphism': CoreSurfaceStyleId.neumorphism,
  'claymorphism': CoreSurfaceStyleId.claymorphism,
};

/// Fails when a preset is neither audited nor declared as reusing the base
/// palette — the state in which a preset silently escapes contrast review.
void _checkPresetCoverage() {
  final registered = _kAuditedPresets.keys.toSet();

  // A preset that bends the palette is a different palette wearing the same
  // token names, so claiming it reuses the base one stops being true the
  // moment its recipe gains a colour statement. Reading the recipe rather
  // than trusting the list below is what makes that failure loud: the story
  // that gives a preset vivid accents cannot also leave it unaudited.
  for (final entry in _kPresetIds.entries) {
    final bendsPalette = !CoreSurfaceRecipe.of(
      entry.value,
    ).colorConstraint.isIdentity;
    if (bendsPalette && _kPresetsReusingBasePalette.contains(entry.key)) {
      stderr.writeln(
        '❌ ${entry.key} bends the palette in its recipe but is still listed '
        'as reusing the base one — it needs its own audited scheme.',
      );
      exit(1);
    }
  }

  final unknown = registered.difference(_kPresetRoster);
  if (unknown.isNotEmpty) {
    stderr.writeln(
      '❌ contrast registry names no known preset: ${unknown.join(', ')} — '
      'the registry and the preset roster have diverged.',
    );
    exit(1);
  }

  final both = registered.intersection(_kPresetsReusingBasePalette);
  if (both.isNotEmpty) {
    stderr.writeln(
      '❌ ${both.join(', ')} both reuses the base palette and registers its '
      'own — one of the two claims is stale.',
    );
    exit(1);
  }

  final unclassified = _kPresetRoster
      .difference(_kPresetsReusingBasePalette)
      .difference(registered);
  if (unclassified.isNotEmpty) {
    stderr.writeln(
      '❌ ${unclassified.join(', ')} is audited by nothing. A preset either '
      'reuses the base palette (say so) or registers its own scheme.',
    );
    exit(1);
  }
}

/// How finely the stage-tint sweep samples hue.
///
/// One degree. The bound this proves is only as good as the worst hue it
/// looked at, and a coarse step buys speed by not looking — which is the
/// one economy an audit cannot make. The sweep runs against the pairs the
/// page background takes part in, not the whole matrix, so the full circle
/// stays cheap.
const double _kStageTintHueStep = 1;

/// Accent saturation and lightness the sweep holds while hue moves.
///
/// Hue is the parameter this bound is proven across; saturation and
/// lightness are pinned by the scale generator to the same accent-versus-
/// page ratio whatever they are set to, which is why one pair of values
/// stands in for the family rather than a second and third nested loop.
const double _kSweepSaturation = 0.9;
const double _kSweepLightness = 0.6;

/// A tint request past what sRGB holds at any page lightness.
///
/// The constraint fits requests down into the gamut, so asking for far
/// more than is available is how this measures the real ceiling instead of
/// the product bound. What it proves is the useful invariant: the page
/// cannot be tinted hard enough to break a pair, because colour runs out
/// first.
const double _kStageTintProbeChroma = 0.4;

/// Fails when the page tint the tuning permits would drop a pair at some
/// hue.
///
/// The hue is the app's to choose — a brand palette tints the page toward
/// its own colour — so no single registered scheme can cover this preset
/// the way `auditedSchemes()` covers the fixed ones. What can be covered is
/// the *range*: bound the magnitude, then sweep the free parameter and show
/// every hue clears. That is a stronger claim than registering one scheme,
/// not a weaker one — it says any app's choice is safe, rather than that
/// ours is.
///
/// Reuses `_pairs()` rather than restating the couples. An earlier
/// hand-written list for this sweep was wrong twice in one sitting: it
/// invented a container-versus-page couple the design system deliberately
/// does not require, and it audited an accent that had been retired from
/// page text. Both showed up as the untinted palette "failing".
void _checkStageTintSweep() {
  // Deliberately past anything sRGB can give at any page lightness, so the
  // tint is fitted down to the gamut ceiling and this measures the *most
  // colour the page can physically hold* rather than whatever the product
  // bound happens to be.
  //
  // Asking for `maxStageTintChroma` instead made this guard inert: the fit
  // capped every request well below it, so 0.12 and 0.40 produced an
  // identical worst margin and no value could have failed. A sweep that
  // cannot fail is not a sweep.
  const chroma = _kStageTintProbeChroma;
  // Read per brightness: `_pairs` states some bars by mode.
  final onPage = {
    for (final brightness in CoreBrightness.values)
      brightness: _pairs(
        brightness: brightness,
      ).where((p) => p.background == 'surface').toList(),
  };

  var worst = double.infinity;
  var worstAt = '';

  // One measurement: the worst on-page margin a tinted scheme reaches.
  void measure(CoreSchemeSource source, String at) {
    for (final brightness in CoreBrightness.values) {
      final scheme = resolveThemeSchemeFrom(
        source,
        brightness: brightness,
        surfaceStyle: .neoBrutalism,
        surfaceTuning: CoreSurfaceTuning(stageTintChroma: chroma),
      ).resolved(brightness);
      final slots = _slots(scheme);

      for (final pair in onPage[brightness]!) {
        final fg = slots[pair.foreground];
        final bg = slots[pair.background];
        if (fg == null || bg == null) continue;
        final margin = _contrast(fg, bg) / pair.minimum;
        if (margin < worst) {
          worst = margin;
          worstAt =
              '${pair.foreground}/${pair.background} at $at '
              '(${brightness.name}) — '
              '${_contrast(fg, bg).toStringAsFixed(2)}:1 '
              'owes ${pair.minimum}';
        }
      }
    }
  }

  // The free parameter is the app's *brand hue*, and it reaches the page
  // through the palette — the tint takes `primary`'s hue, so sweeping means
  // building a palette per hue, not passing an angle. An earlier draft
  // declared the loop variable and never used it, which made this run the
  // same point 360 times and report the whole circle clear.
  //
  // Swept under every mapping in [_kSweptMappings], bound explicitly to
  // each hue's palette: a configuration this bound never looked at is one
  // it cannot vouch for.
  for (var hue = 0.0; hue < 360; hue += _kStageTintHueStep) {
    final palette = PrimitiveColors.generate(
      primaryHSL: (h: hue, s: _kSweepSaturation, l: _kSweepLightness),
      secondaryHSL: (h: (hue + 40) % 360, s: 0.55, l: 0.45),
      tertiaryHSL: (h: (hue + 320) % 360, s: 0.55, l: 0.45),
      successHSL: (h: 145, s: 0.55, l: 0.38),
      infoHSL: (h: 205, s: 0.60, l: 0.45),
      warningHSL: (h: 40, s: 0.85, l: 0.55),
      errorHSL: (h: 0, s: 0.65, l: 0.50),
      neutralHue: hue,
    );

    for (final (prefix, mapping) in _kSweptMappings) {
      measure(mapping.bind(palette), 'hue ${hue.toInt()}° ($prefix)');
    }
  }

  // CoUI's own palette has no free hue — its ink is fixed — so it is the
  // one point it can be: its own source, at the same probe chroma.
  measure(CouiColorPresets.source, "CoUI's own hue ($kCouiSchemePrefix)");

  if (worst < 1) {
    stderr
      ..writeln(
        '❌ the deepest page tint sRGB allows drops a pair at some brand '
        'hue:',
      )
      ..writeln('   $worstAt')
      ..writeln(
        '   Not a bound that can be lowered — it is what the page colour '
        'itself can hold. A page light enough to stay safe is the fix, or '
        'the axis does not ship.',
      );
    exit(1);
  }

  stdout.writeln(
    '✅ the deepest page tint sRGB allows clears every brand hue '
    '(worst margin ×${worst.toStringAsFixed(2)} — $worstAt).',
  );
}

void main(List<String> args) {
  _selfCheck();
  _checkPresetCoverage();
  _checkStageTintSweep();
  final update = args.contains('--update');
  final ci = args.contains('--ci');

  final schemes = auditedSchemes();

  // Refuse to report before measuring something nobody renders. A guard
  // that audits the wrong mapping is not noisy — it is green, about
  // colours no screen shows, and silent about the ones every screen does.
  final drift = auditDriftFromCouiTheme(schemes);
  if (drift != null) {
    stderr.writeln(
      '❌ the audit is not measuring what CoUI renders: $drift. Every '
      '$kCouiSchemePrefix finding below would be about a palette nobody '
      'sees, so this fails instead of reporting.',
    );
    exit(2);
  }

  // A preset scheme is audited only on the pairs it actually changes.
  //
  // Every key is namespaced by scheme, so registering a preset would
  // otherwise re-audit every pair under a new prefix and surface the
  // palette's own pre-existing failures as net-new findings against a
  // preset that never touched them. Recording inherited debt against a
  // style that improved the pairs it did touch is both wrong and enough
  // to block the style on something unrelated to it.
  //
  // Pairs where neither slot moved resolve to the identical two colours
  // already audited under the mapping's own `light` / `dark`, so skipping
  // them loses no coverage.
  final findings = <_Finding>[];
  var checked = 0;

  // Per-scheme, so the summary can say what it actually did rather than
  // a fixed "light + dark" that was already stale the day high-contrast
  // and the preset deltas were added (#3461) — a reader who trusts that
  // line has no way to tell audited-and-clean from never-looked-at.
  final checkedPerScheme = <String, int>{};
  final findingsPerScheme = <String, int>{};

  for (final audited in schemes) {
    final key = audited.key;
    checkedPerScheme[key] = 0;
    findingsPerScheme[key] = 0;
    final slots = _slots(audited.scheme);
    final baseSlots = audited.base == null ? null : _slots(audited.base!);
    for (final pair in _pairs(
      brightness: audited.brightness,
      highContrast: audited.highContrast,
      holdsHighContrastLine: audited.holdsHighContrastLine,
    )) {
      final fg = slots[pair.foreground];
      final bg = slots[pair.background];
      if (baseSlots != null &&
          fg == baseSlots[pair.foreground] &&
          bg == baseSlots[pair.background]) {
        continue;
      }
      if (fg == null || bg == null) {
        stderr.writeln(
          '❌ unknown slot in pair ${pair.foreground}/${pair.background} — '
          'the slot map is out of date with CoreColorScheme.',
        );
        exit(2);
      }
      checked++;
      checkedPerScheme[key] = checkedPerScheme[key]! + 1;
      final ratio = _contrast(fg, bg);
      if (ratio < pair.minimum) {
        findings.add(_Finding(_key(key, pair), ratio, pair.minimum));
        findingsPerScheme[key] = findingsPerScheme[key]! + 1;
      }
    }

    // The couples components really paint, composited. Only the base
    // schemes — a style preset bends chrome, not these tables, so running
    // them again would restate the same numbers under other names.
    if (audited.isPresetDelta) continue;
    final scheme = audited.scheme;
    for (final r in renderedCouples()) {
      final ratio = renderedRatio(scheme, r);
      if (ratio == null) continue;
      checked++;
      checkedPerScheme[key] = checkedPerScheme[key]! + 1;
      final minimum = r.minimumIn(highContrast: audited.holdsHighContrastLine);
      if (ratio < minimum) {
        findings.add(_Finding(_renderedKey(key, r, minimum), ratio, minimum));
        findingsPerScheme[key] = findingsPerScheme[key]! + 1;
      }
    }
  }

  final current = findings.map((f) => f.key).toSet();
  final sorted = current.toList()..sort();

  if (update) {
    final currentSet = current;
    final categories = _readCategories();
    final buffer = StringBuffer()
      ..writeln('# WCAG contrast violations accepted as of the last --update.')
      ..writeln('# Net-new entries fail CI; this list may only shrink.')
      ..writeln('#')
      ..writeln('# Every entry sits under a `##` category header carrying a')
      ..writeln('# `# reason:` — bare debt with no reason is exactly what this')
      ..writeln('# file used to be, and what #3458 replaced. `--update`')
      ..writeln("# preserves a category's reason lines for any entry that")
      ..writeln('# survives the run; a newly-added entry lands with no reason')
      ..writeln('# and needs one written by hand before it should be trusted.');

    final claimed = <String>{};
    for (final category in categories) {
      if (category.header == null) continue;
      final surviving = category.keys.where(currentSet.contains).toList()
        ..sort();
      // A category whose every entry got fixed is dropped rather than
      // kept as an empty header — an empty category reads as "still
      // tracked" when there is nothing left to track.
      if (surviving.isEmpty) continue;
      claimed.addAll(surviving);
      buffer
        ..writeln()
        ..writeln(category.header);
      category.commentLines.forEach(buffer.writeln);
      surviving.forEach(buffer.writeln);
    }

    final uncategorised = sorted.where((k) => !claimed.contains(k)).toList();
    if (uncategorised.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Uncategorised — needs a `# reason:` written by hand');
      uncategorised.forEach(buffer.writeln);
    }

    File(_kBaselinePath).writeAsStringSync(buffer.toString());
    stdout.writeln('Wrote baseline (${sorted.length}) → $_kBaselinePath');
    if (uncategorised.isNotEmpty) {
      final plural = uncategorised.length == 1 ? 'y' : 'ies';
      stdout.writeln(
        '   ⚠ ${uncategorised.length} entr$plural landed uncategorised — '
        'add a `##` header and a `# reason:` by hand.',
      );
    }
    return;
  }

  final baseline = _readBaseline();
  final netNew = findings.where((f) => !baseline.contains(f.key)).toList()
    ..sort((a, b) => a.ratio.compareTo(b.ratio));
  final fixed = baseline.where((b) => !current.contains(b)).length;

  // "Checked N pairs across light + dark" was true the day it was
  // written and false from the moment high-contrast and the preset
  // deltas joined `schemes` — the audit widened, the sentence did not.
  // A reader who trusts it has no way to tell "high-contrast is clean"
  // from "high-contrast was never looked at", and both read the same:
  // silence. Naming every scheme and its own count, zero included, is
  // what leaves a trace either way.
  //
  // Read off `schemes` rather than stated as a literal — a hardcoded
  // "4 named schemes" would go right back to being the same kind of
  // claim this replaces the moment a scheme is added or removed from
  // that list and nobody remembers to also edit this string.
  final baseSchemeNames = [
    for (final s in schemes)
      if (!s.isPresetDelta) s.key,
  ];
  final presetSchemeCount = schemes.length - baseSchemeNames.length;
  stdout.writeln(
    'Checked $checked semantic pairs across ${baseSchemeNames.length} '
    'schemes (${baseSchemeNames.join(', ')}) + $presetSchemeCount preset '
    'delta${presetSchemeCount == 1 ? '' : 's'}:',
  );
  for (final s in schemes) {
    stdout.writeln(
      '     ${s.key.padRight(_kSchemeColumnWidth)} '
      '${checkedPerScheme[s.key]} pairs, '
      '${findingsPerScheme[s.key]} below threshold',
    );
  }

  if (findings.isNotEmpty) {
    stdout.writeln(
      '   ${findings.length} below threshold '
      '(${baseline.length} in baseline):',
    );
    final shown = findings.toList()..sort((a, b) => a.ratio.compareTo(b.ratio));
    for (final f in shown) {
      final mark = baseline.contains(f.key) ? ' ' : '!';
      stdout.writeln(
        '   $mark ${f.key.padRight(_kKeyColumnWidth)} '
        '${f.ratio.toStringAsFixed(2)}',
      );
    }
  }

  if (netNew.isNotEmpty) {
    stdout
      ..writeln()
      ..writeln('❌ ${netNew.length} net-new contrast violation(s):');
    for (final f in netNew) {
      stdout.writeln(
        '     ${f.key} — measured ${f.ratio.toStringAsFixed(2)}',
      );
    }
    stdout
      ..writeln('   Adjust the palette or the semantic mapping, or run')
      ..writeln('   `dart run tool/check_contrast.dart --update` to accept')
      ..writeln('   it into the baseline (only with a reason).');
    if (ci) exit(1);
    return;
  }

  stdout.writeln('✅ No net-new contrast violations.');
  if (fixed > 0) {
    stdout.writeln(
      '   ℹ $fixed baseline entr${fixed == 1 ? 'y is' : 'ies are'} now '
      'passing — run --update to shrink the baseline.',
    );
  }
}
