import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/gap/gap_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Web variant of Flutter `SliverGap`.
///
/// Web has no sliver protocol, so this component renders as a
/// `Gap`-equivalent flex spacer. The API mirrors
/// `gap_package.SliverGap` so existing Flutter call-sites that
/// cross-compile to Web don't break.
class SliverGap extends UiComponent implements CoreSliverGapContract {
  /// Creates a [SliverGap] with an optional [gapStyle] override.
  const SliverGap({
    this.gapStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  // ───── Spacing token chaining constructors ─────────────

  /// 0px sliver gap.
  const SliverGap.space0({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space0),
       super(tag: 'div');

  /// 2px sliver gap.
  const SliverGap.space2({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space2),
       super(tag: 'div');

  /// 4px sliver gap.
  const SliverGap.space4({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space4),
       super(tag: 'div');

  /// 6px sliver gap.
  const SliverGap.space6({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space6),
       super(tag: 'div');

  /// 8px sliver gap.
  const SliverGap.space8({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space8),
       super(tag: 'div');

  /// 10px sliver gap.
  const SliverGap.space10({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space10),
       super(tag: 'div');

  /// 12px sliver gap.
  const SliverGap.space12({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space12),
       super(tag: 'div');

  /// 14px sliver gap.
  const SliverGap.space14({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space14),
       super(tag: 'div');

  /// 16px sliver gap.
  const SliverGap.space16({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space16),
       super(tag: 'div');

  /// 18px sliver gap.
  const SliverGap.space18({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space18),
       super(tag: 'div');

  /// 20px sliver gap.
  const SliverGap.space20({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space20),
       super(tag: 'div');

  /// 24px sliver gap.
  const SliverGap.space24({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space24),
       super(tag: 'div');

  /// 28px sliver gap.
  const SliverGap.space28({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space28),
       super(tag: 'div');

  /// 32px sliver gap.
  const SliverGap.space32({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space32),
       super(tag: 'div');

  /// 36px sliver gap.
  const SliverGap.space36({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space36),
       super(tag: 'div');

  /// 40px sliver gap.
  const SliverGap.space40({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space40),
       super(tag: 'div');

  /// 44px sliver gap.
  const SliverGap.space44({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space44),
       super(tag: 'div');

  /// 48px sliver gap.
  const SliverGap.space48({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space48),
       super(tag: 'div');

  /// 52px sliver gap.
  const SliverGap.space52({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space52),
       super(tag: 'div');

  /// 56px sliver gap.
  const SliverGap.space56({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space56),
       super(tag: 'div');

  /// 60px sliver gap.
  const SliverGap.space60({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space60),
       super(tag: 'div');

  /// 64px sliver gap.
  const SliverGap.space64({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space64),
       super(tag: 'div');

  /// 72px sliver gap.
  const SliverGap.space72({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space72),
       super(tag: 'div');

  /// 80px sliver gap.
  const SliverGap.space80({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space80),
       super(tag: 'div');

  /// 88px sliver gap.
  const SliverGap.space88({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space88),
       super(tag: 'div');

  /// 96px sliver gap.
  const SliverGap.space96({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space96),
       super(tag: 'div');

  /// 104px sliver gap.
  const SliverGap.space104({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space104),
       super(tag: 'div');

  /// 112px sliver gap.
  const SliverGap.space112({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space112),
       super(tag: 'div');

  /// 120px sliver gap.
  const SliverGap.space120({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space120),
       super(tag: 'div');

  /// 128px sliver gap.
  const SliverGap.space128({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space128),
       super(tag: 'div');

  /// 136px sliver gap.
  const SliverGap.space136({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space136),
       super(tag: 'div');

  /// 144px sliver gap.
  const SliverGap.space144({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space144),
       super(tag: 'div');

  /// 152px sliver gap.
  const SliverGap.space152({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space152),
       super(tag: 'div');

  /// 160px sliver gap.
  const SliverGap.space160({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space160),
       super(tag: 'div');

  /// 168px sliver gap.
  const SliverGap.space168({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space168),
       super(tag: 'div');

  /// 176px sliver gap.
  const SliverGap.space176({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space176),
       super(tag: 'div');

  /// 184px sliver gap.
  const SliverGap.space184({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space184),
       super(tag: 'div');

  /// 192px sliver gap.
  const SliverGap.space192({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space192),
       super(tag: 'div');

  /// 200px sliver gap.
  const SliverGap.space200({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space200),
       super(tag: 'div');

  /// 208px sliver gap.
  const SliverGap.space208({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space208),
       super(tag: 'div');

  /// 216px sliver gap.
  const SliverGap.space216({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space216),
       super(tag: 'div');

  /// 224px sliver gap.
  const SliverGap.space224({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space224),
       super(tag: 'div');

  /// 232px sliver gap.
  const SliverGap.space232({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space232),
       super(tag: 'div');

  /// 240px sliver gap.
  const SliverGap.space240({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space240),
       super(tag: 'div');

  /// 248px sliver gap.
  const SliverGap.space248({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space248),
       super(tag: 'div');

  /// 256px sliver gap.
  const SliverGap.space256({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space256),
       super(tag: 'div');

  /// Per-instance style override.
  final CoreGapStyle? gapStyle;

  // ───── CoreSliverGapContract getters (forward from gapStyle) ──────────

  @override
  double? get size => gapStyle?.size;

  @override
  CoreColor? get color => gapStyle?.color;
  @override
  SliverGap copyWith({
    CoreGapStyle? gapStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return SliverGap(
      key: key ?? this.key,
      gapStyle: gapStyle ?? this.gapStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveSliverGap(context, gapStyle: gapStyle);
    return div(
      [],
      id: id,
      classes: mergeClasses(resolved.root.className, classes),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }
}

/// Chain sugar mirroring the Flutter `SliverGap.withStyle` extension —
/// merges a [CoreGapStyle] patch into [SliverGap.gapStyle] via the
/// existing [SliverGap.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreGapStyle.merge` right-side-wins semantics).
extension SliverGapStyleChain on SliverGap {
  /// Returns a copy of this [SliverGap] with [patch] merged into
  /// [gapStyle] (patch fields win on conflict).
  SliverGap withStyle(CoreGapStyle patch) =>
      copyWith(gapStyle: (gapStyle ?? const CoreGapStyle()).merge(patch));
}
