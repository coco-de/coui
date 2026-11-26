import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/hidden/hidden_style.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified collapse-toggle container for CoUI Web.
///
/// Mirrors Flutter `Hidden` — fades and collapses its [child] when
/// [hidden] is `true`. Uses CSS `opacity` + `max-height` / `max-width`
/// transitions, timed by the same [duration] and [curve] tokens the
/// Flutter twin reads ([curve] becomes the `cubic-bezier(...)` timing
/// function of that shorthand).
class Hidden extends UiComponent implements CoreHiddenContract<Component> {
  /// Creates a [Hidden].
  const Hidden({
    required this.child,
    required this.hidden,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.direction,
    this.duration,
    this.keepSpace,
    this.reverse,
    this.curve,
    this.semanticLabel,
  }) : super(tag: 'div');

  @override
  final Component child;

  @override
  final bool hidden;

  @override
  final CoreHiddenDirection? direction;

  @override
  final Duration? duration;

  @override
  final bool? keepSpace;

  @override
  final bool? reverse;

  @override
  final CoreCubicBezier? curve;

  @override
  final String? semanticLabel;

  @override
  Hidden copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    bool? hidden,
    CoreHiddenDirection? direction,
    Duration? duration,
    bool? keepSpace,
    bool? reverse,
    CoreCubicBezier? curve,
    String? semanticLabel,
    Component? child,
  }) {
    return Hidden(
      key: key ?? this.key,
      hidden: hidden ?? this.hidden,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      direction: direction ?? this.direction,
      duration: duration ?? this.duration,
      keepSpace: keepSpace ?? this.keepSpace,
      reverse: reverse ?? this.reverse,
      curve: curve ?? this.curve,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveHidden(
      context,
      hidden: hidden,
      direction: direction,
      duration: duration,
      keepSpace: keepSpace,
      reverse: reverse,
      curve: curve,
    );

    final attrs = {
      ...componentAttributes,
      'aria-hidden': '$hidden',
      'data-state': hidden ? WebLayout.hidden : 'visible',
    };
    final label = semanticLabel;
    if (label != null) attrs['aria-label'] = label;

    return div(
      [child],
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: attrs,
      events: events.isEmpty ? null : events,
    );
  }
}
