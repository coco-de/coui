/// CoUI Web application wrapper — Flutter `CoUIApp` parity for the
/// jaspr Web target.
///
/// Wraps the user's component tree with:
/// - [Theme] (the active `ThemeData` chosen by [CoUIWeb.themeMode]
///   and the light / dark inputs)
/// - [RecentColorsScope] (application-wide recent-colour history for
///   `ColorPicker`, seeded from [CoUIWeb.initialRecentColors] and
///   capped at [CoUIWeb.maxRecentColors])
/// - [OverlayHost] (root portal mount-point for popover / tooltip /
///   menu floating panels)
/// - optional `builder` / `title` / `background` wrappers
///
/// The recent-colour history is app-wide by default. A screen that
/// needs its own history wraps itself with another `RecentColorsScope`
/// — the nearer scope wins.
///
/// ```dart
/// runApp(
///   CoUIWeb(
///     theme: ThemeData.light,
///     darkTheme: ThemeData.dark,
///     themeMode: CoreThemeMode.system,
///     child: Router(
///       routes: [
///         Route(path: '/', builder: (ctx, _) => HomePage()),
///       ],
///     ),
///   ),
/// );
/// ```
///
/// Mirrors `CoUIApp` 1:1 for the parameters that have a meaningful
/// Web equivalent. Flutter framework-only fields (`scaling` /
/// `materialTheme` / `home` / `routes` / `actions` / `shortcuts`
/// etc.) are intentionally absent — Web uses the equivalent native
/// browser feature (CSS rem scaling, jaspr_router, document keydown
/// listeners) instead.
///
/// `popoverHandler` / `menuHandler` / `tooltipHandler` are
/// intentionally not exposed on Web — and this is a deliberate
/// course-correction, not a follow-up gap. Flutter `CoUIApp`
/// uses those props to auto-swap between popover and bottom-sheet
/// based on touch / narrow viewport detection. The trade-off:
///
/// - the same `Select(...)` call site renders as a different
///   shape depending on viewport width (popover on desktop, sheet
///   on mobile), so a designer who actually wanted a popover on
///   mobile has to *opt out* by passing
///   `handler: const PopoverOverlayHandler()` — making the
///   "I want what I drew" path *longer* than the implicit-magic
///   path;
/// - QA / visual regression has to capture every component twice
///   (one shape per viewport class), and the second capture is
///   driven by hardware detection rather than designer intent;
/// - debugging "why did this render as a sheet?" leads into a
///   hidden `mobileMode` branch instead of a prop on the call site.
///
/// CoUI's direction across both platforms is the opposite:
/// rendering shape is an explicit per-component `variant` prop
/// (e.g. `Select(variant: .popover | .sheet)`), so the same call
/// site produces the same shape on every viewport and on both
/// platforms. CoUI Web ships that direction natively from the
/// start; the Flutter `CoUIApp` handler-injection + mobileMode
/// branch is scheduled to be removed in a separate epic
/// (per-component `variant` prop migration) — its existence today
/// reflects legacy code, not the intended target shape.
///
/// See the PR #1276 description for the full parity matrix.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/adaptive_quality_scope.dart';
import 'package:coui_web/src/base/density_scope.dart';
import 'package:coui_web/src/base/fold_scope.dart';
import 'package:coui_web/src/base/quality_feed.dart';
import 'package:coui_web/src/base/surface_refraction_host.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/infra/scrollview/scrollview_interceptor.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations_scope.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:coui_web/src/overlay/overlay_host.dart';
import 'package:coui_web/src/overlay/recent_colors_scope.dart';
import 'package:coui_web/src/page/page_transition_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/theme/theme_data.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

part 'page/page_transition_head.dart';

/// Default capacity of the app-root recent-colors history (matches
/// `RecentColorsScope`'s own default and Flutter `CoUIApp`).
const _kDefaultMaxRecentColors = 10;

/// What `CoUIWeb` writes as the document's typography tier once it lifts a
/// pin it set — a value that names no tier, so the viewport rules
/// (`ThemeConfig.typographyTierBlocks`) take the document again.
const _kTypographyTierViewport = 'viewport';

/// Colour-only theme cross-fade rule, injected under `.coui-theme-anim`
/// when `CoUIWeb.enableThemeAnimation` is set. Animates the properties
/// that the `--coui-*` variable flip touches, matching the Flutter
/// `CoUIAnimatedTheme` duration (`CoreDuration.fast`) and linear curve.
/// Scoped to colour properties (not `all`) so component-owned
/// transitions and layout are unaffected.
// `:where()` keeps the rule at specificity 0 so component-owned
// transition utilities (`transition-all` on overlay bubbles, etc.)
// always win — a plain `.coui-theme-anim *` (0,1,1) outranked
// `.transition-all` (0,1,0) and silently replaced its property list
// with the colour-only set, snapping every opacity/transform
// enter/exit animation under an animated theme.
//
// Shared with [_kSurfaceGeometryTransitionCss] below: a longhand
// `transition-property` list from a later same-specificity rule fully
// *replaces* an earlier one for any element both rules match — it
// never merges the two lists — so the geometry rule must restate this
// colour set alongside its own additions, or every surface-marked
// element would silently lose its colour cross-fade the moment the
// geometry rule was added. Keeping one Dart constant is what makes
// that restatement impossible to drift out of sync.
const _kThemeTransitionColourProperties =
    'background-color,border-color,color,fill,stroke,outline-color,'
    'box-shadow,text-decoration-color';

