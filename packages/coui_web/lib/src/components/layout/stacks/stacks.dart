import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/stacks/stacks_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform z-stack layout — direct equivalent of Flutter's
/// `Stack`. Renders [children] inside a CSS Grid single cell so each
/// non-positioned child overlaps the others, and forwards `Position`
/// children to absolute positioning (Flutter `Positioned` parity).
///
/// ```dart
/// Stacks(
///   children: [
///     someBackground,
///     Position(top: 8, right: 8, child: badge),
///   ],
/// )
/// ```
class Stacks extends UiComponent implements CoreStacksContract<Component> {
  /// Creates a [Stacks].
  const Stacks({
    required this.children,
    this.alignment = CoreAlignment.topStart,
    this.fit = CoreStackFit.loose,
    this.clipBehavior = CoreClipBehavior.hardEdge,
    this.textDirection,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<Component> children;

  @override
  final CoreAlignment alignment;

  @override
  final CoreStackFit fit;

  @override
  final CoreClipBehavior clipBehavior;

  @override
  final CoreTextDirection? textDirection;

  @override
  Stacks copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    CoreAlignment? alignment,
    CoreStackFit? fit,
    CoreClipBehavior? clipBehavior,
    CoreTextDirection? textDirection,
    List<Component>? children,
  }) {
    return Stacks(
      key: key ?? this.key,
      alignment: alignment ?? this.alignment,
      fit: fit ?? this.fit,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      textDirection: textDirection ?? this.textDirection,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? this.children,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveStacks(
      context,
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
    );

    // Wrap each non-`Position` child in an absolute-positioned
    // layer anchored by the resolved alignment. `Position`
    // children render their own absolute positioning (see
    // [Position.build]) and bypass the layer anchor.
    final wrapped = <Component>[
      for (final child in children)
        if (child is Position)
          child
        else
          div(
            [child],
            classes: resolved.layer.className,
            styles: resolved.layer.inlineStyles,
          ),
    ];

    final dirAttr = switch (textDirection) {
      null => null,
      .ltr => {'dir': 'ltr'},
      .rtl => {'dir': 'rtl'},
    };
    final mergedAttrs = {...componentAttributes, ...?dirAttr};

    return div(
      wrapped,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: mergedAttrs.isEmpty ? null : mergedAttrs,
      events: events.isEmpty ? null : events,
    );
  }
}

/// Unified cross-platform `Positioned` — direct equivalent of Flutter's
/// `Positioned`. Used inside a [Stacks] to place [child] at
/// explicit coordinates relative to the stack's edges.
///
/// ```dart
/// Stacks(
///   children: [
///     background,
///     Position(top: 8, right: 8, child: badge),
///   ],
/// )
/// ```
class Position extends UiComponent implements CorePositionContract<Component> {
  /// Creates a [Position].
  const Position({
    required this.child,
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.width,
    this.height,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  /// Convenience constructor matching Flutter's `Positioned.fill` —
  /// pins all four sides to the surrounding stack so [child] fills
  /// the entire box.
  const Position.fill({
    required this.child,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    this.left = 0.0,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : width = null,
       height = null,
       super(tag: 'div');

  @override
  final Component? child;

  @override
  final double? top;

  @override
  final double? right;

  @override
  final double? bottom;

  @override
  final double? left;

  @override
  final double? width;

  @override
  final double? height;

  @override
  Position copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    double? top,
    double? right,
    double? bottom,
    double? left,
    double? width,
    double? height,
    Component? child,
  }) {
    return Position(
      key: key ?? this.key,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      width: width ?? this.width,
      height: height ?? this.height,
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
    final resolved = resolvePosition(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      width: width,
      height: height,
    );
    return div(
      [?child],
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
