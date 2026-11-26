/// Per-instance style for `Tracker`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/tracker/tracker_contract.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:meta/meta.dart';

/// Immutable style describing how a `Tracker` should render.
///
/// `CoreTrackerStyle` is **platform-neutral** (Epic #1415 option D /
/// Phase 6f). Chrome / dimensional overrides flow through the
/// nested-merge chain:
///
/// ```text
/// design system default (this class' `static const defaultX` /
///   `defaultsByStatus[status]`)
///   → CoreTrackerTheme.style                         // 프로젝트 공통
///   → parent component slot override
///   → widget.trackerStyle                            // 인스턴스별
/// ```
///
/// Behaviour / semantic fields (`segments` data input, `rounded`
/// boolean toggle) stay flat on the widget / contract (Epic #1302
/// 원칙 6/7).
@immutable
class CoreTrackerStyle implements CoreStyle<CoreTrackerStyle> {
  /// Creates a [CoreTrackerStyle].
  const CoreTrackerStyle({
    this.itemHeight,
    this.itemSpacing,
    this.endRadius,
    this.segmentColor,
  });

  // ─── Design-system defaults (Phase 6f / 6g, Epic #1696 Phase 4) ──
  // Variant-independent defaults live here as `static const`. Status
  // → colour defaults live in [defaultsByStatus]. Flutter and Web
  // resolvers read these directly so both platforms share a single
  // source of truth. Replaces the previous `CoreTrackerTokens`
  // holder — Tokens 폐기 + 1:1:1:1 매핑.

  /// Default per-segment height — `CoreSpace.space32` (32 logical px).
  ///
  /// Matches the previous `CoreTrackerTokens.itemHeight` constant.
  /// Both Flutter and Web read this default when neither
  /// `widget.trackerStyle.itemHeight` nor
  /// `CoreTrackerTheme.style.itemHeight` is set.
  static const double defaultItemHeight = CoreSpace.space32;

  /// Default horizontal spacing between segments — `CoreSpace.space4`
  /// (4 logical px, #6467). Flows directly into `Row.spacing` (Flutter native
  /// paint-API argument, 3.27+) and the outer flex row's CSS `gap`
  /// inline rule (Web) — both consume the raw double, so this slot
  /// stays scalar (`double?`) rather than a nested `CoreGapStyle`.
  static const double defaultItemSpacing = CoreSpace.space4;

  /// Default border-radius applied to the outer ends of the segment
  /// row when `widget.rounded == true` — `CoreRadius.radius2`
  /// (2 logical px). Both Flutter and Web read this single default, so
  /// the row renders identical corners on both platforms.
  static const double defaultEndRadius = CoreRadius.radius2;

  /// Per-[CoreTrackerStatus] segment colour mapping. Each entry is a
  /// [CoreTrackerStyle] whose only set field is [segmentColor] — the
  /// resolver reads `defaultsByStatus[segment.status]!.segmentColor!`
  /// when the user has not overridden [segmentColor] directly.
  ///
  /// Value type is [CoreTrackerStyle] itself (not a record) so the
  /// 1:1:1:1 mapping between `CoreTrackerStyle.segmentColor` and per-
  /// status default is preserved without a separate holder shape.
  ///
  /// Both Flutter and Web read this map (single source of truth):
  ///
  /// - Flutter: `scheme.resolve(defaultsByStatus[s]!.segmentColor!).toValue()`
  ///   (CoreColor → Flutter `Color`);
  /// - Web: `bg-${defaultsByStatus[s]!.segmentColor!.tailwindColor}` Tailwind
  ///   class — the `.tailwindColor` adapter emits the token name
  ///   (e.g. `'success'`), resolved to a CSS variable by the browser
  ///   at runtime (theme-free EMIT).
  static const Map<CoreTrackerStatus, CoreTrackerStyle> defaultsByStatus = {
    // A healthy segment recedes so the warning and critical ones carry
    // the row (#6467): the same hue at 40 %, the others at full colour.
    CoreTrackerStatus.fine: CoreTrackerStyle(
      segmentColor: CoreColor.token(
        CoreColors.success,
        opacity: CoreOpacity.opacity40,
      ),
    ),
    CoreTrackerStatus.warning: CoreTrackerStyle(
      segmentColor: CoreColor.token(CoreColors.warning),
    ),
    CoreTrackerStatus.critical: CoreTrackerStyle(
      segmentColor: CoreColor.token(CoreColors.error),
    ),
    CoreTrackerStatus.unknown: CoreTrackerStyle(
      segmentColor: CoreColor.token(CoreColors.outlineVariant),
    ),
  };

  // ── Chrome (flat) ────────────────────────────

  /// Height of each tracker segment (logical px).
  final double? itemHeight;

  /// Horizontal spacing (logical px, pre-scaling) between adjacent
  /// tracker segments. Falls back to [defaultItemSpacing] when null.
  ///
  /// Flows directly into `Row.spacing` (Flutter native paint-API
  /// argument, 3.27+) on Flutter and the outer flex row's CSS `gap`
  /// inline rule on Web — both are native paint-API consumers that take a
  /// raw double, so this slot stays scalar (`double?`) rather than the
  /// nested `CoreGapStyle` shape used for `Gap` slots.
  final double? itemSpacing;

  /// Border-radius applied to the outer ends of the segment row when
  /// `widget.rounded == true` (logical px).
  final double? endRadius;

  /// Optional global override applied to every segment, regardless of
  /// the segment's [CoreTrackerStatus]. When `null` (the default) each
  /// segment uses its status colour from [defaultsByStatus].
  final CoreColor? segmentColor;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreTrackerStyle merge(CoreTrackerStyle? other) {
    if (other == null) return this;
    return CoreTrackerStyle(
      itemHeight: other.itemHeight ?? itemHeight,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      endRadius: other.endRadius ?? endRadius,
      segmentColor: other.segmentColor ?? segmentColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTrackerStyle copyWith({
    double? itemHeight,
    double? itemSpacing,
    double? endRadius,
    CoreColor? segmentColor,
  }) {
    return CoreTrackerStyle(
      itemHeight: itemHeight ?? this.itemHeight,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      endRadius: endRadius ?? this.endRadius,
      segmentColor: segmentColor ?? this.segmentColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTrackerStyle &&
          runtimeType == other.runtimeType &&
          itemHeight == other.itemHeight &&
          itemSpacing == other.itemSpacing &&
          endRadius == other.endRadius &&
          segmentColor == other.segmentColor;

  @override
  int get hashCode =>
      Object.hash(itemHeight, itemSpacing, endRadius, segmentColor);
}
