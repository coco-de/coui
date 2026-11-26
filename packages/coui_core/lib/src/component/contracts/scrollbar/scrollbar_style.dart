/// Per-instance style for `Scrollbar`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable chrome style describing how a `Scrollbar` renders.
///
/// `CoreScrollbarStyle` carries only visual chrome — thumb colour,
/// thickness, corner radius, the gap the thumb keeps from the edge, the
/// hover / drag look of the thumb, and the track colour. Behavioural /
/// semantic fields (`axis`, `visibility`, `interactive`, `child`) stay flat
/// on the widget.
///
/// ```text
/// CoreScrollbarStyle.defaultX
///   → CoreScrollbarTheme.style
///   → widget.scrollbarStyle
/// ```
@immutable
class CoreScrollbarStyle implements CoreStyle<CoreScrollbarStyle> {
  /// Creates a [CoreScrollbarStyle].
  const CoreScrollbarStyle({
    this.thumbColor,
    this.hoverThumbColor,
    this.thumbRadius,
    this.thickness,
    this.hoverThickness,
    this.thumbInset,
    this.minThumbLength,
    this.trackColor,
  });

  /// Thumb colour override. The alpha lives in the colour itself, so one
  /// field carries both the ink and how strongly it shows.
  final CoreColor? thumbColor;

  /// Thumb colour while the pointer is on the thumb or it is being dragged.
  /// `null` → [defaultHoverThumbColor].
  final CoreColor? hoverThumbColor;

  /// Thumb corner radius override.
  final CoreBorderRadius? thumbRadius;

  /// Thumb thickness (logical px, pre-scaling).
  final double? thickness;

  /// Thumb thickness while the pointer is on the thumb or it is being
  /// dragged (logical px, pre-scaling). `null` → [defaultHoverThickness].
  ///
  /// The bar's footprint does not change: the thumb grows into the gap it
  /// keeps from the edge ([thumbInset]), and is never wider than the bar's
  /// footprint (see `CoreScrollbarThumbGeometry`).
  final double? hoverThickness;

  /// Gap between the thumb and the edge it hugs, on every side (logical px,
  /// pre-scaling). `null` → [defaultThumbInset].
  ///
  /// The bar's footprint is the thumb plus this gap on both sides.
  final double? thumbInset;

  /// Minimum thumb length (logical px, pre-scaling). `null` → token
  /// default ([defaultMinThumbLength]).
  final double? minThumbLength;

  /// Track colour override. `null` → [defaultTrackColor] (transparent —
  /// the thumb floats over the content with no visible gutter).
  final CoreColor? trackColor;

  /// Default thumb colour — the surface's own ink at half strength.
  ///
  /// Drawing the ink translucently keeps the thumb one step darker than
  /// whatever it sits on, on a white page, a grey container and in dark
  /// alike, and it holds 3:1 against the surfaces a scrollbar is drawn on
  /// (WCAG 1.4.11 — the thumb is operated by dragging it). Half is the
  /// weakest strength that holds it; 40 % does not.
  static const CoreColor defaultThumbColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.opacity50,
  );

  /// Default thumb colour while hovered or dragged — the same ink, stronger.
  static const CoreColor defaultHoverThumbColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.opacity70,
  );

  /// Default thumb corner radius — a capsule.
  static const CoreBorderRadius defaultThumbRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default thumb thickness in logical pixels.
  static const double defaultThickness = CoreSize.size6;

  /// Default thumb thickness while hovered or dragged.
  static const double defaultHoverThickness = CoreSize.size8;

  /// Default gap between the thumb and the edge it hugs.
  ///
  /// Keeps the thumb clear of the rounded corners of the card, dialog or
  /// popover it scrolls inside.
  static const double defaultThumbInset = CoreSpace.space2;

  /// Multiplier applied to [defaultThickness] (and to the hover thickness)
  /// when `CoreScrollbarVisibility.thin` is selected.
  static const double thinThicknessFactor = 0.5;

  /// Minimum thumb length (logical px) so a tiny thumb stays grabbable.
  static const double defaultMinThumbLength = CoreSize.size48;

  /// Default track colour (transparent).
  static const CoreColor defaultTrackColor = .transparent;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreScrollbarStyle merge(CoreScrollbarStyle? other) {
    if (other == null) return this;
    return CoreScrollbarStyle(
      thumbColor: other.thumbColor ?? thumbColor,
      hoverThumbColor: other.hoverThumbColor ?? hoverThumbColor,
      thumbRadius: other.thumbRadius ?? thumbRadius,
      thickness: other.thickness ?? thickness,
      hoverThickness: other.hoverThickness ?? hoverThickness,
      thumbInset: other.thumbInset ?? thumbInset,
      minThumbLength: other.minThumbLength ?? minThumbLength,
      trackColor: other.trackColor ?? trackColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreScrollbarStyle copyWith({
    CoreColor? thumbColor,
    CoreColor? hoverThumbColor,
    CoreBorderRadius? thumbRadius,
    double? thickness,
    double? hoverThickness,
    double? thumbInset,
    double? minThumbLength,
    CoreColor? trackColor,
  }) {
    return CoreScrollbarStyle(
      thumbColor: thumbColor ?? this.thumbColor,
      hoverThumbColor: hoverThumbColor ?? this.hoverThumbColor,
      thumbRadius: thumbRadius ?? this.thumbRadius,
      thickness: thickness ?? this.thickness,
      hoverThickness: hoverThickness ?? this.hoverThickness,
      thumbInset: thumbInset ?? this.thumbInset,
      minThumbLength: minThumbLength ?? this.minThumbLength,
      trackColor: trackColor ?? this.trackColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreScrollbarStyle &&
          runtimeType == other.runtimeType &&
          thumbColor == other.thumbColor &&
          hoverThumbColor == other.hoverThumbColor &&
          thumbRadius == other.thumbRadius &&
          thickness == other.thickness &&
          hoverThickness == other.hoverThickness &&
          thumbInset == other.thumbInset &&
          minThumbLength == other.minThumbLength &&
          trackColor == other.trackColor;

  @override
  int get hashCode => Object.hash(
    thumbColor,
    hoverThumbColor,
    thumbRadius,
    thickness,
    hoverThickness,
    thumbInset,
    minThumbLength,
    trackColor,
  );
}
