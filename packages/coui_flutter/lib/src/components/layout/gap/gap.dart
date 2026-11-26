import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/gap/render_gap.dart';
import 'package:flutter/foundation.dart';

/// Unified gap component.
///
/// Adds spacing along the parent flex axis. Works inside any `Row`,
/// `Column`, or `Flex` — the gap automatically sizes itself along the
/// parent's main axis. Inside a `Scrollable` that is not a flex, the
/// scroll axis is used as a fallback.
///
/// All chrome (`size`, `crossAxisExtent`, `color`) lives in
/// [gapStyle]; for common spacing tokens prefer the `Gap.spaceN()`
/// named constructors which fold a `const CoreGapStyle(size:
/// CoreSpace.spaceN)` for you.
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     Text('First'),
///     const Gap.space16(),
///     Text('Second'),
///   ],
/// )
/// ```
class Gap extends StatelessWidget implements CoreGapContract {
  /// Creates a [Gap] with an optional [gapStyle] override.
  ///
  /// When [gapStyle] is `null` the resolver falls back to
  /// `CoreGapTheme.style` and finally to `CoreGapStyle.defaultSize`.
  const Gap({this.gapStyle, super.key});

  /// Creates a [Gap] that expands to fill the parent's cross axis
  /// while taking [mainAxisExtent] along the main axis.
  ///
  /// Mirrors `gap_package.Gap.expand`.
  Gap.expand(double mainAxisExtent, {Key? key, CoreColor? color})
    : this(
        key: key,
        gapStyle: CoreGapStyle(
          size: mainAxisExtent,
          crossAxisExtent: .infinity,
          color: color,
        ),
      );

  // ───── Spacing token chaining constructors ─────────────
  // One per `CoreSpace.spaceN` constant — each folds a `const
  // CoreGapStyle(size: CoreSpace.spaceN)` so call-sites stay const.

  /// 0px gap.
  const Gap.space0({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space0);

  /// 2px gap.
  const Gap.space2({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space2);

  /// 4px gap (design-system default).
  const Gap.space4({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space4);

  /// 6px gap.
  const Gap.space6({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space6);

  /// 8px gap.
  const Gap.space8({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space8);

  /// 10px gap.
  const Gap.space10({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space10);

  /// 12px gap.
  const Gap.space12({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space12);

  /// 14px gap.
  const Gap.space14({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space14);

  /// 16px gap.
  const Gap.space16({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space16);

  /// 18px gap.
  const Gap.space18({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space18);

  /// 20px gap.
  const Gap.space20({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space20);

  /// 24px gap.
  const Gap.space24({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space24);

  /// 28px gap.
  const Gap.space28({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space28);

  /// 32px gap.
  const Gap.space32({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space32);

  /// 36px gap.
  const Gap.space36({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space36);

  /// 40px gap.
  const Gap.space40({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space40);

  /// 44px gap.
  const Gap.space44({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space44);

  /// 48px gap.
  const Gap.space48({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space48);

  /// 52px gap.
  const Gap.space52({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space52);

  /// 56px gap.
  const Gap.space56({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space56);

  /// 60px gap.
  const Gap.space60({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space60);

  /// 64px gap.
  const Gap.space64({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space64);

  /// 72px gap.
  const Gap.space72({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space72);

  /// 80px gap.
  const Gap.space80({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space80);

  /// 88px gap.
  const Gap.space88({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space88);

  /// 96px gap.
  const Gap.space96({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space96);

  /// 104px gap.
  const Gap.space104({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space104);

  /// 112px gap.
  const Gap.space112({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space112);

  /// 120px gap.
  const Gap.space120({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space120);

  /// 128px gap.
  const Gap.space128({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space128);

  /// 136px gap.
  const Gap.space136({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space136);

  /// 144px gap.
  const Gap.space144({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space144);

  /// 152px gap.
  const Gap.space152({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space152);

  /// 160px gap.
  const Gap.space160({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space160);

  /// 168px gap.
  const Gap.space168({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space168);

  /// 176px gap.
  const Gap.space176({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space176);

  /// 184px gap.
  const Gap.space184({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space184);

  /// 192px gap.
  const Gap.space192({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space192);

  /// 200px gap.
  const Gap.space200({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space200);

  /// 208px gap.
  const Gap.space208({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space208);

  /// 216px gap.
  const Gap.space216({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space216);

  /// 224px gap.
  const Gap.space224({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space224);

  /// 232px gap.
  const Gap.space232({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space232);

  /// 240px gap.
  const Gap.space240({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space240);

  /// 248px gap.
  const Gap.space248({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space248);

  /// 256px gap.
  const Gap.space256({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space256);

  /// Per-instance style override. `null` inherits the theme + the
  /// design-system default chain.
  final CoreGapStyle? gapStyle;

  // ───── CoreGapContract getters (forward from gapStyle) ──────────

  @override
  double? get size => gapStyle?.size;

  @override
  double? get crossAxisExtent => gapStyle?.crossAxisExtent;

  @override
  CoreColor? get color => gapStyle?.color;

  /// Returns a copy of this [Gap] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Gap copyWith({Key? key, CoreGapStyle? gapStyle}) {
    return Gap(key: key ?? this.key, gapStyle: gapStyle ?? this.gapStyle);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveGap(context, gapStyle: gapStyle);
    final scrollable = Scrollable.maybeOf(context);
    final fallbackDirection = scrollable == null
        ? null
        : axisDirectionToAxis(scrollable.axisDirection);
    return _RawGap(
      mainAxisExtent: resolved.size,
      crossAxisExtent: resolved.crossAxisExtent,
      color: resolved.color,
      fallbackDirection: fallbackDirection,
    );
  }
}

/// Chain sugar for merging a [CoreGapStyle] patch into
/// [Gap.gapStyle] without hand-reconstructing every field. Mirrors
/// the Web `Gap.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreGapStyle.merge` right-side-wins semantics).
extension GapStyleChain on Gap {
  /// Returns a copy of this [Gap] with [patch] merged into [gapStyle]
  /// (patch fields win on conflict).
  Gap withStyle(CoreGapStyle patch) =>
      copyWith(gapStyle: (gapStyle ?? const CoreGapStyle()).merge(patch));
}

class _RawGap extends LeafRenderObjectWidget {
  const _RawGap({
    required this.mainAxisExtent,
    this.crossAxisExtent,
    this.color,
    this.fallbackDirection,
  });

  final double mainAxisExtent;
  final double? crossAxisExtent;
  final Color? color;
  final Axis? fallbackDirection;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGap(
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent ?? 0,
      fallbackDirection: fallbackDirection,
      color: color,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderGap renderObject) {
    renderObject
      ..mainAxisExtent = mainAxisExtent
      ..crossAxisExtent = crossAxisExtent ?? 0
      ..color = color
      ..fallbackDirection = fallbackDirection;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('mainAxisExtent', mainAxisExtent))
      ..add(DoubleProperty('crossAxisExtent', crossAxisExtent, defaultValue: 0))
      ..add(ColorProperty('color', color))
      ..add(EnumProperty<Axis>('fallbackDirection', fallbackDirection));
  }
}
