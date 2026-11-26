import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/internal/input_focus_border_paint.dart';
import 'package:coui_web/src/internal/selection_paint.dart';
import 'package:coui_web/src/internal/text_area_border_paint.dart';
import 'package:coui_web/src/internal/text_area_boundary_paint.dart';
import 'package:coui_web/src/util/core_to_css.dart'
    show
        CoreCubicBezierToCss,
        CoreRadiusValueToTailwind,
        CoreShadowLayersToCss,
        durationMsCss,
        kActiveBoundaryMarker,
        kActiveBoundaryVar,
        kActiveBoundaryWithinMarker,
        kDiffDraggingAttribute,
        kDiffHandleDiscMarker,
        kDiffHandleDurationVar,
        kDiffHandleHoverShadowVar,
        kDiffHandleMarker,
        kDiffHandlePressedScaleVar,
        kDiffHandlePressedShadowVar,
        kDiffHandleShadowVar,
        kDiffHandleStripMarker,
        kFocusBandMarker,
        kFocusBandVar,
        kRadiusSteps,
        kShadowStrengthVariable,
        kStateLayerHoverMarker,
        kStateLayerHoverVar,
        kSurfaceRimVar,
        strokeWidthCss,
        surfaceEdgeSheenCss;
import 'package:coui_web/src/util/web_constants.dart'
    show
        kControlBorderMarker,
        kControlChromeDurationVar,
        kControlEngageDurationVar,
        kControlPressScaleMarker,
        kControlPressScaleVar,
        kControlPressShrinkVar,
        kControlShadowPressMarker,
        kControlShadowRestMarker,
        kFadeBoxClass,
        kFadeGlassLayerNameVar,
        kFadeGlassPaintNameVar,
        kFadeLayerAnimationVar,
        kFadeNoAnimation,
        kFadeOpacityAnimationVar,
        kFadeOpacityNameVar,
        kFadePaintAnimationVar,
        kFadePanelClass,
        kFadeProgressVar,
        kPercentScale,
        kSkeletonPulseAnimationName,
        kSkeletonPulseNameVar,
        kSkeletonRestAnimationName,
        kSurfaceRimLiftMarker,
        kTransitionMotionFactorVar,
        kWebLocalSurfaceMarker,
        kWebSurfaceBleedBottomVar,
        kWebSurfaceBleedTopVar,
        kWebSurfaceBleedVar,
        kWebSurfaceClipMarker,
        kWebSurfaceClipPadVar,
        kWebSurfaceEdgeStyleVar,
        kWebSurfaceFillAlphaVar,
        kWebSurfaceFillVar,
        kWebSurfaceFoldVar,
        kWebSurfaceFrostVar,
        kWebSurfaceMarker,
        kWebSurfacePassVar,
        kWebSurfaceRefractionModelVar,
        kWebSurfaceRimAngleDarkVar,
        kWebSurfaceRimAngleVar,
        kWebSurfaceRimSweepDarkVar,
        kWebSurfaceRimSweepVar,
        kWebSurfaceRoleContent,
        kWebSurfaceRoleFunctional,
        kWebSurfaceShadeVar,
        kWebSvgBackdropAttribute,
        kWebSvgBackdropOff,
        kWebTouchTargetMarker,
        kWebTouchTargetVar;

/// CoUI Web theme configuration generator.
///
/// Generates Tailwind CSS config and CSS variables from a
/// [CoreSchemeSource], providing the bridge between coui_core
/// tokens and Tailwind utility classes.
///
/// Usage in a Jaspr project — CoUI's own colours:
/// ```dart
/// final config = ThemeConfig.defaults();
///
/// // In <head>:
/// // <script>{config.tailwindConfig}</script>
/// // <style>{config.cssVariables}</style>
/// ```
///
/// Or a brand's generated palette:
/// ```dart
/// final config = ThemeConfig(PrimitiveColors.generate(...));
/// ```
///
/// The declaration body `ThemeConfig._controlShadowPressRule`'s two
/// `@media (hover: …)`-gated engage triggers share — hiding the rest
/// shadow and travelling into the space it vacated is one effect with two
/// triggers, not two effects, so it is written once here (top-level, the
/// same pattern `coui_web.dart` uses for `_kPressTransform` /
/// `_kPressShadow` to keep a `ThemeConfig`-class field from following a
/// private method and tripping `member-ordering`) and referenced from
/// both `@media` blocks. A hand-edit to only one copy is exactly the
/// drift a shared constant rules out.
const _kEngageShadowDeclarations =
    'box-shadow:var(--coui-control-shadow-press,'
    'var(--coui-button-rest-shadow))'
    ' !important;translate:var(--coui-control-shadow-offset-x)'
    ' var(--coui-control-shadow-offset-y);';

/// [ThemeConfig._kShadowColorBase] at zero alpha, colour channel
/// preserved — `kControlShadowGhostVar`'s base.
///
/// The rgb slash-alpha form (`rgb(X / 0%)`, the same pattern
/// `CoreColorToCss.toValue` already uses for a translucent token), not
/// `color-mix(in srgb, X 0%, transparent)`. `color-mix` at 0% of the
/// first colour is defined as exactly the second colour — here
/// `transparent`, whose own colour channel is `0 0 0` — so it drops
/// [ThemeConfig._kShadowColorBase]'s RGB entirely rather than keeping it
/// at zero
/// alpha. Measured in a real browser: the ghost read back as
/// `color(srgb 0 0 0 / 0)` against a real cast of `rgb(255 255 255)` —
/// different colours, not the same colour at different alphas — which
/// is the mismatched-shape hazard `kControlShadowGhostVar` exists to
/// avoid, just moved from geometry into the colour channel.
///
/// Top-level rather than a `ThemeConfig` field for the same reason
/// [_kEngageShadowDeclarations] above is — see that constant's doc
/// comment.
const _kShadowColorGhostBase = 'rgb(var(--coui-shadow) / 0%)';

/// The declaration body `ThemeConfig._controlPressScaleRule`'s two
/// `@media (hover: …)` triggers share — one effect with two triggers,
/// written once for the same reason [_kEngageShadowDeclarations] is.
const _kPressScaleDeclaration =
    'scale:calc(1 - (1 - var($kControlPressScaleVar,1)) * '
    'var($kControlPressShrinkVar,1));';

/// The press trigger on a hover-capable pointer — `:active` held while
/// still over the control, so dragging a press off it releases it.
const _kPressScaleHoverSelector =
    '.$kControlPressScaleMarker:active:hover:not(:disabled)';

/// The press trigger on a touch pointer, where `:hover` is unreliable.
const _kPressScaleTouchSelector =
    '.$kControlPressScaleMarker:active:not(:disabled)';

/// The light high-contrast block's selector — the doubled `:root` for rank,
/// and a `:where()`-wrapped exclusion of an explicitly dark page that adds
/// none. Why both, in [ThemeConfig.cssVariables].
const _kLightHighContrastSelector =
    ':root:root:where(:not([data-theme="dark"]))';

/// The stylesheet side of a CoUI web theme — the Tailwind config and the
/// CSS variable blocks every component's classes and inline styles resolve
/// through, generated from one colour source.
class ThemeConfig {
  /// Creates theme config from a brand's generated [PrimitiveColors].
  ///
  /// [mapping] is the brand's Primitive → Semantic interpretation — the
  /// palette says what colours exist, the mapping says what each semantic
  /// slot means, and the pair travels together.
  const ThemeConfig(
    PrimitiveColors this._colors, {
    this.surfaceTunings = const {},
    this.typography = CoreTypography.coui,
    CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
  }) : _mapping = mapping,
       _statedSource = null;

  /// Creates theme config from a colour [source] that is not a generated
  /// palette — CoUI's own `CouiColorPresets.source`, for one.
  const ThemeConfig.from(
    CoreSchemeSource source, {
    this.surfaceTunings = const {},
    this.typography = CoreTypography.coui,
  }) : _statedSource = source,
       _colors = null,
       _mapping = null;

  /// Creates theme config with CoUI's own colours —
  /// [CouiColorPresets.source], the fixed palette read through CoUI's own
  /// mapping, which is the CoUI look.
  factory ThemeConfig.defaults() =>
      const ThemeConfig.from(CouiColorPresets.source);

  // A const constructor cannot build the source from its parameters, so a
  // palette config keeps the pair and [_source] wraps it on read.
  final PrimitiveColors? _colors;

  final CoreSemanticMappingSet? _mapping;

  final CoreSchemeSource? _statedSource;

  /// The colours every block below is generated from.
  CoreSchemeSource get _source =>
      _statedSource ?? CorePrimitiveSchemeSource(_colors!, _mapping!);

  /// What this app changes about each surface style.
  ///
  /// Read at stylesheet-generation time rather than at render time, which
  /// is the whole reason Web needs no new transport for this feature: the
  /// per-style rules already emit *resolved* values — a bent radius, a
  /// floored stroke, an offset pair — so a tuned recipe reaches the
  /// browser as different numbers in the same variables.
  ///
  /// It follows that a tuning is a build-time decision here. Style
  /// *switching* stays an attribute flip because a preset is a closed set
  /// of names; a tuning is a continuous value, and an attribute cannot
  /// select one without a selector per value.
  final Map<CoreSurfaceStyleId, CoreSurfaceTuning> surfaceTunings;

  /// What this app's text roles are made of — the composition the
  /// `text-{role}` classes read. Defaults to CoUI's own scale.
  ///
  /// This is the route a role's own font family takes to the browser
  /// (`CoreTypography.withFamily` — a product's display face on its
  /// headings): the stylesheet is generated from it. The runtime
  /// custom-theme path carries colour and corners only, so a face set there
  /// would not reach the page.
  final CoreTypography typography;

  /// The typography block for [typography] — the cached default block when
  /// this config keeps CoUI's own scale.
  String get _typographyCss => identical(typography, CoreTypography.coui)
      ? _typographyCssBlock
      : typographyCssBlock(typography);

  /// The recipe for [id] with this app's tuning folded in.
  ///
  /// Goes through the shared seat rather than folding here, so Web and
  /// Flutter cannot disagree about what a tuned preset is.
  CoreSurfaceRecipe _recipeFor(CoreSurfaceStyleId id) => resolveThemeRecipe(
    surfaceStyle: id,
    surfaceTuning: surfaceTunings[id] ?? CoreSurfaceTuning.none,
  );

  // ── Screens (Responsive Breakpoint) Config ──────────────────
  // Single-source: every `sm:`/`md:`/`lg:`/`xl:`/`2xl:` utility variant
  // resolves through `CoreBreakpoint`, the same enum `Breakpoint` (Web)
  // and its Flutter counterpart read for viewport-tier judgement.
  // Tailwind's own built-in `screens` scale happens to carry the same
  // five numbers, which is why nothing looked broken before this was
  // wired — but without this key, moving `CoreBreakpoint` would move
  // Flutter and silently leave every `sm:`/`md:` class on Web still
  // keyed to Tailwind's unrelated default scale (#3776).
  //
  // `CoreBreakpoint.xs` (0px — the unprefixed, mobile-first base) has no
  // entry here: Tailwind has no default `xs:` variant, and a
  // `(min-width:0px)` media query would always match, so adding one
  // would introduce a new variant rather than wire an existing one.
  static final _screensConfig =
      'sm:"${CoreBreakpoint.sm.minWidth.toInt()}px",'
      'md:"${CoreBreakpoint.md.minWidth.toInt()}px",'
      'lg:"${CoreBreakpoint.lg.minWidth.toInt()}px",'
      'xl:"${CoreBreakpoint.xl.minWidth.toInt()}px",'
      // `2xl` starts with a digit — invalid unquoted JS object key.
      '"2xl":"${CoreBreakpoint.xxl.minWidth.toInt()}px"';

  // ── Tailwind Colors Config ──────────────────────────────────

  static const _colorsConfig =
      // M3 Semantic tokens — rgb() wrapper enables Tailwind opacity modifier.
      'surface:"rgb(var(--coui-surface))",'
      '"surface-dim":"rgb(var(--coui-surface-dim))",'
      '"surface-bright":"rgb(var(--coui-surface-bright))",'
      '"surface-tint":"rgb(var(--coui-surface-tint))",'
      '"on-surface":"rgb(var(--coui-on-surface))",'
      '"on-surface-variant":"rgb(var(--coui-on-surface-variant))",'
      'placeholder:"rgb(var(--coui-placeholder))",'
      'link:"rgb(var(--coui-link))",'
      '"on-surface-subtle":"rgb(var(--coui-on-surface-subtle))",'
      '"surface-raised":"rgb(var(--coui-surface-raised))",'
      '"surface-container-lowest":'
      '"rgb(var(--coui-surface-container-lowest))",'
      '"surface-container-low":'
      '"rgb(var(--coui-surface-container-low))",'
      '"surface-container":"rgb(var(--coui-surface-container))",'
      '"surface-container-high":'
      '"rgb(var(--coui-surface-container-high))",'
      '"surface-container-highest":'
      '"rgb(var(--coui-surface-container-highest))",'
      'primary:"rgb(var(--coui-primary))",'
      '"on-primary":"rgb(var(--coui-on-primary))",'
      '"primary-container":"rgb(var(--coui-primary-container))",'
      '"on-primary-container":'
      '"rgb(var(--coui-on-primary-container))",'
      '"primary-text":"rgb(var(--coui-primary-text))",'
      '"primary-text-large":"rgb(var(--coui-primary-text-large))",'
      'secondary:"rgb(var(--coui-secondary))",'
      '"on-secondary":"rgb(var(--coui-on-secondary))",'
      '"secondary-container":'
      '"rgb(var(--coui-secondary-container))",'
      '"on-secondary-container":'
      '"rgb(var(--coui-on-secondary-container))",'
      'tertiary:"rgb(var(--coui-tertiary))",'
      '"on-tertiary":"rgb(var(--coui-on-tertiary))",'
      '"tertiary-container":"rgb(var(--coui-tertiary-container))",'
      '"on-tertiary-container":'
      '"rgb(var(--coui-on-tertiary-container))",'
      // The `-fixed` family: slots for a surface that must not follow the
      // theme. Registered because a class only exists if it is named here —
      // without an entry, a `bg-primary-fixed-dim` on an element finds its
      // CSS variable present and still paints nothing.
      '"primary-fixed":"rgb(var(--coui-primary-fixed))",'
      '"primary-fixed-dim":"rgb(var(--coui-primary-fixed-dim))",'
      '"on-primary-fixed":"rgb(var(--coui-on-primary-fixed))",'
      '"on-primary-fixed-variant":'
      '"rgb(var(--coui-on-primary-fixed-variant))",'
      '"secondary-fixed":"rgb(var(--coui-secondary-fixed))",'
      '"secondary-fixed-dim":"rgb(var(--coui-secondary-fixed-dim))",'
      '"on-secondary-fixed":"rgb(var(--coui-on-secondary-fixed))",'
      '"on-secondary-fixed-variant":'
      '"rgb(var(--coui-on-secondary-fixed-variant))",'
      '"tertiary-fixed":"rgb(var(--coui-tertiary-fixed))",'
      '"tertiary-fixed-dim":"rgb(var(--coui-tertiary-fixed-dim))",'
      '"on-tertiary-fixed":"rgb(var(--coui-on-tertiary-fixed))",'
      '"on-tertiary-fixed-variant":'
      '"rgb(var(--coui-on-tertiary-fixed-variant))",'
      // Same slots as tertiary / on-tertiary. Registered because a class
      // only exists if it is named here — `bg-accent` would otherwise
      // paint nothing while the CSS variable exists.
      'accent:"rgb(var(--coui-accent))",'
      '"on-accent":"rgb(var(--coui-on-accent))",'
      'error:"rgb(var(--coui-error))",'
      // Registered because a class only exists if it is named here. The
      // CSS variable is generated either way, so a missing entry produces
      // markup that looks right and paints nothing — which is exactly how
      // `bg-error-strong` shipped inert.
      '"error-strong":"rgb(var(--coui-error-strong))",'
      '"focus-ring":"rgb(var(--coui-focus-ring))",'
      '"primary-hover":"rgb(var(--coui-primary-hover))",'
      '"primary-pressed":"rgb(var(--coui-primary-pressed))",'
      '"secondary-hover":"rgb(var(--coui-secondary-hover))",'
      '"secondary-pressed":"rgb(var(--coui-secondary-pressed))",'
      '"error-pressed":"rgb(var(--coui-error-pressed))",'
      '"on-error":"rgb(var(--coui-on-error))",'
      '"error-container":"rgb(var(--coui-error-container))",'
      '"on-error-container":'
      '"rgb(var(--coui-on-error-container))",'
      'success:"rgb(var(--coui-success))",'
      '"on-success":"rgb(var(--coui-on-success))",'
      '"success-container":"rgb(var(--coui-success-container))",'
      '"on-success-container":'
      '"rgb(var(--coui-on-success-container))",'
      'warning:"rgb(var(--coui-warning))",'
      '"on-warning":"rgb(var(--coui-on-warning))",'
      '"warning-container":"rgb(var(--coui-warning-container))",'
      '"on-warning-container":'
      '"rgb(var(--coui-on-warning-container))",'
      'info:"rgb(var(--coui-info))",'
      '"on-info":"rgb(var(--coui-on-info))",'
      '"info-container":"rgb(var(--coui-info-container))",'
      '"on-info-container":'
      '"rgb(var(--coui-on-info-container))",'
      '"error-icon":"rgb(var(--coui-error-icon))",'
      '"success-icon":"rgb(var(--coui-success-icon))",'
      '"warning-icon":"rgb(var(--coui-warning-icon))",'
      '"info-icon":"rgb(var(--coui-info-icon))",'
      'outline:"rgb(var(--coui-outline))",'
      '"outline-variant":"rgb(var(--coui-outline-variant))",'
      '"outline-subtle":"rgb(var(--coui-outline-subtle))",'
      '"inverse-surface":"rgb(var(--coui-inverse-surface))",'
      '"inverse-on-surface":'
      '"rgb(var(--coui-inverse-on-surface))",'
      '"inverse-primary":"rgb(var(--coui-inverse-primary))",'
      'shadow:"rgb(var(--coui-shadow))",'
      'scrim:"rgb(var(--coui-scrim))",'
      // Disabled — a fixed token instead of an opacity multiplier, so the
      // contrast does not depend on the surface underneath.
      '"disabled-content":"rgb(var(--coui-disabled-content))",'
      '"disabled-container":"rgb(var(--coui-disabled-container))",'
      '"disabled-outline":"rgb(var(--coui-disabled-outline))",'
      // Syntax — code highlighting.
      '"syntax-keyword":"rgb(var(--coui-syntax-keyword))",'
      '"syntax-type":"rgb(var(--coui-syntax-type))",'
      '"syntax-function":"rgb(var(--coui-syntax-function))",'
      '"syntax-string":"rgb(var(--coui-syntax-string))"';

  // The category colours — every hue's five slots (`bg-category-red`,
  // `text-on-category-red-container`, `border-category-red-outline`, …).
  // Walked off the same enums the CSS variables are emitted from, so a
  // class can name exactly the slots that have a variable. Keys are
  // JS-quoted: every one holds a `-`.
  static final String _categoryColorsConfig = [
    for (final color in CoreCategoryColor.values)
      for (final slot in CoreCategorySlot.values) color.token(slot).name,
  ].map((name) => '"$name":"rgb(var(--coui-$name))"').join(',');

  // ── Border Radius Config ────────────────────────────────────
  // Single-source: each Tailwind class key resolves to the matching
  // `--coui-radius-N` CSS variable so component overrides only need
  // to touch the variable.

  static final _borderRadiusConfig =
      '${CoreRadius.scale.radius0}:"var(--coui-radius-0)",'
      '${CoreRadius.scale.radius2}:"var(--coui-radius-2)",'
      '${CoreRadius.scale.radius4}:"var(--coui-radius-4)",'
      '${CoreRadius.scale.radius6}:"var(--coui-radius-6)",'
      '${CoreRadius.scale.radius8}:"var(--coui-radius-8)",'
      '${CoreRadius.scale.radius10}:"var(--coui-radius-10)",'
      '${CoreRadius.scale.radius12}:"var(--coui-radius-12)",'
      '${CoreRadius.scale.radius14}:"var(--coui-radius-14)",'
      '${CoreRadius.scale.radius16}:"var(--coui-radius-16)",'
      '${CoreRadius.scale.radius20}:"var(--coui-radius-20)",'
      '${CoreRadius.scale.radius24}:"var(--coui-radius-24)",'
      '${CoreRadius.scale.radius28}:"var(--coui-radius-28)",'
      '${CoreRadius.scale.radius32}:"var(--coui-radius-32)",'
      '${CoreRadius.scale.radius36}:"var(--coui-radius-36)",'
      '${CoreRadius.scale.radius40}:"var(--coui-radius-40)",'
      '${CoreRadius.scale.radius48}:"var(--coui-radius-48)",'
      '${CoreRadius.scale.radius56}:"var(--coui-radius-56)",'
      '${CoreRadius.scale.radius64}:"var(--coui-radius-64)",'
      '${CoreRadius.scale.radius9999}:"var(--coui-radius-9999)"';

  // ── Box Shadow Config ───────────────────────────────────────
  // Overrides Tailwind's built-in `shadow-*` scale (fixed black alpha)
  // with the designer's 9 semantic shadows, each sourced from
  // the matching `--shadow-*` CSS variable (single source — see
  // `_shadowCssVariables`). Existing `shadow-sm/md/lg` emit sites resolve
  // to the spec values without per-site changes.

  // Keys are quoted — `2xl` / `3xl` start with a digit, which is an
  // invalid unquoted JS object key in the emitted `tailwind.config={...}`.
  static final _boxShadowConfig =
      '"${CoreShadow.scale.none}":"var(--shadow-${CoreShadow.scale.none})",'
      '"${CoreShadow.scale.xs}":"var(--shadow-${CoreShadow.scale.xs})",'
      '"${CoreShadow.scale.sm}":"var(--shadow-${CoreShadow.scale.sm})",'
      '"${CoreShadow.scale.md}":"var(--shadow-${CoreShadow.scale.md})",'
      '"${CoreShadow.scale.lg}":"var(--shadow-${CoreShadow.scale.lg})",'
      '"${CoreShadow.scale.xl}":"var(--shadow-${CoreShadow.scale.xl})",'
      '"${CoreShadow.scale.xl2}":"var(--shadow-${CoreShadow.scale.xl2})",'
      '"${CoreShadow.scale.xl3}":"var(--shadow-${CoreShadow.scale.xl3})",'
      '"${CoreShadow.scale.inset}":"var(--shadow-${CoreShadow.scale.inset})"';

  // ── Font Size Config ──────────────────────────────────────
  // Single-source via `--coui-font-size-N` CSS variables.

  // Tailwind keys sourced from CoreFontSize.scale (single source of truth,
  // matching the dimensional tokens). CSS variable VALUES come from the
  // direct token members (see _tokenCssVariables below).
  static final _fontSizeConfig =
      '${CoreFontSize.scale.s10}:"var(--coui-font-size-10)",'
      '${CoreFontSize.scale.s11}:"var(--coui-font-size-11)",'
      '${CoreFontSize.scale.s12}:"var(--coui-font-size-12)",'
      '${CoreFontSize.scale.s13}:"var(--coui-font-size-13)",'
      '${CoreFontSize.scale.s14}:"var(--coui-font-size-14)",'
      '${CoreFontSize.scale.s15}:"var(--coui-font-size-15)",'
      '${CoreFontSize.scale.s16}:"var(--coui-font-size-16)",'
      '${CoreFontSize.scale.s18}:"var(--coui-font-size-18)",'
      '${CoreFontSize.scale.s20}:"var(--coui-font-size-20)",'
      '${CoreFontSize.scale.s24}:"var(--coui-font-size-24)",'
      '${CoreFontSize.scale.s28}:"var(--coui-font-size-28)",'
      '${CoreFontSize.scale.s32}:"var(--coui-font-size-32)",'
      '${CoreFontSize.scale.s36}:"var(--coui-font-size-36)",'
      '${CoreFontSize.scale.s40}:"var(--coui-font-size-40)",'
      '${CoreFontSize.scale.s44}:"var(--coui-font-size-44)",'
      '${CoreFontSize.scale.s48}:"var(--coui-font-size-48)",'
      '${CoreFontSize.scale.s52}:"var(--coui-font-size-52)",'
      '${CoreFontSize.scale.s60}:"var(--coui-font-size-60)",'
      '${CoreFontSize.scale.s72}:"var(--coui-font-size-72)",'
      '${CoreFontSize.scale.s96}:"var(--coui-font-size-96)",'
      '${CoreFontSize.scale.s128}:"var(--coui-font-size-128)"';

  // ── Font Weight Config ────────────────────────────────────
  // Values from CoreFontWeight (CSS standard 100-900).

  static final _fontWeightConfig =
      '${CoreFontWeight.scale.thin}:"var(--coui-font-weight-thin)",'
      '${CoreFontWeight.scale.extralight}:"var(--coui-font-weight-extralight)",'
      '${CoreFontWeight.scale.light}:"var(--coui-font-weight-light)",'
      '${CoreFontWeight.scale.regular}:"var(--coui-font-weight-regular)",'
      '${CoreFontWeight.scale.medium}:"var(--coui-font-weight-medium)",'
      '${CoreFontWeight.scale.semibold}:"var(--coui-font-weight-semibold)",'
      '${CoreFontWeight.scale.bold}:"var(--coui-font-weight-bold)",'
      '${CoreFontWeight.scale.extrabold}:"var(--coui-font-weight-extrabold)",'
      '${CoreFontWeight.scale.black}:"var(--coui-font-weight-black)"';

