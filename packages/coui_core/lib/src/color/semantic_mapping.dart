import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/primary_container_gap.dart';
import 'package:coui_core/src/color/primitive_colors.dart';
import 'package:coui_core/src/color/syntax_palette.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// Maps a brand's generated [PrimitiveColors] to [CoreColorScheme] — the
/// standard interpretation (`CoreSemanticMappingSet.standard`) every brand
/// palette reads unless the brand states its own set.
///
/// The single source of truth for that mapping, used by both coui_flutter
/// and coui_web. CoUI's own fixed palette has its own mapping,
/// `CouiSemanticMapping`.
///
/// Usage:
/// ```dart
/// final primitive = PrimitiveColors.generate(...);
/// final light = CoreSemanticMapping.light(primitive);
/// final dark = CoreSemanticMapping.dark(primitive);
/// ```
abstract final class CoreSemanticMapping {
  /// Light mode [CoreColorScheme] from [PrimitiveColors].
  static CoreColorScheme light(PrimitiveColors c) {
    final n = c.neutral;
    final scheme = CoreColorScheme(
      // Primary
      primary: c.primary.base,
      // Secondary
      secondary: c.secondary.base,
      // Error
      error: c.error.base,
      // Success
      success: c.success.base,
      // Warning
      warning: c.warning.base,
      // Info
      info: c.info.base,
      // Surface
      surface: n.white,
      surfaceDim: n.whiteDark,
      surfaceBright: n.white,
      surfaceContainerLowest: n.white,
      surfaceContainerLow: n.whiteDark,
      surfaceContainer: n.whiteDarker,
      surfaceContainerHigh: n.greyLightest,
      surfaceContainerHighest: n.greyLighter,
      onSurface: n.black,
      onSurfaceVariant: n.greyDarkest,
      // One step softer than onSurfaceVariant — a placeholder has to read
      // as weaker than the value that will replace it.
      placeholder: n.greyDarker,
      // A link is read as text, so it owes 4.5:1 on every surface tone.
      // `info.base` is a status colour tuned for a filled chip and promises
      // nothing of the kind; `darker` is the step `check_contrast` measures
      // clear on all eight light tones of the standard palette.
      link: c.info.darker,
      // The third text step reads the placeholder's step: the standard
      // ramp has no step between it and `onSurfaceVariant` to spare.
      onSurfaceSubtle: n.greyDarker,
      // The selected face that rises out of a track: the page itself.
      surfaceRaised: n.white,
      surfaceTint: c.primary.base,
      onPrimary: n.white,
      // `lightest`, or up to two steps darker when that melts into the
      // page — `CorePrimaryContainerGap` holds the contract and the reasons.
      primaryContainer: CorePrimaryContainerGap.pick(
        [c.primary.lightest, c.primary.lighter, c.primary.light],
        surface: n.white,
        onContainer: c.primary.darkest,
        primaryText: c.primary.darker,
        brightness: .light,
      ),
      onPrimaryContainer: c.primary.darkest,
      primaryFixed: c.primary.lightest,
      primaryFixedDim: c.primary.lighter,
      onPrimaryFixed: c.primary.darkest,
      onPrimaryFixedVariant: c.primary.dark,
      // Primary AS TEXT on surfaces. The STANDARD mapping must hold for any
      // brand hue (check_contrast's hue sweep audits exactly that), and
      // `base` cannot — a yellow-family base is 1.14:1 on the light surface,
      // and even `dark` is 2.41:1 under the sweep's hostile bright-saturated
      // seed. `darker` is the lightest step that clears the sweep, so it is
      // the structural default; a brand whose own base clears 4.5:1
      // (Unibook's does) states `base` in its own mapping instead.
      primaryText: c.primary.darker,
      primaryTextLarge: c.primary.darker,
      onSecondary: n.white,
      secondaryContainer: c.secondary.lightest,
      onSecondaryContainer: c.secondary.darkest,
      secondaryFixed: c.secondary.lightest,
      secondaryFixedDim: c.secondary.lighter,
      onSecondaryFixed: c.secondary.darkest,
      onSecondaryFixedVariant: c.secondary.dark,
      // Tertiary
      tertiary: c.tertiary.base,
      onTertiary: n.white,
      tertiaryContainer: c.tertiary.lightest,
      onTertiaryContainer: c.tertiary.darkest,
      tertiaryFixed: c.tertiary.lightest,
      tertiaryFixedDim: c.tertiary.lighter,
      onTertiaryFixed: c.tertiary.darkest,
      onTertiaryFixedVariant: c.tertiary.dark,
      onError: n.white,
      errorContainer: c.error.lightest,
      onErrorContainer: c.error.darkest,
      // Pressed step for the destructive `Button` (B2 opaque swap,
      // `CoUI_Button_State_Layer_Decision.md` §9) — one step darker than
      // `error.base` in light mode, matching the Figma `color/error-strong`
      // source token.
      errorStrong: c.error.darker,
      // Interaction steps for filled controls — one chromatic step per
      // state in the direction this mode already moves (`errorStrong`
      // above is the two-step version of the same walk). `errorPressed`
      // is the Figma `color/error-pressed` measurement: `dark`, one step
      // from `base`, where `error-strong` sits two.
      errorPressed: c.error.dark,
      primaryHover: c.primary.dark,
      primaryPressed: c.primary.darker,
      secondaryHover: c.secondary.dark,
      secondaryPressed: c.secondary.darker,
      focusRing: c.primary.base,
      onSuccess: n.white,
      successContainer: c.success.lightest,
      onSuccessContainer: c.success.darkest,
      onWarning: n.black,
      warningContainer: c.warning.lightest,
      onWarningContainer: c.warning.darkest,
      onInfo: n.white,
      infoContainer: c.info.lightest,
      onInfoContainer: c.info.darkest,
      // Status indicators (icons, status dots, progress bars) owe 3:1 on
      // the page. A generated ramp has no in-between step to lighten the
      // mark by, so it reads the status fill's own step — except warning,
      // whose fill is light by design (`onWarning` is black on it) and
      // measures under 2:1 on white: the mark takes the next step, `dark`
      // (about 4.5:1).
      errorIcon: c.error.base,
      successIcon: c.success.base,
      warningIcon: c.warning.dark,
      infoIcon: c.info.base,
      // Outline
      // `outline` draws control boundaries, so WCAG 1.4.11 asks 3:1 against
      // whatever surface tone the control sits on. `greyLight` cleared that
      // on none of the eight light tones (worst 1.26 on
      // surfaceContainerHighest); `greyDarker` is the lightest step that
      // clears all eight (worst 3.34). `outlineVariant` stays a hairline —
      // 1.4.11 covers boundaries that delimit a control, not decorative
      // rules, so holding it to 3:1 would stop it being a hairline.
      outline: n.greyDarker,
      outlineVariant: n.greyLighter,
      // No brand states a floating-panel border of its own, so this reads as
      // `outlineVariant` — in every mode below too. A brand that does gets
      // its own mapping, as for any other slot.
      outlineSubtle: n.greyLighter,
      // Inverse
      inverseSurface: n.black,
      inverseOnSurface: n.white,
      inversePrimary: c.primary.light,
      // Special
      shadow: n.pureBlack,
      // Brighter than `surface` (a hue-tinted off-white), so the rim
      // reads even on the lightest page.
      surfaceHighlight: n.pureWhite,
      scrim: n.pureBlack,
      // Disabled — fixed values rather than an opacity multiplier, so the
      // contrast is decided here once instead of depending on whatever
      // surface the element happens to sit on.
      disabledContent: n.greyDark,
      disabledContainer: n.whiteDarker,
      disabledOutline: n.greyLighter,
    );

    // The category slots are brand-neutral. Their strong chip's label reads
    // pure white and pure black, never `n.white`: that off-white measures
    // 3.47:1 on the lowest light fill, under the 3.5:1 the label is allowed.
    return CoreCategoryPalette.applyTo(
      // Syntax: keyword, type and string are brand-less; function names
      // read the link step, the info step already measured as text here.
      CoreSyntaxPalette.applyTo(scheme, .light, function: c.info.darker),
      .light,
      highContrast: false,
      white: n.pureWhite,
      black: n.pureBlack,
    );
  }

