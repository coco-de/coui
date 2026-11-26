/// Per-instance style for `DisclosureBadge`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/disclosure_badge/core_disclosure_kind.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `DisclosureBadge` should render.
///
/// Platform-neutral. The semantic identifier (`kind`) and the content
/// (`label`) stay on the widget.
///
/// ```text
/// design system default for kind
///   → CoreDisclosureBadgeTheme.style               // 프로젝트 공통
///   → CoreDisclosureBadgeTheme.kindStyles[kind]
///   → widget.disclosureBadgeStyle                  // 인스턴스별
/// ```
///
/// ### What this style deliberately cannot do
///
/// Three absences are load-bearing, not oversights:
///
/// * **No `backgroundColor`.** A disclosure badge is an outline and a
///   word. A fill is what makes a `Chip` read as a pressable control,
///   and this thing is not pressable — it is a claim about whether a
///   document opens. There is no slot to fill it through.
/// * **No hover / pressed / focus slot.** Same reason: pointer feedback
///   on a static marker promises an interaction that does not exist.
/// * **No stroke-pattern or marker slot.** Those live on
///   [CoreDisclosureKind] so that no theme can flatten the three kinds
///   into colour alone (WCAG 1.4.1). See that enum's doc.
@immutable
class CoreDisclosureBadgeStyle implements CoreStyle<CoreDisclosureBadgeStyle> {
  /// Creates a [CoreDisclosureBadgeStyle].
  const CoreDisclosureBadgeStyle({
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.labelStyle,
    this.markerSize,
    this.markerRadius,
    this.markerSpacing,
  });

  // ─── Design-system defaults ─────────────────────────────────────