final _kThemeTransitionCss =
    ':where(.coui-theme-anim),:where(.coui-theme-anim *), '
    ':where(.coui-theme-anim *)::before,:where(.coui-theme-anim *)::after{ '
    'transition-property:$_kThemeTransitionColourProperties;'
    // `var(--coui-duration-150)`, not a literal `150ms` — this rule is
    // scoped to `.coui-theme-anim *`, i.e. every descendant of a
    // `CoUIWeb.enableThemeAnimation` root (139/139 docs pages). A literal
    // ms value here never passed through the CSS variable the
    // `@media (prefers-reduced-motion:reduce)` override in
    // `theme_config.dart` retimes to `0ms` — so a user with that
    // preference got a full-speed theme crossfade on every descendant,
    // site-wide, with no way for the override to reach it (#3468).
    'transition-duration:${durationMsCss(CoreDuration.fast)};'
    'transition-timing-function:linear;}';

/// Adds geometry to the cross-fade for surface-recipe-marked elements
/// only (`kWebSurfaceMarker` — `outlined_container` / `popup` / `card` /
/// `dock` / `scaffold` / `navigation_bar` / `dialog` / `tooltip`, the
/// components a [CoreSurfaceStyleId] preset actually restyles).
///
/// [_kThemeTransitionCss] above only ever needed *colour* — a light/dark
/// swap never touches geometry — but switching the surface *preset*
/// itself also changes `border-width` / `border-radius` (neo-brutalism
/// thickens borders and squares corners; `surface_geometry_css_test.dart`
/// exercises the recipe), so a preset change with no colour difference at
/// all (e.g. a corner-radius-only recipe) previously snapped instantly
/// even with `enableThemeAnimation` on.
///
/// Scoped to the marker rather than widening [_kThemeTransitionCss]
/// itself: every *other* element on the page has no reason to suddenly
/// animate a `border-width` / `border-radius` change that used to
/// snap — a focus ring's border-width flip, for one, would otherwise
/// grow an unintended lag.
///
/// `opacity` / `transform` are restated here for the same reason
/// [_kThemeTransitionColourProperties] is — replacement, not merging.
/// A marked element that manages its own enter/exit through Tailwind's
/// `transition-all` loses it entirely once this rule matches, because
/// this longhand list wins the cascade and does not name those two.
/// `Tooltip`'s bubble is exactly that shape: it carries
/// [kWebSurfaceMarker] and `transition-all` on the same element and
/// enters/exits by swapping `opacity-0 scale-90` ↔ `opacity-100
/// scale-100`, so omitting them here snapped every tooltip in/out with
/// no fade — the precise regression [_kThemeTransitionCss]'s own
/// `:where()` note above says it used `:where()` to avoid.
///
/// Naming them costs nothing on the interaction this rule exists for: a
/// theme or preset switch does not change `opacity` or `transform`, and
/// `transition-property` only animates properties that actually change.
final _kSurfaceGeometryTransitionCss =
    ':where(.coui-theme-anim, .coui-theme-anim *) .$kWebSurfaceMarker{ '
    'transition-property:$_kThemeTransitionColourProperties,'
    'border-width,border-radius,opacity,transform;'
    'transition-duration:${durationMsCss(CoreDuration.fast)};'
    'transition-timing-function:linear;}';

/// Global press-feedback rule for `Clickable` (and every component
/// composed on it). The shrink rides the browser-native `:active`
/// pseudo-class — no Dart re-render — but on hover-capable pointers it
/// additionally requires `:hover`, so pressing an element and dragging
/// the pointer off it releases the shrink immediately, matching
/// Flutter's `onTapCancel` (which un-scales when the press drifts out of
/// bounds). Touch pointers (`hover: none`) keep the plain `:active`
/// shrink because `:hover` is unreliable there. The per-instance scale
/// factor rides the `--coui-press-scale` custom property the widget sets
/// inline; the `active:hover:` selector can't be a Tailwind utility (the
/// runtime CDN build doesn't compile stacked pseudo variants), so it
/// lives here as a single raw rule instead of a per-instance `<style>`.
/// The transform a pressed control wears.
///
/// Translate before scale, so the distance is the one the style stated
/// rather than that distance shrunk by the scale factor. Both components
/// default to zero, so a control that only states a scale is unchanged.
const _kPressTransform =
    'transform:translate(var(--coui-press-x,0),var(--coui-press-y,0)) '
    'scale(var(--coui-press-scale,1));';

/// The pressed shadow, on a class of its own.
///
/// Separate from the transform rule because it writes `box-shadow`
/// outright: a control with a resting shadow and nothing to say about
/// pressing would otherwise lose that shadow the moment it was pressed.
/// The class is only added when a style states one.
const _kPressShadow = 'box-shadow:var(--coui-press-shadow);';

const _kClickablePressCss =
    '@media (hover:hover){ '
    '.coui-clickable-press:active:hover{$_kPressTransform}'
    '.coui-clickable-press-shadow:active:hover{$_kPressShadow}}'
    '@media (hover:none){ '
    '.coui-clickable-press:active{$_kPressTransform}'
    '.coui-clickable-press-shadow:active{$_kPressShadow}}'
    // Keyboard-activation twin of the two rules above (#4421). Not
    // gated on `@media (hover:*)` — the drag-off-release ambiguity that
    // split those in two has no keyboard equivalent, and `Clickable`
    // toggles this marker itself (keydown/keyup pair for Space, a pulse
    // for Enter) rather than relying on any pseudo-class.
    '.coui-clickable-press.$kClickableKeyPressedMarker{$_kPressTransform}'
    '.coui-clickable-press-shadow.$kClickableKeyPressedMarker'
    '{$_kPressShadow}';

/// Paints an app bar's scroll-edge layer as an opaque surface when the
/// reader asks for more contrast or less transparency.
const _kGlassChromeAccessibilityCss =
    '@media (prefers-contrast:more),(prefers-reduced-transparency:reduce){ '
    '[data-coui-app-bar-edge]{opacity:1!important;'
    'background:rgb(var(--coui-surface))!important;}}';

