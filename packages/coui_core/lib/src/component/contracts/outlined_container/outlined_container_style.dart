/// Per-instance style for `OutlinedContainer`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/frame/core_gradient.dart';
import 'package:coui_core/src/component/contracts/outlined_container/core_outlined_container_border_style.dart';
import 'package:coui_core/src/component/contracts/outlined_container/core_outlined_container_elevation.dart';
import 'package:coui_core/src/component/contracts/stacks/core_clip_behavior.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/dashed_border.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/surface/surface_style_id.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `OutlinedContainer` should render.
///
/// `CoreOutlinedContainerStyle` exposes every chrome / dimensional field
/// as a nullable override so a single style object can flow through the
/// nested-merge chain (Epic #1302):
///
/// ```text
/// design system default
///   → theme.outlinedContainer.style
///   → parent component slot override
///       (e.g. CoreCardStyle delegates panel chrome through this slot
///        when the higher-level component embeds an outlined-container
///        primitive)
///   → widget.containerStyle
/// ```
///
/// `OutlinedContainer` is the infrastructure primitive that powers
/// many higher-level components (`Card`, `CardImage`, `Window`,
/// `Alert`, picker panels …). Composite styles therefore nest a
/// `CoreOutlinedContainerStyle?` slot when they need to delegate chrome
/// rather than re-declaring `bg / border / radius` flat fields.
@immutable
class CoreOutlinedContainerStyle
    implements CoreStyle<CoreOutlinedContainerStyle> {
  /// Creates a [CoreOutlinedContainerStyle].
  const CoreOutlinedContainerStyle({
    this.surfaceStyle,
    this.backgroundColor,
    this.backgroundGradient,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.preserveTransparentBorder,
    this.borderStyle,
    this.dashLength,
    this.dashSpacing,
    this.elevation,
    this.boxShadow,
    this.shadowBaseColor,
    this.shadowStrengthens,
    this.padding,
    this.surfaceOpacity,
    this.surfaceBlur,
    this.width,
    this.height,
    this.duration,
    this.clipBehavior,
  });

  /// Material override for this surface; null inherits the surrounding
  /// material.
  ///
  /// The material — translucency, backdrop blur, chroma lift, backdrop
  /// dimming, edge sheen and refraction — is a theme axis that reaches every
  /// surface at once. A value here replaces it for this instance alone:
  /// [CoreSurfaceStyleId.defaultStyle] is an opaque, stroke-bounded face
  /// inside a glass theme, [CoreSurfaceStyleId.liquidGlass] a glass face
  /// inside an opaque one. Palette, typography, geometry and density stay the
  /// surrounding theme's.
  ///
  /// [surfaceOpacity] and [surfaceBlur] tune the fill and the blur within
  /// whichever material applies. They cannot remove one, because neither
  /// reaches the sheen, the chroma lift or the backdrop dimming.
  ///
  /// Deliberately no default: null inherits the active theme material axis;
  /// a fixed default would override that axis before the resolver sees it.
  final CoreSurfaceStyleId? surfaceStyle;

  /// Background fill colour override.
  final CoreColor? backgroundColor;

  /// Background gradient fill override — painted instead of
  /// [backgroundColor] when set. The border and the shadow are unaffected;
  /// [surfaceOpacity] scales every stop's alpha.
  ///
  /// **No default — absence is the design.** Null means a solid
  /// [backgroundColor] fill, which both platforms branch on; a constant here
  /// would turn every surface built on this primitive into a gradient.
  final CoreGradient? backgroundGradient;

  /// Border colour override.
  final CoreColor? borderColor;

  /// Border radius override.
  final CoreBorderRadius? borderRadius;

  /// Border width override (logical px, pre-scaling).
  final double? borderWidth;

  /// Whether a fully transparent border still reserves its stated width.
  ///
  /// The default collapses an invisible border. Set this when another state
  /// paints a border and its layout must not move during the transition.
  /// For dashed and dotted borders, opting in also reserves the width when
  /// the color is visible. A `none` border ignores this option.
  final bool? preserveTransparentBorder;

  /// Border style override (solid / dashed / dotted / none).
  final CoreOutlinedContainerBorderStyle? borderStyle;

  /// Dash segment length when [borderStyle] is dashed (logical px).
  /// `null` → [defaultDashLength].
  final double? dashLength;

  /// Gap between dash segments (logical px). `null` → [defaultDashSpacing].
  final double? dashSpacing;

  /// Shadow elevation override. When [boxShadow] is also set,
  /// [boxShadow] wins.
  final CoreOutlinedContainerElevation? elevation;

  /// Explicit shadow stack, overriding the [elevation]-derived one.
  ///
  /// The elevation enum can only name three prepared stacks, all of them
  /// soft ambient shadows. Some surface treatments are defined by shadows
  /// it cannot describe at all: a hard offset shadow has zero blur, and a
  /// raised-from-the-page look needs two layers going in opposite
  /// directions. This slot takes the stack directly so those are
  /// expressible without inventing a new enum member per look.
  final List<CoreShadowLayer>? boxShadow;

  /// Shadow base colour override — the tint every layer of the shadow stack
  /// is drawn in, each layer's own opacity scaling its alpha. `null` defers
  /// to [defaultShadowBaseColor].
  ///
  /// A token follows the active scheme. A raw colour pins the cast: it is the
  /// same in every mode, which is what a surface that stands for a physical
  /// object wants. On Web the pinned cast is written as the stack's literal
  /// layers instead of through the `--shadow-*` variables a surface style
  /// bends, so a style's shadow geometry reaches it on Flutter only.
  final CoreColor? shadowBaseColor;

  /// Whether a dark theme strengthens the stack this style states — the
  /// [boxShadow] or the [elevation] preset — by `CoreShadow.darkStrength`
  /// (capped at 1). `null` defers to [defaultShadowStrengthens].
  ///
  /// `false` pins the stack's alpha at what each layer states, in every
  /// brightness: the cast is drawn the same on a light page and a dark one.
  /// That is for a surface that stands for a physical object photographed
  /// under one light (`MockupDevice`), not for a panel lifted off the page,
  /// whose cast has to read on a dark face too. The geometry a surface style
  /// bends is untouched — only the brightness's multiplier is left out. A
  /// cast the surface style contributes to a surface that states none
  /// (`controlShadow`) is the style's, not this stack, and keeps it.
  final bool? shadowStrengthens;

  /// Inner padding override. Falls back to [defaultPadding] when null.
  final CoreEdgeInsets? padding;

  /// Background opacity multiplier (0.0 – 1.0). Multiplied into the
  /// alpha channel of [backgroundColor].
  final double? surfaceOpacity;

  /// Backdrop blur sigma (logical px). When > 0, applies a
  /// `BackdropFilter` (Flutter) / `backdrop-filter: blur()` (Web).
  final double? surfaceBlur;

  /// Explicit width override (logical px).
  ///
  /// **No default, and must not have one.** Null is not "width unknown",
  /// it is "size to the child" — both platforms branch on it rather than
  /// reading a value. Flutter hands the null straight to the container's
  /// `width:`, where it means unconstrained; Web only writes the
  /// `width` declaration inside `if (width != null)`. A constant here
  /// would pin every surface built on this primitive — `Card`, `Alert`,
  /// `Window`, every picker panel — to one width, and nothing in the
  /// tree asks for that.
  final double? width;

  /// Explicit height override (logical px).
  ///
  /// **No default, and must not have one** — same branch as [width], on
  /// the block axis.
  final double? height;

  /// How long changes to the container's look (color / radius / width /
  /// height) animate. `null` or [Duration.zero] means no animation.
  final Duration? duration;

  /// Clip behaviour override.
  final CoreClipBehavior? clipBehavior;

  // ── Design-system defaults ──────────────────────────────────────
  // Variant-independent chrome / behaviour defaults live as static
  // const on this class so Flutter / Web resolvers share a single
  // source of truth (no file-local `_kDefault*` token consts).

  /// Default background fill — M3 `surface` token. Single source of
  /// truth for both platforms (Flutter `scheme.resolve(...).toValue()`,
  /// Web `emitColor(...)` token class). Routes every default-colour read
  /// through this field so neither resolver references `cs.surface`
  /// directly (1:1:1:1:1:1 single source).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default border colour — M3 `outline-variant` token. Single source
  /// of truth for both platforms (same routing as
  /// [defaultBackgroundColor]).
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default border width (1 logical px before scaling).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Invisible borders do not occupy layout unless explicitly requested.
  static const bool defaultPreserveTransparentBorder = false;

  /// Default dash segment length — the shared [CoreDashedBorder]
  /// baseline, rendered identically by the Flutter dash painter and the
  /// Web SVG `stroke-dasharray` overlay.
  static const double defaultDashLength = CoreDashedBorder.dashLength;

  /// Default gap between dash segments — see [defaultDashLength].
  static const double defaultDashSpacing = CoreDashedBorder.dashGap;

  /// Default border radius (16 logical px before scaling).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default border style.
  static const CoreOutlinedContainerBorderStyle defaultBorderStyle = .solid;

  /// Default shadow elevation.
  static const CoreOutlinedContainerElevation defaultElevation = .none;

  /// Default explicit shadow stack — none, so [elevation] decides.
  static const List<CoreShadowLayer> defaultBoxShadow = CoreShadow.none;

  /// Default shadow base colour — the palette's `shadow` token. Stated by the
  /// palette rather than chosen here: a surface has no way to know whether
  /// the page it lands on is light or dark, and the theme's brightness sets
  /// how strongly the palette's colour is drawn, so the cast reads in either.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default for [shadowStrengthens] — a dark theme strengthens the cast,
  /// as it does every cast on the page.
  static const bool defaultShadowStrengthens = true;

  /// Default inner padding — none. The primitive draws a box, not a
  /// spacing scheme: every composing component (`Card`, `Alert`, picker
  /// panels …) states its own padding through this slot, so a non-zero
  /// baseline here would inset all of them at once.
  ///
  /// The two platforms express zero differently and that is deliberate.
  /// Flutter reads this constant (`Container(padding:)` takes a value,
  /// and zero is that value). Web emits no `padding` declaration at all
  /// when the slot is unset — `padding` has a CSS initial value of 0 and
  /// the preflight reset restates it, so an inline `padding: 0rem` would
  /// be the same pixels plus a declaration that outranks anything a
  /// caller's class could say.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.zero;

  /// Default chrome transition duration — [Duration.zero], meaning chrome
  /// changes land immediately with no animation.
  static const Duration defaultDuration = Duration.zero;

  /// Default clip behaviour.
  static const CoreClipBehavior defaultClipBehavior = .antiAlias;

  // ── Elevation shadow stacks (designer `CoreShadow` scale) ───────
  // The elevation enum maps to these `CoreShadowLayer` lists when a
  // platform materialises a shadow. They alias the designer semantic
  // scale (`CoreShadow.sm/md/lg`) — the same tokens the Web
  // `shadow-{sm|md|lg}` utility classes resolve to via the
  // `--shadow-*` CSS variables — so Flutter `BoxShadow` and Web
  // `shadow-*` paint the identical stack. Flutter's
  // `CoreOutlinedContainerElevationShadow.toValue` reads these; Web
  // reads the equivalent `tailwindShadowClass`.
  //
  // Shadow chrome flows as a whole [CoreShadowLayer] list. Per-axis
  // scalars (offsetY / blur / spread) are forbidden — consumers that
  // need a single axis must read the layer record component
  // (e.g. `defaultMediumShadow[0].blurRadius`).

  /// `shadow-sm` elevation stack — [CoreShadow.sm].
  /// Drives [CoreOutlinedContainerElevation.soft].
  static const List<CoreShadowLayer> defaultSoftShadow = CoreShadow.sm;

  /// `shadow-md` elevation stack — [CoreShadow.md].
  /// Drives [CoreOutlinedContainerElevation.medium].
  static const List<CoreShadowLayer> defaultMediumShadow = CoreShadow.md;

  /// `shadow-lg` elevation stack — [CoreShadow.lg].
  /// Drives [CoreOutlinedContainerElevation.strong].
  static const List<CoreShadowLayer> defaultStrongShadow = CoreShadow.lg;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreOutlinedContainerStyle merge(CoreOutlinedContainerStyle? other) {
    if (other == null) return this;
    return CoreOutlinedContainerStyle(
      surfaceStyle: other.surfaceStyle ?? surfaceStyle,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      preserveTransparentBorder:
          other.preserveTransparentBorder ?? preserveTransparentBorder,
      borderStyle: other.borderStyle ?? borderStyle,
      dashLength: other.dashLength ?? dashLength,
      dashSpacing: other.dashSpacing ?? dashSpacing,
      elevation: other.elevation ?? elevation,
      boxShadow: other.boxShadow ?? boxShadow,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
      shadowStrengthens: other.shadowStrengthens ?? shadowStrengthens,
      padding: other.padding ?? padding,
      surfaceOpacity: other.surfaceOpacity ?? surfaceOpacity,
      surfaceBlur: other.surfaceBlur ?? surfaceBlur,
      width: other.width ?? width,
      height: other.height ?? height,
      duration: other.duration ?? duration,
      clipBehavior: other.clipBehavior ?? clipBehavior,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreOutlinedContainerStyle copyWith({
    CoreSurfaceStyleId? surfaceStyle,
    CoreColor? backgroundColor,
    CoreGradient? backgroundGradient,
    CoreColor? borderColor,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    bool? preserveTransparentBorder,
    CoreOutlinedContainerBorderStyle? borderStyle,
    double? dashLength,
    double? dashSpacing,
    CoreOutlinedContainerElevation? elevation,
    List<CoreShadowLayer>? boxShadow,
    CoreColor? shadowBaseColor,
    bool? shadowStrengthens,
    CoreEdgeInsets? padding,
    double? surfaceOpacity,
    double? surfaceBlur,
    double? width,
    double? height,
    Duration? duration,
    CoreClipBehavior? clipBehavior,
  }) {
    return CoreOutlinedContainerStyle(
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      preserveTransparentBorder:
          preserveTransparentBorder ?? this.preserveTransparentBorder,
      borderStyle: borderStyle ?? this.borderStyle,
      dashLength: dashLength ?? this.dashLength,
      dashSpacing: dashSpacing ?? this.dashSpacing,
      elevation: elevation ?? this.elevation,
      boxShadow: boxShadow ?? this.boxShadow,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
      shadowStrengthens: shadowStrengthens ?? this.shadowStrengthens,
      padding: padding ?? this.padding,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      clipBehavior: clipBehavior ?? this.clipBehavior,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreOutlinedContainerStyle &&
          runtimeType == other.runtimeType &&
          surfaceStyle == other.surfaceStyle &&
          backgroundColor == other.backgroundColor &&
          backgroundGradient == other.backgroundGradient &&
          borderColor == other.borderColor &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          preserveTransparentBorder == other.preserveTransparentBorder &&
          dashLength == other.dashLength &&
          dashSpacing == other.dashSpacing &&
          borderStyle == other.borderStyle &&
          elevation == other.elevation &&
          _listEq(boxShadow, other.boxShadow) &&
          shadowBaseColor == other.shadowBaseColor &&
          shadowStrengthens == other.shadowStrengthens &&
          padding == other.padding &&
          surfaceOpacity == other.surfaceOpacity &&
          surfaceBlur == other.surfaceBlur &&
          width == other.width &&
          height == other.height &&
          duration == other.duration &&
          clipBehavior == other.clipBehavior;

  @override
  int get hashCode => Object.hashAll([
    surfaceStyle,
    backgroundColor,
    backgroundGradient,
    borderColor,
    borderRadius,
    borderWidth,
    preserveTransparentBorder,
    borderStyle,
    dashLength,
    dashSpacing,
    elevation,
    if (boxShadow != null) Object.hashAll(boxShadow!),
    shadowBaseColor,
    shadowStrengthens,
    padding,
    surfaceOpacity,
    surfaceBlur,
    width,
    height,
    duration,
    clipBehavior,
  ]);

  /// Element-wise list comparison.
  ///
  /// A shadow stack is a list, and Dart list equality is identity, so
  /// without this two structurally identical stacks compare unequal and
  /// every rebuild looks like a change.
  static bool _listEq<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}