  /// Dark mode [CoreColorScheme] from [PrimitiveColors].
  static CoreColorScheme dark(PrimitiveColors c) {
    final n = c.neutral;
    final scheme = CoreColorScheme(
      // Primary
      primary: c.primary.light,
      // Secondary
      secondary: c.secondary.light,
      // Error
      error: c.error.light,
      // Success
      success: c.success.light,
      // Warning
      warning: c.warning.light,
      // Info
      info: c.info.light,
      // Surface
      surface: n.black,
      surfaceDim: n.pureBlack,
      surfaceBright: n.blackLighter,
      surfaceContainerLowest: n.pureBlack,
      surfaceContainerLow: n.black,
      surfaceContainer: n.blackLight,
      surfaceContainerHigh: n.blackLighter,
      surfaceContainerHighest: n.greyDarkest,
      onSurface: n.white,
      onSurfaceVariant: n.greyLighter,
      placeholder: n.greyLight,
      // `info.light` is the status step for this mode and measures 4.30 on
      // `surfaceContainerHighest`; one step lighter clears all eight tones.
      link: c.info.lighter,
      onSurfaceSubtle: n.greyLight,
      // The topmost surface tone (`surfaceContainerHighest`), above every
      // track tone below it.
      surfaceRaised: n.greyDarkest,
      surfaceTint: c.primary.light,
      onPrimary: c.primary.darkest,
      // `darker`, or up to two steps lighter when that melts into the page
      // — `CorePrimaryContainerGap` holds the contract and the reasons.
      primaryContainer: CorePrimaryContainerGap.pick(
        [c.primary.darker, c.primary.dark, c.primary.base],
        surface: n.black,
        onContainer: c.primary.lightest,
        primaryText: c.primary.lighter,
        brightness: .dark,
      ),
      onPrimaryContainer: c.primary.lightest,
      primaryFixed: c.primary.lightest,
      primaryFixedDim: c.primary.lighter,
      onPrimaryFixed: c.primary.darkest,
      onPrimaryFixedVariant: c.primary.dark,
      // Text on the dark surface needs LIGHT steps; normal text takes one
      // step lighter than large text because it needs 4.5:1 where large
      // needs only 3:1.
      primaryText: c.primary.lighter,
      primaryTextLarge: c.primary.light,
      onSecondary: c.secondary.darkest,
      secondaryContainer: c.secondary.darker,
      onSecondaryContainer: c.secondary.lightest,
      secondaryFixed: c.secondary.lightest,
      secondaryFixedDim: c.secondary.lighter,
      onSecondaryFixed: c.secondary.darkest,
      onSecondaryFixedVariant: c.secondary.dark,
      // Tertiary
      tertiary: c.tertiary.light,
      onTertiary: c.tertiary.darkest,
      tertiaryContainer: c.tertiary.darker,
      onTertiaryContainer: c.tertiary.lightest,
      tertiaryFixed: c.tertiary.lightest,
      tertiaryFixedDim: c.tertiary.lighter,
      onTertiaryFixed: c.tertiary.darkest,
      onTertiaryFixedVariant: c.tertiary.dark,
      onError: c.error.darkest,
      errorContainer: c.error.darker,
      onErrorContainer: c.error.lightest,
      // Dark mode inverts polarity against light — the pressed step moves
      // *lighter*, matching the Figma `color/error-strong` source token.
      errorStrong: c.error.lightest,
      // Mirror of `light` — one lighter step per interaction state
      // (`error-pressed` measured `lighter` in Figma's Dark mode).
      errorPressed: c.error.lighter,
      primaryHover: c.primary.lighter,
      primaryPressed: c.primary.lightest,
      secondaryHover: c.secondary.lighter,
      secondaryPressed: c.secondary.lightest,
      focusRing: c.primary.light,
      onSuccess: c.success.darkest,
      successContainer: c.success.darker,
      onSuccessContainer: c.success.lightest,
      onWarning: c.warning.darkest,
      warningContainer: c.warning.darker,
      onWarningContainer: c.warning.lightest,
      onInfo: c.info.darkest,
      infoContainer: c.info.darker,
      onInfoContainer: c.info.lightest,
      // Status indicators — the status fill's own step, as in [light].
      errorIcon: c.error.light,
      successIcon: c.success.light,
      warningIcon: c.warning.light,
      infoIcon: c.info.light,
      // Outline
      // Same 1.4.11 requirement, mirrored: on dark surfaces the boundary has
      // to be *lighter* than the page. `greyDark` missed on the three
      // brightest dark tones (worst 2.07); `greyLight` is the darkest step
      // that clears all eight (worst 3.79).
      outline: n.greyLight,
      outlineVariant: n.greyDarker,
      outlineSubtle: n.greyDarker,
      // Inverse
      inverseSurface: n.white,
      inverseOnSurface: n.black,
      inversePrimary: c.primary.dark,
      // Special
      //
      // Black, as in light. A black cast on a dark page is faint at the
      // light alpha, so the dark theme draws each cast layer at its alpha
      // × `CoreShadow.darkStrength` — the strength lives on the geometry
      // seat, not in this slot. Components ask for `shadow` and none of
      // them decides either.
      shadow: n.pureBlack,
      // Not `pureWhite`: at the same layer opacity a full white rim
      // reads far hotter against a dark page than against a light one.
      surfaceHighlight: n.greyLight,
      scrim: n.pureBlack,
      // Disabled — `greyDark` carries in both modes because it sits mid
      // scale: 3.92:1 on the light surface, 4.38:1 on the dark one.
      disabledContent: n.greyDark,
      disabledContainer: n.blackLight,
      disabledOutline: n.greyDarkest,
    );

    return CoreCategoryPalette.applyTo(
      CoreSyntaxPalette.applyTo(scheme, .dark, function: c.info.lighter),
      .dark,
      highContrast: false,
      white: n.pureWhite,
      black: n.pureBlack,
    );
  }