  // ── Line Height Config ────────────────────────────────────

  static final _lineHeightConfig =
      '${CoreLineHeight.scale.h100}:"var(--coui-line-height-100)",'
      '${CoreLineHeight.scale.h120}:"var(--coui-line-height-120)",'
      '${CoreLineHeight.scale.h140}:"var(--coui-line-height-140)",'
      '${CoreLineHeight.scale.h150}:"var(--coui-line-height-150)",'
      '${CoreLineHeight.scale.h160}:"var(--coui-line-height-160)",'
      '${CoreLineHeight.scale.h180}:"var(--coui-line-height-180)",'
      '${CoreLineHeight.scale.h200}:"var(--coui-line-height-200)"';

  // ── Letter Spacing Config ─────────────────────────────────

  static final _letterSpacingConfig =
      '${CoreLetterSpacing.scale.tighter}:"var(--coui-letter-spacing-tighter)",'
      '${CoreLetterSpacing.scale.tight}:"var(--coui-letter-spacing-tight)",'
      '${CoreLetterSpacing.scale.tight20}:"var(--coui-letter-spacing-tight20)",'
      '${CoreLetterSpacing.scale.tight15}:"var(--coui-letter-spacing-tight15)",'
      '${CoreLetterSpacing.scale.tight10}:"var(--coui-letter-spacing-tight10)",'
      '${CoreLetterSpacing.scale.tight5}:"var(--coui-letter-spacing-tight5)",'
      '${CoreLetterSpacing.scale.normal}:"var(--coui-letter-spacing-normal)",'
      '${CoreLetterSpacing.scale.wide}:"var(--coui-letter-spacing-wide)",'
      '${CoreLetterSpacing.scale.wider}:"var(--coui-letter-spacing-wider)",'
      '${CoreLetterSpacing.scale.widest}:"var(--coui-letter-spacing-widest)"';

  // ── Semantic Typography Config ────────────────────────────
  // text-{role} → fontSize + lineHeight + fontWeight + letterSpacing.
  // Tailwind fontSize array: ["size", {lineHeight, fontWeight, letterSpacing}].
  //
  // Each property references a per-role CSS variable
  // (`--coui-text-{role}-{size,line-height,weight,tracking}`) emitted from
  // `CoreTypography` by this stylesheet alone — `cssVariables`, from
  // `typography`; the runtime theme path (`CssVariableGenerator.runtimeVars`)
  // leaves the roles out — so a project-supplied `theme.typography` drives
  // the role composition on Web identically to Flutter (#2624). The role
  // entries are generated rather than hand-listed so they stay 1:1 with
  // every `CoreTextStyles` token.
  //
  // The role's rendered line height is defined in typographyCssBlock,
  // alongside the source variables and inherited leading. Replacing that
  // block can change the role's multiplier/length type without rebuilding
  // Tailwind. Its expression still reads the original public source live.
  static final String _semanticFontSizeConfig = CoreTextStyles.values
      .map(
        (token) =>
            '"${token.name}":["var(--coui-text-${token.name}-size)",'
            '{lineHeight:"var(--coui-text-${token.name}-rendered-line-height)",'
            'fontWeight:"var(--coui-text-${token.name}-weight)",'
            'letterSpacing:"var(--coui-text-${token.name}-tracking)"}]',
      )
      .join(',');

  static final _spacingConfig =
      '${CoreSpace.scale.space0}:"var(--coui-space-0)",'
      '${CoreSpace.scale.space2}:"var(--coui-space-2)",'
      '${CoreSpace.scale.space4}:"var(--coui-space-4)",'
      '${CoreSpace.scale.space6}:"var(--coui-space-6)",'
      '${CoreSpace.scale.space8}:"var(--coui-space-8)",'
      '${CoreSpace.scale.space10}:"var(--coui-space-10)",'
      '${CoreSpace.scale.space12}:"var(--coui-space-12)",'
      '${CoreSpace.scale.space14}:"var(--coui-space-14)",'
      '${CoreSpace.scale.space16}:"var(--coui-space-16)",'
      '${CoreSpace.scale.space18}:"var(--coui-space-18)",'
      '${CoreSpace.scale.space20}:"var(--coui-space-20)",'
      '${CoreSpace.scale.space24}:"var(--coui-space-24)",'
      '${CoreSpace.scale.space28}:"var(--coui-space-28)",'
      '${CoreSpace.scale.space32}:"var(--coui-space-32)",'
      '${CoreSpace.scale.space36}:"var(--coui-space-36)",'
      '${CoreSpace.scale.space40}:"var(--coui-space-40)",'
      '${CoreSpace.scale.space44}:"var(--coui-space-44)",'
      '${CoreSpace.scale.space48}:"var(--coui-space-48)",'
      '${CoreSpace.scale.space52}:"var(--coui-space-52)",'
      '${CoreSpace.scale.space56}:"var(--coui-space-56)",'
      '${CoreSpace.scale.space60}:"var(--coui-space-60)",'
      '${CoreSpace.scale.space64}:"var(--coui-space-64)",'
      '${CoreSpace.scale.space72}:"var(--coui-space-72)",'
      '${CoreSpace.scale.space80}:"var(--coui-space-80)",'
      '${CoreSpace.scale.space88}:"var(--coui-space-88)",'
      '${CoreSpace.scale.space96}:"var(--coui-space-96)",'
      '${CoreSpace.scale.space104}:"var(--coui-space-104)",'
      '${CoreSpace.scale.space112}:"var(--coui-space-112)",'
      '${CoreSpace.scale.space120}:"var(--coui-space-120)",'
      '${CoreSpace.scale.space128}:"var(--coui-space-128)",'
      '${CoreSpace.scale.space136}:"var(--coui-space-136)",'
      '${CoreSpace.scale.space144}:"var(--coui-space-144)",'
      '${CoreSpace.scale.space152}:"var(--coui-space-152)",'
      '${CoreSpace.scale.space160}:"var(--coui-space-160)",'
      '${CoreSpace.scale.space168}:"var(--coui-space-168)",'
      '${CoreSpace.scale.space176}:"var(--coui-space-176)",'
      '${CoreSpace.scale.space184}:"var(--coui-space-184)",'
      '${CoreSpace.scale.space192}:"var(--coui-space-192)",'
      '${CoreSpace.scale.space200}:"var(--coui-space-200)",'
      '${CoreSpace.scale.space208}:"var(--coui-space-208)",'
      '${CoreSpace.scale.space216}:"var(--coui-space-216)",'
      '${CoreSpace.scale.space224}:"var(--coui-space-224)",'
      '${CoreSpace.scale.space232}:"var(--coui-space-232)",'
      '${CoreSpace.scale.space240}:"var(--coui-space-240)",'
      '${CoreSpace.scale.space248}:"var(--coui-space-248)",'
      '${CoreSpace.scale.space256}:"var(--coui-space-256)"';

  // ── Border Width Config ─────────────────────────────────────

  /// Maps spec primitive stroke tokens to numeric Tailwind keys.
  static final _borderWidthConfig =
      // Tailwind's own `border` utility resolves `borderWidth.DEFAULT`, and
      // without this key that stays its built-in literal 1px — so the bare
      // `border` class used across the component set would be the one
      // border a surface style could never move. Naming DEFAULT routes it
      // through the same variable as every numbered step.
      'DEFAULT:"var(--coui-stroke-width-1)",'
      '${CoreStrokeWidth.scale.stroke0}:"var(--coui-stroke-width-0)",'
      '${CoreStrokeWidth.scale.stroke0_5}:"var(--coui-stroke-width-0_5)",'
      '${CoreStrokeWidth.scale.stroke1}:"var(--coui-stroke-width-1)",'
      '${CoreStrokeWidth.scale.stroke1_5}:"var(--coui-stroke-width-1_5)",'
      '${CoreStrokeWidth.scale.stroke2}:"var(--coui-stroke-width-2)",'
      '${CoreStrokeWidth.scale.stroke3}:"var(--coui-stroke-width-3)",'
      '${CoreStrokeWidth.scale.stroke4}:"var(--coui-stroke-width-4)",'
      '${CoreStrokeWidth.scale.stroke5}:"var(--coui-stroke-width-5)",'
      '${CoreStrokeWidth.scale.stroke6}:"var(--coui-stroke-width-6)",'
      '${CoreStrokeWidth.scale.stroke8}:"var(--coui-stroke-width-8)"';

  // ── Ring Width / Offset Config ──────────────────────────────

  static final _ringWidthConfig =
      '${CoreFocusRing.ringWidth.toInt()}:"var(--coui-ring-width)"';

  static final _ringOffsetWidthConfig =
      '${CoreFocusRing.ringOffset.toInt()}:"var(--coui-ring-offset)"';

  // ── Outline Width / Offset Config ───────────────────────────

  /// The focus ring's `outline-{n}` step on the ring-width variable —
  /// the focus ring is an outline (`focusRingClassName`), and without
  /// this key `outline-2` stays Tailwind's literal `2px`, the one width
  /// a theme could not move through `--coui-ring-width`.
  static final _outlineWidthConfig =
      '${CoreFocusRing.ringWidth.toInt()}:"var(--coui-ring-width)"';

  /// The focus ring's `outline-offset-{n}` step on the ring-offset
  /// variable, for the same reason as [_outlineWidthConfig].
  static final _outlineOffsetConfig =
      '${CoreFocusRing.ringOffset.toInt()}:"var(--coui-ring-offset)"';

  /// Tailwind's own `transition` property list with `outline-color`
  /// added beside `box-shadow`.
  ///
  /// The stock list names `box-shadow` because Tailwind's ring utilities
  /// paint with it; CoUI's focus ring is an outline, so a host that fades
  /// its ring through the plain `transition` utility (Clickable) needs
  /// the outline colour named the same way, or the ring snaps while the
  /// rest of the control eases. The order is Tailwind's own with the
  /// one addition, which is also the list Tailwind v4 ships.
  static const _transitionPropertyDefault =
      'color, background-color, border-color, outline-color, '
      'text-decoration-color, fill, stroke, opacity, box-shadow, transform, '
      'filter, backdrop-filter';

  // ── Easing Config (Tailwind `transitionTimingFunction`) ─────

  /// Press-shrink scale key — single-sourced from the shared
  /// `CoreClickableStyle.defaultPressedScale` (mirrors Flutter
  /// `Clickable`'s pressed feedback).
  static final _pressScaleConfig =
      '${(CoreClickableStyle.defaultPressedScale * 100).round()}:'
      '"${CoreClickableStyle.defaultPressedScale}"';

  /// Tailwind `transitionDuration` scale — every `CoreDuration.scale`
  /// key becomes a `duration-*` utility. Tailwind's built-in scale lacks
  /// several token steps (e.g. 250), which silently no-ops the emitted
  /// class and falls back to the 150ms default.
  /// Every `duration-*` utility key, in scale order.
  ///
  /// Each key is the millisecond count as a string (`'150'`), which is what
  /// both the utility name and the CSS variable name are built from.
  ///
  /// Includes [CoreDuration.scale]'s `indeterminate` (1500ms, `Loading.bar`
  /// / `Progress` indeterminate fill) alongside the numbered steps — both
  /// the adapter (`tailwindDuration`) and this config key list have to
  /// carry every step `tailwindDuration` can produce, or the two silently
  /// drift into a key the adapter emits and the config never defines (a
  /// `duration-1500` class that compiles and does nothing).
  static final List<String> _durationScaleKeys = [
    CoreDuration.scale.ms0,
    CoreDuration.scale.ms50,
    CoreDuration.scale.ms100,
    CoreDuration.scale.ms150,
    CoreDuration.scale.ms200,
    CoreDuration.scale.ms250,
    CoreDuration.scale.ms300,
    CoreDuration.scale.ms350,
    CoreDuration.scale.ms400,
    CoreDuration.scale.ms450,
    CoreDuration.scale.ms500,
    CoreDuration.scale.ms1000,
    CoreDuration.scale.ms2000,
    CoreDuration.scale.ms3000,
    CoreDuration.scale.ms4000,
    CoreDuration.scale.ms5000,
    CoreDuration.scale.indeterminate,
  ];

  // Each utility resolves through a CSS variable rather than a literal
  // `150ms`. That indirection is the whole reduced-motion mechanism on the
  // web: the utilities stay as they are and a single media query below
  // retimes them, so no component has to know the preference exists.
  static final String _durationConfig = [
    for (final key in _durationScaleKeys) '"$key":"var(--coui-duration-$key)"',
  ].join(',');

  /// `--coui-duration-*` definitions for the `:root` block.
  static final String _durationCssVariables = [
    for (final key in _durationScaleKeys) '--coui-duration-$key:${key}ms;',
  ].join();

  /// Reduced-motion overrides — the web half of the accessibility axis whose
  /// policy lives in `coui_core`'s [CoreReducedMotion].
  ///
  /// Only the transition tier is zeroed. Display-tier durations keep their
  /// values because they answer "how long does this stay / cycle" rather than
  /// "how fast does it move" — a spinner frozen mid-cycle stops saying "still
  /// working", which trades one accessibility failure for another.
  ///
  /// The ceiling comes from [CoreReducedMotion.transitionCeilingMs] so the two
  /// platforms cannot disagree about where the line sits.
  static final String _reducedMotionCssVariables = [
    '$kTransitionMotionFactorVar:0;',
    for (final key in _durationScaleKeys)
      if ((int.tryParse(key) ?? 0) > 0 &&
          (int.tryParse(key) ?? 0) <= CoreReducedMotion.transitionCeilingMs)
        '--coui-duration-$key:0ms;',
    // A display-tier loop the request stops: every Skeleton node's
    // inline `animation-name` reads this variable, so the placeholder holds
    // its resting end instead of pulsing.
    if (!CoreReducedMotion.runsPlaceholderPulse(reduce: true))
      '$kSkeletonPulseNameVar:$kSkeletonRestAnimationName;',
  ].join();

  /// The screen density from which a CSS px is at least two device pixels, so
  /// the steps with half a pixel in them — the hairline
  /// ([CoreStrokeWidth.stroke0_5]) and the active boundary
  /// ([CoreStrokeWidth.stroke1_5]) — can be drawn at their own width
  /// ([CoreStrokeWidth.hairlineMinDevicePixelRatio]).
  static const int _kHalfPixelStepMinDppx = 2;

  /// The dense-screen half of `--coui-stroke-width-0_5` and
  /// `--coui-stroke-width-1_5`.
  ///
  /// Below 2x a CSS px is one device pixel and there is no half of one, so
  /// both steps state one whole px there ([CoreStrokeWidth.hairlineAt],
  /// [CoreStrokeWidth.activeBoundaryAt]) — half a pixel would be a sub-pixel
  /// row, and Chrome already drew a 1.5px border as one pixel there. `:root`
  /// keeps that 1px; from 2x up each variable reads the token's own width,
  /// a whole number of device pixels. Flutter folds the same screen into its
  /// theme geometry, so both platforms draw the same width on each screen.
  ///
  /// Declared on `:root` so each variable stays a single indirection a
  /// surface style's stroke floor can overwrite later in the sheet, the same
  /// as every other `--coui-stroke-width-*` step.
  static const _halfPixelStepsRule =
      '@media (min-resolution:${_kHalfPixelStepMinDppx}dppx) '
      '{:root{'
      '--coui-stroke-width-0_5:${CoreStrokeWidth.stroke0_5}px;'
      '--coui-stroke-width-1_5:${CoreStrokeWidth.stroke1_5}px;'
      '}}';

  /// The named curves, in the order both the Tailwind `easing` map and the
  /// `--easing-*` variables list them. `linear` is not among them — it is
  /// the CSS keyword, not a curve.
  static final List<(String, CoreCubicBezier)> _easingCurves = [
    (CoreEasing.scale.ease, CoreEasing.ease),
    (CoreEasing.scale.easeIn, CoreEasing.easeIn),
    (CoreEasing.scale.easeOut, CoreEasing.easeOut),
    (CoreEasing.scale.easeInOut, CoreEasing.easeInOut),
    (CoreEasing.scale.easeInSine, CoreEasing.easeInSine),
    (CoreEasing.scale.easeOutSine, CoreEasing.easeOutSine),
    (CoreEasing.scale.easeInOutSine, CoreEasing.easeInOutSine),
    (CoreEasing.scale.easeInQuad, CoreEasing.easeInQuad),
    (CoreEasing.scale.easeOutQuad, CoreEasing.easeOutQuad),
    (CoreEasing.scale.easeInOutQuad, CoreEasing.easeInOutQuad),
    (CoreEasing.scale.easeInCubic, CoreEasing.easeInCubic),
    (CoreEasing.scale.easeOutCubic, CoreEasing.easeOutCubic),
    (CoreEasing.scale.easeInOutCubic, CoreEasing.easeInOutCubic),
    (CoreEasing.scale.easeInQuart, CoreEasing.easeInQuart),
    (CoreEasing.scale.easeOutQuart, CoreEasing.easeOutQuart),
    (CoreEasing.scale.easeInOutQuart, CoreEasing.easeInOutQuart),
    (CoreEasing.scale.easeInQuint, CoreEasing.easeInQuint),
    (CoreEasing.scale.easeOutQuint, CoreEasing.easeOutQuint),
    (CoreEasing.scale.easeInOutQuint, CoreEasing.easeInOutQuint),
    (CoreEasing.scale.easeInExpo, CoreEasing.easeInExpo),
    (CoreEasing.scale.easeOutExpo, CoreEasing.easeOutExpo),
    (CoreEasing.scale.easeInOutExpo, CoreEasing.easeInOutExpo),
    (CoreEasing.scale.easeInCirc, CoreEasing.easeInCirc),
    (CoreEasing.scale.easeOutCirc, CoreEasing.easeOutCirc),
    (CoreEasing.scale.easeInOutCirc, CoreEasing.easeInOutCirc),
    (CoreEasing.scale.easeInBack, CoreEasing.easeInBack),
    (CoreEasing.scale.easeOutBack, CoreEasing.easeOutBack),
    (CoreEasing.scale.easeInOutBack, CoreEasing.easeInOutBack),
    (CoreEasing.scale.fastOutSlowIn, CoreEasing.fastOutSlowIn),
    (CoreEasing.scale.slowMiddle, CoreEasing.slowMiddle),
    (
      CoreEasing.scale.fastLinearToSlowEaseIn,
      CoreEasing.fastLinearToSlowEaseIn,
    ),
    (CoreEasing.scale.easeInToLinear, CoreEasing.easeInToLinear),
    (CoreEasing.scale.linearToEaseOut, CoreEasing.linearToEaseOut),
  ];

  static final String _easingConfig = [
    _easingEntry(CoreEasing.scale.linear, 'linear'),
    for (final (key, curve) in _easingCurves)
      _easingEntry(key, _bezierTuple(curve)),
  ].join(',');

  static final String _easingCssVariables = [
    '--easing-${CoreEasing.scale.linear}:linear;',
    for (final (key, curve) in _easingCurves) _easingCssVar(key, curve),
  ].join();

  // ── Box Shadow CSS variables (designer spec) ─────────────────
  //
  // Each `--shadow-*` resolves to the designer's box-shadow — two layers
  // (Sharp + Diffuse) for `xs`/`sm`, one for the floating rungs from `md`
  // up — with the shadow colour sourced from the `--coui-shadow` token
  // and each layer's alpha multiplied by `--coui-shadow-strength` (the
  // dark blocks set it; see `kShadowStrengthVariable`). These replace
  // Tailwind's built-in fixed-black shadows via `_boxShadowConfig`.

  static const _kShadowColorBase = 'rgb(var(--coui-shadow))';

  /// The tint a style's inset rim is drawn in — the counterpart of
  /// [_kShadowColorBase]. Always defined: a palette that states no
  /// highlight still emits this variable, derived from its own surface.
  static const _kSurfaceHighlightBase = 'rgb(var(--coui-surface-highlight))';

  /// Where the edge band and the rim ring sit on their surface: its own box
  /// (`inset: 0`), widened by the border the surface says it keeps
  /// ([kWebSurfaceBleedVar]) so the band reaches the outer edge, as the
  /// Flutter twin's sheen does. A surface that states no border keeps 0.
  ///
  /// The top and bottom edges read [kWebSurfaceBleedTopVar] and
  /// [kWebSurfaceBleedBottomVar] first, so a bar that keeps its border on one
  /// of them only widens the band there and nowhere else.
  static const _kSurfaceBandInset =
      'inset:calc(var($kWebSurfaceBleedTopVar,var($kWebSurfaceBleedVar,0px)) '
      '* -1) calc(var($kWebSurfaceBleedVar,0px) * -1) '
      'calc(var($kWebSurfaceBleedBottomVar,var($kWebSurfaceBleedVar,0px)) '
      '* -1);';

  /// A `box-shadow` layer that renders nothing.
  ///
  /// The rim variable always resolves — an undefined custom property
  /// invalidates the whole declaration it appears in, taking the cast
  /// shadow with it, so the no-rim case has to be a real layer rather
  /// than an empty string.
  static const _kNoRim = '0 0 0 0 transparent';

  static final _shadowCssVariables =
      // Declared unconditionally so a surface can name it without
      // guarding: an undefined custom property invalidates the whole
      // declaration it appears in, which was measured to strip a
      // panel's cast shadow along with the rim it did not have.
      '--coui-surface-rim:$_kNoRim;'
      // Same reasoning, for the shadow counterpart of the rim
      // (`CoreSurfaceGeometryConstraint.controlShadow`): a control with
      // no shadow of its own (`Button` at rest) references this
      // unconditionally, so it must resolve to a real "nothing" layer —
      // reusing [_kNoRim]'s value, not its name, since the layer that
      // renders nothing is the same either way.
      //
      // The offset pair and `--coui-control-shadow-press` (the press
      // effect's *value*, not its rule — see `kControlShadowPressMarker`)
      // travel separately: zero / undefined by default, so a press never
      // moves a control or touches its shadow under a style that states
      // no [CoreSurfaceGeometryConstraint.shadowOffsetAdd].
      '--coui-control-shadow:$_kNoRim;'
      // [CoreCastMotion.reverse]'s rest value — see [kControlShadowGhostVar].
      // Same "nothing" layer as [_kNoRim] by default; a style with a real
      // `controlShadow` resolves it to a same-shape, zero-alpha twin
      // below.
      '--coui-control-shadow-ghost:$_kNoRim;'
      '--coui-control-shadow-offset-x:0px;'
      '--coui-control-shadow-offset-y:0px;'
      '${_shadowCssVar(CoreShadow.scale.none, CoreShadow.none)}'
      '${_shadowCssVar(CoreShadow.scale.xs, CoreShadow.xs)}'
      '${_shadowCssVar(CoreShadow.scale.sm, CoreShadow.sm)}'
      '${_shadowCssVar(CoreShadow.scale.md, CoreShadow.md)}'
      '${_shadowCssVar(CoreShadow.scale.lg, CoreShadow.lg)}'
      '${_shadowCssVar(CoreShadow.scale.xl, CoreShadow.xl)}'
      '${_shadowCssVar(CoreShadow.scale.xl2, CoreShadow.xl2)}'
      '${_shadowCssVar(CoreShadow.scale.xl3, CoreShadow.xl3)}'
      '${_shadowCssVar(CoreShadow.scale.inset, CoreShadow.inset)}'
      // The `filter: drop-shadow()` counterpart of every step above,
      // minus `inset` — `drop-shadow()` cannot express an inset layer,
      // so that step has no filter var to move a style could bend.
      // Without these, `Hover`'s `shadow` effect (the only caller that
      // takes the `drop-shadow` path — a stack with no inset layer casts
      // through `filter` so it follows the child's rendered shape, not
      // its wrapper's square border-box) baked `CoreShadow.lg`'s literal
      // blur/offset straight into the `filter` value, so no surface
      // style could reach it — neo-brutalism bent every other cast
      // (`--shadow-lg`, `--coui-control-shadow`) to its hard, opaque,
      // diagonally-offset look while this one stayed the soft ambient
      // ombre, quietly opted out of the preset.
      '${_shadowFilterCssVar(CoreShadow.scale.none, CoreShadow.none)}'
      '${_shadowFilterCssVar(CoreShadow.scale.xs, CoreShadow.xs)}'
      '${_shadowFilterCssVar(CoreShadow.scale.sm, CoreShadow.sm)}'
      '${_shadowFilterCssVar(CoreShadow.scale.md, CoreShadow.md)}'
      '${_shadowFilterCssVar(CoreShadow.scale.lg, CoreShadow.lg)}'
      '${_shadowFilterCssVar(CoreShadow.scale.xl, CoreShadow.xl)}'
      '${_shadowFilterCssVar(CoreShadow.scale.xl2, CoreShadow.xl2)}'
      '${_shadowFilterCssVar(CoreShadow.scale.xl3, CoreShadow.xl3)}';

  // ── Size Axis Config (width/height/min/max) ─────────────────

