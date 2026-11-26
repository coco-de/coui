/// Per-instance style for `Card`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/card/card_variant.dart';
import 'package:coui_core/src/component/contracts/card/core_card_elevation.dart';
import 'package:coui_core/src/component/contracts/card/core_card_sizing.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/clip_mode.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/surface/surface_style_id.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Card` should render.
///
/// `CoreCardStyle` is **platform-neutral** (Epic #1415 option D). Every
/// chrome / dimensional field is exposed as a nullable override so a
/// single style object can flow through the nested-merge chain:
///
/// ```text
/// design system default (this class' `static const defaultX`)
///   → theme.card.style
///   → parent component slot override
///   → widget.style
/// ```
///
/// Cards are *containers* — they have their own chrome, but they are
/// often used as panel chrome for composite components (popover panels,
/// dialog panels, picker bottom sheets …).
@immutable
class CoreCardStyle implements CoreStyle<CoreCardStyle> {
  /// Creates a [CoreCardStyle].
  const CoreCardStyle({
    this.surfaceStyle,
    this.padding,
    this.borderRadius,
    this.borderWidth,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.headerBodyGapStyle,
    this.bodyFooterGapStyle,
    this.chromeAnimationDuration,
    this.hoverShadowAnimationDuration,
    this.width,
    this.height,
    this.sizing,
    this.elevation,
    this.clipBehavior,
    this.bodyTextStyle,
    this.headerTextStyle,
    this.overlayInset,
    this.shadowBaseColor,
    this.hoverElevation,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.clickableStyle,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────
  // Variant-independent defaults live as static const on this class.
  // Variant-dependent chrome (background / border colours) is supplied
  // by [defaultsByVariant].

  /// Default content padding — 20 vertical, 24 horizontal.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space24,
    vertical: CoreSpace.space20,
  );

  /// Default header → body gap style — `CoreGapStyle(size: 8)`.
  /// Per-instance override flows through [headerBodyGapStyle] (merged
  /// on top of this default).
  static const CoreGapStyle defaultHeaderBodyGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default body → footer gap style — `CoreGapStyle(size: 12)`.
  /// Per-instance override flows through [bodyFooterGapStyle].
  static const CoreGapStyle defaultBodyFooterGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default border radius.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default border width. Variant-dependent — `outlined` keeps the
  /// stroke, `filled` uses 0.
  static const double defaultOutlinedBorderWidth = CoreStrokeWidth.stroke1;

  /// Default elevation.
  static const CoreCardElevation defaultElevation = .none;

  /// Default sizing mode.
  static const CoreCardSizing defaultSizing = .intrinsic;

  /// Default animation duration for chrome state transitions
  /// (background / border / borderRadius / padding under
  /// theme change or per-instance style swap).
  static const Duration defaultChromeAnimationDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default animation duration for the interactive hover-shadow
  /// transition (the AnimatedContainer wrapper around the surface).
  static const Duration defaultHoverShadowAnimationDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default elevation rendered when an interactive card is hovered
  /// (medium shadow — slight depth bump from the resting state).
  static const CoreCardElevation defaultHoverElevation = .medium;

  /// Default clip behaviour (resolver upgrades to anti-aliased clipping
  /// when a media slot is present).
  static const CoreClipMode defaultClipBehavior = .none;

  /// Default shadow stack (none — elevation tokens drive shadows when
  /// non-zero).
  static const List<CoreShadowLayer> defaultBoxShadow = CoreShadow.none;

  /// Default body text style — token-backed reference to the
  /// `bodyMedium` slot with the `onSurface` text colour layered on.
  /// Web emits `text-body-medium` from `token.name`; Flutter resolves
  /// the slot through `theme.coreTypography.resolve(...)` then applies
  /// the `color` overlay.
  static const CoreTextStyle defaultBodyTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default header text style — token-backed reference to the
  /// `titleMedium` slot with the `onSurface` colour. The weight is the
  /// role's own (bold), which already sets the header apart from body
  /// text, so the style states no weight of its own.
  static const CoreTextStyle defaultHeaderTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default inset (0) applied to the absolutely-positioned overlay
  /// slot inside the media wrapper.
  static const double defaultOverlayInset = CoreSpace.space0;

  /// Default shadow base colour used as the foundation of the elevation
  /// shadow stack.
  /// The shadow tint. Stated by the palette rather than chosen here — a
  /// component has no way to know whether the page it lands on is light or
  /// dark. The palette states one colour and the theme's brightness sets
  /// how strongly it is drawn (`CoreShadow.darkStrength`), so the cast
  /// reads in either.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// `Clickable` on a tappable card — a partial that pins
  /// `pressedScale: 1` (press-shrink OFF): a card is a large surface, so
  /// the scale feedback that suits small controls would visibly squash
  /// the whole panel. Interactive cards feed back through the hover
  /// shadow instead. Everything else stays null and resolves inside the
  /// Clickable's own resolver via
  /// `defaultClickableStyle.merge(merged.clickableStyle)`.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
  );

