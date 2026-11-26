import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/aspect_ratio_box/aspect_ratio_box_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform aspect-ratio container — direct equivalent
/// of Flutter's `AspectRatio` widget. Constrains the wrapper to a
/// fixed width-to-height [ratio] using the CSS `padding-top`
/// percentage trick and lays the [child] inside an absolutely
/// positioned content layer.
///
/// ```dart
/// AspectRatioBox(
///   ratio: 16 / 9,
///   child: img(src: 'image.jpg'),
/// )
/// ```
class AspectRatioBox extends UiComponent
    implements CoreAspectRatioBoxContract<Component> {
  /// Creates a [AspectRatioBox].
  const AspectRatioBox({
    required this.child,
    required this.ratio,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  /// Width-to-height ratio (`width / height`). Must be a finite
  /// positive value. Non-positive / `NaN` values fall back to the
  /// surrounding
  /// `CoreComponentTheme.aspectRatioBox.style.defaultRatio`, then to
  /// the design-system default `1.0`.
  @override
  final double ratio;

  /// Child laid out inside the ratio-constrained wrapper.
  @override
  final Component child;

  @override
  AspectRatioBox copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    double? ratio,
    Component? child,
  }) {
    return AspectRatioBox(
      key: key ?? this.key,
      ratio: ratio ?? this.ratio,
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
    final resolved = resolveAspectRatioBox(context, ratio: ratio);
    return div(
      [
        // Spacer that holds the aspect ratio open via padding-top%.
        div(
          const [],
          classes: resolved.spacer.className,
          styles: resolved.spacer.inlineStyles,
        ),
        // Content layer pinned to the wrapper.
        div(
          [child],
          classes: resolved.content.className,
          styles: resolved.content.inlineStyles,
        ),
      ],
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