  // ── Monochrome mapping (black-identity brands) ──────────────────────
  //
  // Retired: CoUI read its generated palette this way before it moved to
  // the fixed `CouiPalette` / `CouiSemanticMapping`. Kept, values unchanged,
  // for the deprecation window.
  //
  // A brand whose identity is black-on-light / white-on-dark
  // keeps its CHROMATIC primary/secondary ramps in the palette — tertiary,
  // status colours and any future chromatic use still draw from them — but
  // resolves the primary/secondary SLOT FAMILIES to the neutral scale
  // instead. Stated as a second mapping rather than a grey-seeded palette
  // because the designer authored it that way in the Figma DS file: the
  // primitives stay chromatic there, and only the semantic aliases go
  // monochrome. A grey-seeded palette would also collapse
  // tertiary/status derivation, which this deliberately does not.
  //
  // Built as `light(c).copyWith(...)` so every slot this mapping does NOT
  // reinterpret stays byte-identical to the standard mapping — the two can
  // never drift apart on the slots they agree about.

  /// Monochrome light mode: primary/secondary families on the neutral
  /// scale, everything else identical to [light].
  @Deprecated(
    'CoUI reads CouiColorPresets.source (its fixed CouiPalette through '
    'CouiSemanticMapping) now; the monochrome reading of a generated '
    'palette is retired (since 0.154).',
  )
  static CoreColorScheme monochromeLight(PrimitiveColors c) {
    final n = c.neutral;
    return light(c).copyWith(
      primary: n.black,
      focusRing: n.black,
      // Measured off the Figma `color/primary-hover` … `secondary-pressed`
      // variables (Light mode: #26272a / #37393c / #3c3e41 / #2b2c2f) and
      // snapped to the neutral ladder — the walk is not one rule:
      // `primary` (black) steps AWAY from the page toward grey, while
      // `secondary` (greyDarkest) steps toward black. Both converge on the
      // same two steps from opposite sides.
      primaryHover: n.blackLight,
      primaryPressed: n.blackLighter,
      secondaryHover: n.blackLighter,
      secondaryPressed: n.blackLight,
      onPrimary: n.white,
      primaryContainer: n.greyLightest,
      onPrimaryContainer: n.black,
      primaryFixed: n.greyLightest,
      primaryFixedDim: n.greyLighter,
      onPrimaryFixed: n.black,
      onPrimaryFixedVariant: n.greyDarkest,
      primaryText: n.black,
      primaryTextLarge: n.black,
      secondary: n.greyDarkest,
      onSecondary: n.white,
      secondaryContainer: n.whiteDarker,
      onSecondaryContainer: n.black,
      secondaryFixed: n.whiteDarker,
      secondaryFixedDim: n.greyLightest,
      onSecondaryFixed: n.black,
      onSecondaryFixedVariant: n.greyDarkest,
      surfaceTint: n.black,
      inversePrimary: n.white,
    );
  }