  /// Default outline stroke width.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default corner radius.
  ///
  /// Deliberately a small radius rather than the pill
  /// (`CoreRadius.radius9999`) that `Badge` and `Chip` default to — a
  /// pill outline plus a short word is the shape a filter chip has, and
  /// this component must not borrow the silhouette of something you can
  /// press.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius4,
  );

  /// Default padding around the label.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space6,
    vertical: CoreSpace.space2,
  );

  /// Default label typography role.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
  );

  /// Default diameter of the [CoreDisclosureKind.commitment] marker dot.
  static const double defaultMarkerSize = CoreSize.size4;

  /// Marker corner radius — a full circle.
  ///
  /// Lives in the contract rather than inline in the Web resolver so the
  /// resolver never reaches for a common token class directly
  /// (`verify_contracts.sh` [11/13]).
  static const CoreBorderRadius defaultMarkerRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default gap between the marker dot and the label.
  static const double defaultMarkerSpacing = CoreSpace.space4;

  /// Per-kind colour defaults. Single source of truth shared by every
  /// platform renderer.
  ///
  /// [CoreDisclosureKind.private] uses `on-surface-variant` over
  /// `outline` and **never** a primary-family token: painting the
  /// unopenable thing in the colour of the openable thing is a lie the
  /// reader only discovers after clicking. [CoreDisclosureKind.open]
  /// owns `primary` for the same reason — it is the one kind that
  /// actually resolves to a link.
  ///
  /// [CoreDisclosureKind.commitment] shares `outline` with `private` on
  /// purpose. Its separation from `private` is carried by shape (solid
  /// + marker vs. dashed), which is the separation that survives
  /// greyscale; the full-strength `on-surface` label is a reinforcement,
  /// not the signal.
  static const Map<CoreDisclosureKind, CoreDisclosureBadgeKindStyle>
  defaultsByKind = {
    CoreDisclosureKind.open: CoreDisclosureBadgeKindStyle(
      foreground: CoreColor.token(CoreColors.primary),
      borderColor: CoreColor.token(CoreColors.primary),
    ),
    CoreDisclosureKind.commitment: CoreDisclosureBadgeKindStyle(
      foreground: CoreColor.token(CoreColors.onSurface),
      borderColor: CoreColor.token(CoreColors.outline),
    ),
    CoreDisclosureKind.private: CoreDisclosureBadgeKindStyle(
      foreground: CoreColor.token(CoreColors.onSurfaceVariant),
      borderColor: CoreColor.token(CoreColors.outline),
    ),
  };

  // ─── Fields ─────────────────────────────────────────────────────

  /// Label + marker colour override. `null` defers to
  /// `defaultsByKind[kind]!.foreground`.
  ///
  /// This field **deliberately has no `defaultForegroundColor`**, and the
  /// absence is the design. A flat default would have to answer for all
  /// three kinds at once, and the moment it does, `open` / `commitment` /
  /// `private` render in one colour — which is the exact failure this
  /// component exists to prevent (WCAG 1.4.1: the kinds must stay
  /// distinguishable without colour, and colour is the *first* signal a
  /// reader reaches for). The per-kind map is the default; it is keyed by
  /// [CoreDisclosureKind] so no theme can collapse the three.
  final CoreColor? foregroundColor;

  /// Outline colour override. `null` defers to
  /// `defaultsByKind[kind]!.borderColor`.
  final CoreColor? borderColor;

  /// Outline stroke width override. `null` defers to
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Corner radius override. `null` defers to [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// Padding around the label. `null` defers to [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Label typography override. `null` defers to [defaultLabelStyle].
  final CoreTextStyle? labelStyle;

  /// Diameter of the [CoreDisclosureKind.commitment] marker dot in
  /// logical px. `null` defers to [defaultMarkerSize]. Only consumed by
  /// the kinds whose [CoreDisclosureKind.hasMarker] is `true`.
  final double? markerSize;

  /// Marker corner radius override. `null` defers to
  /// [defaultMarkerRadius] — a full circle.
  final CoreBorderRadius? markerRadius;

  /// Gap between the marker dot and the label in logical px. `null`
  /// defers to [defaultMarkerSpacing].
  final double? markerSpacing;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreDisclosureBadgeStyle merge(CoreDisclosureBadgeStyle? other) {
    if (other == null) return this;
    return CoreDisclosureBadgeStyle(
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      markerSize: other.markerSize ?? markerSize,
      markerRadius: other.markerRadius ?? markerRadius,
      markerSpacing: other.markerSpacing ?? markerSpacing,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreDisclosureBadgeStyle copyWith({
    CoreColor? foregroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    CoreTextStyle? labelStyle,
    double? markerSize,
    CoreBorderRadius? markerRadius,
    double? markerSpacing,
  }) {
    return CoreDisclosureBadgeStyle(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      labelStyle: labelStyle ?? this.labelStyle,
      markerSize: markerSize ?? this.markerSize,
      markerRadius: markerRadius ?? this.markerRadius,
      markerSpacing: markerSpacing ?? this.markerSpacing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDisclosureBadgeStyle &&
          runtimeType == other.runtimeType &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          labelStyle == other.labelStyle &&
          markerSize == other.markerSize &&
          markerRadius == other.markerRadius &&
          markerSpacing == other.markerSpacing;

  @override
  int get hashCode => Object.hash(
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    labelStyle,
    markerSize,
    markerRadius,
    markerSpacing,
  );

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Colour defaults for one [CoreDisclosureKind].
///
/// Colour only — the kind's shape (stroke pattern, marker dot) lives on
/// [CoreDisclosureKind] itself so it cannot be themed away.
@immutable
class CoreDisclosureBadgeKindStyle {
  /// Creates a [CoreDisclosureBadgeKindStyle].
  const CoreDisclosureBadgeKindStyle({
    required this.foreground,
    required this.borderColor,
  });

  /// Label and marker colour.
  final CoreColor foreground;

  /// Outline colour.
  final CoreColor borderColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDisclosureBadgeKindStyle &&
          runtimeType == other.runtimeType &&
          foreground == other.foreground &&
          borderColor == other.borderColor;

  @override
  int get hashCode => Object.hash(foreground, borderColor);
}