  /// Stroke steps that have a `--coui-stroke-width-*` variable to move.
  static const List<({String key, double value})> _kStrokeVariableSteps = [
    (key: '0', value: CoreStrokeWidth.stroke0),
    (key: '0_5', value: CoreStrokeWidth.stroke0_5),
    (key: '1', value: CoreStrokeWidth.stroke1),
    (key: '1_5', value: CoreStrokeWidth.stroke1_5),
    (key: '2', value: CoreStrokeWidth.stroke2),
    (key: '3', value: CoreStrokeWidth.stroke3),
    (key: '4', value: CoreStrokeWidth.stroke4),
    (key: '5', value: CoreStrokeWidth.stroke5),
    (key: '6', value: CoreStrokeWidth.stroke6),
    (key: '8', value: CoreStrokeWidth.stroke8),
  ];

  /// Shadow steps that have a `--shadow-*` variable to move.
  ///
  /// Only the token scale is here. A component that emits an arbitrary
  /// stack inline resolves to no variable, so a style cannot reach it on
  /// this platform — the same limit radius has, and for the same reason.
  static final List<({String key, List<CoreShadowLayer> layers})>
  _kShadowVariableSteps = [
    (key: CoreShadow.scale.xs, layers: CoreShadow.xs),
    (key: CoreShadow.scale.sm, layers: CoreShadow.sm),
    (key: CoreShadow.scale.md, layers: CoreShadow.md),
    (key: CoreShadow.scale.lg, layers: CoreShadow.lg),
    (key: CoreShadow.scale.xl, layers: CoreShadow.xl),
    (key: CoreShadow.scale.xl2, layers: CoreShadow.xl2),
    (key: CoreShadow.scale.xl3, layers: CoreShadow.xl3),
    (key: CoreShadow.scale.inset, layers: CoreShadow.inset),
  ];

  // ── Font Family Config ───────────────────────────────────

  static final _fontFamilyConfig =
      '${CoreFontFamily.scale.sans}:"var(--coui-font-family-sans)",'
      '${CoreFontFamily.scale.mono}:"var(--coui-font-family-mono)"';

  /// `h-control40` / `min-h-control40` → `var(--coui-control-height-40)`,
  /// one key per rung of the control ladder (`CoreControlSize.steps`).
  ///
  /// The class a control row emits for its height, so a density's
  /// `[data-coui-density]` rule re-points the row and nothing else.
  static final String _controlHeightConfig = [
    for (final h in CoreControlSize.steps)
      '${h.tailwindControlHeight}:"var(--coui-control-height-${h.toInt()})"',
  ].join(',');

  /// The `:root` values of the control-height variables — each rung's own
  /// height, so a page with no density attribute draws the authored rows.
  static String _controlHeightRootVars() => [
    for (final h in CoreControlSize.steps)
      '--coui-control-height-${h.toInt()}:${h / 16}rem;',
  ].join();

  /// CoreSize-based axis config for width/height/minWidth/minHeight/maxWidth/maxHeight.
  ///
  /// Generated once and reused across all dimensional axes so that
  /// `w-size80`, `min-h-size40`, `max-h-size256` etc. all resolve to
  /// the same underlying CoreSize values.
  static final _sizeAxisConfig =
      '${CoreSize.scale.size4}:"var(--coui-size-4)",'
      '${CoreSize.scale.size6}:"var(--coui-size-6)",'
      '${CoreSize.scale.size8}:"var(--coui-size-8)",'
      '${CoreSize.scale.size10}:"var(--coui-size-10)",'
      '${CoreSize.scale.size12}:"var(--coui-size-12)",'
      '${CoreSize.scale.size14}:"var(--coui-size-14)",'
      '${CoreSize.scale.size16}:"var(--coui-size-16)",'
      '${CoreSize.scale.size18}:"var(--coui-size-18)",'
      '${CoreSize.scale.size20}:"var(--coui-size-20)",'
      '${CoreSize.scale.size24}:"var(--coui-size-24)",'
      '${CoreSize.scale.size28}:"var(--coui-size-28)",'
      '${CoreSize.scale.size32}:"var(--coui-size-32)",'
      '${CoreSize.scale.size36}:"var(--coui-size-36)",'
      '${CoreSize.scale.size40}:"var(--coui-size-40)",'
      '${CoreSize.scale.size44}:"var(--coui-size-44)",'
      '${CoreSize.scale.size48}:"var(--coui-size-48)",'
      '${CoreSize.scale.size56}:"var(--coui-size-56)",'
      '${CoreSize.scale.size64}:"var(--coui-size-64)",'
      '${CoreSize.scale.size72}:"var(--coui-size-72)",'
      '${CoreSize.scale.size80}:"var(--coui-size-80)",'
      '${CoreSize.scale.size88}:"var(--coui-size-88)",'
      '${CoreSize.scale.size96}:"var(--coui-size-96)",'
      '${CoreSize.scale.size112}:"var(--coui-size-112)",'
      '${CoreSize.scale.size128}:"var(--coui-size-128)"';

  /// CoreLayout-based axis config — panel / overlay bounds, appended to the
  /// same dimensional axes as [_sizeAxisConfig] so `max-w-layout640` and
  /// `max-h-layout400` resolve to `--coui-layout-*`.
  static final _layoutAxisConfig =
      '${CoreLayout.scale.layout160}:"var(--coui-layout-160)",'
      '${CoreLayout.scale.layout240}:"var(--coui-layout-240)",'
      '${CoreLayout.scale.layout248}:"var(--coui-layout-248)",'
      '${CoreLayout.scale.layout280}:"var(--coui-layout-280)",'
      '${CoreLayout.scale.layout320}:"var(--coui-layout-320)",'
      '${CoreLayout.scale.layout400}:"var(--coui-layout-400)",'
      '${CoreLayout.scale.layout560}:"var(--coui-layout-560)",'
      '${CoreLayout.scale.layout640}:"var(--coui-layout-640)"';

  // ── Z-Index Config ──────────────────────────────────────────
  // `CoreZIndex` starts numbering at 1000 specifically so this shared
  // ladder never collides with a component's own local stacking (see
  // `CoreZIndex`'s doc comment). Variable prefix is `--z-*` (not
  // `--coui-z-*`) — `CoreZIndex.scale`'s own doc comment already spells
  // out `var(--z-${CoreZIndex.scale.z50})`, so this mirrors the contract
  // the token itself declares rather than inventing a second name.

  static final _zIndexConfig =
      '${CoreZIndex.scale.z0}:"var(--z-0)",'
      '${CoreZIndex.scale.z10}:"var(--z-10)",'
      '${CoreZIndex.scale.z20}:"var(--z-20)",'
      '${CoreZIndex.scale.z30}:"var(--z-30)",'
      '${CoreZIndex.scale.z40}:"var(--z-40)",'
      '${CoreZIndex.scale.z50}:"var(--z-50)",'
      '${CoreZIndex.scale.z60}:"var(--z-60)",'
      '${CoreZIndex.scale.z70}:"var(--z-70)",'
      '${CoreZIndex.scale.z80}:"var(--z-80)",'
      '${CoreZIndex.scale.z90}:"var(--z-90)",'
      '${CoreZIndex.scale.z100}:"var(--z-100)",'
      '${CoreZIndex.scale.zAuto}:"var(--z-auto)"';

  // Core already publishes these utility keys and their values. Extend the
  // pinned Tailwind scale rather than replacing its other default keys.
  static final String _opacityConfig = <String, double>{
    CoreOpacity.scale.opacity0: CoreOpacity.opacity0,
    CoreOpacity.scale.opacity3: CoreOpacity.opacity3,
    CoreOpacity.scale.opacity5: CoreOpacity.opacity5,
    CoreOpacity.scale.opacity8: CoreOpacity.opacity8,
    CoreOpacity.scale.opacity10: CoreOpacity.opacity10,
    CoreOpacity.scale.opacity12: CoreOpacity.opacity12,
    CoreOpacity.scale.opacity15: CoreOpacity.opacity15,
    CoreOpacity.scale.opacity16: CoreOpacity.opacity16,
    CoreOpacity.scale.opacity20: CoreOpacity.opacity20,
    CoreOpacity.scale.opacity25: CoreOpacity.opacity25,
    CoreOpacity.scale.opacity30: CoreOpacity.opacity30,
    CoreOpacity.scale.opacity40: CoreOpacity.opacity40,
    CoreOpacity.scale.opacity50: CoreOpacity.opacity50,
    CoreOpacity.scale.opacity60: CoreOpacity.opacity60,
    CoreOpacity.scale.opacity70: CoreOpacity.opacity70,
    CoreOpacity.scale.opacity75: CoreOpacity.opacity75,
    CoreOpacity.scale.opacity80: CoreOpacity.opacity80,
    CoreOpacity.scale.opacity85: CoreOpacity.opacity85,
    CoreOpacity.scale.opacity90: CoreOpacity.opacity90,
    CoreOpacity.scale.opacity95: CoreOpacity.opacity95,
    CoreOpacity.scale.opacity100: CoreOpacity.opacity100,
    CoreOpacity.scale.disabled: CoreOpacity.disabled,
    CoreOpacity.scale.hover: CoreOpacity.hover,
    CoreOpacity.scale.focus: CoreOpacity.focus,
    CoreOpacity.scale.pressed: CoreOpacity.pressed,
    CoreOpacity.scale.scrim: CoreOpacity.scrim,
  }.entries.map((entry) => '${entry.key}:"${entry.value}"').join(',');

  /// Tailwind CSS config JavaScript string.
  ///
  /// Registers M3 Semantic token names as Tailwind colors
  /// referencing CSS variables, plus border-radius overrides and the
  /// `screens` scale sourced from `CoreBreakpoint` and opacity keys/values
  /// sourced from `CoreOpacity`.
  /// The internal selection variant targets one root; its fixed utility
  /// consumes that instance's existing color variable in the utility sheet.
  ///
  /// Inject as `<script>{tailwindConfig}</script>`.
  String get tailwindConfig =>
      'tailwind.config={corePlugins:{preflight:false},'
      'theme:{extend:{'
      'screens:{$_screensConfig},'
      'colors:{$_colorsConfig,$_categoryColorsConfig},'
      'opacity:{$_opacityConfig},'
      'borderRadius:{$_borderRadiusConfig},'
      'boxShadow:{$_boxShadowConfig},'
      'borderWidth:{$_borderWidthConfig},'
      'ringWidth:{$_ringWidthConfig},'
      'ringOffsetWidth:{$_ringOffsetWidthConfig},'
      'outlineWidth:{$_outlineWidthConfig},'
      'outlineOffset:{$_outlineOffsetConfig},'
      'transitionProperty:{DEFAULT:"$_transitionPropertyDefault"},'
      'spacing:{$_spacingConfig},'
      'width:{$_sizeAxisConfig,$_layoutAxisConfig},'
      'height:{$_sizeAxisConfig,$_layoutAxisConfig,$_controlHeightConfig},'
      'minWidth:{$_sizeAxisConfig,$_layoutAxisConfig},'
      'minHeight:{$_sizeAxisConfig,$_layoutAxisConfig,$_controlHeightConfig},'
      'maxWidth:{$_sizeAxisConfig,$_layoutAxisConfig},'
      'maxHeight:{$_sizeAxisConfig,$_layoutAxisConfig},'
      'fontFamily:{$_fontFamilyConfig},'
      'fontSize:{$_fontSizeConfig,$_semanticFontSizeConfig},'
      'fontWeight:{$_fontWeightConfig},'
      'lineHeight:{$_lineHeightConfig},'
      'letterSpacing:{$_letterSpacingConfig},'
      'transitionTimingFunction:{$_easingConfig},'
      'transitionDuration:{$_durationConfig},'
      'scale:{$_pressScaleConfig},'
      'zIndex:{$_zIndexConfig},'
      '}},plugins:[function({addUtilities,addVariant}){'
      'addVariant("$kSelectableRootSelectionVariant","&::selection");'
      'addUtilities({".$kSelectableSelectionUtility":{'
      'backgroundColor:"var($kSelectableSelectionColorVar)"}});'
      '}]}';

  /// CSS `:root { ... }` block with all color variables and design tokens.
  ///
  /// Includes:
  /// - Color Primitive, Semantic (Light), and legacy aliases.
  /// - Spacing / Size / Font-size / Border-width tokens as CSS custom
  ///   properties (e.g. `--coui-space-16: 1rem;`). Web inline style can
  ///   reference these as `'var(--coui-space-16)'`, giving the same
  ///   accessibility-scale behaviour as Tailwind utility classes.
  ///
  /// Inject as `<style>{cssVariables}</style>`.
  String get cssVariables =>
      '${PrimitiveCssGenerator.toCssBlockFrom(_source)}'
      '\n$_tokenCssVariables\n'
      '$_typographyCss'
      // The typography tiers, beside the role variables they re-point.
      // Always present: the viewport selects a tier with no pin on the page,
      // and a pin (`CoUIWeb.typographyTier`, `TypographyTierScope`) is an
      // attribute that would do nothing without its rule.
      '$typographyTierBlocks'
      // The density rules, beside the tokens they re-point. Always present:
      // a density is chosen by an attribute on the document
      // (`DensityScope.setDensity` / `CoUIWeb.density`), and a rule that
      // was not in the sheet would make that attribute do nothing.
      '$densityVariableBlocks'
      // High contrast lives here rather than in the static token block
      // because it needs the palette. The same vocabulary resolved to
      // stronger values, so no component knows the preference exists — and
      // only the variables the source's raise governs, so a slot it leaves
      // alone keeps whatever a surface style states for it.
      //
      // Surface tones are among those left alone: several components
      // distinguish cards, inputs and popovers by background tone and only
      // some draw a border, so flattening the tones would erase boundaries
      // with nothing to replace them. The raise leaves them to the base, so
      // the block never writes them.
      // The doubled `:root` is load-bearing, not a typo. A surface style
      // writes `[data-coui-style="…"]`, and in dark it writes
      // `[data-theme="dark"][data-coui-style="…"]` — the same or higher
      // specificity than a plain `:root` / `[data-theme="dark"]`. Left as
      // written, whether a decorative style or a contrast preference won a
      // shared slot would come down to which stylesheet the page appended
      // last, and in dark the style would win outright.
      //
      // A style has every right to state a boundary colour — that is the
      // whole of what one of the shipped styles says — so the answer is not
      // to stop it writing the slot. The answer is that the preference
      // outranks it wherever both speak, and specificity says so
      // structurally rather than leaving it to injection order.
      //
      // Specificity, not `!important`: this only has to outrank another
      // author rule, and leaving the door open means an app can still
      // override deliberately. `!important` is for a declaration that has
      // to beat an inline style, which no rule here does.
      //
      // The light block stays out of an explicitly dark page. Without the
      // `:not`, it matches there too and outranks the plain dark rule, and
      // the dark block below only restates its own slots — so a slot the
      // light raise governs and the dark one does not would paint its light
      // high-contrast value on a dark page. Excluding it makes explicit dark
      // read exactly dark + the dark block, which is what the theme seat
      // computes. The exclusion sits inside `:where()` so the selector keeps
      // the specificity the doubled `:root` gives it: an OS-dark page with
      // no attribute (`darkAutoVariableBlock`, (0,2,0)) still meets it at
      // the same rank it always did.
      '@media (prefers-contrast:more){$_kLightHighContrastSelector{'
      '${_highContrastVars(_source, .light)}'
      '}}'
      '@media (prefers-contrast:more){:root:root[data-theme="dark"]{'
      '${_highContrastVars(_source, .dark)}'
      '}}'
      // Last, so the scope rules sit after everything they restate — they
      // win on specificity regardless, see [brightnessScopeBlock].
      '$brightnessScopeBlock';

  /// The rules a brightness scope — `data-theme` on an element below the
  /// root, which `BrightnessScope` writes — renders its subtree with.
  ///
  /// The document's mode lives on the root: `:root` carries the light
  /// palette and [darkVariableBlock] the dark one. A custom property
  /// inherits, so restating the palette on an element re-colours everything
  /// inside it. What a scope restates, all of it in this stylesheet:
  ///
  ///   · its palette and its shadow strength. The dark one too, although
  ///     [darkVariableBlock] names no root: only an app with a dark mode
  ///     injects that block, and a light-only app previewing a dark screen
  ///     would otherwise have no dark palette to reach;
  ///   · the variables the root *derives* from the palette —
  ///     the legacy aliases and every shadow stack. A custom property that
  ///     names another is substituted where it is declared, so the root's
  ///     stacks reach a scope already computed with the root's strength (a
  ///     dark page's casts carry four times the alpha); restated here, they
  ///     are computed with the scope's;
  ///   · the text colour, restarted from the scope's `onSurface` — an
  ///     inherited `color` was resolved where it was set;
  ///   · high contrast, raised over the scope's own palette.
  ///
  /// Every selector carries `:not(:root)`, so the root keeps exactly the
  /// rules it had. Inside a scope the ladder is strict, so the order these
  /// sheets are injected in cannot decide anything: the palette (0,2,0) <
  /// a surface style's bends for the scope (0,3,0, in
  /// [surfaceStyleVariableBlocks]) < high contrast (0,4,0) — the preference
  /// outranks the style here as it does on the root.
  ///
  /// Reaches what the stylesheet states. A palette swapped at runtime
  /// (`CoUIThemeController.setCustomTheme`) is written onto the root
  /// element and does not reach a scope, which keeps the palette this
  /// config was built with.
  String get brightnessScopeBlock {
    String declarations(Map<String, String> vars) =>
        vars.entries.map((e) => '${e.key}:${e.value};').join();
    final legacy = {
      ...PrimitiveCssGenerator.generateDaisyUiAliases(),
      ...PrimitiveCssGenerator.generateShadcnAliases(),
    };
    // Only the shadow declarations that name another variable — those are
    // substituted where they are declared, so the root's arrive computed.
    // The rest are plain values that inherit unchanged, and restating them
    // would put back the defaults a surface style moved on the root (a
    // press offset, a rim).
    final derivedShadows = _shadowCssVariables
        .split(';')
        .where((declaration) => declaration.contains('var('))
        .map((declaration) => '$declaration;')
        .join();

    final buffer = StringBuffer()
      // Each scope's palette and shadow strength.
      ..write('[data-theme="light"]:not(:root){')
      ..write(declarations(semanticLightVars))
      ..write('$kShadowStrengthVariable:1;}')
      ..write('[data-theme="dark"]:not(:root){')
      ..write(declarations(semanticDarkVars))
      ..write('$_darkShadowStrength;}')
      // What the root derives from the palette, and the text colour, for
      // either scope.
      ..write('[data-theme]:not(:root){')
      ..write(declarations(legacy))
      ..write(derivedShadows)
      ..write('color:rgb(var(--coui-on-surface));}')
      // High contrast over each scope's own palette.
      ..write('@media (prefers-contrast:more){')
      ..write(':root [data-theme="light"][data-theme="light"]:not(:root){')
      ..write(_highContrastVars(_source, .light))
      ..write('}:root [data-theme="dark"][data-theme="dark"]:not(:root){')
      ..write(_highContrastVars(_source, .dark))
      ..write('}}');

    return buffer.toString();
  }

  /// Default per-role typography variables (`--coui-text-{role}-{size,
  /// line-height,weight,tracking}`) for the SSR `<style>` block, derived
  /// from [CoreTypography.coui] through [CssVariableGenerator.typographyVars]
  /// — the same single source the runtime override path consumes. The
  /// Tailwind `fontSize` config references these per-role variables, so a
  /// project-supplied `theme.typography` overrides the role composition on
  /// Web identically to Flutter (#2624).
  static final String _typographyCssBlock = typographyCssBlock(.coui);

  /// The per-role typography variables for [typography], then one rule per
  /// role that names its own font family.
  ///
  /// A family cannot ride the `text-{role}` class itself — Tailwind's
  /// `fontSize` entry carries size, leading, weight and tracking only — so
  /// the role's family variable is read by a rule of its own. The rule is
  /// wrapped in `:where()` so it carries no specificity: it beats the
  /// inherited root face, and an explicit `font-mono` on the same element
  /// still wins. A role that names no family gets no rule and no variable.
  /// The default scale names one only on the code roles (mono), so its
  /// block is the variables plus one `:where(.text-code-*)` rule for each.
  static String typographyCssBlock(CoreTypography typography) {
    final variables = CssVariableGenerator.typographyVars(typography);
    // `--coui-text-scale` is the scale of the element that states it — a
    // nested `Text` keeps its own box — so it does not inherit.
    final buffer = StringBuffer(
      '@property --coui-text-scale '
      '{syntax:"<number>";inherits:false;initial-value:1}:root{',
    );
    for (final entry in variables.entries) {
      buffer.write('${entry.key}:${entry.value};');
    }
    buffer.write('}');
    for (final token in CoreTextStyles.values) {
      if (token.read(typography).fontFamily == null) continue;
      buffer.write(
        ':where(.text-${token.name})'
        '{font-family:var(--coui-text-${token.name}-family)}',
      );
    }
    // Keep the rendering expression with the typography that determines
    // its unit. A role with no line height still gets the number expression:
    // its missing source remains invalid, so native inheritance applies,
    // and setting a multiplier variable later works as it did previously.
    for (final token in CoreTextStyles.values) {
      final role = token.name;
      final style = token.read(typography);
      final unit = style.lineHeightPx != null
          ? 'var(--coui-text-scale, 1)'
          : '1em';
      final lineBox = CssVariableGenerator.roundToPixelCss(
        'calc(var(--coui-text-$role-line-height) * $unit)',
      );
      final leading = _leadingOf(style);
      buffer.write(
        ':where(.text-$role)'
        '{--coui-text-$role-rendered-line-height:$lineBox;',
      );
      if (leading != null) {
        buffer.write('${CssVariableGenerator.leadingVar}:$leading;');
      }
      buffer.write('}');
    }
    return buffer.toString();
  }

  /// The multiplier [style] hands to text below it — its own, or its fixed
  /// box over its size. `null` when it states neither.
  static double? _leadingOf(CoreTextStyle style) {
    final box = style.lineHeightPx;
    final size = style.fontSize;
    if (box != null) return size == null ? null : box / size;

    return style.lineHeight;
  }

  /// The rules that step the display and headline roles down with the
  /// viewport, and that pin a page — or a part of one — to one tier.
  ///
  /// The values are [typography] at each tier (`CoreTypography.atTier`, the
  /// seat Flutter folds into its theme), restated over the role variables
  /// the `:root` typography block writes. Below the desktop boundary the
  /// tablet values apply and below the tablet boundary the mobile ones; the
  /// boundaries are `CoreBreakpointContract.defaultBoundaries`, the widths
  /// `CoreBreakpoint.forWidth` turns into a tier. Each query is the negation
  /// of `min-width`, so a width lands in exactly the tier the shared judgement
  /// (`>=`) gives it — a `max-width` one pixel short would leave a
  /// fractional width between the two in neither.
  ///
  /// A page pins a tier with `kTypographyTierAttribute` on the root
  /// (`CoUIWeb.typographyTier`), which turns the viewport rules off, and a
  /// subtree pins one with the same attribute on an element below it
  /// (`TypographyTierScope`). The values are plain lengths that inherit, so
  /// the subtree rule restates them on its own element and everything inside
  /// reads them. The viewport rules hold for a root whose attribute names no
  /// tier — none at all, or the value `CoUIWeb` writes to lift a pin it set,
  /// since on the client it cannot take the attribute off.
  ///
  /// Print draws the scale as authored. A printed page is laid out at the
  /// paper's width, which the queries would read as a phone's, so an unpinned
  /// root restates the desktop values under `print`, after the viewport
  /// rules it ties with.
  ///
  /// Every rule states the same variables — every one some tier gives a value
  /// of its own, at that rule's tier. Viewport rules overlap (a phone matches
  /// both queries) and pins nest, so a rule that left a variable out would let
  /// the outer tier's value through for it. Under CoUI's scale that is the six
  /// heading sizes and the tracking of the one heading that crosses the
  /// tracking step.
  ///
  /// Every selector is (0,2,0): above the `:root` block, so the order the
  /// page injects stylesheets in cannot decide the tier. The media rules
  /// tie, so mobile comes after tablet and print after both, and the later
  /// one wins where several match. A surface style restates the roles'
  /// weights and nothing a tier moves, so the two axes do not meet.
  ///
  /// Reaches what reads a role variable — the `text-{role}` classes and every
  /// emit that resolves to one. A size written as a literal (an explicit
  /// `fontSize` override, a primitive size step) does not move.
  String get typographyTierBlocks => identical(typography, CoreTypography.coui)
      ? _typographyTierCssBlock
      : _typographyTierBlocksFor(typography);

  /// [typographyTierBlocks] for CoUI's own scale, built once.
  static final String _typographyTierCssBlock = _typographyTierBlocksFor(
    .coui,
  );