  /// Monochrome dark mode — [monochromeLight] with the polarity reversed.
  @Deprecated(
    'CoUI reads CouiColorPresets.source (its fixed CouiPalette through '
    'CouiSemanticMapping) now; the monochrome reading of a generated '
    'palette is retired (since 0.154).',
  )
  static CoreColorScheme monochromeDark(PrimitiveColors c) {
    final n = c.neutral;
    return dark(c).copyWith(
      primary: n.white,
      focusRing: n.white,
      // Figma Dark mode: #e7e8ea / #d1d2d3 / #c1c2c5 / #acadb0 — both
      // families step toward the page (darker) here.
      primaryHover: n.whiteDarker,
      primaryPressed: n.greyLightest,
      secondaryHover: n.greyLighter,
      secondaryPressed: n.greyLight,
      onPrimary: n.black,
      primaryContainer: n.blackLighter,
      onPrimaryContainer: n.white,
      primaryFixed: n.greyLightest,
      primaryFixedDim: n.greyLighter,
      onPrimaryFixed: n.black,
      onPrimaryFixedVariant: n.greyDarkest,
      primaryText: n.white,
      primaryTextLarge: n.white,
      secondary: n.greyLightest,
      onSecondary: n.black,
      secondaryContainer: n.blackLight,
      onSecondaryContainer: n.white,
      secondaryFixed: n.whiteDarker,
      secondaryFixedDim: n.greyLightest,
      onSecondaryFixed: n.black,
      onSecondaryFixedVariant: n.greyDarkest,
      surfaceTint: n.white,
      inversePrimary: n.black,
    );
  }

