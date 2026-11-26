import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/mask/mask_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified mask component for CoUI Web.
///
/// Wraps [child] in a `<div class="mask mask-{shape}">` container, relying on
/// daisyUI CSS `mask-image` definitions for the actual clipping.
///
/// Mirrors Flutter `Mask` — same parameter names and visual outcome.
class Mask extends UiComponent implements CoreMaskContract<Component> {
  /// Creates a [Mask].
  const Mask({
    required this.child,
    super.key,
    this.shape = .squircle,
    this.half = .none,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component child;

  @override
  final CoreMaskShape shape;

  @override
  final CoreMaskHalf half;

  @override
  Mask copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    CoreMaskShape? shape,
    CoreMaskHalf? half,
    Component? child,
  }) {
    return Mask(
      key: key ?? this.key,
      shape: shape ?? this.shape,
      half: half ?? this.half,
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
    final resolved = resolveMask(
      context,
      shape: shape,
      half: half,
    );

    return div(
      [child],
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }
}