  /// Per-variant default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  static const Map<CoreCardVariant, CoreCardVariantStyle> defaultsByVariant = {
    CoreCardVariant.outlined: CoreCardVariantStyle(
      backgroundColor: CoreColor.token(
        CoreColors.surface,
        fallbacks: [CoreColors.surfaceContainerLowest],
      ),
      borderWidth: defaultOutlinedBorderWidth,
      borderColor: CoreColor.token(
        CoreColors.outlineVariant,
        fallbacks: [CoreColors.outline],
      ),
    ),
    CoreCardVariant.filled: CoreCardVariantStyle(
      backgroundColor: CoreColor.token(
        CoreColors.surfaceContainer,
        fallbacks: [CoreColors.surface],
      ),
      borderWidth: 0,
      // Explicit transparent border — a null borderColor lets Flutter's
      // `OutlinedContainer` fall back to a `surfaceContainerHigh` hairline
      // even at `borderWidth: 0`, so the filled card grew a stray border
      // on Flutter that Web (no border class) never drew.
      borderColor: .transparent,
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Material override for this card; null inherits the surrounding
  /// material.
  ///
  /// The material — translucency, backdrop blur, chroma lift, backdrop
  /// dimming, edge sheen and refraction — is a theme axis that reaches every
  /// surface at once. A value here replaces it for this card alone:
  /// [CoreSurfaceStyleId.defaultStyle] is an opaque, stroke-bounded card
  /// inside a glass theme, [CoreSurfaceStyleId.liquidGlass] a glass card
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

  /// Content padding override.
  final CoreEdgeInsets? padding;

  /// Border radius override.
  final CoreBorderRadius? borderRadius;

  /// Border width override (logical px, pre-scaling).
  final double? borderWidth;

  /// Background colour override.
  final CoreColor? backgroundColor;

  /// Border colour override.
  final CoreColor? borderColor;

  /// Box shadow override. Takes precedence over [elevation]-derived
  /// shadow when set.
  final List<CoreShadowLayer>? boxShadow;

  /// Gap between the header and body slots, passed to the `Gap` that
  /// separates them. `null` defers to [defaultHeaderBodyGapStyle].
  final CoreGapStyle? headerBodyGapStyle;

  /// Gap between the body and footer slots, passed to the `Gap` that
  /// separates them. `null` defers to [defaultBodyFooterGapStyle].
  final CoreGapStyle? bodyFooterGapStyle;

  /// Duration of the animation when the card's background, border,
  /// borderRadius or padding changes (on a theme change or a per-instance
  /// style swap). `null` defers to [defaultChromeAnimationDuration].
  final Duration? chromeAnimationDuration;

  /// Hover-shadow animation duration override (AnimatedContainer
  /// wrapping the interactive surface). `null` defers to
  /// [defaultHoverShadowAnimationDuration].
  final Duration? hoverShadowAnimationDuration;

  /// Fixed width override (logical px). Honoured when [sizing] is
  /// [CoreCardSizing.fixed].
  ///
  /// **Deliberately has no `default*` — absence is the design.** [sizing]
  /// is the axis that decides the geometry and it already has one
  /// ([defaultSizing] = `intrinsic`); this field is the operand the caller
  /// states for the `fixed` case, and only that case reads it. Null there
  /// still means "no measurement given": Flutter falls through to
  /// `IntrinsicWidth` on `width == null && height == null`, and the Web
  /// resolver writes the `width` rule only inside
  /// `if (merged.width != null)`. A constant would hand every
  /// `sizing: fixed` card a width nobody chose — a card that set only
  /// [height] would jump from auto to that number — and there is no
  /// design-system answer to "how wide is a card" to put here.
  final double? width;

  /// Fixed height override (logical px). Honoured when [sizing] is
  /// [CoreCardSizing.fixed].
  ///
  /// **Deliberately has no `default*` — same reasoning as [width]**, and
  /// it shares the branch: Flutter's fall-through to `IntrinsicWidth`
  /// tests both fields at once, so a constant on either one alone puts
  /// every `fixed` card into a `SizedBox`. A card's height is its
  /// content's, which is why the two other sizing modes never read this
  /// field at all.
  final double? height;

  /// How the card is sized: `intrinsic` (its content's size), `expand`
  /// (fills the available width) or `fixed` ([width] / [height]).
  final CoreCardSizing? sizing;

  /// Shadow elevation level (none / soft / medium / strong). When
  /// [boxShadow] is also set, [boxShadow] wins.
  final CoreCardElevation? elevation;

  /// Clip behaviour override.
  final CoreClipMode? clipBehavior;

  /// Body text style override (typography role + colour + weight in
  /// one `CoreTextStyle`). `null` defers to [defaultBodyTextStyle].
  final CoreTextStyle? bodyTextStyle;

  /// Header text style override (typography role + colour + weight).
  /// `null` defers to [defaultHeaderTextStyle].
  final CoreTextStyle? headerTextStyle;

  /// Overlay inset (logical px) — applied to the absolutely-positioned
  /// overlay slot. `null` defers to [defaultOverlayInset].
  final double? overlayInset;

  /// Shadow base colour override. `null` defers to
  /// [defaultShadowBaseColor].
  final CoreColor? shadowBaseColor;

  /// Hover elevation override (applied when an interactive card is
  /// hovered). `null` defers to [defaultHoverElevation].
  final CoreCardElevation? hoverElevation;

  /// Backdrop blur sigma (logical px) for a glassmorphism surface —
  /// forwarded to the `OutlinedContainer` surface (Flutter `SurfaceBlur` /
  /// Web `backdrop-filter: blur()`). `null`/`0` = no blur. Opt-in: the
  /// design-system default cards are opaque.
  final double? surfaceBlur;

  /// Surface fill opacity (0.0–1.0) for a glassmorphism surface — lets the
  /// blurred backdrop show through the fill. `null` = fully opaque fill.
  ///
  /// **Deliberately has no `default*` — the baseline is a theme axis, and
  /// a `static const` is downstream of it.** The card raw-forwards this
  /// into the composed `OutlinedContainer`, whose resolver reads
  /// `merged.surfaceOpacity ?? theme.surfaceOpacity`: a constant here
  /// would always be non-null, so it would shadow the theme-wide surface
  /// treatment for cards specifically and put the value beyond the axis's
  /// reach — which `core/theme-axis-composition.md` forbids, since the
  /// axis's seat is token resolution and this class sits after it.
  ///
  /// The Web half additionally keys its emit on the null: it scales the
  /// background token's alpha only when this is set, and the resolver says
  /// why — an absent override has to stay null so `emitColor` still reads
  /// "no override" and leaves the background on its Tailwind token class
  /// rather than manufacturing an inline `rgb(… / a)` for every card.
  final double? surfaceOpacity;

  /// Style for the `Clickable` of a tappable card (`onTap != null`) —
  /// press scale, durations, focus ring, disabled opacity. Laid over
  /// [defaultClickableStyle] (which pins `pressedScale: 1`) and passed to
  /// the `Clickable` as is; it fills the unset fields with its own
  /// defaults.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreCardStyle merge(CoreCardStyle? other) {
    if (other == null) return this;
    return CoreCardStyle(
      surfaceStyle: other.surfaceStyle ?? surfaceStyle,
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      boxShadow: other.boxShadow ?? boxShadow,
      headerBodyGapStyle: _mergeGapStyle(
        headerBodyGapStyle,
        other.headerBodyGapStyle,
      ),
      bodyFooterGapStyle: _mergeGapStyle(
        bodyFooterGapStyle,
        other.bodyFooterGapStyle,
      ),
      chromeAnimationDuration:
          other.chromeAnimationDuration ?? chromeAnimationDuration,
      hoverShadowAnimationDuration:
          other.hoverShadowAnimationDuration ?? hoverShadowAnimationDuration,
      width: other.width ?? width,
      height: other.height ?? height,
      sizing: other.sizing ?? sizing,
      elevation: other.elevation ?? elevation,
      clipBehavior: other.clipBehavior ?? clipBehavior,
      bodyTextStyle: _mergeTextStyle(bodyTextStyle, other.bodyTextStyle),
      headerTextStyle: _mergeTextStyle(headerTextStyle, other.headerTextStyle),
      overlayInset: other.overlayInset ?? overlayInset,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
      hoverElevation: other.hoverElevation ?? hoverElevation,
      surfaceBlur: other.surfaceBlur ?? surfaceBlur,
      surfaceOpacity: other.surfaceOpacity ?? surfaceOpacity,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreCardStyle copyWith({
    CoreSurfaceStyleId? surfaceStyle,
    CoreEdgeInsets? padding,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    List<CoreShadowLayer>? boxShadow,
    CoreGapStyle? headerBodyGapStyle,
    CoreGapStyle? bodyFooterGapStyle,
    Duration? chromeAnimationDuration,
    Duration? hoverShadowAnimationDuration,
    double? width,
    double? height,
    CoreCardSizing? sizing,
    CoreCardElevation? elevation,
    CoreClipMode? clipBehavior,
    CoreTextStyle? bodyTextStyle,
    CoreTextStyle? headerTextStyle,
    double? overlayInset,
    CoreColor? shadowBaseColor,
    CoreCardElevation? hoverElevation,
    double? surfaceBlur,
    double? surfaceOpacity,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreCardStyle(
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      boxShadow: boxShadow ?? this.boxShadow,
      headerBodyGapStyle: headerBodyGapStyle ?? this.headerBodyGapStyle,
      bodyFooterGapStyle: bodyFooterGapStyle ?? this.bodyFooterGapStyle,
      chromeAnimationDuration:
          chromeAnimationDuration ?? this.chromeAnimationDuration,
      hoverShadowAnimationDuration:
          hoverShadowAnimationDuration ?? this.hoverShadowAnimationDuration,
      width: width ?? this.width,
      height: height ?? this.height,
      sizing: sizing ?? this.sizing,
      elevation: elevation ?? this.elevation,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      overlayInset: overlayInset ?? this.overlayInset,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
      hoverElevation: hoverElevation ?? this.hoverElevation,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCardStyle &&
          runtimeType == other.runtimeType &&
          surfaceStyle == other.surfaceStyle &&
          padding == other.padding &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          _listEq(boxShadow, other.boxShadow) &&
          headerBodyGapStyle == other.headerBodyGapStyle &&
          bodyFooterGapStyle == other.bodyFooterGapStyle &&
          chromeAnimationDuration == other.chromeAnimationDuration &&
          hoverShadowAnimationDuration == other.hoverShadowAnimationDuration &&
          width == other.width &&
          height == other.height &&
          sizing == other.sizing &&
          elevation == other.elevation &&
          clipBehavior == other.clipBehavior &&
          bodyTextStyle == other.bodyTextStyle &&
          headerTextStyle == other.headerTextStyle &&
          overlayInset == other.overlayInset &&
          shadowBaseColor == other.shadowBaseColor &&
          hoverElevation == other.hoverElevation &&
          surfaceBlur == other.surfaceBlur &&
          surfaceOpacity == other.surfaceOpacity &&
          clickableStyle == other.clickableStyle;

  static CoreTextStyle? _mergeTextStyle(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGapStyle(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static bool _listEq<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    surfaceStyle,
    padding,
    borderRadius,
    borderWidth,
    backgroundColor,
    borderColor,
    if (boxShadow != null) Object.hashAll(boxShadow!),
    headerBodyGapStyle,
    bodyFooterGapStyle,
    chromeAnimationDuration,
    hoverShadowAnimationDuration,
    width,
    height,
    sizing,
    elevation,
    clipBehavior,
    bodyTextStyle,
    headerTextStyle,
    overlayInset,
    shadowBaseColor,
    hoverElevation,
    surfaceBlur,
    surfaceOpacity,
    clickableStyle,
  ]);
}

/// Visual style definition for a [CoreCardVariant].
///
/// Carries the variant-dependent chrome (background / border /
/// border-width). All values are platform-neutral ([CoreColor] /
/// `double`); the consuming renderer converts at use-site.
@immutable
class CoreCardVariantStyle {
  /// Creates a card variant style.
  const CoreCardVariantStyle({
    required this.backgroundColor,
    required this.borderWidth,
    this.borderColor,
  });

  /// Background colour.
  final CoreColor backgroundColor;

  /// Border colour. `null` for variants without a visible border.
  final CoreColor? borderColor;

  /// Border width (logical px, pre-scaling).
  final double borderWidth;
}