  /// [raiseContrast] for a monochrome-mapped scheme.
  ///
  /// The shared raise moves the accent slots to their darkest CHROMATIC
  /// step, which for a monochrome family is wrong twice over (it would
  /// re-introduce the hue the mapping removed), so the primary/secondary
  /// families are re-stated on the neutral extremes after the shared raise.
  /// Takes an arbitrary [base] for the same reason [raiseContrast] does —
  /// an earlier axis (surface style) must survive into high contrast on the
  /// slots this does not govern.
  @Deprecated(
    'CoUI reads CouiColorPresets.source (its fixed CouiPalette through '
    'CouiSemanticMapping) now; the monochrome reading of a generated '
    'palette is retired (since 0.154).',
  )
  static CoreColorScheme monochromeRaiseContrast(
    CoreColorScheme base,
    PrimitiveColors c,
    CoreBrightness brightness,
  ) {
    final n = c.neutral;
    final raised = raiseContrast(base, c, brightness);
    return brightness == .dark
        ? raised.copyWith(
            primary: n.pureWhite,
            focusRing: n.pureWhite,
            // Figma HC Dark: #eaebec / #d3d4d5 (primary), #e7e8ea / #d1d2d3
            // (secondary) — both families land on the same two neutral steps.
            primaryHover: n.whiteDarker,
            primaryPressed: n.greyLightest,
            secondaryHover: n.whiteDarker,
            secondaryPressed: n.greyLightest,
            primaryContainer: n.greyDarkest,
            onPrimaryContainer: n.pureWhite,
            primaryText: n.pureWhite,
            primaryTextLarge: n.pureWhite,
            secondary: n.white,
            secondaryContainer: n.blackLighter,
            onSecondaryContainer: n.pureWhite,
            surfaceTint: n.pureWhite,
            inversePrimary: n.pureBlack,
          )
        : raised.copyWith(
            primary: n.pureBlack,
            focusRing: n.pureBlack,
            // Figma HC Light: #151617 / #252629 (primary), #26272a / #37393c
            // (secondary).
            primaryHover: n.black,
            primaryPressed: n.blackLight,
            secondaryHover: n.blackLight,
            secondaryPressed: n.blackLighter,
            primaryContainer: n.greyLighter,
            onPrimaryContainer: n.pureBlack,
            primaryText: n.pureBlack,
            primaryTextLarge: n.pureBlack,
            secondary: n.black,
            secondaryContainer: n.greyLightest,
            onSecondaryContainer: n.pureBlack,
            surfaceTint: n.pureBlack,
            inversePrimary: n.pureWhite,
          );
  }