  static String _typographyTierBlocksFor(CoreTypography typography) {
    final varsByTier = {
      for (final tier in CoreBreakpointTier.values)
        tier: CssVariableGenerator.typographyVars(typography.atTier(tier)),
    };
    final desktop = varsByTier[CoreBreakpointTier.desktop]!;
    final moved = [
      for (final MapEntry(:key, :value) in desktop.entries)
        if (varsByTier.values.any((vars) => vars[key] != value)) key,
    ];
    if (moved.isEmpty) return '';

    String declarations(CoreBreakpointTier tier) => [
      for (final key in moved) '$key:${varsByTier[tier]![key]};',
    ].join();
    String below(CoreBreakpointTier tier) =>
        '@media not all and (min-width:'
        '${CoreBreakpointContract.defaultBoundaries[tier]!.minWidth.toInt()}'
        'px)';

    String pin(CoreBreakpointTier tier) =>
        '[$kTypographyTierAttribute="${tier.name}"]';
    final unpinned =
        ':root:not(${CoreBreakpointTier.values.map(pin).join(',')})';

    final buffer = StringBuffer()
      ..write('${below(.desktop)}{$unpinned{${declarations(.tablet)}}}')
      ..write('${below(.tablet)}{$unpinned{${declarations(.mobile)}}}')
      ..write('@media print{$unpinned{${declarations(.desktop)}}}');
    for (final tier in CoreBreakpointTier.values) {
      buffer.write(
        ':root${pin(tier)},${pin(tier)}:not(:root){${declarations(tier)}}',
      );
    }

    return buffer.toString();
  }

  /// CSS `:root { ... }` block for design tokens (non-color, light/dark agnostic).
  ///
  /// Dimensional values use `rem` (root font-size relative) so the browser's
  /// text-scale / zoom settings resize components proportionally. Border
  /// widths stay in `px` — border thickness should not scale with font size.
  static final _tokenCssVariables =
      ':root{'
      // ── Space (rem) ─────────────────────────────────────
      '--coui-space-0:0rem;'
      '--coui-space-2:${CoreSpace.space2 / 16}rem;'
      '--coui-space-4:${CoreSpace.space4 / 16}rem;'
      '--coui-space-6:${CoreSpace.space6 / 16}rem;'
      '--coui-space-8:${CoreSpace.space8 / 16}rem;'
      '--coui-space-10:${CoreSpace.space10 / 16}rem;'
      '--coui-space-12:${CoreSpace.space12 / 16}rem;'
      '--coui-space-14:${CoreSpace.space14 / 16}rem;'
      '--coui-space-16:${CoreSpace.space16 / 16}rem;'
      '--coui-space-18:${CoreSpace.space18 / 16}rem;'
      '--coui-space-20:${CoreSpace.space20 / 16}rem;'
      '--coui-space-24:${CoreSpace.space24 / 16}rem;'
      '--coui-space-28:${CoreSpace.space28 / 16}rem;'
      '--coui-space-32:${CoreSpace.space32 / 16}rem;'
      '--coui-space-36:${CoreSpace.space36 / 16}rem;'
      '--coui-space-40:${CoreSpace.space40 / 16}rem;'
      '--coui-space-44:${CoreSpace.space44 / 16}rem;'
      '--coui-space-48:${CoreSpace.space48 / 16}rem;'
      '--coui-space-52:${CoreSpace.space52 / 16}rem;'
      '--coui-space-56:${CoreSpace.space56 / 16}rem;'
      '--coui-space-60:${CoreSpace.space60 / 16}rem;'
      '--coui-space-64:${CoreSpace.space64 / 16}rem;'
      '--coui-space-72:${CoreSpace.space72 / 16}rem;'
      '--coui-space-80:${CoreSpace.space80 / 16}rem;'
      '--coui-space-88:${CoreSpace.space88 / 16}rem;'
      '--coui-space-96:${CoreSpace.space96 / 16}rem;'
      '--coui-space-104:${CoreSpace.space104 / 16}rem;'
      '--coui-space-112:${CoreSpace.space112 / 16}rem;'
      '--coui-space-120:${CoreSpace.space120 / 16}rem;'
      '--coui-space-128:${CoreSpace.space128 / 16}rem;'
      '--coui-space-136:${CoreSpace.space136 / 16}rem;'
      '--coui-space-144:${CoreSpace.space144 / 16}rem;'
      '--coui-space-152:${CoreSpace.space152 / 16}rem;'
      '--coui-space-160:${CoreSpace.space160 / 16}rem;'
      '--coui-space-168:${CoreSpace.space168 / 16}rem;'
      '--coui-space-176:${CoreSpace.space176 / 16}rem;'
      '--coui-space-184:${CoreSpace.space184 / 16}rem;'
      '--coui-space-192:${CoreSpace.space192 / 16}rem;'
      '--coui-space-200:${CoreSpace.space200 / 16}rem;'
      '--coui-space-208:${CoreSpace.space208 / 16}rem;'
      '--coui-space-216:${CoreSpace.space216 / 16}rem;'
      '--coui-space-224:${CoreSpace.space224 / 16}rem;'
      '--coui-space-232:${CoreSpace.space232 / 16}rem;'
      '--coui-space-240:${CoreSpace.space240 / 16}rem;'
      '--coui-space-248:${CoreSpace.space248 / 16}rem;'
      '--coui-space-256:${CoreSpace.space256 / 16}rem;'
      // ── Size (rem) ──────────────────────────────────────
      '--coui-size-4:${CoreSize.size4 / 16}rem;'
      '--coui-size-6:${CoreSize.size6 / 16}rem;'
      '--coui-size-8:${CoreSize.size8 / 16}rem;'
      '--coui-size-10:${CoreSize.size10 / 16}rem;'
      '--coui-size-12:${CoreSize.size12 / 16}rem;'
      '--coui-size-14:${CoreSize.size14 / 16}rem;'
      '--coui-size-16:${CoreSize.size16 / 16}rem;'
      '--coui-size-18:${CoreSize.size18 / 16}rem;'
      '--coui-size-20:${CoreSize.size20 / 16}rem;'
      '--coui-size-24:${CoreSize.size24 / 16}rem;'
      '--coui-size-28:${CoreSize.size28 / 16}rem;'
      '--coui-size-32:${CoreSize.size32 / 16}rem;'
      '--coui-size-36:${CoreSize.size36 / 16}rem;'
      '--coui-size-40:${CoreSize.size40 / 16}rem;'
      '--coui-size-44:${CoreSize.size44 / 16}rem;'
      '--coui-size-48:${CoreSize.size48 / 16}rem;'
      '--coui-size-56:${CoreSize.size56 / 16}rem;'
      '--coui-size-64:${CoreSize.size64 / 16}rem;'
      '--coui-size-72:${CoreSize.size72 / 16}rem;'
      '--coui-size-80:${CoreSize.size80 / 16}rem;'
      '--coui-size-88:${CoreSize.size88 / 16}rem;'
      '--coui-size-96:${CoreSize.size96 / 16}rem;'
      '--coui-size-112:${CoreSize.size112 / 16}rem;'
      '--coui-size-128:${CoreSize.size128 / 16}rem;'
      // ── Control row height (rem) ───────────────────────
      // Its own category rather than `--coui-size-*`: a density moves a
      // control row and must not move an icon or an avatar that happens to
      // measure the same — the size variables are shared by both.
      '${_controlHeightRootVars()}'
      // ── Layout (rem) ────────────────────────────────────
      '--coui-layout-160:${CoreLayout.layout160 / 16}rem;'
      '--coui-layout-240:${CoreLayout.layout240 / 16}rem;'
      '--coui-layout-248:${CoreLayout.layout248 / 16}rem;'
      '--coui-layout-280:${CoreLayout.layout280 / 16}rem;'
      '--coui-layout-320:${CoreLayout.layout320 / 16}rem;'
      '--coui-layout-400:${CoreLayout.layout400 / 16}rem;'
      '--coui-layout-560:${CoreLayout.layout560 / 16}rem;'
      '--coui-layout-640:${CoreLayout.layout640 / 16}rem;'
      // ── Font size (rem) ─────────────────────────────────
      '--coui-font-size-10:${CoreFontSize.s10 / 16}rem;'
      '--coui-font-size-11:${CoreFontSize.s11 / 16}rem;'
      '--coui-font-size-12:${CoreFontSize.s12 / 16}rem;'
      '--coui-font-size-13:${CoreFontSize.s13 / 16}rem;'
      '--coui-font-size-14:${CoreFontSize.s14 / 16}rem;'
      '--coui-font-size-15:${CoreFontSize.s15 / 16}rem;'
      '--coui-font-size-16:${CoreFontSize.s16 / 16}rem;'
      '--coui-font-size-18:${CoreFontSize.s18 / 16}rem;'
      '--coui-font-size-20:${CoreFontSize.s20 / 16}rem;'
      '--coui-font-size-24:${CoreFontSize.s24 / 16}rem;'
      '--coui-font-size-28:${CoreFontSize.s28 / 16}rem;'
      '--coui-font-size-32:${CoreFontSize.s32 / 16}rem;'
      '--coui-font-size-36:${CoreFontSize.s36 / 16}rem;'
      '--coui-font-size-40:${CoreFontSize.s40 / 16}rem;'
      '--coui-font-size-44:${CoreFontSize.s44 / 16}rem;'
      '--coui-font-size-48:${CoreFontSize.s48 / 16}rem;'
      '--coui-font-size-52:${CoreFontSize.s52 / 16}rem;'
      '--coui-font-size-60:${CoreFontSize.s60 / 16}rem;'
      '--coui-font-size-72:${CoreFontSize.s72 / 16}rem;'
      '--coui-font-size-96:${CoreFontSize.s96 / 16}rem;'
      '--coui-font-size-128:${CoreFontSize.s128 / 16}rem;'
      // ── Border width (px, intentionally fixed) ───────────
      '--coui-stroke-width-0:${CoreStrokeWidth.stroke0}px;'
      // The two half-pixel steps read one whole CSS px here and their own
      // width on a dense screen (see `_halfPixelStepsRule`): a CSS px is two
      // device pixels only at 2x and above, so only there is the half a
      // whole device pixel.
      '--coui-stroke-width-0_5:${CoreStrokeWidth.stroke1}px;'
      '--coui-stroke-width-1:${CoreStrokeWidth.stroke1}px;'
      '--coui-stroke-width-1_5:${CoreStrokeWidth.stroke1}px;'
      '--coui-stroke-width-2:${CoreStrokeWidth.stroke2}px;'
      '--coui-stroke-width-3:${CoreStrokeWidth.stroke3}px;'
      '--coui-stroke-width-4:${CoreStrokeWidth.stroke4}px;'
      '--coui-stroke-width-5:${CoreStrokeWidth.stroke5}px;'
      '--coui-stroke-width-6:${CoreStrokeWidth.stroke6}px;'
      '--coui-stroke-width-8:${CoreStrokeWidth.stroke8}px;'
      // ── Border radius (px, intentionally fixed) ─────────
      // Same policy as stroke-width: corner radii don't scale with
      // text size (visual identity of the component).
      '--coui-radius-0:${CoreRadius.radius0}px;'
      '--coui-radius-2:${CoreRadius.radius2}px;'
      '--coui-radius-4:${CoreRadius.radius4}px;'
      '--coui-radius-6:${CoreRadius.radius6}px;'
      '--coui-radius-8:${CoreRadius.radius8}px;'
      '--coui-radius-10:${CoreRadius.radius10}px;'
      '--coui-radius-12:${CoreRadius.radius12}px;'
      '--coui-radius-14:${CoreRadius.radius14}px;'
      '--coui-radius-16:${CoreRadius.radius16}px;'
      '--coui-radius-20:${CoreRadius.radius20}px;'
      '--coui-radius-24:${CoreRadius.radius24}px;'
      '--coui-radius-28:${CoreRadius.radius28}px;'
      '--coui-radius-32:${CoreRadius.radius32}px;'
      '--coui-radius-36:${CoreRadius.radius36}px;'
      '--coui-radius-40:${CoreRadius.radius40}px;'
      '--coui-radius-48:${CoreRadius.radius48}px;'
      '--coui-radius-56:${CoreRadius.radius56}px;'
      '--coui-radius-64:${CoreRadius.radius64}px;'
      '--coui-radius-9999:${CoreRadius.radius9999}px;'
      // ── Ring width / offset (px, intentionally fixed) ────
      '--coui-ring-width:${CoreFocusRing.ringWidth}px;'
      '--coui-ring-offset:${CoreFocusRing.ringOffset}px;'
      // ── Z-index (unitless, intentionally fixed) ──────────
      // `--z-*` (not `--coui-z-*`) — see the `_zIndexConfig` comment.
      '--z-0:${CoreZIndex.z0};'
      '--z-10:${CoreZIndex.z10};'
      '--z-20:${CoreZIndex.z20};'
      '--z-30:${CoreZIndex.z30};'
      '--z-40:${CoreZIndex.z40};'
      '--z-50:${CoreZIndex.z50};'
      '--z-60:${CoreZIndex.z60};'
      '--z-70:${CoreZIndex.z70};'
      '--z-80:${CoreZIndex.z80};'
      '--z-90:${CoreZIndex.z90};'
      '--z-100:${CoreZIndex.z100};'
      '--z-auto:${CoreZIndex.zAuto};'
      // ── Font weight (unitless, CSS standard 100-900) ─────
      '--coui-font-weight-thin:${CoreFontWeight.thin};'
      '--coui-font-weight-extralight:${CoreFontWeight.extraLight};'
      '--coui-font-weight-light:${CoreFontWeight.light};'
      '--coui-font-weight-regular:${CoreFontWeight.regular};'
      '--coui-font-weight-medium:${CoreFontWeight.medium};'
      '--coui-font-weight-semibold:${CoreFontWeight.semiBold};'
      '--coui-font-weight-bold:${CoreFontWeight.bold};'
      '--coui-font-weight-extrabold:${CoreFontWeight.extraBold};'
      '--coui-font-weight-black:${CoreFontWeight.black};'
      // ── Line height (unitless multiplier) ────────────────
      '--coui-line-height-100:${CoreLineHeight.h100};'
      '--coui-line-height-120:${CoreLineHeight.h120};'
      '--coui-line-height-140:${CoreLineHeight.h140};'
      '--coui-line-height-150:${CoreLineHeight.h150};'
      '--coui-line-height-160:${CoreLineHeight.h160};'
      '--coui-line-height-180:${CoreLineHeight.h180};'
      '--coui-line-height-200:${CoreLineHeight.h200};'
      // ── Letter spacing (em ratio) ────────────────────────
      '--coui-letter-spacing-tighter:${CoreLetterSpacing.tighter}em;'
      '--coui-letter-spacing-tight:${CoreLetterSpacing.tight}em;'
      '--coui-letter-spacing-tight20:${CoreLetterSpacing.tight20}em;'
      '--coui-letter-spacing-tight15:${CoreLetterSpacing.tight15}em;'
      '--coui-letter-spacing-tight10:${CoreLetterSpacing.tight10}em;'
      '--coui-letter-spacing-tight5:${CoreLetterSpacing.tight5}em;'
      '--coui-letter-spacing-normal:${CoreLetterSpacing.normal}em;'
      '--coui-letter-spacing-wide:${CoreLetterSpacing.wide}em;'
      '--coui-letter-spacing-wider:${CoreLetterSpacing.wider}em;'
      '--coui-letter-spacing-widest:${CoreLetterSpacing.widest}em;'
      // ── Font family (primary + fallback stack) ───────────
      // Pretendard sits behind the mono face because Geist Mono carries no
      // Hangul — the same order Flutter's bundled fallback draws in.
      '--coui-font-family-sans:"${CoreFontFamily.sans}", '
      'system-ui, '
      'sans-serif;--coui-font-family-mono:"${CoreFontFamily.mono}", '
      '"${CoreFontFamily.sans}", '
      'monospace;'
      // ── Easing (cubic-bezier, intentionally fixed) ──────
      '$_easingCssVariables'
      // ── Box shadow (designer spec) ──────────────────────
      '$_shadowCssVariables'
      // ── Duration (ms) ───────────────────────────────────
      // Indirection point for reduced motion — see the media query below.
      '$_durationCssVariables'
      '}'
      // ── Reduced motion ──────────────────────────────────
      '@media (prefers-reduced-motion:reduce){:root{'
      '$_reducedMotionCssVariables'
      '}}'
      // ── Half-pixel stroke steps ─────────────────────────
      '$_halfPixelStepsRule'
      // ── Minimum pointer target ──────────────────────────
      '$_touchTargetRule'
      // ── Surface fill alpha, reset per surface ───────────
      '$_surfaceFillAlphaRule'
      // ── Injected cast at rest ────────────────────────────
      '$_controlShadowRestRule'
      // ── Surface rim on a class-driven elevation ──────────
      '$_surfaceRimLiftRule'
      // ── Injected boundary ────────────────────────────────
      '$_controlBorderRule'
      // ── Control press-squash affordance ──────────────────
      '$_controlShadowPressRule'
      // ── Control press shrink ─────────────────────────────
      '$_controlPressScaleRule'
      // ── Control focus band vs. inline rest-shadow ────────
      '$_controlFocusBandRule'
      // ── Diff handle rest / hover / held ──────────────────
      '$_diffHandleRule'
      // ── Text input focused active boundary ───────────────
      '$_activeBoundaryRule'
      '$_textAreaFrameActiveBoundaryRule'
      '$_inputFocusBorderRule'
      '$_inputFocusBorderInlineRule'
      '$_textAreaRestBorderRule'
      '$_textAreaHoverBorderRule'
      // ── Hover state layer ────────────────────────────────
      '$_stateLayerHoverRule'
      // ── Skeleton pulse ───────────────────────────────────
      '$_skeletonPulseKeyframes'
      '$_skeletonRestKeyframes';

  /// The `Diff` handle's rest, hover and held looks.
  ///
  /// The strip publishes the three casts, the held scale and the clock as
  /// custom properties ([kDiffHandleShadowVar] and its siblings); the disc
  /// reads the cast and the focus-ring host reads the scale. Hover is the
  /// pointer over the strip — the whole grab area, not just the disc — and
  /// gated on `(hover:hover)` so a touch does not leave the lift behind. Held
  /// is the root's [kDiffDraggingAttribute], which Dart sets for the length
  /// of a gesture, because `:active` would let go when the pointer leaves the
  /// strip mid-drag.
  ///
  /// The shrink is the standalone `scale` property, so it never fights a
  /// `transform` on the same element. The cast rides the disc and the scale
  /// the ring's host for the reason the Flutter twin wraps the scale around
  /// the ring: the ring shrinks with the disc. The host's own inline
  /// `box-shadow` is the focus ring's gap band, so the cast cannot share it.
  ///
  /// Selector specificity is explicit: the held rules carry the strip marker
  /// too, so (0,4,0) beats the hover rule's (0,3,0) wherever the stylesheet
  /// order lands.
  static final _diffHandleRule =
      '.$kDiffHandleDiscMarker{box-shadow:var($kDiffHandleShadowVar,none); '
      'transition:box-shadow var($kDiffHandleDurationVar,0s) $_moveEasing;} '
      '.$kDiffHandleMarker{ '
      'transition:scale var($kDiffHandleDurationVar,0s) $_moveEasing;} '
      '@media (hover:hover){ '
      '.$kDiffHandleStripMarker:hover .$kDiffHandleDiscMarker{ '
      'box-shadow:var($kDiffHandleHoverShadowVar,none);}} '
      '[$kDiffDraggingAttribute] '
      '.$kDiffHandleStripMarker.$kDiffHandleStripMarker '
      '.$kDiffHandleDiscMarker{ '
      'box-shadow:var($kDiffHandlePressedShadowVar,none);} '
      '[$kDiffDraggingAttribute] '
      '.$kDiffHandleStripMarker.$kDiffHandleStripMarker '
      '.$kDiffHandleMarker{ '
      'scale:var($kDiffHandlePressedScaleVar,1);}';

