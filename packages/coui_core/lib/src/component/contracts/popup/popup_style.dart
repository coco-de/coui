/// Per-instance style for `Popup`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/surface/surface_style_id.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Popup` floating panel renders.
///
/// Carries the panel chrome — padding, corner radius, border, fill
/// colour, elevation shadow and minimum width. Platform-neutral
/// (Epic #1415 option D) — colour fields use [CoreColor]; dimensional
/// fields use the shared [CoreEdgeInsets] / [CoreBorderRadius] domain
/// types.
///
/// All design-system defaults live here as `static const` fields so
/// the Flutter and Web resolvers share a single source of truth.
@immutable
class CorePopupStyle implements CoreStyle<CorePopupStyle> {
  /// Creates a [CorePopupStyle].
  const CorePopupStyle({
    this.surfaceStyle,
    this.padding,
    this.borderRadius,
    this.borderWidth,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.shadowBaseColor,
    this.minWidth,
    this.maxWidth,
    this.spacing,
    this.contentColor,
    this.openAnimationDuration,
    this.closeAnimationDuration,
  });

  /// Material override for this surface; `null` inherits the surrounding
  /// material.
  ///
  /// Deliberately no default: null inherits the active theme material axis;
  /// a fixed default would override that axis before the resolver sees it.
  final CoreSurfaceStyleId? surfaceStyle;

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Padding of a panel that holds a list of rows (a menu, a picker, a
  /// select) — 6, so the rows sit concentrically inside the panel radius
  /// (12 = 6 + 6). The component that holds the list passes it; the popup
  /// does not assume a list.
  static const CoreEdgeInsets defaultListPadding = CoreEdgeInsets.all(
    CoreSpace.space6,
  );

  /// Padding of a panel that holds free-form content (a form, a card, a
  /// calendar) — 16.
  static const CoreEdgeInsets defaultContentPadding = CoreEdgeInsets.all(
    CoreSpace.space16,
  );

  /// Default internal padding of the popup panel — the content preset, since
  /// a popup that holds arbitrary content does not know it holds a list.
  /// Components that hold a list state [defaultListPadding].
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space16,
  );

