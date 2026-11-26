import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/gap/render_gap.dart';
import 'package:flutter/foundation.dart';

/// Flexible gap that takes at most `gapStyle.size` along the parent's
/// main axis and shrinks when the parent is too small.
///
/// Mirrors `gap_package.MaxGap`. Must be a descendant of `Row`,
/// `Column`, or `Flex` — internally wraps a `_RawMaxGap` in
/// `Flexible`.
class MaxGap extends StatelessWidget implements CoreMaxGapContract {
  /// Creates a [MaxGap] with an optional [gapStyle] override.
  const MaxGap({this.gapStyle, super.key});

  /// Creates a [MaxGap] that expands to fill the parent's cross
  /// axis. Mirrors `gap_package.MaxGap.expand`.
  MaxGap.expand(double mainAxisExtent, {Key? key, CoreColor? color})
    : this(
        key: key,
        gapStyle: CoreGapStyle(
          size: mainAxisExtent,
          crossAxisExtent: .infinity,
          color: color,
        ),
      );

  // ───── Spacing token chaining constructors ─────────────

  /// 0px max gap.
  const MaxGap.space0({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space0);

  /// 2px max gap.
  const MaxGap.space2({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space2);

  /// 4px max gap.
  const MaxGap.space4({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space4);

  /// 6px max gap.
  const MaxGap.space6({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space6);

  /// 8px max gap.
  const MaxGap.space8({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space8);

  /// 10px max gap.
  const MaxGap.space10({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space10);

  /// 12px max gap.
  const MaxGap.space12({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space12);

  /// 14px max gap.
  const MaxGap.space14({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space14);

  /// 16px max gap.
  const MaxGap.space16({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space16);

  /// 18px max gap.
  const MaxGap.space18({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space18);

  /// 20px max gap.
  const MaxGap.space20({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space20);

  /// 24px max gap.
  const MaxGap.space24({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space24);

  /// 28px max gap.
  const MaxGap.space28({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space28);

  /// 32px max gap.
  const MaxGap.space32({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space32);

  /// 36px max gap.
  const MaxGap.space36({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space36);

  /// 40px max gap.
  const MaxGap.space40({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space40);

  /// 44px max gap.
  const MaxGap.space44({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space44);

  /// 48px max gap.
  const MaxGap.space48({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space48);

  /// 52px max gap.
  const MaxGap.space52({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space52);

  /// 56px max gap.
  const MaxGap.space56({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space56);

  /// 60px max gap.
  const MaxGap.space60({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space60);

  /// 64px max gap.
  const MaxGap.space64({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space64);

  /// 72px max gap.
  const MaxGap.space72({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space72);

  /// 80px max gap.
  const MaxGap.space80({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space80);

  /// 88px max gap.
  const MaxGap.space88({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space88);

  /// 96px max gap.
  const MaxGap.space96({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space96);

  /// 104px max gap.
  const MaxGap.space104({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space104);

  /// 112px max gap.
  const MaxGap.space112({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space112);

  /// 120px max gap.
  const MaxGap.space120({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space120);

  /// 128px max gap.
  const MaxGap.space128({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space128);

  /// 136px max gap.
  const MaxGap.space136({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space136);

  /// 144px max gap.
  const MaxGap.space144({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space144);

  /// 152px max gap.
  const MaxGap.space152({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space152);

  /// 160px max gap.
  const MaxGap.space160({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space160);

  /// 168px max gap.
  const MaxGap.space168({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space168);

  /// 176px max gap.
  const MaxGap.space176({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space176);

  /// 184px max gap.
  const MaxGap.space184({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space184);

  /// 192px max gap.
  const MaxGap.space192({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space192);

  /// 200px max gap.
  const MaxGap.space200({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space200);

  /// 208px max gap.
  const MaxGap.space208({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space208);

  /// 216px max gap.
  const MaxGap.space216({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space216);

  /// 224px max gap.
  const MaxGap.space224({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space224);

  /// 232px max gap.
  const MaxGap.space232({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space232);

  /// 240px max gap.
  const MaxGap.space240({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space240);

  /// 248px max gap.
  const MaxGap.space248({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space248);

  /// 256px max gap.
  const MaxGap.space256({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space256);

  /// Per-instance style override.
  final CoreGapStyle? gapStyle;

  // ───── CoreMaxGapContract getters (forward from gapStyle) ──────────

  @override
  double? get size => gapStyle?.size;

  @override
  double? get crossAxisExtent => gapStyle?.crossAxisExtent;

  @override
  CoreColor? get color => gapStyle?.color;

  /// Returns a copy of this [MaxGap] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  MaxGap copyWith({Key? key, CoreGapStyle? gapStyle}) {
    return MaxGap(key: key ?? this.key, gapStyle: gapStyle ?? this.gapStyle);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMaxGap(context, gapStyle: gapStyle);
    return Flexible(
      child: _RawMaxGap(
        mainAxisExtent: resolved.size,
        crossAxisExtent: resolved.crossAxisExtent,
        color: resolved.color,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreGapStyle] patch into
/// [MaxGap.gapStyle] without hand-reconstructing every field. Mirrors
/// the Web `MaxGap.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreGapStyle.merge` right-side-wins semantics).
extension MaxGapStyleChain on MaxGap {
  /// Returns a copy of this [MaxGap] with [patch] merged into
  /// [gapStyle] (patch fields win on conflict).
  MaxGap withStyle(CoreGapStyle patch) =>
      copyWith(gapStyle: (gapStyle ?? const CoreGapStyle()).merge(patch));
}

class _RawMaxGap extends LeafRenderObjectWidget {
  const _RawMaxGap({
    required this.mainAxisExtent,
    this.crossAxisExtent,
    this.color,
  });

  final double mainAxisExtent;
  final double? crossAxisExtent;
  final Color? color;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGap(
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent ?? 0,
      color: color,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderGap renderObject) {
    renderObject
      ..mainAxisExtent = mainAxisExtent
      ..crossAxisExtent = crossAxisExtent ?? 0
      ..color = color;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('mainAxisExtent', mainAxisExtent))
      ..add(DoubleProperty('crossAxisExtent', crossAxisExtent, defaultValue: 0))
      ..add(ColorProperty('color', color));
  }
}