/// Stretches the direct child of an `AspectRatioBox` content layer to
/// fill the ratio-constrained box on both axes — the CSS mirror of the
/// tight constraints Flutter's `AspectRatio` passes to its child.
/// Lives here as a single global rule (same model as
/// [_kClickablePressCss]) because a fit-content child (e.g. `Card`'s
/// `w-fit` root) would otherwise render at its intrinsic size and no
/// parent-side class can override the child's own sizing without a
/// child selector.
const _kAspectRatioFillCss = '.coui-aspect-fill>*{width:100%;height:100%;}';

/// Keeps focus visible — and only focus visible — when the platform forces
/// its own palette (Windows High Contrast and friends).
///
/// Two separate failures meet here, and they point in opposite directions.
///
/// Tailwind v3's `outline-none` does not remove the outline; it sets
/// `outline: 2px solid transparent`, deliberately, so that a forced-colours
/// mode has something to paint. That is exactly right on a focus state and
/// exactly wrong at rest: the forcing pass overrides `transparent`, so every
/// element that reserves a resting outline wears a permanent ring and focus
/// becomes impossible to pick out. Suppressing the ring would be a smaller
/// bug than making everything look focused.
///
/// The mirror problem is that a component focus ring does not always sit on
/// the focused element: `FocusOutline` draws it on a wrapper, `Checkbox` and
/// `Toggle` on a descendant, `ChipInput` on the frame around a focused
/// input. The first rule switches those outlines off along with every other
/// unfocused one (their `outline-style` is turned on at zero specificity or
/// by a class for exactly this reason), and the second gives the element
/// that does hold focus the one ring the platform paints — a gap band,
/// which is a `box-shadow` forced colours leaves alone, cannot stand in for
/// it.
///
/// Both are fixed here rather than at the ~15 emit sites, because several of
/// those are unconditional for good reasons of their own (see
/// `CoreClickableStyle.defaultDisabledOpacity`'s neighbour in
/// `clickable_style.dart`: flipping `outline-style` on focus makes the
/// theme cross-fade flash a text-coloured border). Confining the correction
/// to the media query leaves normal rendering byte-identical.
///
/// Scoped to `.coui-root` so the specificity (0,2,0) beats Tailwind's
/// `.outline-none` (0,1,0) without depending on stylesheet order.
const _kForcedColorsFocusCss =
    '@media (forced-colors:active){ '
    '.coui-root :not(:focus-visible){outline-style:none;} '
    '.coui-root :focus-visible{outline:2px solid;outline-offset:2px;}}';

/// CoUI Web application root component.
///
/// Provides `Theme` (an `InheritedComponent`) so descendants can
/// read theme tokens via `Theme.of(context)` / `context.theme`, and
/// installs a [OverlayHost] so floating components (popover /
/// tooltip / menu) can portal their panels above the user tree.
///
/// Use this once at the application root. For nested theme
/// overrides inside the tree, use `Theme` directly.
class CoUIWeb extends StatefulComponent {
  /// Creates a CoUI Web application wrapper.
  ///
  /// Mirrors the field set of Flutter `CoUIApp` for parameters that
  /// have a meaningful Web equivalent. See the class doc-comment
  /// for the full parity matrix.
  const CoUIWeb({
    required this.child,
    required this.theme,
    super.key,
    this.darkTheme,
    this.themeMode = CoreThemeMode.system,
    this.locale,
    this.supportedLocales = const [Locale('en', 'US')],
    this.title,
    this.builder,
    this.background,
    this.color,
    this.disableBrowserContextMenu = true,
    this.enableScrollInterception = true,
    this.enableThemeAnimation = true,
    this.initialRecentColors = const [],
    this.maxRecentColors = _kDefaultMaxRecentColors,
    this.onRecentColorsChanged,
    this.density = CoreDensity.defaultDensity,
    this.typographyTier,
    this.adaptiveQuality,
  });

  /// The root component of the application.
  final Component child;

  /// The density the app sets its spacing, control rows and their corners
  /// in — the twin of Flutter `CoUIApp.density`.
  ///
  /// Written to the document as `data-coui-density`, which is what the
  /// stylesheet's density rules key off, so it reaches the server-rendered
  /// markup. Left at the default, the document keeps whatever density it
  /// already carries — the state a host page or `DensityScope.setDensity`
  /// manages — instead of this field clearing it on every rebuild.
  final CoreDensity density;

  /// The viewport tier the app's display and headline roles are pinned to —
  /// the twin of Flutter `CoUIApp.typographyTier`.
  ///
  /// `null`, the default, lets the viewport choose: the stylesheet's
  /// typography tier rules (`ThemeConfig.typographyTierBlocks`) size the
  /// headings for the width the browser lays the page out at, from the first
  /// paint, with no width read on the Dart side — a server render has none.
  /// A tier written here goes onto the document as
  /// `data-coui-typography-tier` and holds every width to that tier, which
  /// is how an app keeps the desktop headings it shipped with. Left `null`,
  /// the document keeps whatever tier a host page already pinned it to,
  /// for the reason [density] keeps a density. Rebuilding with another
  /// value moves the pin, and rebuilding with `null` after a tier lifts it,
  /// as `CoUIApp` does.
  final CoreBreakpointTier? typographyTier;

  /// Lets the app trade the glass for smoothness when the device cannot hold
  /// the display's rate — or fixes the trade. Off (`null`) by default. The
  /// twin of Flutter `CoUIApp.adaptiveQuality`, and the same object.
  ///
  /// Each surface goes without the bend at its rim, then without its backdrop
  /// pass, as the page's frames arrive late ([CoreQualityTier]). The tier is
  /// written to the document as `data-coui-quality`, which the stylesheet's
  /// rules and the refraction host key off — so it reaches markup the server
  /// already rendered, and a step costs no rebuild of the page. A tier is
  /// never added to what the style states; a reduce-transparency preference
  /// is the lowest tier whatever is stated here (the stylesheet answers it
  /// on its own), and nothing is measured while it holds.
  ///
  /// [CoreAdaptiveQuality.forced] and [CoreAdaptiveQuality.initialQuality]
  /// are written into the server-rendered `<html>`, so the first paint is
  /// already at that tier. Measuring happens in the browser only: the page
  /// is asked for frames only while it is in motion, and the display's rate
  /// is read off the first of them unless [CoreAdaptiveQuality.targetFrameRate]
  /// states it. Read the tier with [AdaptiveQualityScope.of]; hold measurement
  /// around heavy work of your own with [AdaptiveQualityScope.holdMeasurement].
  final CoreAdaptiveQuality? adaptiveQuality;