  /// Extends where a marked element accepts a pointer to at least the
  /// WCAG 2.2 minimum, drawing nothing and taking no room.
  ///
  /// `max(100%, …)` is what makes this one rule rather than one per
  /// component: the browser compares the element's own size against the
  /// floor, so nothing in Dart has to know how large the element came
  /// out. That matters for controls sized by their content — a chip's
  /// height comes from its padding and label, and no resolver field
  /// holds it.
  ///
  /// The pseudo-element is centred rather than inset because it may be
  /// *smaller* than its element: an element already past the floor gets a
  /// hit area exactly its own size, which changes nothing.
  ///
  /// **It is a hit area, not an overlay.** It paints nothing, and it sits
  /// *behind* the marked element's content (`z-index:-1`) — reading it as
  /// something layered on top is what the geometry invites and what the
  /// name would suggest, and neither is true. Hit testing walks paint
  /// order in reverse, so being behind only matters where something is in
  /// front: over the element's own content the content wins, and out in
  /// the margin ring — where nothing else is drawn — this is still the
  /// topmost thing and still catches. Wanting exactly the ring is the
  /// whole point.
  ///
  /// That is the Flutter twin's contract rather than an approximation of
  /// it. `_RenderTouchTarget.hitTest` returns early when the element
  /// already meets the floor, and otherwise clamps an outside position to
  /// just inside the child and delegates down (`super.hitTest`) — it never
  /// consumes a hit the child could have had. "Behind the content" is how
  /// CSS says "outside positions only".
  ///
  /// In front it was the hit target for everything inside, so descendants
  /// stopped matching `:hover` and nested controls stopped receiving
  /// clicks: a chip's remove button fired the chip's own tap instead, and
  /// a dot indicator's hover chrome was dead.
  ///
  /// `isolation:isolate` is not decoration — it is the other half. Without
  /// a stacking context here, `z-index:-1` escapes past this element and
  /// lands behind an *ancestor's* background, where it catches nothing at
  /// all; measured, the expansion simply stopped working. With it, the
  /// element's *own* background cannot swallow the ring either: inside a
  /// stacking context a negative-z descendant paints after that background
  /// and before the content. The two declarations only mean this together.
  /// The engage-squash affordance — hides a control's rest `box-shadow`
  /// when the control engages and travels it by the distance the engaged
  /// style throws shadows, so it "sinks into" the shadow it loses. One
  /// shared rule pair, like [_touchTargetRule] above, rather than a
  /// per-instance scoped one every plain button would otherwise have to
  /// emit for nothing.
  ///
  /// "Engage" is not one trigger — it is gated on device capability,
  /// each half in its own `@media (hover: …)` block:
  ///
  /// * `(hover: hover)` — a pointer that can rest without pressing, so
  ///   the rule fires on `:hover` alone. This matches the neo-brutalism
  ///   reference exactly (its `button.tsx`/`switch.tsx` carry the whole
  ///   shadow affordance on `hover:` and never touch `active:`); on a
  ///   desktop, pressing afterward layers no *further* change, because
  ///   `:hover` is already true for the whole press.
  /// * `(hover: none)` — no pointer that can rest, so the rule falls back
  ///   to the pre-existing `:active` trigger instead. A touch device's
  ///   emulated `:hover` fires on tap and then *sticks* until something
  ///   else is tapped, so carrying the `:hover` branch there would leave
  ///   a tapped control looking permanently pressed; `:active` clears the
  ///   moment the finger lifts, which is the only trigger touch has that
  ///   does not stick. Deleting this branch would leave touch with no
  ///   engage affordance at all — it is not a fallback to prune once
  ///   `:hover` exists, it is touch's *only* path to the same effect.
  ///
  /// Both blocks share one declaration body
  /// (`_kEngageShadowDeclarations`, top-level above this class) — same
  /// effect, different trigger — so the two cannot drift apart by
  /// hand-editing only one.
  ///
  /// A single global selector deliberately, in both blocks — a *second*,
  /// `[data-coui-style="X"]`-scoped selector here would out-rank the
  /// high-contrast preference's specificity floor
  /// (`preset_vs_high_contrast_test.dart`'s whole premise: no style rule
  /// may be as specific as `:root:root`); wrapping in `@media` changes
  /// nothing about that — a media query filters *whether* a rule applies,
  /// it adds no selector specificity. So which style is active can only
  /// speak through *values*, not through a second rule — every knob
  /// below is a variable this rule reads, each one undefined (and so
  /// falling to its fallback) under any style that states no
  /// [CoreSurfaceGeometryConstraint.shadowOffsetAdd]
  /// (`surfaceStyleGeometryBlock`):
  ///
  /// * `--coui-control-shadow-offset-x/y` — `0px` baseline, so the
  ///   translate is a no-op under every other style.
  /// * `--coui-control-shadow-press` — undefined baseline, falling back
  ///   to `--coui-button-rest-shadow` (the *same* `box-shadow` value the
  ///   control's own inline style already carries, duplicated into a
  ///   variable by the resolver precisely so this fallback has something
  ///   to point at) — re-declaring a property to the value it already
  ///   has is a no-op, not a clobber, so a control's own rest shadow
  ///   (real, like `Fab`'s elevation, or "nothing", like a plain
  ///   button's unstated one) survives an engage under every style but
  ///   the one that means to touch it.
  ///
  /// `!important` is load-bearing, not a shortcut: the rest `box-shadow`
  /// is emitted inline (a variable reference, not a fixed Tailwind
  /// utility, so it cannot ride a class — the same class-vs-inline split
  /// every other chrome value follows), and an inline declaration
  /// outranks any selector-based rule regardless of specificity. Only
  /// `:hover` or `:active` reaches it — which is exactly why the value it
  /// reaches with has to be a genuine no-op under every other style,
  /// rather than a blanket `none`: `!important` cannot be undone by
  /// specificity, only by the value itself agreeing with what was
  /// already there.
  ///
  /// The `transition` below carries a second group it did not start with:
  /// the control's *chrome* — border radius, padding, border width and
  /// the three colours — on the clock the control publishes through
  /// [kControlChromeDurationVar]. Flutter interpolates that whole set
  /// through one `AnimatedContainer`, and the Web twin was interpolating
  /// only the colours (a Tailwind `transition-colors` utility on the
  /// control), so a runtime `shape` / `size` change snapped on Web and
  /// eased on Flutter.
  ///
  /// It joins *this* declaration rather than getting one of its own
  /// because `transition` is a shorthand: a second declaration on the
  /// same element resets `transition-property` wholesale, so the two
  /// groups can only coexist inside one value. A second class-level rule
  /// would be equally specific and the survivor would be decided by
  /// stylesheet source order; an inline `transition` on the control would
  /// beat every rule here. Either way one group dies silently — which is
  /// what the utility class and this rule were already doing to each
  /// other. See [kControlChromeDurationVar].
  ///
  /// The chrome group's `0s` fallback is what lets the property list be
  /// unconditional: a control that publishes no clock does not animate
  /// the extra properties, so carrying the marker still costs nothing.
  /// The engage group keeps its own clock — pairing a hide with a
  /// travel means both halves must move together, and that pair is not
  /// the per-instance chrome speed. One clock for both trigger blocks,
  /// same reason as `_kEngageShadowDeclarations` (top-level, above this
  /// class): the `:hover` and `:active` branches are the same affordance
  /// wearing a different trigger, not two affordances that happen to
  /// look alike.
  ///
  /// That clock is [kControlEngageDurationVar], falling back to
  /// [durationMsCss]`(CoreDuration.ms50)` — a `var(--coui-duration-50)`
  /// reference, not a bare `50ms` literal (#4407). `--coui-duration-50`
  /// is defined once on `:root` and zeroed under `@media
  /// (prefers-reduced-motion:reduce)` alongside every other
  /// transition-tier step ([_reducedMotionCssVariables]); a literal here
  /// sat outside that indirection and kept animating with the preference
  /// on, even though [_chromeTransitionGroup] right beside it already
  /// reached the same media query. Both halves of the pair name the same
  /// [kControlEngageDurationVar] custom property — same reasoning as
  /// [kControlChromeDurationVar] on [_chromeTransitionClock]: the shared
  /// rule is this element's *sole* `transition` declaration, so a
  /// per-instance override (`CoreButtonStyle.castHideDuration` /
  /// `CoreChipStyle.castHideDuration`) cannot ride its own `transition`
  /// without silently resetting the property list this rule already
  /// states. The control publishes the override (`resolveButton`'s /
  /// `resolveChip`'s `buildRootInlineStyles`, both through
  /// [durationMsCss] so a token-step override still reaches reduced
  /// motion) and this rule reads it back with the token default as the
  /// fallback — a control that states no override still resolves through
  /// `--coui-duration-50`, so carrying the marker costs nothing where
  /// nothing overrides the default. Written once here, it reaches both
  /// the `:hover` and `:active` branches below the same way the
  /// un-varied `50ms` used to — the state this rule must preserve is the
  /// shadow hiding and the control moving, not how fast either one gets
  /// there.
  ///
  /// The travel rides the standalone `translate` property, not
  /// `transform`, for the same reason the `box-shadow` half above reaches
  /// for a variable whose baseline is the control's own rest shadow:
  /// **this rule must be a no-op under every style that states no
  /// offset**, and `transform` cannot be written that way. `transform` is
  /// one property holding the element's whole matrix, so declaring it
  /// here replaces whatever the control was already wearing — and a
  /// control positioned by a transform is wearing its *position* there.
  /// `translate` composes instead: the browser applies it before
  /// `transform`, so a positioning transform survives the press
  /// untouched, and a `0px 0px` offset moves nothing.
  ///
  /// This is not hypothetical. Carousel's prev/next buttons centre
  /// themselves with `-translate-y-1/2`; while this rule wrote
  /// `transform`, pressing one discarded that centring and the button
  /// dropped half its own height, then sprang back on release. The same
  /// hazard is already recorded on the dialog panel's keyframes, which
  /// composite the centring translate into the animation by hand for
  /// exactly this reason — two components hitting one clobber is the rule
  /// being wrong, not the components.
  ///
  /// `transition` names `translate` to match. Naming `transform` there
  /// would leave the travel un-eased while easing a property this rule no
  /// longer writes.
  ///
  /// The whole declaration is `!important` for a reason that has nothing
  /// to do with specificity fights this file already documents
  /// elsewhere: `_kSurfaceGeometryTransitionCss` (`coui_web.dart`) states
  /// its own `transition-property`/`-duration`/`-timing-function` on
  /// `.$kWebSurfaceMarker` — the *same* selector specificity as this rule
  /// (one class each) — and a marked control that also takes a style's
  /// cast (a filled neo-brutalism button, say) carries both classes. Two
  /// equal-specificity rules resolve by source order, and
  /// `_kSurfaceGeometryTransitionCss` is emitted after this one on every
  /// page that turns on `CoUIWeb.enableThemeAnimation` — so it *always*
  /// won on those pages, silently replacing this rule's property list
  /// with one that never names `translate` and clocks `box-shadow` at
  /// the surface-crossfade duration instead of the press one.
  ///
  /// The visible result was not a jank artefact — it was a firm 1:2 ratio
  /// every time. `translate`, dropped from the property list, has no
  /// transition and jumps to its engaged offset in the same frame the
  /// pointer enters; `box-shadow`, still named (the surface rule's list
  /// happens to include it), keeps interpolating for the surface
  /// duration with the control already sitting at its final position.
  /// For that whole window the cast's own offset is contracting toward
  /// zero *relative to a box that has already arrived* — so its measured
  /// page position runs from twice the resting offset down to the
  /// resting offset itself, a real excursion outward before it retreats.
  /// A shadow you can watch slide away from a button that already
  /// stopped moving reads as "the shadow moved with the button" — the
  /// symptom this rule exists to close. Reshaping what the *values*
  /// interpolate toward cannot fix this: the property being interpolated
  /// was never this rule's in the first place. Confirmed
  /// against the running docs site, not just this file's own tests —
  /// `getComputedStyle` on a hovered neo-brutalism `Button` showed
  /// exactly `_kSurfaceGeometryTransitionCss`'s property list and
  /// `0.15s` duration before this fix, and this rule's own list and
  /// `--coui-duration-50` after it.
  ///
  /// `!important` is safe here for the same reason it already is on
  /// [_kEngageShadowDeclarations]'s `box-shadow` line: `chip_style.dart`
  /// and `button_style.dart` both state, as a precondition of carrying
  /// this marker, that "this rule owns this element's only `transition`"
  /// — no per-instance override rides its own `transition` declaration
  /// (a per-instance clock override instead re-publishes the *variables*
  /// this rule reads, [kControlEngageDurationVar] /
  /// [kControlChromeDurationVar], exactly so it never has to compete with
  /// this declaration for the property itself). `!important` turns that
  /// precondition into something the cascade enforces rather than
  /// something a sibling rule's emission order happens to respect.
  static final _controlShadowPressRule =
      '.$kControlShadowPressMarker{transition:'
      'translate var($kControlEngageDurationVar,'
      '${durationMsCss(CoreDuration.ms50)}),'
      'box-shadow var($kControlEngageDurationVar,'
      '${durationMsCss(CoreDuration.ms50)}),'
      '$_pressScaleTransition,'
      '$_chromeTransitionGroup !important;}@media '
      '(hover:hover){.$kControlShadowPressMarker:hover'
      '{$_kEngageShadowDeclarations}}@media '
      '(hover:none){.$kControlShadowPressMarker:active'
      '{$_kEngageShadowDeclarations}}';

  /// Paints the focus ring's gap band on a control whose rest
  /// `box-shadow` comes from `Button`'s shadow resolver.
  ///
  /// The ring itself is an outline (`focusRingClassName` /
  /// `focusRingScopedRule`), which no `box-shadow` declaration touches —
  /// so the ring needs nothing here. The band is different: it is a
  /// `box-shadow` layer, and `Button` writes its rest/press cast as an
  /// *unconditional* inline `box-shadow` (`'none'` on a control that
  /// casts nothing, a variable reference on one that does —
  /// `buildRootInlineStyles`'s `raw['box-shadow'] = restShadow`). An
  /// inline declaration outranks any selector-based rule regardless of
  /// specificity, so a band emitted as a class or scoped rule would
  /// compile, match on `:focus-visible`, and never paint. Only
  /// `!important` reaches past it.
  ///
  /// So the band travels as a value: a button whose band paints carries
  /// [kFocusBandMarker] and publishes the band layer inline on
  /// [kFocusBandVar]; this rule composes it over the control's own rest
  /// shadow in that order, so a control that casts something keeps
  /// casting it under the band. A button with the default transparent
  /// band carries no marker, and its focus leaves `box-shadow` alone.
  ///
  /// The band-on button's resting inline `box-shadow` leads with the same
  /// band at zero alpha (`resolveButton`'s `focusBandRest`), so rest and
  /// focus carry the same layers in the same order. `box-shadow`
  /// interpolates layer by index on this control's engage clock; without
  /// the resting twin the band would pair with the first cast layer and
  /// the cast would swing into the band instead of the band fading in.
  ///
  /// Reads `--coui-button-rest-shadow-layer`, not
  /// `--coui-button-rest-shadow` itself — a *list-item-safe* twin of it
  /// `buildRootInlineStyles` also publishes. `none` is only valid as an
  /// entire `box-shadow` property value, not as one item in this rule's
  /// comma-separated list (`<shadow>#` excludes it), and a control that
  /// casts nothing states exactly that literal. Substituting `none` into
  /// the list position makes the *whole* declaration invalid at
  /// computed-value time, which falls back to `box-shadow`'s initial
  /// value — swallowing the band with it.
  ///
  /// The marker pair makes the selector (0,3,0), above the engage rules'
  /// (0,2,0) `:hover` / `:active` blocks in [_controlShadowPressRule]:
  /// a focused, hovered band-on control keeps its band rather than
  /// trading it for the engaged cast.
  ///
  /// One global marker-class selector, not one scoped per style, for the
  /// identical reason [kControlShadowPressMarker] is: a
  /// `[data-coui-style="X"]`-scoped rule here would out-rank the plain
  /// selector the high-contrast preference's specificity floor is built
  /// to clear (`preset_vs_high_contrast_test.dart`). Which style is
  /// active speaks only through the `--coui-button-rest-shadow-layer`
  /// value this rule reads, never through a second, more specific rule.
  ///
  /// Reaches `Fab` for free — it composes its main/action buttons from
  /// `Button` rather than drawing its own root.
  static const _controlFocusBandRule =
      '.$kControlShadowPressMarker.$kFocusBandMarker:focus-visible{'
      'box-shadow:var($kFocusBandVar,0'
      ' 0 #0000),var(--coui-button-rest-shadow-layer,0'
      ' 0 #0000) !important;}';

  /// Paints a text input's focused active boundary — the width the focused
  /// boundary adds beyond the resting border, as an inset `box-shadow`.
  ///
  /// `TextField` / `TextArea` keep their resting `border` in the layout
  /// and draw only the difference, so the content does not move when the
  /// boundary widens. The box that draws the boundary carries
  /// [kActiveBoundaryMarker] (the bare `<input>` / `<textarea>`, which is
  /// itself the focused element) or [kActiveBoundaryWithinMarker] (the
  /// affix wrapper around it) and publishes the whole layer inline on
  /// [kActiveBoundaryVar]; this rule reads it while the box is focused.
  /// The same pseudo the box's `focus-visible:` / `focus-within:` border
  /// tint rides.
  ///
  /// One global marker-class selector rather than a rule per instance, so
  /// a field needs no id and no `<style>` element for its boundary. The
  /// selector is (0,2,0) and needs no `!important`: the only other
  /// `box-shadow` this kit writes on these boxes is the error boundary,
  /// inline on the same element and gated apart from the marker (an error
  /// box carries none), so the two never meet. The focus ring is an
  /// `outline` on the `FocusOutline` wrapper one element out, and none of
  /// the shared shadow markers ([kControlShadowRestMarker],
  /// [kControlShadowPressMarker], [kSurfaceRimLiftMarker]) is on a text
  /// input box — the active-boundary tests hold that. An app's
  /// class-level rule on the same box outranks this one; that is the
  /// override door left open on purpose — `!important` is for a
  /// declaration that has to beat an inline style, which this one never
  /// meets.
  static const _activeBoundaryRule =
      '.$kActiveBoundaryMarker:focus-visible,'
      '.$kActiveBoundaryWithinMarker:focus-within{'
      'box-shadow:var($kActiveBoundaryVar);}';

  /// A footed text area's box follows only its own editing surface's focus.
  /// The exact first-row selector excludes controls in the footer. The
  /// instance publishes the existing layer on this same box; no inline
  /// resting shadow competes here, so the declaration stays non-important.
  static const _textAreaFrameActiveBoundaryRule =
      '.$kTextAreaFrameBoundaryMarker$kTextAreaFrameFocusSelector{'
      'box-shadow:var($kActiveBoundaryVar);}';

  /// Consumes the focused stroke on the actual input box, even when no
  /// extra boundary shadow is drawn. A footer control does not focus its
  /// frame; the existing exact first-row predicate remains the owner.
  static const _inputFocusBorderRule =
      '.$kInputFocusBorderWithinMarker:focus-within,'
      '.$kTextAreaFrameFocusBorderMarker$kTextAreaFrameFocusSelector{'
      'border-color:var($kInputFocusBorderVar);}';

  /// Only TextField's explicit inline resting/error edge competes with
  /// this state declaration. Important beats that normal inline value;
  /// zero specificity preserves the caller's important-class priority.
  static const _inputFocusBorderInlineRule =
      ':where(.$kInputFocusBorderInlineMarker:focus-within){'
      'border-color:var($kInputFocusBorderVar) !important;}';

  /// Raw idle values belong to the box that paints the border.
  /// Zero specificity leaves normal caller classes and ID rules available.
  /// No inline border competes on this path, so the reader is not important.
  /// Disabled raw idle is excluded only by physical hover: a footer/affix
  /// control taking focus cannot erase the disabled editing surface's rest.
  static const _textAreaRestBorderRule =
      ':where(.$kTextAreaRestWithinMarker:not(:hover):not(:focus-within)),'
      ':where(.$kTextAreaRestFrameMarker:not(:hover)'
      ':not($kTextAreaFrameFocusSelector)),'
      ':where(.$kTextAreaRestDisabledMarker:not(:hover)){'
      'border-color:var($kTextAreaRestBorderVar);}';

  static const _textAreaHoverBorderRule =
      '.$kTextAreaHoverWithinMarker:hover:where(:not(:focus-within)),'
      '.$kTextAreaHoverFrameMarker:hover'
      ':where(:not($kTextAreaFrameFocusSelector)){'
      'border-color:var($kTextAreaHoverBorderVar);}';

  /// Lays a box's hover state layer — a flat `linear-gradient` of the
  /// published colour ([kStateLayerHoverVar]) painted as the box's
  /// `background-image`, i.e. over its `background-color` and under its
  /// content.
  ///
  /// The box that wears the layer carries [kStateLayerHoverMarker] and
  /// publishes the colour (already at the hover weight) inline. A
  /// `background-image` rather than a second `background-color`, so the face
  /// stays the face: the chosen segment's raised fill, an edited segment's
  /// primary-container fill and a transparent unchosen segment all keep
  /// their own colour and the layer is added over them. One global
  /// marker-class selector, so a box needs no id and no `<style>` element.
  static const _stateLayerHoverRule =
      '.$kStateLayerHoverMarker:hover{'
      'background-image:linear-gradient(var($kStateLayerHoverVar),'
      'var($kStateLayerHoverVar));}';

  /// The chrome half of [_controlShadowPressRule]'s `transition` — the
  /// properties Flutter's chrome `AnimatedContainer` interpolates, each on
  /// the clock the control publishes through [kControlChromeDurationVar].
  ///
  /// Named per property rather than through `all`: `all` would drag
  /// `transform` and `box-shadow` onto the chrome clock and desync the
  /// press pair, and Tailwind offers no utility for two clocks in one
  /// declaration anyway (an arbitrary-value class is what the token guard
  /// forbids).
  ///
  /// `color` is here because the Web control already transitioned it
  /// (Tailwind's `transition-colors` names it) and dropping it would be a
  /// visual regression on hover. Flutter's label snaps instead — its
  /// colour rides `DefaultTextStyle.merge`, outside the animated
  /// container — so the two platforms disagree on this one property in
  /// the *opposite* direction from the rest of the group. Kept
  /// deliberately: closing it means animating the Flutter label, not
  /// freezing the Web one.
  ///
  /// `outline-color` is here because the focus ring is an outline that
  /// fades between transparent and the ring colour, the same fade the
  /// Flutter `FocusOutline` runs on its ring. Without it this rule —
  /// which owns the control's only `transition`, `!important` — would
  /// leave the ring snapping on while everything around it eases.
  ///
  /// The curve is named through the alias tier — movement between two
  /// on-screen states — rather than by the raw curve it currently pins,
  /// so a systemic easing change reaches this the way it reaches every
  /// component. (This file is exempt from the alias guard because its
  /// config block has to enumerate all 34 raw curves; that exemption is
  /// about enumerating, not about choosing.) The fallback spells the same
  /// alias out as a literal curve, because an unresolvable `var()` inside
  /// a shorthand drops the *whole* declaration — a page rendered without
  /// the variable block would lose the press pair too, not just the
  /// easing it was missing.
  static final String _chromeTransitionGroup = [
    'color',
    'background-color',
    'border-color',
    'outline-color',
    'border-width',
    'border-radius',
    'padding',
  ].map((property) => '$property $_chromeTransitionClock').join(',');

  /// `<duration> <timing-function>` shared by every property in
  /// [_chromeTransitionGroup] — see there for both fallbacks.
  static final _chromeTransitionClock =
      'var($kControlChromeDurationVar,0s) $_moveEasing';

  /// The movement curve both clocks of [_controlShadowPressRule] ease on
  /// — the alias variable, with the literal curve as the fallback (see
  /// [_chromeTransitionGroup] for why the fallback is load-bearing).
  static final _moveEasing =
      'var(--easing-${CoreEasing.scale.standard},'
      '${_bezierTuple(CoreEasing.move)})';

  /// The press shrink's entry in [_controlShadowPressRule]'s `transition`
  /// — the standalone `scale` property on the engage clock, eased on the
  /// movement curve.
  ///
  /// The engage clock because that is the clock the Flutter twin runs the
  /// shrink on: `Button` hands `Clickable` its `castHideDuration` as the
  /// press duration, and `Clickable` animates `pressedScale` over it on
  /// `CoreEasing.move`. It joins the shared declaration rather than
  /// getting its own for the reason every other entry does — that
  /// declaration is the control's only `transition`.
  static final _pressScaleTransition =
      'scale var($kControlEngageDurationVar,'
      '${durationMsCss(CoreDuration.ms50)}) $_moveEasing';

  /// The press shrink for a control carrying [kControlPressScaleMarker].
  ///
  /// `:active` is the press, gated on `:hover` too for hover-capable
  /// pointers so dragging a press off the control releases it — the
  /// Flutter twin un-scales on `onTapCancel` the same way (and the
  /// `Clickable` rule in `coui_web.dart` uses the same split). Touch
  /// pointers keep the plain `:active`. `:not(:disabled)` because a
  /// disabled `<button>` must not animate a press it will not act on.
  ///
  /// The factor is `1 - (1 - scale) × shrink`: [kControlPressScaleVar] is
  /// how far this control shrinks, [kControlPressShrinkVar] is whether
  /// the active style lets it. A style whose engage signal is the shift
  /// into the cast sets the second to `0` and the product collapses to
  /// the identity — the Flutter resolver's `pressedScale` pin, expressed
  /// through values because a per-style selector here would out-rank the
  /// high-contrast specificity floor (`kControlShadowPressMarker`'s doc).
  ///
  /// Only `:active` sets `scale`, so a control at rest renders exactly as
  /// it did before this rule existed.
  static const _controlPressScaleRule =
      '@media (hover:hover){$_kPressScaleHoverSelector '
      '{$_kPressScaleDeclaration}} '
      '@media (hover:none){$_kPressScaleTouchSelector '
      '{$_kPressScaleDeclaration}}';

  /// Every marked surface starts from an opaque fill alpha and no border for
  /// the edge band to reach over.
  ///
  /// A surface publishes [kWebSurfaceFillAlphaVar] only when its fill token
  /// is translucent, and a custom property inherits — so without this a
  /// marked surface with an opaque fill, nested in a translucent one, would
  /// read its ancestor's alpha and paint at a fraction of its share. The same
  /// goes for [kWebSurfaceBleedVar], which only a surface that keeps a border
  /// of its own states: a button inside a field would otherwise draw its band
  /// past its own edge by the field's border. Reset on every marked element
  /// instead, at zero specificity (`:where`), so what a surface publishes
  /// itself — inline, or through a class at any pseudo-state — always wins
  /// over it.
  static const _surfaceFillAlphaRule =
      ':where(.$kWebSurfaceMarker){$kWebSurfaceFillAlphaVar:1;'
      '$kWebSurfaceBleedVar:0px;$kWebSurfaceBleedTopVar:initial;'
      '$kWebSurfaceBleedBottomVar:initial;$kWebSurfaceEdgeStyleVar:initial;'
      '$kWebSurfaceFoldVar:initial;}';

  /// The terms [id]'s recipe lays over its backdrop pass, or nulls for the
  /// ones it does not state.
  ///
  /// They ride the pass, so a recipe none of whose surfaces draws one has
  /// nothing for them to act on; a shade of nothing is no shade.
  ({CoreSurfaceFrost? frost, CoreSurfaceBodyShade? shade}) _finishOf(
    CoreSurfaceStyleId id,
  ) {
    final recipe = _recipeFor(id);
    final drawsPass = CoreSurfaceRole.values.any(
      (role) => recipe.surfaceFor(role)?.blurRadius != null,
    );
    if (!drawsPass) return (frost: null, shade: null);
    final shade = recipe.bodyShade;

    return (
      frost: recipe.frost,
      shade: shade == null || shade.isIdentity ? null : shade,
    );
  }

  /// The frost's filter reference in [mode], or null when the style states no
  /// frost.
  static String? _frostUrl(CoreSurfaceFrost? frost, CoreBrightness mode) {
    final cloud = frost?.atBrightness(mode);
    if (cloud == null) return null;

    return surfaceFinishFilterUrl(
      surfaceFrostFilterMarkup(sigma: cloud.sigma, opacity: cloud.opacity),
    );
  }

  /// The body shade's filter reference in [mode], or null when the shade
  /// states none there.
  static String? _shadeUrl(CoreSurfaceBodyShade? shade, CoreBrightness mode) {
    if (shade == null) return null;
    final strength = shade.strengthFor(mode);
    if (strength <= 0) return null;

    return surfaceFinishFilterUrl(
      surfaceBodyShadeFilterMarkup(strength: strength),
    );
  }

  /// The name of the `:root` custom property that holds the filter reference
  /// a style uses for [base] in [mode].
  ///
  /// The dark mode borrows the light name when the two modes draw the same
  /// document, so a term that does not differ by mode is defined once.
  static String _finishDefinitionVar(
    String base,
    CoreSurfaceStyleId id,
    CoreBrightness mode, {
    required String? light,
    required String? dark,
  }) {
    final useDark = mode == CoreBrightness.dark && dark != light;

    return '$base-${id.name}-${useDark ? 'dark' : 'light'}';
  }

  /// The filter documents of one style, defined once on `:root`.
  ///
  /// Every rule that draws the frost or the shade names these through
  /// [kWebSurfaceFrostVar] and [kWebSurfaceShadeVar]. A document is a few
  /// hundred characters of percent-encoded SVG, and a style restates its
  /// surface rules for every role, depth, palette and scope: spelling the
  /// document in each of them would add tens of kilobytes to the sheet for a
  /// term that is the same everywhere. A definition on `:root` has no
  /// selector to get wrong — every element inherits it, whatever carries
  /// the style attribute — and the rules that choose between modes keep
  /// choosing, by naming a different definition.
  String _surfaceFinishDefinitions(CoreSurfaceStyleId id) {
    final (:frost, :shade) = _finishOf(id);
    final out = StringBuffer();
    void define(String base, String? light, String? dark) {
      if (light != null) {
        final name = _finishDefinitionVar(
          base,
          id,
          CoreBrightness.light,
          light: light,
          dark: dark,
        );
        out.write('$name:$light;');
      }
      if (dark != null && dark != light) {
        final name = _finishDefinitionVar(
          base,
          id,
          CoreBrightness.dark,
          light: light,
          dark: dark,
        );
        out.write('$name:$dark;');
      }
    }

    define(
      kWebSurfaceFrostVar,
      _frostUrl(frost, CoreBrightness.light),
      _frostUrl(frost, CoreBrightness.dark),
    );
    define(
      kWebSurfaceShadeVar,
      _shadeUrl(shade, CoreBrightness.light),
      _shadeUrl(shade, CoreBrightness.dark),
    );

    return out.isEmpty ? '' : ':root{$out}';
  }

