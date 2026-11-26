/// Per-instance style for `Resizable`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Resizable` should render.
///
/// `CoreResizableStyle` carries chrome / dimensional flat fields.
/// Behavioural / semantic fields (`panes`, `direction`, `onResize`,
/// `showDragHandle`) stay flat on the widget / contract (Epic #1302
/// 원칙 6/7).
///
/// ```text
/// design system default
///   → CoreResizableTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.resizableStyle                          // 인스턴스별
/// ```
@immutable
class CoreResizableStyle implements CoreStyle<CoreResizableStyle> {
  /// Creates a [CoreResizableStyle].
  const CoreResizableStyle({
    this.dividerThickness,
    this.dividerHitExtent,
    this.dividerColor,
    this.dividerHoverColor,
    this.dividerDraggingThickness,
    this.dividerDraggingColor,
    this.focusOutlineStyle,
    this.transitionDuration,
    this.handleHitExtent,
    this.handleLength,
    this.handleBreadth,
    this.handleColor,
    this.handleIconColor,
    this.handleIconSize,
  });

  /// Default divider stroke thickness (logical px, pre-scaling).
  ///
  /// Variant-independent dimensional default — single source of truth
  /// for both Flutter and Web resolvers (Phase 6f/6g default 패턴).
  static const double defaultDividerThickness = CoreStrokeWidth.stroke1;

  /// Default hit-test region extent around the divider (logical px,
  /// pre-scaling).
  ///
  /// Distinct from [defaultDividerThickness] — this is the wider
  /// invisible grab area that makes the divider easy to drag, while
  /// the thickness is the visible stroke. Single source of truth for
  /// both Flutter and Web resolvers (Phase 6f/6g default 패턴).
  static const double defaultDividerHitExtent = CoreSpace.space8;

  /// Default idle divider stroke colour — the `outlineVariant` token.
  ///
  /// Single source of truth for both Flutter and Web resolvers — the
  /// Flutter resolver materialises it via `scheme.resolve(...).toValue()`
  /// and the Web resolver emits the `bg-{outline}` token class, matching
  /// across platforms (Phase 6f/6g default 패턴).
  static const CoreColor defaultDividerColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default divider stroke colour on hover — the `outline` token.
  ///
  /// Single source of truth for both Flutter and Web resolvers — the
  /// Flutter resolver materialises it via `scheme.resolve(...).toValue()`
  /// and the Web resolver emits the `hover:bg-{primary}` pseudo-state
  /// token class, matching across platforms (Phase 6f/6g default 패턴).
  static const CoreColor defaultDividerHoverColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default divider stroke thickness while the divider is being dragged
  /// (logical px, pre-scaling) — heavier than the idle line so the thing
  /// under the pointer reads as held. The grab area ([defaultDividerHitExtent])
  /// does not change with it.
  static const double defaultDividerDraggingThickness = CoreStrokeWidth.stroke2;

  /// Default divider stroke colour while dragged — the `primary` token.
  static const CoreColor defaultDividerDraggingColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default keyboard focus ring of a divider. The line itself stays as
  /// it is at rest; the ring is the shared `FocusOutline` (only on keyboard
  /// focus), so every field left null defers to its own resolver.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle();

  /// Default divider colour crossfade duration.
  ///
  /// Animates the divider bar's colour swap between the idle
  /// ([dividerColor]) and hover ([dividerHoverColor]) states — uses
  /// `CoreDuration.fast`. Single source of truth for both Flutter and
  /// Web resolvers (Phase 6f/6g default 패턴).
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default enlarged hit-test extent used when a drag handle is shown
  /// (logical px, pre-scaling).
  ///
  /// Wider than [defaultDividerHitExtent] so the centred grab handle is
  /// comfortable to grab on touch platforms (iOS / Android). Single
  /// source of truth for both Flutter and Web resolvers.
  static const double defaultHandleHitExtent = CoreSpace.space24;

  /// Default grab-handle length along the divider axis (logical px,
  /// pre-scaling).
  ///
  /// The long side of the pill — vertical for a horizontal split,
  /// horizontal for a vertical split.
  static const double defaultHandleLength = CoreSpace.space40;

  /// Default grab-handle breadth across the divider axis (logical px,
  /// pre-scaling).
  ///
  /// The short side of the pill; also drives the pill corner radius
  /// (breadth / 2) so it renders as a stadium shape.
  static const double defaultHandleBreadth = CoreSpace.space16;