  /// The light (or default) theme data.
  final ThemeData theme;

  /// Optional dark-mode theme data. When non-null and
  /// [themeMode] resolves to dark, this replaces [theme] before
  /// being handed to descendants.
  final ThemeData? darkTheme;

  /// Light / dark / system selector. `system` reads
  /// `prefers-color-scheme` at runtime and updates live when the
  /// OS-level preference flips.
  final CoreThemeMode themeMode;

  /// BCP 47 language tag (e.g. `'ko'`, `'en-US'`). Mirrors
  /// `CoUIApp.locale`.
  ///
  /// Applied at runtime as `<html lang>` so screen readers, browser
  /// auto-translate heuristics, and SEO crawlers pick up the right
  /// language. SSR head templates can pre-render the same value to
  /// avoid a flash; the runtime call here keeps single-page-app
  /// language switches in sync without a full page reload. Also
  /// selects the [CouiLocalizations] implementation exposed to
  /// descendants via the ambient [CouiLocalizationsScope].
  ///
  /// When left `null` (pure browser auto-negotiation), the server
  /// always renders with [DefaultCouiLocalizations] (browser APIs
  /// are unavailable during SSR) while the client may re-negotiate to
  /// a different locale on hydration — a possible one-frame text
  /// flash. Apps that server-render locale-sensitive CoUI chrome text
  /// should either set this explicitly to a request-resolved value,
  /// or wrap their own [CouiLocalizationsScope] inside [child] for
  /// per-request isolation (see that class's doc comment).
  final Locale? locale;

  /// Supported locales — same role as `CoUIApp.supportedLocales`.
  /// The best match between this list and the browser's
  /// `navigator.languages` (or [locale] when explicitly set) selects
  /// the [CouiLocalizations] implementation installed as the ambient
  /// [CouiLocalizationsScope] for CoUI's own built-in component chrome
  /// strings (calendar month names, pagination labels, validation
  /// messages, etc.). Does not affect the host app's own content —
  /// number / date formatting for application data is the host app's
  /// concern (e.g. via `package:intl`).
  final List<Locale> supportedLocales;

  /// Window / browser tab title — applied at runtime as
  /// `document.title`. jaspr-router-style per-route titles can
  /// override by setting `document.title` directly inside their
  /// own route builders.
  final String? title;

  /// Optional transition wrapper, identical role to
  /// `CoUIApp.builder`. Receives the application subtree (already
  /// wrapped with theme / overlay host) and returns a wrapped tree
  /// — useful for animated route transitions or a global layout
  /// shell.
  final Component Function(BuildContext context, Component? child)? builder;

  /// Page background color (CSS string — `cs.surface.toValue()` or a
  /// CoUI semantic token name). When non-null, applied as
  /// `background-color` on the wrapper `<div>`.
  final String? background;

  /// Application theme colour — mirrors Flutter `CoUIApp.color`. When
  /// non-null, synced at runtime to `<meta name="theme-color">` so
  /// mobile browsers tint their chrome (address bar / task switcher)
  /// to match. Distinct from [background] (the page surface fill): this
  /// is a CSS colour string (`cs.primary.toValue()` or a hex value).
  final String? color;

  /// Whether the wrapper disables the browser's default context
  /// menu (right-click). Mirrors `CoUIApp.disableBrowserContextMenu`.
  /// `true` calls `event.preventDefault()` on every `contextmenu`
  /// event at the document level.
  final bool disableBrowserContextMenu;

  /// Whether the app provides CoUI middle-mouse hold-scroll (desktop
  /// autoscroll). Mirrors Flutter `CoUIApp.enableScrollInterception`,
  /// which mounts a `ScrollViewInterceptor` around the app.
  ///
  /// `true` (default) wraps the subtree in the CoUI `ScrollViewInterceptor`
  /// — the shared cubic auto-scroll engine — which suppresses the
  /// browser's native middle-click autoscroll itself. `false` suppresses
  /// the browser's native autoscroll at the document level (no CoUI
  /// handling), matching Flutter's "remove CoUI auto-scroll" branch.
  final bool enableScrollInterception;

  /// Whether light/dark (and any `data-theme`) switches cross-fade the
  /// colour tokens. Mirrors Flutter `CoUIApp.enableThemeAnimation`
  /// (which fades the theme over `kDefaultDuration`). When `true`, a
  /// scoped `<style>` adds a colour-only CSS `transition`
  /// (`CoreDuration.fast`, linear — matching the Flutter
  /// `CoUIAnimatedTheme` duration/curve) so the `--coui-*` variable
  /// flip animates instead of snapping.
  final bool enableThemeAnimation;

  /// Initial recent-color history for the app-root [RecentColorsScope]
  /// (most-recent-first). Mirrors Flutter `CoUIApp.initialRecentColors`;
  /// seed from persisted storage to restore the palette across loads.
  final List<CoreColor> initialRecentColors;

  /// Maximum retained entries in the app-root recent-color history.
  /// Mirrors Flutter `CoUIApp.maxRecentColors`.
  final int maxRecentColors;

  /// Fired whenever the app-root recent-color history mutates, so the
  /// host app can persist it (e.g. `localStorage`). Mirrors Flutter
  /// `CoUIApp.onRecentColorsChanged`.
  final void Function(List<CoreColor> colors)? onRecentColorsChanged;

