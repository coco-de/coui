import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/gap/gap_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified gap component for Web.
///
/// Adds spacing along the parent flex axis via CSS `flex-basis`.
/// The gap automatically sizes itself along the main axis based on
/// the parent's `flex-direction` — no axis parameter required.
///
/// Mirrors Flutter `Gap`. All chrome (`size`, `crossAxisExtent`,
/// `color`) lives in [gapStyle]; for common spacing tokens prefer
/// the `Gap.spaceN()` named constructors which fold a `const
/// CoreGapStyle(size: CoreSpace.spaceN)` for you.
///
/// Example:
/// ```dart
/// div(
///   [
///     text('First'),
///     Gap.space16(),
///     text('Second'),
///   ],
///   classes: 'flex flex-col',
/// )
/// ```
class Gap extends UiComponent implements CoreGapContract {
  /// Creates a [Gap] with an optional [gapStyle] override.
  ///
  /// When [gapStyle] is `null` the resolver falls back to
  /// `CoreGapTheme.style` and finally to `CoreGapStyle.defaultSize`.
  const Gap({
    this.gapStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  /// Creates a [Gap] that fills the parent's cross axis while
  /// taking [mainAxisExtent] along the main axis. Mirrors
  /// `gap_package.Gap.expand`.
  Gap.expand(
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
  // One per `CoreSpace.spaceN` constant — each folds a `const
  // CoreGapStyle(size: CoreSpace.spaceN)` so call-sites stay const.

  /// 0px gap.
  const Gap.space0({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space0),
       super(tag: 'div');

  /// 2px gap.
  const Gap.space2({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space2),
       super(tag: 'div');

  /// 4px gap (design-system default).
  const Gap.space4({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space4),
       super(tag: 'div');

  /// 6px gap.
  const Gap.space6({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space6),
       super(tag: 'div');

  /// 8px gap.
  const Gap.space8({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space8),
       super(tag: 'div');

  /// 10px gap.
  const Gap.space10({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space10),
       super(tag: 'div');

  /// 12px gap.
  const Gap.space12({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space12),
       super(tag: 'div');

  /// 14px gap.
  const Gap.space14({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space14),
       super(tag: 'div');

  /// 16px gap.
  const Gap.space16({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space16),
       super(tag: 'div');

  /// 18px gap.
  const Gap.space18({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space18),
       super(tag: 'div');

  /// 20px gap.
  const Gap.space20({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space20),
       super(tag: 'div');

  /// 24px gap.
  const Gap.space24({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space24),
       super(tag: 'div');

  /// 28px gap.
  const Gap.space28({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space28),
       super(tag: 'div');

  /// 32px gap.
  const Gap.space32({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space32),
       super(tag: 'div');

  /// 36px gap.
  const Gap.space36({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space36),
       super(tag: 'div');

  /// 40px gap.
  const Gap.space40({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space40),
       super(tag: 'div');

  /// 44px gap.
  const Gap.space44({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space44),
       super(tag: 'div');

  /// 48px gap.
  const Gap.space48({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space48),
       super(tag: 'div');

  /// 52px gap.
  const Gap.space52({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space52),
       super(tag: 'div');

  /// 56px gap.
  const Gap.space56({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space56),
       super(tag: 'div');

  /// 60px gap.
  const Gap.space60({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space60),
       super(tag: 'div');

  /// 64px gap.
  const Gap.space64({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space64),
       super(tag: 'div');

  /// 72px gap.
  const Gap.space72({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space72),
       super(tag: 'div');

  /// 80px gap.
  const Gap.space80({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space80),
       super(tag: 'div');

  /// 88px gap.
  const Gap.space88({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space88),
       super(tag: 'div');

  /// 96px gap.
  const Gap.space96({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space96),
       super(tag: 'div');

  /// 104px gap.
  const Gap.space104({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space104),
       super(tag: 'div');

  /// 112px gap.
  const Gap.space112({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space112),
       super(tag: 'div');

  /// 120px gap.
  const Gap.space120({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space120),
       super(tag: 'div');

  /// 128px gap.
  const Gap.space128({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space128),
       super(tag: 'div');

  /// 136px gap.
  const Gap.space136({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space136),
       super(tag: 'div');

  /// 144px gap.
  const Gap.space144({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space144),
       super(tag: 'div');

  /// 152px gap.
  const Gap.space152({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space152),
       super(tag: 'div');

  /// 160px gap.
  const Gap.space160({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space160),
       super(tag: 'div');

  /// 168px gap.
  const Gap.space168({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space168),
       super(tag: 'div');

  /// 176px gap.
  const Gap.space176({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space176),
       super(tag: 'div');

  /// 184px gap.
  const Gap.space184({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space184),
       super(tag: 'div');

  /// 192px gap.
  const Gap.space192({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space192),
       super(tag: 'div');

  /// 200px gap.
  const Gap.space200({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space200),
       super(tag: 'div');

  /// 208px gap.
  const Gap.space208({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space208),
       super(tag: 'div');

  /// 216px gap.
  const Gap.space216({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space216),
       super(tag: 'div');

  /// 224px gap.
  const Gap.space224({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space224),
       super(tag: 'div');

  /// 232px gap.
  const Gap.space232({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space232),
       super(tag: 'div');

  /// 240px gap.
  const Gap.space240({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space240),
       super(tag: 'div');

  /// 248px gap.
  const Gap.space248({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space248),
       super(tag: 'div');

  /// 256px gap.
  const Gap.space256({
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : gapStyle = const CoreGapStyle(size: CoreSpace.space256),
       super(tag: 'div');

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
  @override
  Gap copyWith({
    CoreGapStyle? gapStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Gap(
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
    final resolved = resolveGap(context, gapStyle: gapStyle);
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

/// Chain sugar mirroring the Flutter `Gap.withStyle` extension —
/// merges a [CoreGapStyle] patch into [Gap.gapStyle] via the
/// existing [Gap.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreGapStyle.merge` right-side-wins semantics).
extension GapStyleChain on Gap {
  /// Returns a copy of this [Gap] with [patch] merged into [gapStyle]
  /// (patch fields win on conflict).
  Gap withStyle(CoreGapStyle patch) =>
      copyWith(gapStyle: (gapStyle ?? const CoreGapStyle()).merge(patch));
}