  /// Default grab-handle background colour — the `outline` token.
  ///
  /// Matches [defaultDividerColor] by default but is a separate field so
  /// the handle fill can be overridden independently of the divider line.
  static const CoreColor defaultHandleColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default drag-dot icon colour inside the grab handle — the muted
  /// `onSurfaceVariant` token.
  static const CoreColor defaultHandleIconColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default drag-dot icon size inside the grab handle (logical px,
  /// pre-scaling).
  static const double defaultHandleIconSize = CoreIconSize.size12;

  /// Divider stroke thickness override (logical px).
  final double? dividerThickness;

  /// Divider hit-test region extent override (logical px).
  final double? dividerHitExtent;

  /// Divider stroke colour override.
  final CoreColor? dividerColor;

  /// Divider stroke colour on hover override.
  final CoreColor? dividerHoverColor;

  /// Divider stroke thickness while dragged override (logical px).
  final double? dividerDraggingThickness;

  /// Divider stroke colour while dragged override.
  final CoreColor? dividerDraggingColor;

  /// Keyboard focus ring override, forwarded to the composed `FocusOutline`.
  /// `null` defers to [defaultFocusOutlineStyle].
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Divider colour crossfade duration override.
  final Duration? transitionDuration;

  /// Enlarged hit-test extent override used when the drag handle is
  /// shown (logical px).
  final double? handleHitExtent;

  /// Grab-handle length along the divider axis override (logical px).
  final double? handleLength;

  /// Grab-handle breadth across the divider axis override (logical px).
  final double? handleBreadth;

  /// Grab-handle background colour override.
  final CoreColor? handleColor;

  /// Drag-dot icon colour inside the grab handle override.
  final CoreColor? handleIconColor;

  /// Drag-dot icon size inside the grab handle override (logical px).
  final double? handleIconSize;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreResizableStyle merge(CoreResizableStyle? other) {
    if (other == null) return this;
    return CoreResizableStyle(
      dividerThickness: other.dividerThickness ?? dividerThickness,
      dividerHitExtent: other.dividerHitExtent ?? dividerHitExtent,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerHoverColor: other.dividerHoverColor ?? dividerHoverColor,
      dividerDraggingThickness:
          other.dividerDraggingThickness ?? dividerDraggingThickness,
      dividerDraggingColor: other.dividerDraggingColor ?? dividerDraggingColor,
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      handleHitExtent: other.handleHitExtent ?? handleHitExtent,
      handleLength: other.handleLength ?? handleLength,
      handleBreadth: other.handleBreadth ?? handleBreadth,
      handleColor: other.handleColor ?? handleColor,
      handleIconColor: other.handleIconColor ?? handleIconColor,
      handleIconSize: other.handleIconSize ?? handleIconSize,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreResizableStyle copyWith({
    double? dividerThickness,
    double? dividerHitExtent,
    CoreColor? dividerColor,
    CoreColor? dividerHoverColor,
    double? dividerDraggingThickness,
    CoreColor? dividerDraggingColor,
    CoreFocusOutlineStyle? focusOutlineStyle,
    Duration? transitionDuration,
    double? handleHitExtent,
    double? handleLength,
    double? handleBreadth,
    CoreColor? handleColor,
    CoreColor? handleIconColor,
    double? handleIconSize,
  }) {
    return CoreResizableStyle(
      dividerThickness: dividerThickness ?? this.dividerThickness,
      dividerHitExtent: dividerHitExtent ?? this.dividerHitExtent,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerHoverColor: dividerHoverColor ?? this.dividerHoverColor,
      dividerDraggingThickness:
          dividerDraggingThickness ?? this.dividerDraggingThickness,
      dividerDraggingColor: dividerDraggingColor ?? this.dividerDraggingColor,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      handleHitExtent: handleHitExtent ?? this.handleHitExtent,
      handleLength: handleLength ?? this.handleLength,
      handleBreadth: handleBreadth ?? this.handleBreadth,
      handleColor: handleColor ?? this.handleColor,
      handleIconColor: handleIconColor ?? this.handleIconColor,
      handleIconSize: handleIconSize ?? this.handleIconSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreResizableStyle &&
          runtimeType == other.runtimeType &&
          dividerThickness == other.dividerThickness &&
          dividerHitExtent == other.dividerHitExtent &&
          dividerColor == other.dividerColor &&
          dividerHoverColor == other.dividerHoverColor &&
          dividerDraggingThickness == other.dividerDraggingThickness &&
          dividerDraggingColor == other.dividerDraggingColor &&
          focusOutlineStyle == other.focusOutlineStyle &&
          transitionDuration == other.transitionDuration &&
          handleHitExtent == other.handleHitExtent &&
          handleLength == other.handleLength &&
          handleBreadth == other.handleBreadth &&
          handleColor == other.handleColor &&
          handleIconColor == other.handleIconColor &&
          handleIconSize == other.handleIconSize;

  @override
  int get hashCode => Object.hash(
    dividerThickness,
    dividerHitExtent,
    dividerColor,
    dividerHoverColor,
    dividerDraggingThickness,
    dividerDraggingColor,
    focusOutlineStyle,
    transitionDuration,
    handleHitExtent,
    handleLength,
    handleBreadth,
    handleColor,
    handleIconColor,
    handleIconSize,
  );
}