  @override
  State<CoUIWeb> createState() => _CoUIWebState();
}

class _CoUIWebState extends State<CoUIWeb> {
  /// Current OS-level dark / light preference — only consulted when
  /// `component.themeMode == .system`. Re-resolves on every media
  /// query change.
  bool _systemPrefersDark = false;

  /// Disposers for the runtime listeners installed in [initState].
  void Function()? _disposeColorScheme;
  void Function()? _disposeContextMenu;
  void Function()? _disposeMiddleClickScroll;

  /// Active [CouiLocalizations] installed as the ambient
  /// [CouiLocalizationsScope] — see [_resolveLocale].
  CouiLocalizations _localizations = DefaultCouiLocalizations.instance;

  /// BCP 47 language tag backing the last [_resolveLocale] call —
  /// `null` only when [CoUIWeb.supportedLocales] is empty. Kept
  /// alongside [_localizations] so [build] can carry it into
  /// `Document.html`, which (unlike the DOM mutation in
  /// [_resolveLocale]) actually reaches server-rendered markup.
  String? _languageTag;

  /// Direction of [_languageTag] (`CoreTextDirectionForLocale.of`),
  /// applied through the same `Document.html` call as [_languageTag].
  /// Defaults to [CoreTextDirection.ltr] — the common answer for a
  /// tag outside the RTL table.
  CoreTextDirection _direction = .ltr;

  /// Whether this app has written a typography tier on the document — see
  /// [_typographyTierAttribute].
  bool _wroteTypographyTier = false;

  /// The tier the surfaces are drawn at, as far as this app knows: the one it
  /// stated, or the one its governor settled on.
  CoreQualityTier _quality = CoreQualityTier.defaultTier;

  /// The browser's frame feed behind [_quality], or null when none runs — the
  /// app stated nothing or a tier, or this is the server.
  WebQualityFeed? _qualityFeed;

  /// Whether the user asked for less transparency. The stylesheet draws the
  /// surfaces opaque on its own; this is so that [AdaptiveQualityScope] says
  /// what it does — the lowest tier — the way the Flutter scope does.
  bool _reducedTransparency = false;

  void Function()? _disposeReducedTransparency;

  void _handleReducedTransparency({required bool reduced}) {
    if (!mounted || _reducedTransparency == reduced) return;
    setState(() => _reducedTransparency = reduced);
  }

  /// What a page can be asked to go without: both, because a browser that
  /// parses the bend and does not draw it cannot be told apart by asking.
  static const Set<CoreQualityEffect> _kQualityDrawable = {
    CoreQualityEffect.refraction,
    CoreQualityEffect.backdropPass,
  };

  /// Whether this app has written a quality tier on the document — see
  /// [_qualityAttribute].
  bool _wroteQuality = false;

  /// The value `data-coui-quality` takes on the document.
  ///
  /// Stated → written, tier by tier and `full` too: a tier the governor gave
  /// up and took back is lifted by naming the top and not by leaving the
  /// attribute out, because on the client jaspr keeps every attribute a
  /// `Document.html` ever declared on `<html>`. The same goes for a statement
  /// the app stops making — the last tier would stay, and the page would
  /// differ from Flutter, where `CoUIApp` draws the style in full as soon as
  /// its `adaptiveQuality` is `null`. Never stated → a tier a host page put
  /// there is echoed, for the reason the density is.
  String? _qualityAttribute() {
    if (component.adaptiveQuality != null) {
      _wroteQuality = true;

      return _quality.name;
    }

    return _wroteQuality
        ? CoreQualityTier.defaultTier.name
        : documentAttribute(kQualityAttribute);
  }

  /// Starts what [CoUIWeb.adaptiveQuality] asks for.
  void _configureQuality() {
    _qualityFeed?.dispose();
    _qualityFeed = null;
    final stated = component.adaptiveQuality;
    if (stated == null) {
      _quality = CoreQualityTier.defaultTier;

      return;
    }
    _quality = stated.startTier(_kQualityDrawable);
    if (stated.forced != null) return;
    _qualityFeed = WebQualityFeed.start(
      stated: stated,
      onChange: _handleQualityChange,
    );
  }

  void _handleQualityChange(CoreQualityChange change) {
    if (!mounted) return;
    // The document first: the stylesheet and the refraction host react to
    // the attribute, so this is when the surfaces change. The rebuild below
    // restates the same value declaratively.
    setDocumentAttribute(kQualityAttribute, change.to.name);
    setState(() => _quality = change.to);
    component.adaptiveQuality?.onQualityChanged?.call(change);
  }

  /// The value `data-coui-typography-tier` takes on the document.
  ///
  /// A stated tier is written. With none, a tier a host page put there is
  /// echoed, for the reason the density is. A pin this app wrote and no
  /// longer states is lifted by writing a value that names no tier, not by
  /// leaving the attribute out: on the client, jaspr keeps every attribute
  /// a `Document.html` ever declared on `<html>`, so the old pin would stay
  /// — and the page would differ from Flutter, where `CoUIApp` follows the
  /// viewport again as soon as its tier is `null`.
  String? _typographyTierAttribute() {
    if (component.typographyTier case final tier?) {
      _wroteTypographyTier = true;

      return tier.name;
    }

    return _wroteTypographyTier
        ? _kTypographyTierViewport
        : documentAttribute(kTypographyTierAttribute);
  }

