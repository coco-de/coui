import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/gap/render_sliver_gap.dart';
import 'package:flutter/foundation.dart';

/// Sliver variant of [Gap] for use inside `CustomScrollView` and
/// other sliver lists.
///
/// Mirrors `gap_package.SliverGap`. Takes a fixed main-axis extent
/// from the sliver constraints — the parent decides the cross axis.
class SliverGap extends StatelessWidget implements CoreSliverGapContract {
  /// Creates a [SliverGap] with an optional [gapStyle] override.
  const SliverGap({this.gapStyle, super.key});

  // ───── Spacing token chaining constructors ─────────────

  /// 0px sliver gap.
  const SliverGap.space0({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space0);

  /// 2px sliver gap.
  const SliverGap.space2({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space2);

  /// 4px sliver gap.
  const SliverGap.space4({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space4);

  /// 6px sliver gap.
  const SliverGap.space6({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space6);

  /// 8px sliver gap.
  const SliverGap.space8({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space8);

  /// 10px sliver gap.
  const SliverGap.space10({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space10);

  /// 12px sliver gap.
  const SliverGap.space12({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space12);

  /// 14px sliver gap.
  const SliverGap.space14({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space14);

  /// 16px sliver gap.
  const SliverGap.space16({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space16);

  /// 18px sliver gap.
  const SliverGap.space18({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space18);

  /// 20px sliver gap.
  const SliverGap.space20({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space20);

  /// 24px sliver gap.
  const SliverGap.space24({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space24);

  /// 28px sliver gap.
  const SliverGap.space28({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space28);

  /// 32px sliver gap.
  const SliverGap.space32({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space32);

  /// 36px sliver gap.
  const SliverGap.space36({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space36);

  /// 40px sliver gap.
  const SliverGap.space40({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space40);

  /// 44px sliver gap.
  const SliverGap.space44({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space44);

  /// 48px sliver gap.
  const SliverGap.space48({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space48);

  /// 52px sliver gap.
  const SliverGap.space52({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space52);

  /// 56px sliver gap.
  const SliverGap.space56({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space56);

  /// 60px sliver gap.
  const SliverGap.space60({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space60);

  /// 64px sliver gap.
  const SliverGap.space64({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space64);

  /// 72px sliver gap.
  const SliverGap.space72({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space72);

  /// 80px sliver gap.
  const SliverGap.space80({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space80);

  /// 88px sliver gap.
  const SliverGap.space88({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space88);

  /// 96px sliver gap.
  const SliverGap.space96({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space96);

  /// 104px sliver gap.
  const SliverGap.space104({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space104);

  /// 112px sliver gap.
  const SliverGap.space112({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space112);

  /// 120px sliver gap.
  const SliverGap.space120({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space120);

  /// 128px sliver gap.
  const SliverGap.space128({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space128);

  /// 136px sliver gap.
  const SliverGap.space136({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space136);

  /// 144px sliver gap.
  const SliverGap.space144({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space144);

  /// 152px sliver gap.
  const SliverGap.space152({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space152);

  /// 160px sliver gap.
  const SliverGap.space160({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space160);

  /// 168px sliver gap.
  const SliverGap.space168({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space168);

  /// 176px sliver gap.
  const SliverGap.space176({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space176);

  /// 184px sliver gap.
  const SliverGap.space184({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space184);

  /// 192px sliver gap.
  const SliverGap.space192({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space192);

  /// 200px sliver gap.
  const SliverGap.space200({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space200);

  /// 208px sliver gap.
  const SliverGap.space208({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space208);

  /// 216px sliver gap.
  const SliverGap.space216({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space216);

  /// 224px sliver gap.
  const SliverGap.space224({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space224);

  /// 232px sliver gap.
  const SliverGap.space232({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space232);

  /// 240px sliver gap.
  const SliverGap.space240({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space240);

  /// 248px sliver gap.
  const SliverGap.space248({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space248);

  /// 256px sliver gap.
  const SliverGap.space256({super.key})
    : gapStyle = const CoreGapStyle(size: CoreSpace.space256);

  /// Per-instance style override.
  final CoreGapStyle? gapStyle;

  // ───── CoreSliverGapContract getters (forward from gapStyle) ──────────

  @override
  double? get size => gapStyle?.size;

  @override
  CoreColor? get color => gapStyle?.color;

  /// Returns a copy of this [SliverGap] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  SliverGap copyWith({Key? key, CoreGapStyle? gapStyle}) {
    return SliverGap(key: key ?? this.key, gapStyle: gapStyle ?? this.gapStyle);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSliverGap(context, gapStyle: gapStyle);
    return _RawSliverGap(
      mainAxisExtent: resolved.size,
      color: resolved.color,
    );
  }
}

/// Chain sugar for merging a [CoreGapStyle] patch into
/// [SliverGap.gapStyle] without hand-reconstructing every field. Mirrors
/// the Web `SliverGap.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreGapStyle.merge` right-side-wins semantics).
extension SliverGapStyleChain on SliverGap {
  /// Returns a copy of this [SliverGap] with [patch] merged into
  /// [gapStyle] (patch fields win on conflict).
  SliverGap withStyle(CoreGapStyle patch) =>
      copyWith(gapStyle: (gapStyle ?? const CoreGapStyle()).merge(patch));
}

class _RawSliverGap extends LeafRenderObjectWidget {
  const _RawSliverGap({required this.mainAxisExtent, this.color});

  final double mainAxisExtent;
  final Color? color;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSliverGap(mainAxisExtent: mainAxisExtent, color: color);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverGap renderObject) {
    renderObject
      ..mainAxisExtent = mainAxisExtent
      ..color = color;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('mainAxisExtent', mainAxisExtent))
      ..add(ColorProperty('color', color));
  }
}