  /// Default corner radius of the popup panel — the panel role (12): a
  /// face that floats over the screen to hold a list or a choice. With the
  /// 6 padding it holds rows of 6 concentrically (12 = 6 + 6).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.panel,
  );

  /// Default border width of the popup panel (logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default background colour of the popup panel — the raised floating
  /// face (`surfaceBright`).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Default border colour of the popup panel — the panel line
  /// (`outlineVariant`).
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default elevation shadow of the popup panel — the floating-panel rung
  /// (`CoreShadow.lg`), shared by every menu, popover and select panel.
  static const List<CoreShadowLayer> defaultBoxShadow = CoreShadow.lg;

  /// Default base colour the [boxShadow] layers tint against.
  /// The shadow tint. Stated by the palette rather than chosen here — a
  /// component has no way to know whether the page it lands on is light or
  /// dark. The palette states one colour and the theme's brightness sets
  /// how strongly it is drawn (`CoreShadow.darkStrength`), so the cast
  /// reads in either.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default minimum width of the popup panel (logical px).
  static const double defaultMinWidth = CoreSpace.space128;

  /// Default for [maxWidth] — unbounded. A menu states its own ceiling
  /// (`CoreMenuStyle.defaultPopupStyle`, 280); a popup that hosts arbitrary
  /// content does not get one here.
  static const double defaultMaxWidth = double.infinity;

  /// Default uniform spacing (logical px) between adjacent children laid
  /// out along the panel's axis — `0` (flush) by default since a generic
  /// popup / dropdown row carries its own padding. Menus opt into a small
  /// inter-item gap by setting this on their forwarded panel style.
  static const double defaultSpacing = 0;

  /// Default ambient content text colour (on-surface token). The panel
  /// overrides only the colour on a `DefaultTextStyle` (content keeps its
  /// ambient typography role), so this is a [CoreColor] slot — not a
  /// `CoreTextStyle` (a text slot must be fully honoured, never flattened
  /// to `.color`).
  static const CoreColor defaultContentColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default open (enter) animation duration of the popup panel.
  ///
  /// Drives the panel's scale + fade enter motion on both platforms
  /// (Flutter `popover_overlay.dart`, Web `co-overlay-enter` keyframes).
  /// Every menu (`DropdownMenu` / `ContextMenu` / `Menubar` /
  /// `NavigationMenu`) renders its floating panel as a `Popup`, so this is
  /// the single source of truth for menu panel enter timing — overridable
  /// per instance via `popupStyle: CorePopupStyle(openAnimationDuration:)`.
  static const Duration defaultOpenAnimationDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default close (exit) animation duration of the popup panel.
  ///
  /// Drives the panel's scale + fade exit motion (Web `co-overlay-exit`
  /// keyframes); the panel stays mounted for this long before unmounting.
  static const Duration defaultCloseAnimationDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  // ─── Fields ───────────────────────────────────────────────────────

  /// Internal padding of the popup panel.
  final CoreEdgeInsets? padding;

  /// Corner radius of the popup panel.
  final CoreBorderRadius? borderRadius;

  /// Border width of the popup panel (logical px).
  final double? borderWidth;

  /// Background colour of the popup panel.
  final CoreColor? backgroundColor;

  /// Border colour of the popup panel.
  final CoreColor? borderColor;

  /// Elevation shadow of the popup panel.
  final List<CoreShadowLayer>? boxShadow;

  /// Base colour the [boxShadow] layers tint against.
  final CoreColor? shadowBaseColor;

  /// Minimum width of the popup panel (logical px).
  final double? minWidth;

  /// Maximum panel width (logical px). `null` → [defaultMaxWidth]
  /// (unbounded). Content-driven between [minWidth] and this.
  final double? maxWidth;

  /// Uniform spacing (logical px) between adjacent children laid out
  /// along the panel's axis. Flows into `Column` / `Row.spacing`
  /// (Flutter) and the flex `gap` (Web). `null` → [defaultSpacing] (0,
  /// flush).
  final double? spacing;

  /// Text colour the panel content inherits. The panel wraps its content
  /// in a `DefaultTextStyle` with this colour, keeping the surrounding
  /// typography role and changing only the colour.
  final CoreColor? contentColor;

  /// Open (enter) animation duration of the popup panel. `null` →
  /// [defaultOpenAnimationDuration].
  final Duration? openAnimationDuration;

  /// Close (exit) animation duration of the popup panel. `null` →
  /// [defaultCloseAnimationDuration].
  final Duration? closeAnimationDuration;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CorePopupStyle merge(CorePopupStyle? other) {
    if (other == null) return this;
    return CorePopupStyle(
      surfaceStyle: other.surfaceStyle ?? surfaceStyle,
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      boxShadow: other.boxShadow ?? boxShadow,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
      minWidth: other.minWidth ?? minWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      spacing: other.spacing ?? spacing,
      contentColor: other.contentColor ?? contentColor,
      openAnimationDuration:
          other.openAnimationDuration ?? openAnimationDuration,
      closeAnimationDuration:
          other.closeAnimationDuration ?? closeAnimationDuration,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CorePopupStyle copyWith({
    CoreSurfaceStyleId? surfaceStyle,
    CoreEdgeInsets? padding,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    List<CoreShadowLayer>? boxShadow,
    CoreColor? shadowBaseColor,
    double? minWidth,
    double? maxWidth,
    double? spacing,
    CoreColor? contentColor,
    Duration? openAnimationDuration,
    Duration? closeAnimationDuration,
  }) {
    return CorePopupStyle(
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      boxShadow: boxShadow ?? this.boxShadow,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      spacing: spacing ?? this.spacing,
      contentColor: contentColor ?? this.contentColor,
      openAnimationDuration:
          openAnimationDuration ?? this.openAnimationDuration,
      closeAnimationDuration:
          closeAnimationDuration ?? this.closeAnimationDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePopupStyle &&
          runtimeType == other.runtimeType &&
          surfaceStyle == other.surfaceStyle &&
          padding == other.padding &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          _shadowEq(boxShadow, other.boxShadow) &&
          shadowBaseColor == other.shadowBaseColor &&
          minWidth == other.minWidth &&
          maxWidth == other.maxWidth &&
          spacing == other.spacing &&
          contentColor == other.contentColor &&
          openAnimationDuration == other.openAnimationDuration &&
          closeAnimationDuration == other.closeAnimationDuration;

  @override
  int get hashCode => Object.hash(
    surfaceStyle,
    padding,
    borderRadius,
    borderWidth,
    backgroundColor,
    borderColor,
    boxShadow == null ? null : Object.hashAll(boxShadow!),
    shadowBaseColor,
    minWidth,
    maxWidth,
    spacing,
    contentColor,
    openAnimationDuration,
    closeAnimationDuration,
  );

  static bool _shadowEq(
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