  /// Takes the frost and the body shade away under high contrast and forced
  /// colours.
  ///
  /// `!important` is what lets one mode-free rule beat every palette's own
  /// definition of the two properties (the dark rules, the scopes, the OS
  /// form), whatever their specificity — an important declaration is compared
  /// before specificity is. `initial` is the guaranteed-invalid value, which
  /// the list's `var(--x,)` answers with its empty fallback, so the list
  /// itself is never restated. `:where()` keeps the selector at no
  /// specificity of its own and out of the way of everything else.
  ///
  /// Reduce-transparency needs no rule of its own: it takes the whole
  /// `backdrop-filter` away (see the end of [surfaceStyleTreatmentBlock]).
  static String _surfaceFinishAccessibilityRule({
    required bool frost,
    required bool shade,
  }) => [
    '@media (prefers-contrast:more),(forced-colors:active){',
    ':where(.$kWebSurfaceMarker,.$kWebLocalSurfaceMarker){',
    if (frost) '$kWebSurfaceFrostVar:initial !important;',
    if (shade) '$kWebSurfaceShadeVar:initial !important;',
    '}}',
  ].join();

  /// Takes the frost and the body shade away where the browser draws no SVG
  /// filter named in `backdrop-filter`, by two routes that blank the same two
  /// properties the same way.
  ///
  /// Such a browser draws nothing for a list that names one — the surface's
  /// own blur and saturation included — so the two terms cost the glass its
  /// blur there. A layer the browser has drawn from such a list stays without
  /// its blur when the list changes afterwards (measured in Safari 27.0: the
  /// computed list is clean and the pixels are those of a pane without a
  /// filter), so a rule that lands after the first paint cannot heal a
  /// surface that was painted from the list. Hence two routes:
  ///
  /// * [_surfaceFinishWebKitQuery]: a feature query WebKit answers and Blink
  ///   does not, which applies from the first paint, before any script ran;
  /// * [_surfaceFinishEngineScope]: the attribute the browser build writes on
  ///   `<html>` for every browser the user-agent answer calls unsupported —
  ///   the one answer the refraction reads, Gecko included — which reaches
  ///   the surfaces that are created after it lands.
  ///
  /// Both answer the way [_surfaceFinishAccessibilityRule] answers a contrast
  /// preference: `initial` is the guaranteed-invalid value, which the list's
  /// `var(--x,)` answers with its empty fallback, and `!important` beats every
  /// palette's own definition of the two properties whatever its specificity.
  static String _surfaceFinishEngineRule({
    required bool frost,
    required bool shade,
  }) {
    final body = [
      if (frost) '$kWebSurfaceFrostVar:initial !important;',
      if (shade) '$kWebSurfaceShadeVar:initial !important;',
    ].join();

    return '$_surfaceFinishWebKitQuery{$_surfaceFinishMarked{$body}}'
        '$_surfaceFinishEngineScope{$body}';
  }

  /// Every marked surface. `:where()` keeps the marker out of the
  /// specificity, as in the accessibility rule.
  static const _surfaceFinishMarked =
      ':where(.$kWebSurfaceMarker,.$kWebLocalSurfaceMarker)';

  /// The marked surfaces on a page whose `<html>` carries
  /// [kWebSvgBackdropAttribute]: the attribute route of
  /// [_surfaceFinishEngineRule].
  static const _surfaceFinishEngineScope =
      ':root[$kWebSvgBackdropAttribute="$kWebSvgBackdropOff"] '
      '$_surfaceFinishMarked';

  /// The feature query of the first-paint route of
  /// [_surfaceFinishEngineRule]: true where the browser has the Apple Pay
  /// button property or the system-font keywords.
  ///
  /// Both are Apple's own, which the browser engines that are not WebKit have
  /// no reason to adopt (Chrome 156 answers false to both, Safari 27.0 true to
  /// both); a standard feature that Blink may one day ship would take the
  /// frost and the shade from the browser that draws them. Either one is
  /// enough, so that one being dropped from WebKit leaves the other to answer.
  static const _surfaceFinishWebKitQuery =
      '@supports (-apple-pay-button-style:black) or (font:-apple-system-body)';

  /// Every marked surface starts from the preset's rim light and law.
  ///
  /// [_surfaceRuntimeInputs] states an angle or a law on a surface only where
  /// a tuning moved it off the preset, and a custom property inherits: a
  /// surface that states none, nested in one that does, would read its
  /// ancestor's. A preview of another style inside a tuned page would draw
  /// its rim from the page's light. Reset on every marked element at zero
  /// specificity, like [_surfaceFillAlphaRule], so what a surface states
  /// itself always wins — and written only into a sheet that states one, so
  /// an untuned sheet is the sheet it was.
  static const _surfaceRuntimeInputsReset =
      ':where(.$kWebSurfaceMarker,.$kWebLocalSurfaceMarker){'
      '$kWebSurfaceRimAngleVar:initial;'
      '$kWebSurfaceRimAngleDarkVar:initial;'
      '$kWebSurfaceRefractionModelVar:initial;'
      '$kWebSurfaceRimSweepDarkVar:initial;'
      '}';

  /// The cast a surface takes when it states no rest shadow of its own.
  ///
  /// One class-level selector on purpose — see [kControlShadowRestMarker]
  /// for why this rides a class rather than going inline, and why being
  /// *out-ranked* by `hover:shadow-*` is the point rather than a defect.
  /// Resolves to a genuine no-op under every style that states no cast,
  /// so carrying the marker costs nothing where there is nothing to cast.
  static const _controlShadowRestRule =
      '.$kControlShadowRestMarker{box-shadow:var(--coui-control-shadow);}';

  /// Appends the style's surface rim to a surface whose elevation rides
  /// the `shadow-*` / `hover:shadow-*` classes.
  ///
  /// The value is Tailwind's own `box-shadow` composition (ring offset,
  /// ring, `--tw-shadow`) with the rim as a fourth layer. The elevation
  /// classes vary only `--tw-shadow`, so hovering still changes the lift
  /// and the rim stays on in both states — see [kSurfaceRimLiftMarker]
  /// for why neither inline nor an ID-scoped rule can do this.
  ///
  /// The selector repeats the marker three times on purpose: (0,3,0) is
  /// one class-level selector more than `hover:shadow-*` (0,2,0), so the
  /// rim survives hover whichever of this stylesheet and Tailwind's lands
  /// later in the document. Out-ranking it costs nothing, because this
  /// rule reads every variable the hover class writes.
  ///
  /// Under every style but the one that states a rim,
  /// `--coui-surface-rim` is [_kNoRim] — the declaration renders exactly
  /// what the elevation class alone would.
  static const _surfaceRimLiftRule =
      '.$kSurfaceRimLiftMarker.$kSurfaceRimLiftMarker.$kSurfaceRimLiftMarker{'
      'box-shadow:var(--tw-ring-offset-shadow,0 0 #0000), '
      'var(--tw-ring-shadow,0 0 #0000), '
      'var(--tw-shadow,0 0 #0000), '
      '$kSurfaceRimVar;}';

  /// The boundary a surface takes when it draws none of its own.
  ///
  /// Falls through to a `0` width under every style that contributes
  /// nothing, so the marker is inert rather than conditional — the same
  /// arrangement [_controlShadowRestRule] uses, and for the same reason:
  /// a per-style selector here would out-rank the plain one the
  /// high-contrast preference has to clear.
  static const _controlBorderRule =
      '.$kControlBorderMarker{border:var(--coui-control-border,0px) solid '
      'rgb(var(--coui-outline));}';

  static String get _touchTargetRule =>
      '.$kWebTouchTargetMarker{position:relative;isolation:isolate;}'
      '.$kWebTouchTargetMarker::after{content:"";position:absolute;'
      'left:50%;top:50%;transform:translate(-50%,-50%);'
      'width:max(100%,$_touchTargetFloor);'
      'height:max(100%,$_touchTargetFloor);'
      'z-index:-1;}';

  /// The floor the pointer-target rule holds an element to — the element's
  /// own [kWebTouchTargetVar] where it states one, the WCAG minimum
  /// otherwise.
  static String get _touchTargetFloor =>
      'var($kWebTouchTargetVar,${CoreTouchTarget.minimum}px)';

  /// Global `@keyframes` for the `Skeleton` pulse animation.
  ///
  /// `Skeleton` emits `--pulse-from` / `--pulse-to` custom properties
  /// inline on every node (see `resolveSkeleton`) rather than relying on
  /// Tailwind's built-in `animate-pulse` keyframes, which hardcode
  /// `opacity: 1 → 0.5 → 1` and read nothing — so a
  /// `CoreSkeletonStyle.fromOpacity` / `toOpacity` override was silently
  /// dropped on Web while Flutter honoured it.
  ///
  /// It animates the FILL, not the element. Flutter pulses the fill's
  /// alpha between the same two ends, which fades the surface and
  /// leaves everything else alone; animating `opacity` here faded the node
  /// and every descendant with it. Identical on a bare block, different the
  /// moment a skeleton has a border or a child, and different against
  /// whatever sits behind it in both cases.
  ///
  /// Injected once (not per-instance): a CSS custom property inside
  /// `@keyframes` resolves against the *animated element's own* computed
  /// style, so one shared rule renders every instance's own colours — and
  /// because the token reference sits inside the composed colour, dark mode
  /// keeps tracking through the animation.
  static const _skeletonPulseKeyframes =
      '@keyframes $kSkeletonPulseAnimationName'
      '{0%,100%{background-color:var(--pulse-from)}'
      '50%{background-color:var(--pulse-to)}'
      '}';

  /// The keyframes reduced motion runs in place of the pulse — the resting
  /// end held (see `kSkeletonRestAnimationName`).
  static const _skeletonRestKeyframes =
      '@keyframes $kSkeletonRestAnimationName{ '
      'from,to{background-color:var(--pulse-from)}'
      '}';

  /// CSS `:root { ... }` block for dark mode — the dark palette and the
  /// dark shadow strength.
  String get cssVariablesDark =>
      '${PrimitiveCssGenerator.toCssBlockFrom(_source, brightness: 'dark')}'
      ':root{$_darkShadowStrength}';

  /// The `[data-theme="dark"]{…}` rule, ready to inject.
  ///
  /// Assembling this selector was left to each consuming app, which meant
  /// every app that wanted dark mode had to know the attribute name and the
  /// variable list. Emitting it from the one place that already knows the
  /// palette removes that duplication; how the app injects it — a `<style>`
  /// tag, a JS-created sheet — remains the app's decision.
  String get darkVariableBlock {
    final vars = semanticDarkVars.entries
        .map((e) => '${e.key}:${e.value}')
        .join(';');

    return '[data-theme="dark"]{$vars;$_darkShadowStrength}';
  }

  /// The dark scope's shadow strength — every cast layer's alpha is
  /// multiplied by it (`kShadowStrengthVariable`). Stated beside the dark
  /// palette, in every dark scope, because brightness is what decides it;
  /// the style blocks never write it, so a style's bent stacks are
  /// strengthened by the same rule as the plain ones.
  static const String _darkShadowStrength =
      '$kShadowStrengthVariable:${CoreShadow.darkStrength}';

  /// The same dark palette, keyed off the OS preference instead of an
  /// attribute — ready to inject.
  ///
  /// [darkVariableBlock] only ever applies when something writes
  /// `data-theme="dark"` onto the document, and the only thing that writes it
  /// is `CoUIThemeController` at runtime. A statically rendered site with no
  /// theme controller therefore has **no path to dark mode at all**: the
  /// palette exists, the emitter exists, and nothing can reach it without
  /// shipping JS whose whole job is to set one attribute before first paint.
  ///
  /// This emits the media-query form so the browser applies it directly.
  ///
  /// `:root:not([data-theme="light"])` is what keeps the two compatible: a
  /// visitor who has explicitly chosen light still gets light even while the
  /// OS says dark. Inject [darkVariableBlock] *before* this one so an explicit
  /// `data-theme="dark"` also keeps winning — both rules then agree with the
  /// more specific statement rather than with source order.
  String get darkAutoVariableBlock {
    final vars = semanticDarkVars.entries
        .map((e) => '${e.key}:${e.value}')
        .join(';');

    return '@media '
        '(prefers-color-scheme:dark){'
        ':root:not([data-theme="light"]){$vars;$_darkShadowStrength}'
        '}';
  }

  /// One rule per density other than the default, keyed off the
  /// `data-coui-density` attribute (`kDensityAttribute`).
  ///
  /// Each rule re-points the variables the density moves, and only those:
  /// the spacing steps on the 4px grid, the control-row heights, and the
  /// corners on the band a row's corner lives on — each to the step
  /// `CoreDensity` draws there, the same function Flutter applies at its
  /// conversions. Writing an unchanged step would be a declaration that
  /// asserts a difference that does not exist.
  ///
  /// Corners are also re-pointed by a surface style. A page that carries
  /// both attributes gets the composed corner from the rule
  /// [surfaceStyleVariableBlocks] writes for the pair; this rule alone is
  /// the right answer under the default style, whose corners are identity.
  String get densityVariableBlocks {
    final buffer = StringBuffer();
    for (final density in CoreDensity.values) {
      if (density == .defaultDensity) continue;
      final vars = StringBuffer();
      for (final step in CoreSpace.steps) {
        final bent = density.space(step);
        if (bent != step) {
          vars.write('--coui-space-${step.toInt()}:${bent / 16}rem;');
        }
      }
      for (final height in CoreControlSize.steps) {
        final bent = density.controlHeight(height);
        if (bent != height) {
          vars.write(
            '--coui-control-height-${height.toInt()}:${bent / 16}rem;',
          );
        }
      }
      for (final step in kRadiusSteps) {
        final bent = density.radius(step.value);
        if (bent != step.value) {
          vars.write('--coui-radius-${step.key}:${bent}px;');
        }
      }
      buffer.write('[$kDensityAttribute="${density.name}"]{$vars}');
    }

    return buffer.toString();
  }

  /// The corners one surface style draws under each density — the rule for
  /// a page that carries both attributes.
  ///
  /// Two rules of equal specificity cannot compose: under
  /// `[data-coui-style]` and `[data-coui-density]` alone, whichever came
  /// last in the sheet would win each variable, and the corner would be
  /// the style's or the density's rather than the style's *of* the
  /// density's. The pair selector outranks both and states the composed
  /// value the shared seat computes (`resolveThemeGeometry` — density first,
  /// then the style), for every step either single rule writes.
  ///
  /// A style whose corners are identity needs no pair rule: the density's
  /// own rule is already the composed answer.
  String surfaceStyleDensityBlocks(
    CoreSurfaceStyleId id,
    CoreSurfaceGeometryConstraint geometry,
  ) {
    if (geometry.radiusFloor == null && geometry.radiusCap == null) return '';
    final buffer = StringBuffer();
    for (final density in CoreDensity.values) {
      if (density == .defaultDensity) continue;
      final composed = geometry.atDensity(density);
      final vars = StringBuffer();
      for (final step in kRadiusSteps) {
        final styled = geometry.radius(step.value);
        final moved = density.radius(step.value);
        final both = composed.radius(step.value);
        if (styled == step.value && moved == step.value && both == step.value) {
          continue;
        }
        vars.write('--coui-radius-${step.key}:${both}px;');
      }
      buffer.write(
        '[$kSurfaceStyleAttribute="${id.name}"]'
        '[$kDensityAttribute="${density.name}"]{$vars}',
      );
    }

    return buffer.toString();
  }

  /// Rules that redefine the palette for each surface style, in both modes.
  ///
  /// Selecting a style sets `data-coui-style` on the document; these rules
  /// are what that attribute switches on. The dark rule qualifies both
  /// attributes so it outranks the plain style rule — otherwise which of
  /// "dark" and "styled" won would come down to source order, and the two
  /// axes would stop combining.
  ///
  /// A style whose recipe makes no colour statement emits nothing at all.
  /// Emitting an identical block per style would be dead CSS that still has
  /// to be parsed, and would make the stylesheet imply a difference no one
  /// can see.
  String get surfaceStyleVariableBlocks {
    final buffer = StringBuffer();

    for (final id in CoreSurfaceStyleId.values) {
      if (id == .defaultId) continue;

      // Resolved once. Four separate `of(id)` lookups were equivalent while
      // the recipe was a constant; with tuning they are four chances for one
      // of them to read the untuned preset, which would emit a stylesheet
      // whose colour block and geometry block describe different styles.
      final recipe = _recipeFor(id);

      final constraint = recipe.colorConstraint;
      if (!constraint.isIdentity) {
        buffer.write(surfaceStyleBlock(id, constraint));
      }

      final geometry = recipe.geometry;
      final typography = recipe.typography;
      if (!geometry.isIdentity || !typography.isIdentity) {
        buffer.write(
          surfaceStyleGeometryBlock(id, geometry, typography: typography),
        );
      }
      buffer.write(surfaceStyleDensityBlocks(id, geometry));

      // One rule per (role × depth) the recipe actually distinguishes.
      //
      // Emitted in ascending depth so the cascade reads in the same order
      // as the specificity ladder — not load-bearing (the ladder is
      // strict, so order cannot decide anything) but a sheet whose source
      // order contradicts its specificity is a trap for the next reader.
      //
      // The floor needs no rule of its own: a descendant combinator
      // matches at any depth, so the deepest rule keeps applying to
      // everything below it.
      for (final role in CoreSurfaceRole.values) {
        final steps = recipe.nestedSurfaces?[role]?.length ?? 0;
        for (var depth = 0; depth <= steps; depth++) {
          final material = recipe.surfaceFor(role, depth: depth);
          // Skip a rule that would restate the one above it. A style with
          // one material emits exactly what it emitted before roles and
          // depth existed, and a sheet never claims a distinction the
          // recipe does not make.
          if (depth > 0 &&
              material == recipe.surfaceFor(role, depth: depth - 1)) {
            continue;
          }
          // No skip for "functional matches content". It was correct while
          // the content rule was scoped to the bare marker and therefore
          // matched functional elements too — since content gained its own
          // class, that rule no longer falls through, so skipping the
          // functional one would leave a floating panel with no material
          // at all.
          //
          // Dormant while this style states two different materials, which
          // is why removing it changes the emitted sheet by zero bytes
          // today (13028 either way, measured). It would bite the first
          // preset that states one material for both roles.
          buffer.write(
            surfaceStyleTreatmentBlock(
              id,
              material,
              role: role,
              depth: depth,
              // The graded answer replaces the blunt one for this style.
              suppressNested: steps == 0,
            ),
          );
          // A panel that fades is never inside another surface (the engine
          // portals it to the host), so the fade rules are the floor's.
          if (depth == 0) {
            buffer.write(surfaceFadeTargetBlock(id, material, role: role));
          }
        }
      }

      buffer.write(surfaceStyleForcedColorsBlock(id, recipe.a11y));
    }

    for (final id in CoreSurfaceStyleId.values) {
      final recipe = _recipeFor(id);
      // Visits every style, the default one included, so a definition exists
      // wherever a rule above or below names one.
      buffer.write(_surfaceFinishDefinitions(id));
      for (final role in CoreSurfaceRole.values) {
        final roleClass = role == CoreSurfaceRole.content
            ? kWebSurfaceRoleContent
            : kWebSurfaceRoleFunctional;
        buffer.write(
          surfaceStyleTreatmentBlock(
            id,
            recipe.surfaceFor(role),
            role: role,
            scopeOverride:
                '.$kWebLocalSurfaceMarker.$roleClass.coui-material-${id.name}',
          ),
        );
      }
    }

    // The frost and the shade are decoration over the content a person asked
    // to see more plainly, so a preference for more contrast, or a platform
    // that forces its own palette, takes them away. One rule for the whole
    // sheet: it blanks the two custom properties the lists read, whatever
    // palette or scope a list was restated in.
    var statesFrost = false;
    var statesShade = false;
    for (final id in CoreSurfaceStyleId.values) {
      final (:frost, :shade) = _finishOf(id);
      statesFrost = statesFrost || frost != null;
      statesShade = statesShade || shade != null;
    }
    if (statesFrost || statesShade) {
      buffer
        ..write(
          _surfaceFinishAccessibilityRule(
            frost: statesFrost,
            shade: statesShade,
          ),
        )
        ..write(
          _surfaceFinishEngineRule(frost: statesFrost, shade: statesShade),
        );
    }

    final sheet = buffer.toString();
    // The angle is a prefix of its dark twin, so one test covers both.
    final statesRuntimeInput = [
      kWebSurfaceRimAngleVar,
      kWebSurfaceRefractionModelVar,
    ].any(sheet.contains);

    return statesRuntimeInput ? '$sheet$_surfaceRuntimeInputsReset' : sheet;
  }

  /// The numbers the per-element runtime would get wrong, stated where it
  /// can read them.
  ///
  /// The runtime builds the rim's sweep and the displacement map from the
  /// *preset's* recipe, and a tuning is a build-time decision this sheet
  /// already carries: it cannot see `surfaceTunings`. What a tuning changes
  /// about those two things therefore arrives the way every tuned value
  /// arrives — as numbers in the stylesheet, here as custom properties on the
  /// surface the runtime measures.
  ///
  /// Only what differs from the preset is stated. Both reads fall back to the
  /// preset when the property is absent, so an untuned sheet carries none of
  /// this and is the sheet it always was.
  String _surfaceRuntimeInputs(
    CoreSurfaceStyleId id,
    CoreSurfaceRole role,
    CoreSurfaceToken surface,
  ) {
    final declarations = StringBuffer();
    final preset = CoreSurfaceRecipe.of(id);

    final bevel = surface.sheen?.bevel;
    if (bevel != null && bevel.drawsRim) {
      final authored = preset.surfaceFor(role)?.sheen?.bevel;
      for (final (mode, variable) in [
        (CoreBrightness.light, kWebSurfaceRimAngleVar),
        (CoreBrightness.dark, kWebSurfaceRimAngleDarkVar),
      ]) {
        final angle = bevel.lightAngleFor(mode);
        if (authored == null || angle != authored.lightAngleFor(mode)) {
          declarations.write('$variable:$angle;');
        }
      }
    }

    // A bend rides the backdrop pass, so a surface with none states no law.
    if (surface.blurRadius != null) {
      final law = _recipeFor(id).refraction?.model;
      if (law != null && law != preset.refraction?.model) {
        declarations.write('$kWebSurfaceRefractionModelVar:${law.name};');
      }
    }

    return declarations.toString();
  }

  /// The boundary a shadow-bounded style owes under forced colours.
  ///
  /// Forced colours replaces the palette but draws nothing new, and it
  /// does not paint shadows at all. A style whose only boundary is a
  /// shadow therefore has no boundary in that mode — not a faint one, none
  /// — and no colour substitution can bring back an edge that was never a
  /// stroke. The contract makes such a style declare the stroke that
  /// stands in; this is where that declaration becomes a drawn edge.
  ///
  /// `!important` is load-bearing rather than a shortcut. The surface
  /// primitive writes its border width inline, and an inline declaration
  /// outranks every selector — so the same rule without it would parse,
  /// match, and change nothing, which is the failure this whole path
  /// exists to correct. Accessibility outcomes outrank authored intent,
  /// and in CSS this is how that priority is spelled.
  ///
  /// A style that states no fallback emits nothing: styles bounded by a
  /// real stroke already survive the mode, and one deliberately unbounded
  /// owes a focus indicator instead of an edge.
  String surfaceStyleForcedColorsBlock(
    CoreSurfaceStyleId id,
    CoreSurfaceA11yContract a11y,
  ) {
    final stroke = a11y.forcedColorsBoundary;
    if (stroke == null) return '';

    return '@media '
        '(forced-colors:active){'
        '[data-coui-style="${id.name}"] .$kWebSurfaceMarker'
        '{border-style:solid '
        '!important;border-width:${strokeWidthCss(stroke)} !important;}}';
  }

