import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/gap/gap_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Flexible gap that takes at most `gapStyle.size` along the parent
/// flex main axis and shrinks when the parent is too small.
///
/// Mirrors Flutter `MaxGap`. On Web the shrink behaviour comes from
/// CSS `flex-shrink: 1` (unlike `Gap` which pins `flex-shrink: 0`).
///
/// Example:
/// ```dart
/// div(
///   [
///     text('A'),
///     MaxGap.space16(),
///     text('B'),
///   ],
///   classes: 'flex',
/// )
/// ```
class MaxGap extends UiComponent implements CoreMaxGapContract {
  /// Creates a [MaxGap] with an optional [gapStyle] override.
  const MaxGap({
    this.gapStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  /// Creates a [MaxGap] that expands to fill the parent's cross
  /// axis. Mirrors `gap_package.MaxGap.expand`.
  MaxGap.expand(
    double mainAxisExtent, {
    Key? key,
    String? id,
    CoreColor? color,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
  }) : this(
         key: key,
         gapStyle: CoreGapStyle(
           size: mainAxisExtent,
           crossAxisExtent: .infinity,
           color: color,
         ),
         id: id,
         classes: classes,
         css: css,
         attributes: attributes,
         eventHandlers: eventHandlers,
       );

  // ───── Spacing token chaining constructors ─────────────

  /// 0px max gap.
  const MaxGap.space0({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space0),
       super(tag: 'div');

  /// 2px max gap.
  const MaxGap.space2({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space2),
       super(tag: 'div');

  /// 4px max gap.
  const MaxGap.space4({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space4),
       super(tag: 'div');

  /// 6px max gap.
  const MaxGap.space6({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space6),
       super(tag: 'div');

  /// 8px max gap.
  const MaxGap.space8({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space8),
       super(tag: 'div');

  /// 10px max gap.
  const MaxGap.space10({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space10),
       super(tag: 'div');

  /// 12px max gap.
  const MaxGap.space12({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space12),
       super(tag: 'div');

  /// 14px max gap.
  const MaxGap.space14({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space14),
       super(tag: 'div');

  /// 16px max gap.
  const MaxGap.space16({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space16),
       super(tag: 'div');

  /// 18px max gap.
  const MaxGap.space18({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space18),
       super(tag: 'div');

  /// 20px max gap.
  const MaxGap.space20({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space20),
       super(tag: 'div');

  /// 24px max gap.
  const MaxGap.space24({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space24),
       super(tag: 'div');

  /// 28px max gap.
  const MaxGap.space28({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space28),
       super(tag: 'div');

  /// 32px max gap.
  const MaxGap.space32({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space32),
       super(tag: 'div');

  /// 36px max gap.
  const MaxGap.space36({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space36),
       super(tag: 'div');

  /// 40px max gap.
  const MaxGap.space40({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space40),
       super(tag: 'div');

  /// 44px max gap.
  const MaxGap.space44({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space44),
       super(tag: 'div');

  /// 48px max gap.
  const MaxGap.space48({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space48),
       super(tag: 'div');

  /// 52px max gap.
  const MaxGap.space52({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space52),
       super(tag: 'div');

  /// 56px max gap.
  const MaxGap.space56({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space56),
       super(tag: 'div');

  /// 60px max gap.
  const MaxGap.space60({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space60),
       super(tag: 'div');

  /// 64px max gap.
  const MaxGap.space64({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space64),
       super(tag: 'div');

  /// 72px max gap.
  const MaxGap.space72({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space72),
       super(tag: 'div');

  /// 80px max gap.
  const MaxGap.space80({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space80),
       super(tag: 'div');

  /// 88px max gap.
  const MaxGap.space88({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space88),
       super(tag: 'div');

  /// 96px max gap.
  const MaxGap.space96({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space96),
       super(tag: 'div');

  /// 104px max gap.
  const MaxGap.space104({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space104),
       super(tag: 'div');

  /// 112px max gap.
  const MaxGap.space112({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space112),
       super(tag: 'div');

  /// 120px max gap.
  const MaxGap.space120({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space120),
       super(tag: 'div');

  /// 128px max gap.
  const MaxGap.space128({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space128),
       super(tag: 'div');

  /// 136px max gap.
  const MaxGap.space136({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space136),
       super(tag: 'div');

  /// 144px max gap.
  const MaxGap.space144({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space144),
       super(tag: 'div');

  /// 152px max gap.
  const MaxGap.space152({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space152),
       super(tag: 'div');

  /// 160px max gap.
  const MaxGap.space160({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space160),
       super(tag: 'div');

  /// 168px max gap.
  const MaxGap.space168({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space168),
       super(tag: 'div');

  /// 176px max gap.
  const MaxGap.space176({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space176),
       super(tag: 'div');

  /// 184px max gap.
  const MaxGap.space184({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space184),
       super(tag: 'div');

  /// 192px max gap.
  const MaxGap.space192({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space192),
       super(tag: 'div');

  /// 200px max gap.
  const MaxGap.space200({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space200),
       super(tag: 'div');

  /// 208px max gap.
  const MaxGap.space208({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space208),
       super(tag: 'div');

  /// 216px max gap.
  const MaxGap.space216({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space216),
       super(tag: 'div');

  /// 224px max gap.
  const MaxGap.space224({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space224),
       super(tag: 'div');

  /// 232px max gap.
  const MaxGap.space232({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space232),
       super(tag: 'div');

  /// 240px max gap.
  const MaxGap.space240({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space240),
       super(tag: 'div');

  /// 248px max gap.
  const MaxGap.space248({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space248),
       super(tag: 'div');

  /// 256px max gap.
  const MaxGap.space256({
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

  // ───── CoreMaxGapContract getters (forward from gapStyle) ──────────

  @override
  double? get size => gapStyle?.size;

  @override
  double? get crossAxisExtent => gapStyle?.crossAxisExtent;

  @override
  CoreColor? get color => gapStyle?.color;
  @override
  MaxGap copyWith({
    CoreGapStyle? gapStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return MaxGap(
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
    final resolved = resolveMaxGap(context, gapStyle: gapStyle);
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

/// Chain sugar mirroring the Flutter `MaxGap.withStyle` extension —
/// merges a [CoreGapStyle] patch into [MaxGap.gapStyle] via the
/// existing [MaxGap.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreGapStyle.merge` right-side-wins semantics).
extension MaxGapStyleChain on MaxGap {
  /// Returns a copy of this [MaxGap] with [patch] merged into
  /// [gapStyle] (patch fields win on conflict).
  MaxGap withStyle(CoreGapStyle patch) =>
      copyWith(gapStyle: (gapStyle ?? const CoreGapStyle()).merge(patch));
}