  @override
  void initState() {
    super.initState();
    _systemPrefersDark = prefersDarkColorScheme;
    _disposeColorScheme = registerDarkColorSchemeListener(
      _handleSystemColorSchemeChange,
    );
    if (component.disableBrowserContextMenu) {
      _disposeContextMenu = suppressBrowserContextMenu();
    }
    // Flutter `CoUIApp.enableScrollInterception=false` removes
    // CoUI's auto-scroll handling; the Web equivalent is
    // suppressing the browser's middle-click auto-scroll cursor
    // (browsers' own implementation of the same gesture).
    if (!component.enableScrollInterception) {
      _disposeMiddleClickScroll = suppressMiddleClickAutoScroll();
    }
    // Refraction is aimed at the surface marker, the same way the rest of
    // the material is — see `SurfaceRefractionHost` for why this is one
    // document-level thing rather than eight component wirings.
    SurfaceRefractionHost.install();
    _reducedTransparency = prefersReducedTransparency;
    _disposeReducedTransparency = registerReducedTransparencyListener(
      _handleReducedTransparency,
    );
    _configureQuality();
    final title = component.title;
    if (title != null) setDocumentTitle(title);
    _localizations = _resolveLocale();
    final color = component.color;
    if (color != null) setMetaThemeColor(color);
  }

  /// Sets `<html lang>`/`<html dir>` (client-side DOM mutation — see
  /// [build] for the path that actually reaches SSR markup) and
  /// resolves the ambient [CouiLocalizations] scope value from an
  /// explicit [CoUIWeb.locale] when set, else negotiates the best
  /// match between the browser's `navigator.languages` and
  /// [CoUIWeb.supportedLocales]. Mirrors Flutter
  /// `WidgetsApp.supportedLocales` resolution — including its
  /// guarantee of never leaving the resolved locale unset: browser
  /// negotiation is always a no-op during SSR (no
  /// `navigator.languages`), so without a fallback, a docs/marketing
  /// site that never sets an explicit [CoUIWeb.locale] would render
  /// every page with no `lang`/`dir` at all. When neither an explicit
  /// locale nor a negotiated match is available, this falls back to
  /// `supportedLocales.first` — the same "answer with the app's own
  /// default rather than nothing" rule `WidgetsApp` already applies on
  /// Flutter.
  ///
  /// Pure computation (plus the `<html lang>`/`<html dir>` DOM side
  /// effect, a no-op during SSR) — callers decide how to commit the
  /// result: [initState] mutates [_localizations]/[_languageTag]/
  /// [_direction] directly (no rebuild scheduled yet), [didUpdateComponent]
  /// goes through [_applyLocaleUpdate] to `setState` only when the
  /// value actually changed. [build] reads [_languageTag]/[_direction]
  /// to emit `Document.html(attributes: {'lang': ..., 'dir': ...})` —
  /// Jaspr's `Document.html` is supported both during SSR
  /// pre-rendering and on the client, so unlike the DOM mutation below
  /// it is the single mechanism that actually answers "what language/
  /// direction is this page" for both environments.
  CouiLocalizations _resolveLocale() {
    final locale = component.locale;
    final languageTag =
        locale?.toLanguageTag() ??
        negotiateLocale(
          component.supportedLocales.map((l) => l.toLanguageTag()).toList(),
        ) ??
        (component.supportedLocales.isEmpty
            ? null
            : component.supportedLocales.first.toLanguageTag());

    _languageTag = languageTag;
    // `dir` rides with `lang`, from the same resolved value: the two
    // answer one question between them, and setting only the language
    // leaves an Arabic page announced correctly and rendered backwards.
    // The direction table lives in `coui_core` so the Flutter root
    // cannot disagree with this one about the same locale.
    _direction = languageTag != null
        ? CoreTextDirectionForLocale.of(languageTag)
        : .ltr;

    if (languageTag != null) {
      setHtmlLangAttribute(languageTag);
      setHtmlDirAttribute(_direction == .rtl ? 'rtl' : 'ltr');
    }
    return languageTag != null
        ? resolveCouiLocalizationsFor(languageTag.split('-').first)
        : DefaultCouiLocalizations.instance;
  }

  /// Re-resolves the locale after a component update and schedules a
  /// rebuild only when the resolved value actually changed.
  void _applyLocaleUpdate() {
    final resolved = _resolveLocale();
    if (resolved == _localizations) return;
    setState(() => _localizations = resolved);
  }

  void _handleSystemColorSchemeChange({required bool isDark}) {
    if (!mounted || _systemPrefersDark == isDark) return;
    setState(() => _systemPrefersDark = isDark);
  }

  /// Resolves the active [ThemeData] against [CoUIWeb.themeMode] and
  /// the system preference (when mode is [CoreThemeMode.system]).
  /// Falls back to [CoUIWeb.theme] when no `darkTheme` is supplied.
  ThemeData _resolveTheme() {
    final mode = component.themeMode;
    final darkTheme = component.darkTheme;
    if (darkTheme == null) return component.theme;
    final wantDark = switch (mode) {
      .dark => true,
      .light => false,
      .system => _systemPrefersDark,
    };
    return wantDark ? darkTheme : component.theme;
  }