  /// Translucency and blur, for a style whose surface is a material
  /// rather than a fill.
  ///
  /// Emitted as a CSS rule rather than resolved in Dart because style
  /// switching writes a document attribute and does not rebuild the
  /// tree — a value baked at build time is the value of whichever style
  /// was active when the tree was built, and goes stale the moment the
  /// preset changes. This is the same reason the geometry constraint
  /// rides variables.
  ///
  /// The two declarations are one statement, not two features. A blur
  /// behind an opaque fill is invisible, and translucency without a blur
  /// is just a lighter surface — the material is the pair. So a recipe
  /// that states either gets both, and a recipe that states neither
  /// emits nothing at all: the default style leaves the surface exactly
  /// as its component drew it, with no `backdrop-filter` to create a
  /// containing block that was not there before.
  String surfaceStyleTreatmentBlock(
    CoreSurfaceStyleId id,
    CoreSurfaceToken? surface, {
    CoreSurfaceRole role = CoreSurfaceRole.content,
    int depth = 0,
    bool suppressNested = true,
    String? scopeOverride,
  }) {
    if (surface == null) return '';

    final blur = surface.blurRadius;
    final opacity = surface.opacity;
    final translucent = !opacity.isOpaque;
    final sheen = surface.sheen;
    final saturation = surface.saturationFor(CoreBrightness.light);
    final darkSaturation = surface.saturationFor(CoreBrightness.dark);
    final brightness = surface.backdropBrightness;
    // The terms a style lays over its backdrop pass (`CoreSurfaceFrost`,
    // `CoreSurfaceBodyShade`). They ride the pass, so a material that draws
    // none has nothing for them to act on; a style that states neither
    // leaves this sheet exactly what it was.
    final finish = blur == null ? null : _finishOf(id);
    final frost = finish?.frost;
    final shade = finish?.shade;
    // A nested rule that drops the pass still has to be written. The
    // base rule matches the same element, so saying nothing leaves the
    // outer blur in force — "no blur" and "no rule" are opposites here.
    final dropsPass = depth > 0 && blur == null;
    if (blur == null && !translucent && sheen == null && !dropsPass) {
      return '';
    }

    // Both roles qualify by their own class, and depth adds one
    // ancestor `.coui-surface` per level. That is not cosmetic — it is
    // what keeps the two axes from tying.
    //
    // Qualified by role alone, the rules would read (0,3,0) for floating
    // and (0,2,0) for content; a nested rule spelled `.s .s` is (0,3,0)
    // and would **tie with the floating rule**. A tie is broken by
    // authoring order, and `theme-axis-composition.md` names exactly that
    // as the failure: "누가 이기는지가 구현 순서의 우연이 된다". The
    // screen it produces is a floating menu inside a glass card whose
    // material depends on which rule someone wrote first.
    //
    // With both roles carrying a class the ladder is strict — role sits
    // at (0,3,0) and every level of depth adds (0,1,0) — so depth always
    // outranks role and never coincides with it. The content marker class
    // exists for this; it draws nothing on its own.
    //
    // The floor is free: a descendant combinator matches at *any* depth,
    // so the deepest rule keeps applying to anything deeper.
    final roleClass = switch (role) {
      CoreSurfaceRole.content => kWebSurfaceRoleContent,
      CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
    };
    final ancestors = List.filled(depth, '.$kWebSurfaceMarker ').join();
    final scope =
        scopeOverride ??
        '[data-coui-style="${id.name}"] '
            '$ancestors.$kWebSurfaceMarker.$roleClass';
    final buffer = StringBuffer(scope)..write('{');
    // Built once and asked for twice, for the reason `filterList` below is:
    // the fill differs by mode and the two rules must agree about
    // everything else. Restated from the component's own triplet, so the
    // fill keeps the token it chose and stays dark-mode reactive — and
    // multiplied by the token's own alpha, which the triplet cannot carry.
    // Restating the triplet at the share alone erased that alpha: a 10%
    // tint came out at the full share, and a fill stated at opacity 0 came
    // out half-filled. `token alpha × share` is what the Flutter twin folds.
    String fillDeclaration(double fill) {
      final pct = (fill * kPercentScale).round();

      return 'background-color:rgb(var($kWebSurfaceFillVar) / '
          'calc(var($kWebSurfaceFillAlphaVar, 1) * $pct%));';
    }

    if (translucent) {
      buffer.write(fillDeclaration(opacity.light));
    }
    // One filter list, not two declarations — a second `backdrop-filter`
    // would replace the first rather than add to it, and the surface would
    // lose its blur to gain chroma.
    //
    // Built once and asked for twice, because the dimming differs by mode
    // and the two rules must agree about everything else. Spelling the
    // list out at both call sites is how a blur comes to change in light
    // and not in dark.
    String filterList(double dim, double lift) {
      final list = StringBuffer('backdrop-filter:');
      // The cloud first: it mixes a heavy blur of the backdrop back over the
      // backdrop, and the surface's own blur, lift and dimming then run on
      // the result — the order the Flutter twin's two passes draw in. A
      // custom property with an empty fallback, so one `!important`
      // declaration can take it away (see [kWebSurfaceFrostVar]).
      if (frost != null) list.write('var($kWebSurfaceFrostVar,) ');
      list.write('blur(${blur}px)');
      if (lift != CoreSurfaceToken.identitySaturation) {
        list.write(' saturate($lift)');
      }
      // After the chroma lift, because filter functions run left to
      // right and dimming an amplified backdrop is not the same colour
      // as amplifying a dimmed one. Flutter multiplies the two into one
      // matrix in that same order.
      if (dim != CoreSurfaceToken.identityBrightness) {
        list.write(' brightness($dim)');
      }
      // The shade last, on the finished backdrop: a point operation, so it
      // commutes with the bend the runtime appends after it.
      if (shade != null) list.write(' var($kWebSurfaceShadeVar,)');

      return (list..write(';')).toString();
    }

    // What the two custom properties hold in [mode]: a reference to the
    // style's definition (see [_surfaceFinishDefinitions]), not the filter
    // document itself. Written by every rule that uses them, in every
    // palette: a custom property inherits, and a surface that stated none
    // would read the one of the surface it sits in. `initial` is the
    // guaranteed-invalid value, which `var(--x,)` answers with its empty
    // fallback.
    String finishVars(CoreBrightness mode) {
      final vars = StringBuffer();
      if (frost != null) {
        final name = _finishDefinitionVar(
          kWebSurfaceFrostVar,
          id,
          mode,
          light: _frostUrl(frost, CoreBrightness.light),
          dark: _frostUrl(frost, CoreBrightness.dark),
        );
        vars.write('$kWebSurfaceFrostVar:var($name);');
      }
      if (shade != null) {
        final stated = _shadeUrl(shade, mode) != null;
        final name = _finishDefinitionVar(
          kWebSurfaceShadeVar,
          id,
          mode,
          light: _shadeUrl(shade, CoreBrightness.light),
          dark: _shadeUrl(shade, CoreBrightness.dark),
        );
        final value = stated ? 'var($name)' : 'initial';
        vars.write('$kWebSurfaceShadeVar:$value;');
      }

      return vars.toString();
    }

    if (blur != null) {
      buffer
        ..write(filterList(brightness.light, saturation))
        ..write(finishVars(CoreBrightness.light));
    }
    // Glass does not stack on glass. Blurs compose by variance, so a
    // second pass over an already-blurred backdrop reads as a rendering
    // fault rather than as a material — found by walking the rendered
    // catalog, on an item card inside the column card that held it.
    //
    // Emitted from the recipe's nesting table rather than hardcoded, so
    // the policy is one statement both platforms read. It used to live
    // here alone, which is why Flutter never had it and ran the second
    // pass at full strength (measured: two σ-16 filters, composing to
    // σ≈22.6 where the Web drew σ-16).
    if (dropsPass) buffer.write('backdrop-filter:none;');
    // Colour only. The border box stays, because it is what the
    // forced-colours rule below recolours — and because a zeroed width
    // would grow the content box by 2px per axis on a style swap that is
    // supposed to change paint alone (the swap writes a document attribute
    // and rebuilds nothing).
    //
    // `!important` is load-bearing for exactly one path: `emitColor` puts
    // `border-color` inline whenever the resolved colour is token-less,
    // i.e. on any raw caller override, and inline outranks every selector.
    // The forced-colours block below carries it for the same reason.
    if (surface.drawsOwnEdge) {
      buffer.write('border-color:transparent !important;');
    }
    // What the per-element runtime would otherwise get from the preset. One
    // statement at depth zero: a nested surface matches this rule too, and a
    // second copy at every depth would be a second place to change a number.
    if (depth == 0) buffer.write(_surfaceRuntimeInputs(id, role, surface));
    buffer.write('}');

    // The dimming and the fill are the two terms of this material that
    // differ by mode, and the difference has to survive a theme switch —
    // which writes a document attribute and rebuilds nothing. So each is
    // restated as CSS the browser re-matches, exactly like the palette's
    // own dark rules, and only the declarations that differ are repeated:
    // everything else in the rule above is mode-neutral and a second copy
    // would be a second place to change one value.
    //
    // NOT `brightness(var(--x))`. An undefined custom property invalidates
    // the whole declaration, so the blur would vanish with it on every
    // style that did not define the variable — a failure that shows up as
    // "the glass stopped frosting" and points nowhere near here.
    //
    // Both forms, for the reason `darkVariableBlock` and
    // `darkAutoVariableBlock` are both emitted: the attribute form only
    // ever applies when something writes `data-theme="dark"`, and a
    // statically rendered site with no theme controller has no path to
    // that at all. Shipping only the attribute form would leave a
    // system-dark visitor on the light dimming over the dark palette,
    // which is the exact combination this value exists to correct.
    //
    // Specificity, checked rather than assumed. Light is
    // `[attr] .s.s-role` = (0,3+depth,0). The attribute form adds one
    // attribute → (0,4+depth,0) and wins. The media form adds `:root`
    // and `:not([data-theme="light"])` → (0,4+depth,1) and wins over
    // both. That orders all four states correctly: OS-light unstamped →
    // light; OS-dark unstamped → media; stamped light under OS dark →
    // neither dark rule matches, light; stamped dark under OS light →
    // attribute form.
    //
    // The fill is gated on the fill alone, not on the blur. A nested
    // material drops the backdrop pass and keeps the rest, so it has a fill
    // that differs by mode and no filter to restate.
    //
    // The chroma lift is the third such term, and it rides the same filter
    // list: a material that lifts the dark backdrop by another amount
    // restates the whole list there, not a second declaration.
    final dimsByMode =
        blur != null &&
        (brightness.light != brightness.dark || saturation != darkSaturation);
    final fillsByMode = translucent && opacity.light != opacity.dark;
    // The frost's share and the shade's strength are the other two terms of
    // this pass a palette can disagree about; they live in the custom
    // properties, so a mode that differs restates those and not the list.
    final finishByMode =
        (frost != null &&
            frost.opacityFor(CoreBrightness.light) !=
                frost.opacityFor(CoreBrightness.dark)) ||
        (shade != null &&
            shade.strengthFor(CoreBrightness.light) !=
                shade.strengthFor(CoreBrightness.dark));
    if (dimsByMode || fillsByMode || finishByMode) {
      final darkDeclarations = StringBuffer();
      if (fillsByMode) darkDeclarations.write(fillDeclaration(opacity.dark));
      if (dimsByMode) {
        darkDeclarations.write(filterList(brightness.dark, darkSaturation));
      }
      if (finishByMode) {
        darkDeclarations.write(finishVars(CoreBrightness.dark));
      }
      final target = '$ancestors.$kWebSurfaceMarker.$roleClass';
      final darkScope = scopeOverride == null
          ? '[data-theme="dark"][data-coui-style="${id.name}"] $target'
          : '[data-theme="dark"] $scope';
      buffer
        ..write('$darkScope{$darkDeclarations}')
        ..write('@media (prefers-color-scheme:dark){')
        ..write(':root:not([data-theme="light"]) $scope{$darkDeclarations}')
        ..write('}');

      // A brightness scope (`data-theme` on an element below the root —
      // `BrightnessScope`) draws its surfaces in its own mode, the way the
      // Flutter twin's material reads the scope's theme. One rule per mode,
      // above the light rule (the scope's attribute and `:not(:root)` add
      // two) and at least level with both document forms, written after
      // them so a tie goes to the scope. Two opposite scopes nested inside
      // each other tie as well, and the later rule wins: the nearest scope
      // is not something a selector can say.
      final lightDeclarations = StringBuffer();
      if (fillsByMode) lightDeclarations.write(fillDeclaration(opacity.light));
      if (dimsByMode) {
        lightDeclarations.write(filterList(brightness.light, saturation));
      }
      if (finishByMode) {
        lightDeclarations.write(finishVars(CoreBrightness.light));
      }
      String inScope(String mode) => scopeOverride == null
          ? '[data-coui-style="${id.name}"] '
                '[data-theme="$mode"]:not(:root) $target'
          : '[data-theme="$mode"]:not(:root) $scope';
      buffer
        ..write('${inScope('dark')}{$darkDeclarations}')
        ..write('${inScope('light')}{$lightDeclarations}');
    }

    // The same four forms for a term that lives on a pseudo-element — the
    // wall's `::after` and the rim's `::before`. The light edge is
    // restated for a light scope inside a dark page for the reason the
    // fill's is: the dark document rules would otherwise reach into it.
    void restateByMode(String pseudo, String dark, String light) {
      final target = '$ancestors.$kWebSurfaceMarker.$roleClass';
      final darkScope = scopeOverride == null
          ? '[data-theme="dark"][data-coui-style="${id.name}"] $target'
          : '[data-theme="dark"] $scope';
      String inScope(String mode) => scopeOverride == null
          ? '[data-coui-style="${id.name}"] '
                '[data-theme="$mode"]:not(:root) $target'
          : '[data-theme="$mode"]:not(:root) $scope';
      buffer
        ..write('$darkScope$pseudo{$dark}')
        ..write('@media (prefers-color-scheme:dark){')
        ..write(':root:not([data-theme="light"]) $scope$pseudo{$dark}')
        ..write('}')
        ..write('${inScope('dark')}$pseudo{$dark}')
        ..write('${inScope('light')}$pseudo{$light}');
    }

    // Only when a band is actually drawn, and only on a surface that
    // is not already positioned for a reason of its own. `position`
    // establishes the containing block the band is absolutely placed
    // in — but a surface that opted into `fixed`/`absolute`/`sticky`
    // (a portal-mounted Dialog/Popover/Tooltip panel, a sticky
    // NavigationBar) chose that value to be a containing block for
    // something else entirely: itself, relative to the viewport. A
    // blanket `position:relative` here downgrades a `fixed` panel to
    // `relative` (CSS lets a later, more specific rule win outright —
    // there is no "only if still static"), and it renders wherever it
    // sits in the DOM instead of centered on the viewport. The `:not()`
    // exclusion is selector-level, not a specificity fight, so an
    // excluded surface's own `position` is untouched. A surface that
    // stays genuinely static (the common case — Card, Alert,
    // DescriptionCard) still gets the `relative` promotion the band
    // needs.
    if (sheen != null) {
      buffer.write(
        '$scope:not(.fixed):not(.absolute):not(.sticky){position:relative;}',
      );
    }

    if (sheen != null) {
      final band = surfaceEdgeSheenCss(sheen);
      buffer
        ..write('$scope::after{')
        // Double quotes are load-bearing. The stylesheet is injected as
        // an unescaped single-quoted JS string literal, so a `'` here
        // terminates that literal and takes the whole injection script
        // down with it — the failure is a blank page, not a missing
        // band. The touch-target rule already spells it this way.
        ..write('content:"";position:absolute;$_kSurfaceBandInset')
        // Pseudo-elements do not inherit `border-radius`, so without
        // this the band paints square corners outside a rounded surface.
        ..write('border-radius:inherit;pointer-events:none;');
      for (final entry in band.entries) {
        buffer.write('${entry.key}:${entry.value};');
      }
      // The wall rides the band's own element rather than the surface's
      // `box-shadow`. Two reasons, and the second is the one that made
      // this a separate treatment from `highlightRim`:
      //
      // The band element is already the material's edge — inset 0, the
      // inherited radius, no pointer events — so the wall lands on the
      // same geometry as the runs by construction, including corners.
      //
      // And it is not gated on the surface casting. A component appends
      // `--coui-surface-rim` to its `box-shadow` only when it authored one,
      // so a card with no shadow never references it; that gate is right
      // for a rim decorating a lift, and wrong for a pane's own edge.
      final wall = sheen.bevel?.toLayers() ?? const <CoreShadowLayer>[];
      if (wall.isNotEmpty) {
        // A highlight, not a shadow — the dark does not strengthen it.
        buffer.write(
          'box-shadow:'
          '${wall.toValue(base: _kSurfaceHighlightBase, strengthens: false)};',
        );
      }
      buffer.write('}');

      // Lit from another direction in dark: the wall is restated there,
      // because a theme switch rebuilds nothing and the layers are derived
      // from the angle. The base rule above is the light one — the bevel's
      // own angle is the angle of every mode that states none.
      final lit = sheen.bevel;
      if (wall.isNotEmpty &&
          lit != null &&
          lit.lightAngleFor(CoreBrightness.light) !=
              lit.lightAngleFor(CoreBrightness.dark)) {
        String wallIn(CoreBrightness mode) {
          final layers = lit.atBrightness(mode).toLayers();
          final css = layers.toValue(
            base: _kSurfaceHighlightBase,
            strengthens: false,
          );

          return 'box-shadow:$css;';
        }

        restateByMode(
          '::after',
          wallIn(CoreBrightness.dark),
          wallIn(CoreBrightness.light),
        );
      }

      // The crest of the wall: a ring one rim-width wide just inside the
      // contour, painted with a sweep whose stops the runtime writes per
      // element (`kWebSurfaceRimSweepVar`). The stylesheet owns everything
      // size-independent — the ring's width, its mask, that it sits on the
      // band's geometry — and reads only the gradient from the element,
      // because the gradient is the one part that depends on the box.
      //
      // The ring is the `::before` pseudo-element masked to its own
      // padding: two full-box masks composited with `exclude` leave the
      // padding band and nothing else. Both spellings, because Safari
      // reads only the prefixed one and Chromium the unprefixed.
      //
      // `none` as the fallback, never a guessed gradient: a surface the
      // runtime has not reached (server render, a browser with no
      // ResizeObserver) draws no rim rather than a rim peaked on the
      // wrong corner.
      final rim = sheen.bevel;
      if (rim != null && rim.drawsRim) {
        buffer
          ..write('$scope::before{')
          ..write('content:"";position:absolute;$_kSurfaceBandInset')
          ..write('border-radius:inherit;pointer-events:none;')
          ..write('box-sizing:border-box;')
          ..write('padding:${strokeWidthCss(rim.rimWidth)};')
          ..write('background:var($kWebSurfaceRimSweepVar,none);')
          ..write('-webkit-mask:linear-gradient(#000 0 0) content-box,')
          ..write('linear-gradient(#000 0 0);-webkit-mask-composite:xor;')
          ..write('mask:linear-gradient(#000 0 0) content-box,')
          ..write('linear-gradient(#000 0 0);mask-composite:exclude;')
          ..write('}');

        // Lit from another direction in dark: the runtime writes a second
        // sweep for it (it cannot re-measure when the mode changes), and the
        // dark rules choose it. Falling back to the first is the same light.
        if (rim.lightAngleFor(CoreBrightness.light) !=
            rim.lightAngleFor(CoreBrightness.dark)) {
          restateByMode(
            '::before',
            'background:var($kWebSurfaceRimSweepDarkVar,'
                'var($kWebSurfaceRimSweepVar,none));',
            'background:var($kWebSurfaceRimSweepVar,none);',
          );
        }
      }
    }

    // Give the edge back where the material's own one cannot be seen.
    //
    // Forced colours does not force `background-image`, so the band is
    // erased outright in that mode — a surface suppressed above would be
    // left with no boundary at all, in the mode a user turned on to see
    // boundaries. `prefers-contrast: more` gets the same treatment for the
    // same reason: someone who asked for more contrast should not lose an
    // edge to a decorative style.
    //
    // Written as its own declaration rather than trusting the mode to
    // recolour an authored `transparent`. That behaviour is very likely
    // real, but a boundary guarantee should not rest on a subtle UA rule
    // when one declaration removes the question.
    if (surface.drawsOwnEdge) {
      const restore = 'border-color:rgb(var(--coui-outline)) !important;';
      buffer
        ..write('@media (forced-colors:active){$scope{$restore}}')
        ..write('@media (prefers-contrast:more){$scope{$restore}}');
    }

    // A surface that clips its own content keeps the band inside its padding
    // box: the clip stops there, so widening the band over the border it keeps
    // would push it into the part the clip removes (see
    // [kWebSurfaceClipMarker]). Where the material draws its own edge the
    // border is transparent — a spacer, not a line — so the surface that said
    // it clips has the spacer folded into its padding instead: the border style
    // goes to `none` ([kWebSurfaceEdgeStyleVar], which the surface states its
    // `border-style` through) and the padding takes the width over
    // ([kWebSurfaceClipPadVar], scaled by [kWebSurfaceFoldVar]). The box is the
    // size it was and the content stands where it stood, but the padding box
    // the clip stops at is now the border box, so the band at `inset: 0` is on
    // the outer edge.
    //
    // The style, not the width, because `border-width` is a transitioned
    // property: a width folded to zero would glide over a style swap while the
    // padding that replaces it jumped, and the content would move for a moment.
    // A style is not interpolated, so both change on the same frame.
    //
    // Nothing here touches `overflow`, so the clip is the one the component
    // drew in every browser — which is the point of doing it with the box
    // model rather than with a clip that only some engines can move.
    //
    // A surface that states its own padding adds the clip padding itself. One
    // that states none gets it here, at no specificity (`:where`), so a padding
    // the caller gives it — a class or an inline value — still wins and takes
    // the whole inset on itself. No competing zero-specificity padding exists
    // on a `div`: the base reset leaves it alone.
    //
    // Given back with the border colour above: forced colours and more contrast
    // want a line there, and a border with no style draws none.
    if (sheen != null &&
        surface.drawsOwnEdge &&
        depth == 0 &&
        scopeOverride == null) {
      const fold = '$kWebSurfaceEdgeStyleVar:none;$kWebSurfaceFoldVar:1;';
      const unfold =
          '$kWebSurfaceEdgeStyleVar:initial;$kWebSurfaceFoldVar:initial;';
      buffer
        ..write('$scope.$kWebSurfaceClipMarker{$fold}')
        ..write(
          ':where($scope.$kWebSurfaceClipMarker)'
          '{padding:var($kWebSurfaceClipPadVar,0px);}',
        )
        ..write('@media (forced-colors:active){')
        ..write('$scope.$kWebSurfaceClipMarker{$unfold}}')
        ..write('@media (prefers-contrast:more){')
        ..write('$scope.$kWebSurfaceClipMarker{$unfold}}');
    }

    // Someone who asked for less transparency gets an opaque surface.
    //
    // The a11y contract has said `usesTransparency` since the preset
    // shipped, and its own doc said that drives a reduce-transparency
    // response — which nothing implemented. That is the shape the
    // acceptance gate names by hand: a declaration with no drawn path is
    // not a pass, it is a claim.
    //
    // Both halves of the material go, because they are one statement: an
    // opaque fill with the blur still running would keep compositing a
    // backdrop nobody can see through, and keep amplifying its chroma.
    // The band stays — it is decoration on an edge, not transparency.
    //
    // `!important` for the same reason the rules above carry it: the
    // surface primitive writes its fill inline, and inline outranks every
    // selector. Accessibility outcomes outrank authored intent.
    //
    // Opaque means the material's share is gone, not the token's own alpha:
    // a 10% tint stays a 10% tint, the way the Flutter twin keeps the token
    // and drops only the share (`withoutTransparency`). Restating the bare
    // triplet painted that tint solid.
    //
    // The adaptive-quality tiers that go without the backdrop pass state the
    // same thing under their own attribute, from the same declarations. They
    // are written once and read twice for the reason `filterList` is: the
    // preference and the tier are two reasons for one outcome, and two
    // spellings of it would drift. The attribute sits on the document, so
    // it is joined to the style attribute in one compound selector — a
    // descendant combinator between two attributes of the same element
    // matches nothing — and a local surface, which carries no style
    // attribute, is reached below it.
    if (translucent || blur != null) {
      const fill =
          'background-color:rgb(var($kWebSurfaceFillVar) / '
          'var($kWebSurfaceFillAlphaVar, 1)) !important;';
      const noPass = 'backdrop-filter:none !important;';
      const opaque = '$fill$noPass';
      buffer
        ..write('@media (prefers-reduced-transparency:reduce){$scope{')
        ..write(opaque)
        ..write('}}');

      const ladder = CoreQualityLadder.standard;
      for (final tier in ladder.tiers) {
        if (!ladder.withholds(tier, CoreQualityEffect.backdropPass)) continue;

        final quality = '[$kQualityAttribute="${tier.name}"]';
        final qualityScope = scopeOverride == null
            ? '[data-coui-style="${id.name}"]$quality '
                  '$ancestors.$kWebSurfaceMarker.$roleClass'
            : '$quality $scopeOverride';
        buffer
          ..write(qualityScope)
          ..write('{')
          ..write(opaque)
          ..write('}');
      }
    }

    return buffer.toString();
  }