  /// [monochromeLight] with contrast raised (via [monochromeRaiseContrast]).
  @Deprecated(
    'CoUI reads CouiColorPresets.source (its fixed CouiPalette through '
    'CouiSemanticMapping) now; the monochrome reading of a generated '
    'palette is retired (since 0.154).',
  )
  static CoreColorScheme monochromeHighContrastLight(PrimitiveColors c) =>
      monochromeRaiseContrast(monochromeLight(c), c, .light);

  /// [monochromeDark] with contrast raised — [monochromeHighContrastLight]
  /// mirrored.
  @Deprecated(
    'CoUI reads CouiColorPresets.source (its fixed CouiPalette through '
    'CouiSemanticMapping) now; the monochrome reading of a generated '
    'palette is retired (since 0.154).',
  )
  static CoreColorScheme monochromeHighContrastDark(PrimitiveColors c) =>
      monochromeRaiseContrast(monochromeDark(c), c, .dark);

  /// [light] with contrast raised for users who have asked for it.
  ///
  /// This is an override *set*, not a separate theme: it is the same
  /// slots resolved to stronger values, so no component learns that the
  /// preference exists. That is only affordable because the semantic tier
  /// already exists — without it every component would need its own
  /// high-contrast branch.
  ///
  /// Two things are deliberately **not** done here.
  ///
  /// Surface tones are not collapsed to pure white. It is tempting, since
  /// maximum contrast is the goal, but components differentiate cards,
  /// inputs and popovers by *background tone* and only some of them draw a
  /// border. Flattening the tones would erase those boundaries and leave
  /// nothing to replace them — a component that becomes invisible has worse
  /// contrast than one that was merely low.
  ///
  /// Foregrounds are not flipped to whichever of black/white contrasts more.
  /// Instead the filled surfaces move to the darkest chromatic step and keep
  /// a white foreground. Flipping polarity per role would make the same
  /// component read light-on-dark in one place and dark-on-light in another,
  /// which is a legibility problem of its own.
  static CoreColorScheme highContrastLight(PrimitiveColors c) =>
      raiseContrast(light(c), c, .light);

  /// [dark] with contrast raised for users who have asked for it.
  ///
  /// Mirrors [highContrastLight] with the polarity reversed — filled
  /// surfaces move to the *lightest* chromatic step and take a black
  /// foreground.
  static CoreColorScheme highContrastDark(PrimitiveColors c) =>
      raiseContrast(dark(c), c, .dark);

  /// Raises the contrast of an arbitrary [base] scheme.
  ///
  /// Takes a scheme rather than rebuilding one from the palette so that a
  /// theme axis applied earlier — a surface style bending accent colours,
  /// say — survives into high contrast on the slots this does not touch,
  /// while the slots it does touch are decided here. That ordering is the
  /// point: a decorative axis must not be able to undo a contrast increase
  /// the user explicitly asked for.
  static CoreColorScheme raiseContrast(
    CoreColorScheme base,
    PrimitiveColors c,
    CoreBrightness brightness,
  ) => brightness == .dark ? _raiseDark(base, c) : _raiseLight(base, c);

