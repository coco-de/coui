import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/indicator/indicator_style.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Wraps a [child] and overlays an [item] on a corner / edge of the bounding
/// box. Mirrors Flutter `Indicator` — same edge anchors, same offset
/// resolution, same `Stack(clipBehavior: .none)` semantics (`overflow:
/// visible` on the wrapper so the overlay can extend past the child).
class Indicator extends UiComponent
    implements CoreIndicatorContract<Component> {
  /// Creates a [Indicator].
  const Indicator({
    required this.item,
    required this.child,
    super.key,
    this.horizontalPosition = CoreIndicatorHorizontalPosition.end,
    this.verticalPosition = CoreIndicatorVerticalPosition.top,
    this.indicatorStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component child;

  @override
  final Component item;

  @override
  final CoreIndicatorHorizontalPosition horizontalPosition;

  @override
  final CoreIndicatorVerticalPosition verticalPosition;

  @override
  final CoreIndicatorStyle? indicatorStyle;

  @override
  Indicator copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? item,
    CoreIndicatorHorizontalPosition? horizontalPosition,
    CoreIndicatorVerticalPosition? verticalPosition,
    CoreIndicatorStyle? indicatorStyle,
    Component? child,
  }) {
    return Indicator(
      key: key ?? this.key,
      item: item ?? this.item,
      horizontalPosition: horizontalPosition ?? this.horizontalPosition,
      verticalPosition: verticalPosition ?? this.verticalPosition,
      indicatorStyle: indicatorStyle ?? this.indicatorStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveIndicator(
      context,
      horizontalPosition: horizontalPosition,
      verticalPosition: verticalPosition,
      indicatorStyle: indicatorStyle,
    );

    return Component.element(
      tag: 'div',
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
      children: [
        child,
        Component.element(
          tag: 'div',
          classes: resolved.overlay.className,
          styles: resolved.overlay.inlineStyles,
          children: [item],
        ),
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `Indicator.withStyle` extension —
/// merges a [CoreIndicatorStyle] patch into [Indicator.indicatorStyle] via
/// the existing [Indicator.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreIndicatorStyle.merge` right-side-wins semantics).
extension IndicatorStyleChain on Indicator {
  /// Returns a copy of this [Indicator] with [patch] merged into
  /// [indicatorStyle] (patch fields win on conflict).
  Indicator withStyle(CoreIndicatorStyle patch) => copyWith(
    indicatorStyle: (indicatorStyle ?? const CoreIndicatorStyle()).merge(patch),
  );
}