  /// The rules that let a glass panel fade by its terms and not by an opacity.
  ///
  /// A panel that opens or closes (a dialog, a popover, a menu) plays a
  /// progress, `--coui-fade`, from `0` to `1` on its own element
  /// (`_kFadeCss` in `overlay_host.dart`). A panel that draws no backdrop
  /// pass fades by its opacity and needs nothing from here. One that draws
  /// one cannot: a backdrop filter under an opacity reads a layer with
  /// nothing in it, so the glass would go plain for the whole fade and come
  /// back in the last frame. These rules state what the same surface looks
  /// like at a progress below `1`, and only for a panel that fades — the
  /// motion box's child, or the dialog panel — so every other surface is the
  /// surface it always was.
  ///
  /// The terms are the ones `CoreSurfaceDissolve` states for the Flutter
  /// twin, over the same progress:
  ///
  /// * the **blur, the chroma lift and the dimming** go from nothing (from
  ///   the identity, for the two that have one) to their stated value by
  ///   `CoreSurfaceDissolve.share` of the progress;
  /// * the **fill** goes by the progress itself, like everything an opacity
  ///   would have faded.
  ///
  /// Not here, and not dissolved on the Web: the frost and the body shade a
  /// tuning can add (SVG filters named in the list, whose strength is an
  /// attribute and not a property) and the bend the refraction runtime
  /// appends. They are in the list at their stated strength for the whole
  /// fade. The shadow, the edge, the content and the pseudo-element layers
  /// fade by the keyframes the host's stylesheet states.
  ///
  /// The list is also written to [kWebSurfacePassVar], and `backdrop-filter`
  /// reads it from there, because the refraction runtime appends its bend to
  /// the list and writes the result inline: it writes the reference, so the
  /// list it appends to is the one that moves with the fade.
  ///
  /// What tells the panel it fades by its terms is the animations it names:
  /// the rule below takes its opacity away and names the shadow and edge and
  /// the layers instead. Every rule that drops the pass — the
  /// reduced-transparency preference, the adaptive-quality tiers that go
  /// without the pass, forced colours — names the opacity again, so those
  /// panels fade by it.
  String surfaceFadeTargetBlock(
    CoreSurfaceStyleId id,
    CoreSurfaceToken? surface, {
    CoreSurfaceRole role = CoreSurfaceRole.content,
  }) {
    // Only a surface that draws a pass fades by its terms. A translucent
    // fill with no blur has nothing an opacity would take from it.
    final blur = surface?.blurRadius;
    if (surface == null || blur == null) return '';

    final opacity = surface.opacity;
    final translucent = !opacity.isOpaque;
    final saturation = surface.saturationFor(CoreBrightness.light);
    final darkSaturation = surface.saturationFor(CoreBrightness.dark);
    final brightness = surface.backdropBrightness;
    final (:frost, :shade) = _finishOf(id);

    final roleClass = switch (role) {
      CoreSurfaceRole.content => kWebSurfaceRoleContent,
      CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
    };
    // The panel the engine places is the child of its motion box; the dialog
    // panel is its own. `:is()` takes the more specific of the two, so the
    // rule is level with the one `surfaceStyleTreatmentBlock` writes plus
    // the one class the motion box adds — enough to win the same properties
    // there, and no more.
    const panel =
        ':is(.$kFadeBoxClass>.$kWebSurfaceMarker,'
        '.$kFadePanelClass.$kWebSurfaceMarker)';
    final target = '$panel.$roleClass';
    final scope = '[data-coui-style="${id.name}"] $target';

    // The share of the progress the backdrop terms follow. A progress of 1
    // (a surface that is not fading, or a fade that is over) is a share of 1,
    // so the list at rest is the list the base rule states.
    const progress = 'var($kFadeProgressVar,1)';
    const share = CoreSurfaceDissolve.materialExponent == 1
        ? progress
        : 'pow($progress,${CoreSurfaceDissolve.materialExponent})';

    // A number as CSS spells it: no float noise (`0.6000000000000001`).
    String number(double value) =>
        double.parse(value.toStringAsFixed(4)).toString();
    // A term whose nothing is 1 (chroma lift, dimming): from 1 to [value].
    String towardIdentity(double value) {
      final delta = value - 1;

      return delta < 0
          ? 'calc(1 - ${number(-delta)} * $share)'
          : 'calc(1 + ${number(delta)} * $share)';
    }

    String fillDeclaration(double fill) {
      final pct = (fill * kPercentScale).round();

      return 'background-color:rgb(var($kWebSurfaceFillVar) / '
          'calc(var($kWebSurfaceFillAlphaVar, 1) * $pct% * $progress));';
    }

    // The same list `surfaceStyleTreatmentBlock` writes, term for term and in
    // the same order, with the three terms that can scale scaled.
    String passList(double dim, double lift) {
      final list = StringBuffer('$kWebSurfacePassVar:');
      if (frost != null) list.write('var($kWebSurfaceFrostVar,) ');
      list.write('blur(calc(${blur}px * $share))');
      if (lift != CoreSurfaceToken.identitySaturation) {
        list.write(' saturate(${towardIdentity(lift)})');
      }
      if (dim != CoreSurfaceToken.identityBrightness) {
        list.write(' brightness(${towardIdentity(dim)})');
      }
      if (shade != null) list.write(' var($kWebSurfaceShadeVar,)');

      return (list..write(';backdrop-filter:var($kWebSurfacePassVar);'))
          .toString();
    }

    // The animations a panel with a pass plays in place of its opacity. They
    // are read where the fade root put them, so the names are for the
    // direction it is fading.
    const fadesByTerms =
        '$kFadeOpacityAnimationVar:$kFadeNoAnimation;'
        '$kFadePaintAnimationVar:var($kFadeGlassPaintNameVar);'
        '$kFadeLayerAnimationVar:var($kFadeGlassLayerNameVar);';
    final buffer = StringBuffer('$scope{$fadesByTerms');
    if (translucent) buffer.write(fillDeclaration(opacity.light));
    buffer
      ..write(passList(brightness.light, saturation))
      ..write('}');

    // The terms a palette can disagree about, restated for dark in the four
    // forms `surfaceStyleTreatmentBlock` restates them in, level with those
    // plus the motion box's class.
    final dimsByMode =
        brightness.light != brightness.dark || saturation != darkSaturation;
    final fillsByMode = translucent && opacity.light != opacity.dark;
    if (dimsByMode || fillsByMode) {
      String declarations(CoreBrightness mode) {
        final isDark = mode == CoreBrightness.dark;
        final out = StringBuffer();
        if (fillsByMode) {
          out.write(fillDeclaration(isDark ? opacity.dark : opacity.light));
        }
        if (dimsByMode) {
          out.write(
            isDark
                ? passList(brightness.dark, darkSaturation)
                : passList(brightness.light, saturation),
          );
        }

        return out.toString();
      }

      String inScope(String mode) =>
          '[data-coui-style="${id.name}"] [data-theme="$mode"]:not(:root) '
          '$target';
      final dark = declarations(CoreBrightness.dark);
      buffer
        ..write('[data-theme="dark"][data-coui-style="${id.name}"] $target{')
        ..write('$dark}')
        ..write('@media (prefers-color-scheme:dark){')
        ..write(':root:not([data-theme="light"]) $scope{$dark}')
        ..write('}')
        ..write('${inScope('dark')}{$dark}')
        ..write('${inScope('light')}{${declarations(CoreBrightness.light)}}');
    }

    // Where the pass is dropped the panel fades by its opacity, as a panel
    // with no pass does. `!important`, like the rules that drop the pass,
    // because the names above are normal declarations and these are the
    // answer the cascade already gave.
    const off =
        '$kFadeOpacityAnimationVar:var($kFadeOpacityNameVar) !important;'
        '$kFadePaintAnimationVar:$kFadeNoAnimation !important;'
        '$kFadeLayerAnimationVar:$kFadeNoAnimation !important;';
    buffer.write('@media (prefers-reduced-transparency:reduce){$scope{$off}}');
    const ladder = CoreQualityLadder.standard;
    for (final tier in ladder.tiers) {
      if (!ladder.withholds(tier, CoreQualityEffect.backdropPass)) continue;

      buffer.write(
        '[data-coui-style="${id.name}"][$kQualityAttribute="${tier.name}"] '
        '$target{$off}',
      );
    }
    // Forced colours replaces the fill with an opaque system colour, so the
    // terms that would have faded it have nothing to fade.
    buffer.write('@media (forced-colors:active){$scope{$off}}');

    return buffer.toString();
  }

  /// The pair of rules one surface style contributes.
  ///
  /// Separate from [surfaceStyleVariableBlocks] so the emission can be
  /// exercised with a colour statement while every shipped recipe is still
  /// neutral — otherwise the first story to give a preset its colours would
  /// also be the first to find out whether this worked.
  String surfaceStyleBlock(
    CoreSurfaceStyleId id,
    CoreSurfaceColorConstraint constraint,
  ) {
    final name = id.name;
    final source = _source;
    final light = constraint.apply(source.light()).resolved(.light);
    final dark = constraint.apply(source.dark()).resolved(.dark);

    final baseLight = source.light().resolved(.light);
    final baseDark = source.dark().resolved(.dark);
    final lightVars = _schemeVarsDelta(light, baseLight);
    final darkVars = _schemeVarsDelta(dark, baseDark);

    final lightRule = lightVars.isEmpty
        ? ''
        : '[data-coui-style="$name"]{$lightVars}';
    final darkRule = darkVars.isEmpty
        ? ''
        : '[data-theme="dark"][data-coui-style="$name"]{$darkVars}';
    // The same bends for a brightness scope, which restates its own palette
    // and would otherwise drop them (see [brightnessScopeBlock]).
    final lightScoped = lightVars.isEmpty
        ? ''
        : '[data-coui-style="$name"] '
              '[data-theme="light"]:not(:root){$lightVars}';
    final darkScoped = darkVars.isEmpty
        ? ''
        : '[data-coui-style="$name"] '
              '[data-theme="dark"]:not(:root){$darkVars}';
    return '$lightRule$darkRule$lightScoped$darkScoped';
  }

  /// The rule one surface style contributes for geometry.
  ///
  /// Unqualified by brightness, unlike the colour rules: a corner radius
  /// and a border weight are the same in light and dark, so emitting them
  /// twice would be two places to change one value.
  ///
  /// Only steps the constraint actually moves are written. A style that
  /// squares corners changes eighteen of the nineteen radius steps but
  /// leaves `radius-0` alone, and emitting that unchanged step would be a
  /// declaration asserting a difference that does not exist.
  String surfaceStyleGeometryBlock(
    CoreSurfaceStyleId id,
    CoreSurfaceGeometryConstraint geometry, {
    CoreSurfaceTypographyConstraint typography =
        const CoreSurfaceTypographyConstraint(),
  }) {
    final buffer = StringBuffer();
    // The declarations this block derives from the palette or the shadow
    // strength — written to the style's rule and again for a brightness
    // scope, which restates the base stacks and would otherwise drop this
    // style's bends (see [brightnessScopeBlock]). Corners, strokes and
    // weights are the same in either brightness and stay on the root, where
    // a density's combined rule can still move them.
    final derived = StringBuffer();
    void writeDerived(String declaration) {
      buffer.write(declaration);
      derived.write(declaration);
    }

    for (final step in kRadiusSteps) {
      final bent = geometry.radius(step.value);
      if (bent != step.value) {
        buffer.write('--coui-radius-${step.key}:${bent}px;');
      }
    }
    for (final step in _kStrokeVariableSteps) {
      final bent = geometry.stroke(step.value);
      if (bent != step.value) {
        buffer.write('--coui-stroke-width-${step.key}:${bent}px;');
      }
    }

    for (final entry in CssVariableGenerator.typographyVars(.coui).entries) {
      if (!entry.key.endsWith('-weight')) continue;
      final authored = int.tryParse(entry.value);
      if (authored == null) continue;
      final bent = typography.weight(authored);
      if (bent == null || bent == authored) continue;
      buffer.write('${entry.key}:$bent;');
    }

    // The rim rides its own variable rather than being appended to every
    // shadow step. `CoreShadow` is an elevation-MAGNITUDE vocabulary —
    // its own doc comments read "input field, small button" for `xs` and
    // "popover, tooltip" for `lg` — so it deliberately spans controls and
    // surfaces. A rim is a surface-MATERIAL statement. Attaching one to
    // the magnitude scale put a 55%-alpha white inset glow on a 12px
    // toggle knob, whose fill is `onSurface` while the rim is derived
    // from `surface`: the wrong tint on the opposite token, and it
    // survived into the disabled state.
    //
    // So surfaces opt in by referencing this variable, which is exactly
    // what the Flutter side does by calling `resolveSurfaceRim`.
    final rim = geometry.highlightRim;
    if (rim.isNotEmpty) {
      // A highlight, not a shadow — the dark does not strengthen it.
      writeDerived(
        '--coui-surface-rim:'
        '${rim.toValue(base: _kSurfaceHighlightBase, strengthens: false)};',
      );
    }

    // The control shadow rides its own variable, mirroring the rim
    // above — a control with no shadow to bend (`Button` at rest)
    // references it unconditionally rather than opting in per instance,
    // so only a style that states one (neo-brutalism) resolves it to
    // something visible; every other style leaves it at [_kNoRim].
    final controlShadow = geometry.controlShadow;
    if (controlShadow.isNotEmpty) {
      writeDerived(
        '--coui-control-shadow:'
        '${controlShadow.toValue(base: _kShadowColorBase)};',
      );
      // The ghost twin [kControlShadowGhostVar] describes — same layer
      // count, offset, blur and spread as the value just written, colour
      // alpha zeroed. Computed alongside it (not by a caller) because
      // only this block ever knows the real shape; a per-component
      // resolver is theme-free and cannot invent a matching ghost for a
      // shape it never sees.
      writeDerived(
        '--coui-control-shadow-ghost:'
        '${_ghostOf(controlShadow).toValue(base: _kShadowColorGhostBase)};',
      );
    }

    // The contributed boundary rides its own variable for the same
    // reason the cast above does — see `kControlBorderMarker`. A width
    // only: the colour is the palette's `outline`, stated once in the
    // rule that reads this rather than twice.
    final controlBorder = geometry.controlBorder;
    if (controlBorder != null) {
      buffer.write('--coui-control-border:${controlBorder}px;');
    }

    // Press-squash affordance values — see `kControlShadowPressMarker`'s
    // doc comment for the full rule this feeds (`_controlShadowPressRule`,
    // global, `!important`). Plain custom-property declarations rather
    // than a second selector-scoped rule deliberately: a style-scoped
    // *rule* here would be a second, more specific selector the
    // high-contrast-vs-style specificity contract has to out-rank
    // (`preset_vs_high_contrast_test.dart` catches exactly that), while a
    // *variable* declared inside this already-scoped block carries the
    // same "only this style sees it" conditionality without adding a
    // selector at all. Undefined everywhere but a style that states
    // [CoreSurfaceGeometryConstraint.shadowOffsetAdd], so the global
    // rule's `var(x, <no-op fallback>)` falls through to a no-op under
    // every other style.
    final add = geometry.shadowOffsetAdd;
    if (add != null) {
      buffer.write(
        '--coui-control-shadow-press:none;'
        '--coui-control-shadow-offset-x:${add.dx}px;'
        '--coui-control-shadow-offset-y:${add.dy}px;'
        // The mirror pair [CoreCastMotion.reverse] reads instead of the
        // two lines above. Published here, not computed by a
        // per-instance resolver, for the same reason the ghost shadow
        // is: a component resolver is theme-free and never sees `add`
        // itself. A `reverse` control overrides its own
        // `--coui-control-shadow-offset-x/y` inline with
        // `var(--coui-control-shadow-offset-x-reverse, 0px)` — the
        // element's own declaration for that property, which outranks
        // the inherited value from this block regardless of
        // specificity, so a `reverse` control travels the opposite way
        // from every `defaultMotion` sibling under the same style.
        '--coui-control-shadow-offset-x-reverse:${-add.dx}px;'
        '--coui-control-shadow-offset-y-reverse:${-add.dy}px;',
      );
      // The travel carries the press signal here, so the shrink stands
      // down ([kControlPressShrinkVar]) — on the same condition the
      // Flutter resolver pins `pressedScale` to `1.0`: a non-zero travel.
      // A control that casts nothing restores it inline, because it has
      // no shadow to travel into.
      if (add.dx != 0 || add.dy != 0) {
        buffer.write('$kControlPressShrinkVar:0;');
      }
    }

    for (final step in _kShadowVariableSteps) {
      final bent = geometry.shadow(step.layers);
      if (_sameStack(bent, step.layers)) continue;
      writeDerived(
        '--shadow-${step.key}:'
        '${bent.isEmpty ? 'none' : bent.toValue(base: _kShadowColorBase)};',
      );
      // The `filter: drop-shadow()` twin, so a component casting through
      // `filter` (see [_shadowFilterCssVar]) bends with this style too.
      // `drop-shadow()` cannot express an inset layer, so a step this
      // style bent into one (`inset` itself, or any step a future
      // constraint pushes inward) has no filter var to write — that
      // shape only ever reaches components through `box-shadow`.
      if (!bent.hasInset) {
        final filter = bent.isEmpty
            ? 'none'
            : bent.toDropShadowValue(base: _kShadowColorBase);
        writeDerived('--shadow-${step.key}-filter:$filter;');
      }
    }

    if (buffer.isEmpty) return '';

    final scopedRule = derived.isEmpty
        ? ''
        : '[data-coui-style="${id.name}"] [data-theme]:not(:root){$derived}';
    return '[data-coui-style="${id.name}"]{$buffer}$scopedRule';
  }

  /// [layers], every layer's own opacity pinned to 1 — the shape
  /// `kControlShadowGhostVar` publishes.
  ///
  /// Offset, blur, spread and the inset flag all carry over unchanged, so
  /// the ghost is a same-shape, invisible twin of [layers] rather than a
  /// differently-shaped "nothing" — see `kControlShadowGhostVar`'s doc
  /// comment for why the shape has to match. The zero-alpha half lives
  /// in [_kShadowColorGhostBase]'s own colour string, not here — pinning
  /// each layer's `opacity` to 1 routes [CoreShadowLayersToCss.toValue]
  /// through its `>= 1.0` branch (`'$layer $base'`, the base used
  /// verbatim) rather than wrapping that base in a second `color-mix`
  /// that would flatten it to `transparent`.
  static List<CoreShadowLayer> _ghostOf(List<CoreShadowLayer> layers) => [
    for (final l in layers)
      (
        offsetX: l.offsetX,
        offsetY: l.offsetY,
        blurRadius: l.blurRadius,
        spreadRadius: l.spreadRadius,
        opacity: 1.0,
        inset: l.inset,
      ),
  ];

  /// Whether two stacks describe the same shadow.
  ///
  /// Record equality would do, but comparing the emitted geometry keeps
  /// this honest about what "unchanged" means here: a stack whose numbers
  /// round to the same output does not need a rule.
  static bool _sameStack(
    List<CoreShadowLayer> a,
    List<CoreShadowLayer> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  /// Semantic CSS variable map (Light mode).
  Map<String, String> get semanticLightVars =>
      PrimitiveCssGenerator.semanticVarsFor(_source, .light);

  /// Semantic CSS variable map (Dark mode).
  Map<String, String> get semanticDarkVars =>
      PrimitiveCssGenerator.semanticVarsFor(_source, .dark);

  // ── Spacing Config ────────────────────────────────────────

  /// `--coui-*` overrides for the high-contrast preference.
  ///
  /// Only the variables the source's raise governs are emitted — everything
  /// else inherits from `:root` by ordinary cascade, so this is never a
  /// second full palette that could drift from the first. The set is read
  /// off the raise itself ([PrimitiveCssGenerator.semanticVarsRaised])
  /// rather than off a hand-kept list of slots: a list falls behind the
  /// moment a mapping raises a slot it does not name, and that slot then
  /// renders raised on Flutter and normal here. It is the set the raise
  /// *writes*, not the set whose value changes, because the Flutter seat
  /// lets every written slot outrank a surface style — a slot pinned to its
  /// normal value included.
  ///
  /// The values come from the source's high-contrast builders, the same
  /// source Flutter reads, so the two platforms cannot disagree about what
  /// "high contrast" means.
  static String _highContrastVars(
    CoreSchemeSource source,
    CoreBrightness brightness,
  ) {
    final buffer = StringBuffer();
    for (final entry in PrimitiveCssGenerator.semanticVarsRaised(
      source,
      brightness,
    ).entries) {
      buffer.write('${entry.key}:${entry.value};');
    }

    return buffer.toString();
  }

  /// The slots of [s] that differ from [base].
  ///
  /// A surface style must write only what it actually changed. Writing the
  /// whole vocabulary makes the style rule override every slot of the
  /// high-contrast block — which matches the same element and loses on
  /// source order — so selecting a style would switch high contrast off
  /// wholesale rather than bending the few colours the style asked about.
  /// That inverts the one ordering this axis is built on: a result the user
  /// asked for beats a look the app chose.
  static String _schemeVarsDelta(
    ResolvedColorScheme s,
    ResolvedColorScheme base,
  ) {
    final buffer = StringBuffer();

    void put(String name, CoreColor value, CoreColor reference) {
      if (value == reference) return;
      buffer.write('--coui-$name:${value.red} ${value.green} ${value.blue};');
    }

    put('primary', s.primary, base.primary);
    put('primary-text', s.primaryText, base.primaryText);
    put('primary-text-large', s.primaryTextLarge, base.primaryTextLarge);
    put('secondary', s.secondary, base.secondary);
    put('tertiary', s.tertiary, base.tertiary);
    // Restated with tertiary. `accent` is that slot under another name;
    // a block that bends one and leaves the other keeps a stale fill.
    put('accent', s.tertiary, base.tertiary);
    put('error', s.error, base.error);
    put('success', s.success, base.success);
    put('warning', s.warning, base.warning);
    put('info', s.info, base.info);
    put('error-icon', s.errorIcon, base.errorIcon);
    put('success-icon', s.successIcon, base.successIcon);
    put('warning-icon', s.warningIcon, base.warningIcon);
    put('info-icon', s.infoIcon, base.infoIcon);
    put('on-primary', s.onPrimary, base.onPrimary);
    put('on-secondary', s.onSecondary, base.onSecondary);
    put('on-tertiary', s.onTertiary, base.onTertiary);
    put('on-accent', s.onTertiary, base.onTertiary);
    put('on-error', s.onError, base.onError);
    put('error-strong', s.errorStrong, base.errorStrong);
    put('focus-ring', s.focusRing, base.focusRing);
    put('primary-hover', s.primaryHover, base.primaryHover);
    put('primary-pressed', s.primaryPressed, base.primaryPressed);
    put('secondary-hover', s.secondaryHover, base.secondaryHover);
    put('secondary-pressed', s.secondaryPressed, base.secondaryPressed);
    put('error-pressed', s.errorPressed, base.errorPressed);
    put('on-success', s.onSuccess, base.onSuccess);
    put('on-warning', s.onWarning, base.onWarning);
    put('on-info', s.onInfo, base.onInfo);
    put('on-surface', s.onSurface, base.onSurface);
    put('on-surface-variant', s.onSurfaceVariant, base.onSurfaceVariant);
    put('placeholder', s.placeholder, base.placeholder);
    put('link', s.link, base.link);
    put('on-surface-subtle', s.onSurfaceSubtle, base.onSurfaceSubtle);
    put('outline', s.outline, base.outline);
    put('outline-variant', s.outlineVariant, base.outlineVariant);
    put('outline-subtle', s.outlineSubtle, base.outlineSubtle);
    put('disabled-content', s.disabledContent, base.disabledContent);
    put('disabled-outline', s.disabledOutline, base.disabledOutline);
    put('syntax-keyword', s.syntaxKeyword, base.syntaxKeyword);
    put('syntax-type', s.syntaxType, base.syntaxType);
    put('syntax-function', s.syntaxFunction, base.syntaxFunction);
    put('syntax-string', s.syntaxString, base.syntaxString);

    // The surface family — what lets `surfaceMatchesStage` (neumorphism's
    // defining constraint: component surfaces fold to the page colour)
    // reach the page. Named individually rather than looped, matching
    // every other slot above: a missing name here fails to compile against
    // `ResolvedColorScheme`, a missing entry in a loop-driven list just
    // silently emits nothing.
    put('surface', s.surface, base.surface);
    put('surface-dim', s.surfaceDim, base.surfaceDim);
    put('surface-bright', s.surfaceBright, base.surfaceBright);
    put(
      'surface-container-lowest',
      s.surfaceContainerLowest,
      base.surfaceContainerLowest,
    );
    put(
      'surface-container-low',
      s.surfaceContainerLow,
      base.surfaceContainerLow,
    );
    put('surface-container', s.surfaceContainer, base.surfaceContainer);
    put(
      'surface-container-high',
      s.surfaceContainerHigh,
      base.surfaceContainerHigh,
    );
    put(
      'surface-container-highest',
      s.surfaceContainerHighest,
      base.surfaceContainerHighest,
    );
    put('surface-raised', s.surfaceRaised, base.surfaceRaised);

    return buffer.toString();
  }

  /// CSS `cubic-bezier(x1, y1, x2, y2)` literal for [b].
  ///
  /// Delegates so the Core→CSS easing conversion has one implementation
  /// (`core_to_css.dart`); component resolvers emit through the same
  /// extension.
  static String _bezierTuple(CoreCubicBezier b) => b.toCss();

  /// Tailwind config entry. Keys with hyphens must be JS-quoted.
  static String _easingEntry(String key, String value) => '"$key":"$value"';

  /// CSS variable line for a single CoreEasing token.
  static String _easingCssVar(String key, CoreCubicBezier b) =>
      '--easing-$key:${_bezierTuple(b)};';

  static String _shadowCssVar(String key, List<CoreShadowLayer> layers) =>
      '--shadow-$key:'
      '${layers.isEmpty ? 'none' : layers.toValue(base: _kShadowColorBase)};';

  /// The `filter: drop-shadow()` counterpart of [_shadowCssVar] — same
  /// stack, `drop-shadow()` syntax instead of `box-shadow` syntax, so a
  /// component that casts through `filter` (a stack with no inset layer,
  /// so the shadow follows the child's rendered shape rather than its
  /// wrapper's square border-box) can move with a surface style too.
  static String _shadowFilterCssVar(String key, List<CoreShadowLayer> layers) {
    final filter = layers.isEmpty
        ? 'none'
        : layers.toDropShadowValue(base: _kShadowColorBase);
    return '--shadow-$key-filter:$filter;';
  }
}