  static CoreColorScheme _raiseLight(CoreColorScheme base, PrimitiveColors c) {
    final n = c.neutral;

    final raised = base.copyWith(
      // Filled surfaces darken so a white foreground clears 4.5:1 — the
      // normal palette does not for tertiary / success / info.
      // Body text goes to the ends of the scale.
      onSurface: n.pureBlack,
      onSurfaceVariant: n.blackLight,
      // High contrast collapses the placeholder toward the value it
      // stands in for (1.84:1 against `onSurface`) — legibility beats
      // hierarchy here, so the two stop being separable by colour. The
      // distinction has to be carried by something else in this mode.
      placeholder: n.blackLighter,
      onSurfaceSubtle: n.blackLighter,
      link: c.info.darkest,
      primary: c.primary.darkest,
      onPrimary: n.pureWhite,
      primaryText: c.primary.darkest,
      primaryTextLarge: c.primary.darkest,
      secondary: c.secondary.darkest,
      onSecondary: n.pureWhite,
      tertiary: c.tertiary.darkest,
      onTertiary: n.pureWhite,
      error: c.error.darkest,
      onError: n.pureWhite,
      // High contrast already pushes `error` itself to `darkest` — the
      // pressed step has no further step to move to, so it pins to the
      // same value (measured: this equals Figma's HCLight `error-strong`).
      errorStrong: c.error.darkest,
      // `errorStrong` pins because it had nowhere darker to go; the
      // hover/pressed walk instead steps back toward `base` — that is what
      // Figma's HC Light `error-pressed` (`dark`) measures, and the
      // primary/secondary families follow the same shape.
      errorPressed: c.error.dark,
      primaryHover: c.primary.darker,
      primaryPressed: c.primary.dark,
      secondaryHover: c.secondary.darker,
      secondaryPressed: c.secondary.dark,
      focusRing: c.primary.darkest,
      success: c.success.darkest,
      onSuccess: n.pureWhite,
      warning: c.warning.darkest,
      onWarning: n.pureWhite,
      info: c.info.darkest,
      onInfo: n.pureWhite,
      // Status indicators follow the raised status fill.
      errorIcon: c.error.darkest,
      successIcon: c.success.darkest,
      warningIcon: c.warning.darkest,
      infoIcon: c.info.darkest,
      // Boundaries carry the structure once colour differences shrink, so
      // they move furthest: `outline` is 2.14:1 in the normal set, which is
      // below the 3:1 that component boundaries are meant to clear.
      outline: n.greyDarkest,
      outlineVariant: n.greyDark,
      outlineSubtle: n.greyDark,
      // Disabled stays visibly muted but becomes legible rather than faint.
      disabledContent: n.greyDarkest,
      disabledOutline: n.greyDark,
    );

    // The category slots are written whole, every one of them: a slot left
    // to `base` would keep its normal value under high contrast. The syntax
    // slots are the opposite case — high contrast keeps their normal values,
    // so they are left to `base`.
    return CoreCategoryPalette.applyTo(
      raised,
      .light,
      highContrast: true,
      white: n.pureWhite,
      black: n.pureBlack,
    );
  }

  static CoreColorScheme _raiseDark(CoreColorScheme base, PrimitiveColors c) {
    final n = c.neutral;

    final raised = base.copyWith(
      onSurface: n.pureWhite,
      onSurfaceVariant: n.whiteDark,
      // 1.26:1 against `onSurface` — see `_raiseLight`.
      placeholder: n.whiteDarker,
      onSurfaceSubtle: n.whiteDarker,
      link: c.info.lightest,
      primary: c.primary.lightest,
      onPrimary: n.pureBlack,
      primaryText: c.primary.lightest,
      primaryTextLarge: c.primary.lightest,
      secondary: c.secondary.lightest,
      onSecondary: n.pureBlack,
      tertiary: c.tertiary.lightest,
      onTertiary: n.pureBlack,
      error: c.error.lightest,
      onError: n.pureBlack,
      // Dark high-contrast still has a step to move to (unlike light's
      // pinned `darkest`) — one step back toward `base`, matching Figma's
      // HCDark `error-strong`.
      errorStrong: c.error.light,
      // Mirror of `_raiseLight` — `error-pressed` measured `light` in
      // Figma's HC Dark mode (#f3a8a8), two steps back from `lightest`.
      errorPressed: c.error.light,
      primaryHover: c.primary.lighter,
      primaryPressed: c.primary.light,
      secondaryHover: c.secondary.lighter,
      secondaryPressed: c.secondary.light,
      focusRing: c.primary.lightest,
      success: c.success.lightest,
      onSuccess: n.pureBlack,
      warning: c.warning.lightest,
      onWarning: n.pureBlack,
      info: c.info.lightest,
      onInfo: n.pureBlack,
      // Status indicators follow the raised status fill.
      errorIcon: c.error.lightest,
      successIcon: c.success.lightest,
      warningIcon: c.warning.lightest,
      infoIcon: c.info.lightest,
      outline: n.greyLightest,
      outlineVariant: n.greyLight,
      outlineSubtle: n.greyLight,
      disabledContent: n.greyLightest,
      disabledOutline: n.greyLight,
    );

    return CoreCategoryPalette.applyTo(
      raised,
      .dark,
      highContrast: true,
      white: n.pureWhite,
      black: n.pureBlack,
    );
  }
}