  @override
  void didUpdateComponent(covariant CoUIWeb oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.disableBrowserContextMenu !=
        component.disableBrowserContextMenu) {
      _disposeContextMenu?.call();
      _disposeContextMenu = component.disableBrowserContextMenu
          ? suppressBrowserContextMenu()
          : null;
    }
    if (oldComponent.enableScrollInterception !=
        component.enableScrollInterception) {
      _disposeMiddleClickScroll?.call();
      _disposeMiddleClickScroll = component.enableScrollInterception
          ? null
          : suppressMiddleClickAutoScroll();
    }
    final quality = component.adaptiveQuality;
    final before = oldComponent.adaptiveQuality;
    if (quality == null || before == null
        ? quality != before
        : !quality.sameTerms(before)) {
      _configureQuality();
    }
    if (oldComponent.title != component.title) {
      final title = component.title;
      if (title != null) setDocumentTitle(title);
    }
    if (oldComponent.locale != component.locale) {
      _applyLocaleUpdate();
    }
    if (oldComponent.color != component.color) {
      final color = component.color;
      if (color != null) setMetaThemeColor(color);
    }
  }

  @override
  void dispose() {
    _qualityFeed?.dispose();
    _disposeReducedTransparency?.call();
    SurfaceRefractionHost.uninstall();
    _disposeColorScheme?.call();
    _disposeContextMenu?.call();
    _disposeMiddleClickScroll?.call();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Application root chain: recent-colors → overlay host → user tree.
    // A default [RecentColorsScope] is mounted at the application root
    // (empty history, capacity [CoUIWeb.maxRecentColors], no persistence
    // unless [CoUIWeb.onRecentColorsChanged] is set) so `ColorPicker`
    // shows its recent-colors row out of the box. Screens needing a
    // scoped history wrap themselves with their own `RecentColorsScope`
    // (the nearer scope wins). Mirrors Flutter `CoUIApp`.
    Component subtree = RecentColorsScope(
      initialRecentColors: component.initialRecentColors,
      maxRecentColors: component.maxRecentColors,
      onRecentColorsChanged: component.onRecentColorsChanged,
      child: OverlayHost(child: component.child),
    );

    // Ambient icon sizing baseline — mirrors Flutter `CoUIApp`, which
    // mounts `IconTheme.merge(theme.iconTheme.medium)` at the application
    // root, and both read `CoreIconStyle.defaultAmbientSize`: a bare
    // `Icon(...)` with no explicit size then renders at that size on both
    // platforms. Without this the Web side falls back to
    // `CoreIconStyle.defaultSize` and drifts larger than the Flutter twin.
    // Colour is deliberately NOT pinned here — Web icons inherit
    // `currentColor` from the CSS cascade (value-preserving asymmetry, see
    // `icon_style.dart`), which already converges on `onSurface` at this
    // root.
    subtree = IconTheme(
      data: const IconThemeData(size: CoreIconStyle.defaultAmbientSize),
      child: subtree,
    );

    final wrapper = component.builder;
    if (wrapper != null) {
      subtree = wrapper(context, subtree);
    }

    // Middle-mouse hold-scroll interception (desktop autoscroll). When
    // enabled, wrap the subtree in the CoUI `ScrollViewInterceptor` —
    // Flutter `CoUIApp` mounts the same component around the app — which
    // runs the shared cubic auto-scroll engine and suppresses the
    // browser's native middle-click autoscroll itself. When disabled, the
    // browser's native autoscroll is suppressed at the document level in
    // [initState] (no CoUI handling). Flutter parity for both branches.
    if (component.enableScrollInterception) {
      subtree = ScrollViewInterceptor(child: subtree);
    }

    // Root typography + color baseline.
    //
    // `Text` (coui_web) emits `text-inherit` when no explicit color is
    // set, and no longer self-applies `text-${CoreTextStyles.bodyMedium.name}`
    // either — both are cascade-friendly so a parent like Banner / Link /
    // surface that owns a typography slot (`labelLarge`, etc.) can
    // paint the tone *and* size from the wrapper, and have them flow
    // through to plain `Text('…')` children.
    //
    // The cascade chain still needs a starting point: that's this
    // root `text-${cs.onSurface} text-${CoreTextStyles.bodyMedium.name}`. Light/dark
    // mode switching keeps working because the tokens resolve against
    // the active scheme. A chain modifier (`Text('…').onErrorContainer`,
    // `.titleLarge`) still wins via its own explicit class.
    final theme = _resolveTheme();
    final defaultTextColor =
        'text-${theme.colorScheme.onSurface ?? 'on-surface'}';
    final defaultTypography = 'text-${CoreTextStyles.bodyMedium.name}';
    // Font family joins the same cascade: the root paints the project
    // sans once and `Text` inherits it (parent-decided, mirroring
    // Flutter's `DefaultTextStyle`), so a monospace wrapper (code /
    // masked-input separators) flows through to plain `Text` children
    // instead of being overridden by a child-side `font-sans`.
    final defaultFontFamily = 'font-${CoreFontFamily.scale.sans}';
    // `break-words` (`overflow-wrap: break-word`) is inherited, so one
    // application at the app root mirrors Flutter's engine-wide line
    // breaking: both platforms break at word boundaries first, and a
    // single word longer than the line falls back to character-level
    // breaking. Without it the Web default (`overflow-wrap: normal`)
    // has no fallback and long single words overflow their pane. It
    // only fires on overflow — normal wrapping and intrinsic
    // (min-content) sizing are untouched.
    final defaultClasses =
        '$defaultTextColor $defaultTypography $defaultFontFamily '
        '${WebLayout.breakWords}';
    final hasBackground = component.background != null;

    // Optional [background] painted on a thin wrapping `<div>` so the
    // page surface picks up the user-supplied colour without forcing
    // every child component to opt in. Skipped when null to keep the
    // SSR markup as flat as the Flutter equivalent (Material's
    // `background` property leaks into a `Scaffold` underlay).
    //
    // `w-full` on the root mirrors Flutter's `MaterialApp` filling the
    // viewport — `CoUIWeb` is meant to be the application root, not a
    // narrow inline component, so it should claim the inline-axis of
    // whatever container it's mounted in (typically `<body>` / a flex
    // preview pane). Without `w-full`, mounting `CoUIWeb` in a flex
    // container leaves it at `flex: 0 1 auto` (shrink-to-content),
    // which makes child components like `TextField` / `Slider`
    // collapse to their intrinsic width even though they themselves
    // emit `w-full`.
    // Theme cross-fade (light/dark `data-theme` flip AND surface-preset
    // `data-coui-style` flip — both just rewrite the `--coui-*` CSS
    // variables these transition-property rules watch). When enabled, a
    // scoped `<style>` is mounted as the first root child and the root
    // carries the `.coui-theme-anim` hook so the colour transition applies
    // to the whole subtree (Flutter `CoUIApp.enableThemeAnimation` parity)
    // and the geometry transition applies to surface-marked elements.
    final animate = component.enableThemeAnimation;
    final animClass = animate ? ' coui-theme-anim' : '';
    // The `Clickable` press-shrink rule is always mounted (independent of
    // the theme cross-fade): the shrink rides `:active` but requires
    // `:hover` on hover-capable pointers so a press that drags off the
    // element releases — matching Flutter's `onTapCancel`. See
    // [_kClickablePressCss].
    final rootChildren = [
      const Component.element(
        tag: 'style',
        children: [
          RawText(
            _kClickablePressCss +
                _kAspectRatioFillCss +
                _kForcedColorsFocusCss +
                _kGlassChromeAccessibilityCss,
          ),
        ],
      ),
      if (animate)
        Component.element(
          tag: 'style',
          children: [
            RawText(_kThemeTransitionCss + _kSurfaceGeometryTransitionCss),
          ],
        ),
      subtree,
    ];

    // The root's line height is the one every piece of text below it
    // inherits, so it stays the role's multiplier rather than the
    // whole-pixel box the `text-body-medium` class draws. Text of another
    // size that states no line height of its own — an app's own markup —
    // then inherits the multiplier at its own size, as it inherits
    // Flutter's `DefaultTextStyle.height`, instead of the 14px line. The
    // kit's own text reads the same multiplier from `--coui-leading`
    // (`ThemeConfig`).
    final ambientLeading = {
      'line-height':
          'var(--coui-text-${CoreTextStyles.bodyMedium.name}-line-height)',
    };
    final wrapped = hasBackground
        ? div(
            rootChildren,
            classes: 'coui-root w-full min-h-screen$animClass $defaultClasses',
            styles: Styles(
              raw: {
                ...ambientLeading,
                'background-color': component.background!,
              },
            ),
          )
        : div(
            rootChildren,
            classes: 'coui-root w-full$animClass $defaultClasses',
            styles: Styles(raw: ambientLeading),
          );

    return Component.fragment([
      // The one place the locale resolved in [_resolveLocale] actually
      // reaches server-rendered markup — `Document.html` is supported
      // during SSR pre-rendering as well as on the client (unlike the
      // `setHtmlLangAttribute`/`setHtmlDirAttribute` DOM mutation,
      // which is a no-op server-side), so this is what a screen reader
      // or crawler sees on first paint instead of an unset `lang`/`dir`.
      Document.html(
        attributes: {
          'dir': _direction == .rtl ? 'rtl' : 'ltr',
          'lang': ?_languageTag,
          // Every `Document.html` on the page shares one `<html>`
          // reconciler (`AttachAdapter`, jaspr internals): on each
          // update it rebuilds the *whole* attribute set from every
          // currently-mounted `Document.html`'s declared attrs plus a
          // one-time startup snapshot, and removes anything on
          // `<html>` that isn't in that union. A host page that
          // manages `data-coui-style` itself (a plain script, outside
          // any Dart tree — the common pattern for a style switcher
          // that has to restore the choice before first paint, see
          // `CoreSurfaceStyleId`'s own docs) sets that attribute after
          // the snapshot was taken, so nothing in the union knows
          // about it. The next time *any* `CoUIWeb` island rebuilds —
          // one with no relation to the style switcher, e.g. a search
          // palette opening — the reconciler drops it as unaccounted
          // for. Echoing back whatever is currently on the element
          // keeps it in the union without this widget owning or
          // writing the value.
          kSurfaceStyleAttribute: ?documentAttribute(kSurfaceStyleAttribute),
          // Stated → written, so the first paint is already in that density.
          // Not stated → echoed, for the reason the style attribute above is.
          kDensityAttribute: ?(component.density == .defaultDensity
              ? documentAttribute(kDensityAttribute)
              : component.density.name),
          // The same pair for the typography tier, plus lifting a pin this
          // app wrote — see [_typographyTierAttribute].
          kTypographyTierAttribute: ?_typographyTierAttribute(),
          // Stated → written (the first paint is at that tier), not stated →
          // echoed — see [_qualityAttribute].
          kQualityAttribute: ?_qualityAttribute(),
        },
      ),
      // The page transition, stated in the document head beside the `<html>`
      // attributes above. It reads the theme this `CoUIWeb` was given.
      Theme(data: theme, child: const _PageTransitionHead()),
      CouiLocalizationsScope(
        localizations: _localizations,
        child: DensityScope(
          density: component.density == .defaultDensity
              ? DensityScope.currentDensity()
              : component.density,
          child: AdaptiveQualityScope(
            tier: CoreQualityLadder.standard.effective(
              _quality,
              reduceTransparency: _reducedTransparency,
            ),
            opensHold: _qualityFeed?.hold,
            // The browser's folds, published by a host of their own so that
            // a resize rebuilds what reads them and not this root.
            child: FoldScopeHost(
              direction: _direction,
              child: Theme(data: theme, child: wrapped),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// BCP 47 locale identifier — same role as Flutter SDK's `Locale`
/// but kept as a plain wrapper so Web doesn't pull in
/// `package:flutter/foundation.dart`. Two-arg ctor matches
/// `Locale('en', 'US')` shape so call sites stay identical.
@immutable
class Locale {
  /// Creates a locale.
  const Locale(this.languageCode, [this.countryCode]);

  /// ISO-639 language code (e.g. `'en'`, `'ko'`).
  final String languageCode;

  /// Optional ISO-3166 country / region code (e.g. `'US'`, `'KR'`).
  final String? countryCode;

  /// BCP 47 string form (`'en-US'`).
  String toLanguageTag() {
    final country = countryCode;
    if (country == null) return languageCode;
    return '$languageCode-$country';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Locale &&
            other.languageCode == languageCode &&
            other.countryCode == countryCode;
  }

  @override
  int get hashCode => Object.hash(languageCode, countryCode);

  @override
  String toString() => 'Locale(${toLanguageTag()})';
}
