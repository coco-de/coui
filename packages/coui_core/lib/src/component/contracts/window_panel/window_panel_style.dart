/// Per-instance style for `WindowPanel`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing chrome / dimensional overrides for a
/// `WindowPanel`.
///
/// `CoreWindowPanelStyle` is the single chrome slot for the window
/// panel — the outer frame radius, the title bar background colour and
/// every dimensional token (title bar height / paddings / control
/// button size / control spacing) flow through here.
///
/// Resolve chain per Epic #1302:
///
/// ```text
/// design system default (CoreWindowPanelStyle.defaultX)
///   → CoreWindowPanelTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget.windowPanelStyle                         // 인스턴스별
/// ```
///
/// Behavioural slots (`onClose` / `onTitleBarDragStart` / …) and the
/// boolean toggles (`closable` / `minimizable` / `maximizable` /
/// `isMinimized`) stay on the widget / contract — only chrome /
/// dimensional overrides belong here (Epic #1302 원칙 6/7).
@immutable
class CoreWindowPanelStyle implements CoreStyle<CoreWindowPanelStyle> {
  /// Creates a [CoreWindowPanelStyle].
  const CoreWindowPanelStyle({
    this.borderRadius,
    this.titleBarColor,
    this.titleBarHeight,
    this.titleBarPadding,
    this.contentPadding,
    this.controlSpacing,
    this.containerBorderWidth,
    this.shadowColor,
    this.shadow,
    this.surfaceColor,
    this.borderColor,
    this.titleStyle,
    this.contentStyle,
    this.controlButtonStyle,
    this.closeButtonStyle,
    this.controlIconStyle,
  });

  // ── Design-system defaults (Phase 6f/6g, variant-independent) ──

  /// Default outer window frame corner radius (single-axis token —
  /// the four [defaultBorderRadius] corners derive from this value).
  ///
  /// Exposed as a raw `double` (not wrapped in `CoreBorderRadius`) so
  /// callers that need the scalar — e.g. computing the inner radius =
  /// outer − border width on the Web title bar — can subtract directly
  /// in a `const` expression.
  static const double defaultOuterRadius = CoreRadiusRole.panel;

  /// Default outer window frame corner radius (4-corner). Derives from
  /// [defaultOuterRadius] so both forms share a single source of truth.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    defaultOuterRadius,
  );

  /// Default title bar background colour token.
  static const CoreColor defaultTitleBarColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default title bar height in logical/CSS px (pre-scaling).
  static const double defaultTitleBarHeight = CoreSpace.space32;

  /// Default padding inside the title bar (pre-scaling). Defaults to
  /// horizontal-only padding so the title row's vertical metric stays
  /// driven by `titleBarHeight`.
  static const CoreEdgeInsets defaultTitleBarPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
  );

  /// Default content area padding (pre-scaling) — `CoreSpace.space12`
  /// on all four sides. Resolvers fall back to this constant when
  /// neither the widget nor theme supplies a [contentPadding].
  static const CoreEdgeInsets defaultContentPadding = CoreEdgeInsets.all(
    CoreSpace.space12,
  );

  /// Default spacing between adjacent control buttons (pre-scaling).
  ///
  /// Consumed natively by `Row(spacing: …)` on Flutter and CSS `gap`
  /// on Web so the N control buttons sit on a single flex strip with
  /// equal inter-sibling spacing.
  static const double defaultControlSpacing = CoreSpace.space4;

  /// Default container border width (logical/CSS px). Used by the
  /// inner-radius calculation so the title bar background stops cleanly
  /// inside the outer border instead of painting over it.
  static const double defaultContainerBorderWidth = 1;

  /// Default ambient drop-shadow base colour — the `shadow` token at full
  /// strength (black in both light and dark schemes). The layer alpha comes
  /// from [defaultShadow], so the step's own strength — and the darker
  /// scheme's boost — apply; recolouring the token retints the whole
  /// silhouette on both platforms. Flutter consumes it through
  /// `scheme.resolve(...).toValue()`, Web through `.toValue()`.
  static const CoreColor defaultShadowColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default frame drop-shadow — the `md` step of the shadow scale
  /// ([CoreShadow.md]), the same layers the canvas's `shadow/md` effect
  /// style states, so the Flutter `BoxShadow` and the Web `box-shadow` paint
  /// the same silhouette from this single source.
  static const List<CoreShadowLayer> defaultShadow = CoreShadow.md;

  /// Default outer window frame background colour token.
  static const CoreColor defaultSurfaceColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default border colour token for the outer frame border. The title bar
  /// draws no divider of its own — its fill sets it apart from the content.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default title text typography — `labelLarge` role with the
  /// `onSurface` colour token and `medium` font weight overlay.
  static final CoreTextStyle defaultTitleStyle = const CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurface),
  ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Default content area typography — `bodyMedium` role with the
  /// `onSurface` colour token.
  static const CoreTextStyle defaultContentStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default chrome for the non-close control buttons (minimize /
  /// maximize) — a partial `CoreButtonStyle` raw-forwarded into the
  /// unified `Button(variant: .plain)` (child-component-composition):
  /// square 20px hit box, no padding, field radius, surface-variant
  /// idle glyph that sharpens to on-surface over a container-high
  /// hover wash.
  static const CoreButtonStyle defaultControlButtonStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    hoverBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    hoverForegroundColor: CoreColor.token(CoreColors.onSurface),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    height: CoreSpace.space20,
    width: CoreSpace.space20,
    padding: .zero,
    animationDuration: Duration(milliseconds: CoreDuration.fast),
  );

  /// Default chrome for the close control button — same box and idle glyph
  /// as [defaultControlButtonStyle] (surface-variant), with the error-token
  /// emphasis kept for hover only (error hover wash, on-error hover glyph).
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    hoverBackgroundColor: CoreColor.token(CoreColors.error),
    hoverForegroundColor: CoreColor.token(CoreColors.onError),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    height: CoreSpace.space20,
    width: CoreSpace.space20,
    padding: .zero,
    animationDuration: Duration(milliseconds: CoreDuration.fast),
  );

  /// Default control button icon geometry — 12px Lucide vector inside
  /// the 20px button box (colour is deliberately absent: the glyph
  /// inherits the button's per-state foreground).
  static const CoreIconStyle defaultControlIconStyle = CoreIconStyle(
    size: CoreIconSize.size12,
  );

  /// Corner radius applied to the outer window frame.
  final CoreBorderRadius? borderRadius;

  /// Custom title bar background colour.
  final CoreColor? titleBarColor;

  /// Custom title bar height (pre-scaling).
  final double? titleBarHeight;

  /// Custom padding inside the title bar (pre-scaling).
  final CoreEdgeInsets? titleBarPadding;

  /// Custom content area padding (pre-scaling).
  final CoreEdgeInsets? contentPadding;

  /// Custom spacing between adjacent control buttons (pre-scaling).
  ///
  /// Consumed natively by `Row(spacing: …)` on Flutter and CSS `gap`
  /// on Web so the N control buttons sit on a single flex strip with
  /// equal inter-sibling spacing.
  final double? controlSpacing;

  /// Custom container border width (logical/CSS px) — drives both the
  /// outer frame border and the inner title-bar radius shrink.
  final double? containerBorderWidth;

  /// Custom base colour of the drop shadow (e.g. a tinted shadow).
  final CoreColor? shadowColor;

  /// Custom frame drop-shadow layer geometry (tinted by [shadowColor]).
  final List<CoreShadowLayer>? shadow;

  /// Custom outer window frame background colour.
  final CoreColor? surfaceColor;

  /// Custom border colour for the outer frame.
  final CoreColor? borderColor;

  /// Custom title text typography (role + colour + weight overlay).
  final CoreTextStyle? titleStyle;

  /// Custom content area typography (role + colour).
  final CoreTextStyle? contentStyle;

  /// Custom look for the non-close control buttons (minimize /
  /// maximize) — a `Button` style, passed to the `Button` as is so the
  /// button sets its own final look.
  final CoreButtonStyle? controlButtonStyle;

  /// Custom look for the close control button — a `Button` style.
  final CoreButtonStyle? closeButtonStyle;

  /// Custom control button icon size (colour follows the button's
  /// per-state foreground) — an `Icon` style.
  final CoreIconStyle? controlIconStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreWindowPanelStyle merge(CoreWindowPanelStyle? other) {
    if (other == null) return this;
    return CoreWindowPanelStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      titleBarColor: other.titleBarColor ?? titleBarColor,
      titleBarHeight: other.titleBarHeight ?? titleBarHeight,
      titleBarPadding: other.titleBarPadding ?? titleBarPadding,
      contentPadding: other.contentPadding ?? contentPadding,
      controlSpacing: other.controlSpacing ?? controlSpacing,
      containerBorderWidth: other.containerBorderWidth ?? containerBorderWidth,
      shadowColor: other.shadowColor ?? shadowColor,
      shadow: other.shadow ?? shadow,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      borderColor: other.borderColor ?? borderColor,
      titleStyle: _mergeText(titleStyle, other.titleStyle),
      contentStyle: _mergeText(contentStyle, other.contentStyle),
      controlButtonStyle:
          controlButtonStyle?.merge(other.controlButtonStyle) ??
          other.controlButtonStyle,
      closeButtonStyle:
          closeButtonStyle?.merge(other.closeButtonStyle) ??
          other.closeButtonStyle,
      controlIconStyle:
          controlIconStyle?.merge(other.controlIconStyle) ??
          other.controlIconStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreWindowPanelStyle copyWith({
    CoreBorderRadius? borderRadius,
    CoreColor? titleBarColor,
    double? titleBarHeight,
    CoreEdgeInsets? titleBarPadding,
    CoreEdgeInsets? contentPadding,
    double? controlSpacing,
    double? containerBorderWidth,
    CoreColor? shadowColor,
    List<CoreShadowLayer>? shadow,
    CoreColor? surfaceColor,
    CoreColor? borderColor,
    CoreTextStyle? titleStyle,
    CoreTextStyle? contentStyle,
    CoreButtonStyle? controlButtonStyle,
    CoreButtonStyle? closeButtonStyle,
    CoreIconStyle? controlIconStyle,
  }) {
    return CoreWindowPanelStyle(
      borderRadius: borderRadius ?? this.borderRadius,
      titleBarColor: titleBarColor ?? this.titleBarColor,
      titleBarHeight: titleBarHeight ?? this.titleBarHeight,
      titleBarPadding: titleBarPadding ?? this.titleBarPadding,
      contentPadding: contentPadding ?? this.contentPadding,
      controlSpacing: controlSpacing ?? this.controlSpacing,
      containerBorderWidth: containerBorderWidth ?? this.containerBorderWidth,
      shadowColor: shadowColor ?? this.shadowColor,
      shadow: shadow ?? this.shadow,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      borderColor: borderColor ?? this.borderColor,
      titleStyle: titleStyle ?? this.titleStyle,
      contentStyle: contentStyle ?? this.contentStyle,
      controlButtonStyle: controlButtonStyle ?? this.controlButtonStyle,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
      controlIconStyle: controlIconStyle ?? this.controlIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreWindowPanelStyle &&
          runtimeType == other.runtimeType &&
          borderRadius == other.borderRadius &&
          titleBarColor == other.titleBarColor &&
          titleBarHeight == other.titleBarHeight &&
          titleBarPadding == other.titleBarPadding &&
          contentPadding == other.contentPadding &&
          controlSpacing == other.controlSpacing &&
          containerBorderWidth == other.containerBorderWidth &&
          shadowColor == other.shadowColor &&
          _shadowEquals(shadow, other.shadow) &&
          surfaceColor == other.surfaceColor &&
          borderColor == other.borderColor &&
          titleStyle == other.titleStyle &&
          contentStyle == other.contentStyle &&
          controlButtonStyle == other.controlButtonStyle &&
          closeButtonStyle == other.closeButtonStyle &&
          controlIconStyle == other.controlIconStyle;

  @override
  int get hashCode => Object.hashAll([
    borderRadius,
    titleBarColor,
    titleBarHeight,
    titleBarPadding,
    contentPadding,
    controlSpacing,
    containerBorderWidth,
    shadowColor,
    Object.hashAll(shadow ?? const <CoreShadowLayer>[]),
    surfaceColor,
    borderColor,
    titleStyle,
    contentStyle,
    controlButtonStyle,
    closeButtonStyle,
    controlIconStyle,
  ]);

  /// Recursively merges two nested [CoreTextStyle] slots so a caller that
  /// overrides only one sub-field (e.g. colour) keeps the rest of the
  /// base style.
  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  /// Element-wise equality for the shadow layer list (records compare by
  /// value, lists by identity — so `==` alone would miss equal layers).
  static bool _shadowEquals(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
