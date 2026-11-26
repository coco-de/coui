import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/responsive_container/responsive_container_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Horizontally-centred, max-width-constrained layout wrapper for
/// CoUI Web.
///
/// Mirrors Flutter's `ResponsiveContainer` with identical parameters
/// and defaults. Rendered as a single `<div>` carrying the `w-full`
/// Tailwind utility class plus the inline-CSS bundle (`max-width`,
/// optional `margin-left: auto` / `margin-right: auto`, and horizontal
/// `padding`). All chrome is pre-composed by
/// [resolveResponsiveContainer]; this widget only reads
/// `resolved.root.*` back into `div(...)`.
class ResponsiveContainer extends UiComponent
    implements CoreResponsiveContainerContract<Component> {
  /// Creates a [ResponsiveContainer].
  const ResponsiveContainer({
    required this.child,
    super.key,
    this.maxWidth,
    this.responsiveMaxWidth,
    this.centered,
    this.padding,
    this.responsiveContainerStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component child;

  @override
  final CoreResponsiveContainerMaxWidth? maxWidth;

  @override
  final Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>?
  responsiveMaxWidth;

  @override
  final bool? centered;

  @override
  final CoreEdgeInsets? padding;

  @override
  final CoreResponsiveContainerStyle? responsiveContainerStyle;

  @override
  ResponsiveContainer copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    CoreResponsiveContainerMaxWidth? maxWidth,
    Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>?
    responsiveMaxWidth,
    bool? centered,
    CoreEdgeInsets? padding,
    CoreResponsiveContainerStyle? responsiveContainerStyle,
    Component? child,
  }) {
    return ResponsiveContainer(
      key: key ?? this.key,
      maxWidth: maxWidth ?? this.maxWidth,
      responsiveMaxWidth: responsiveMaxWidth ?? this.responsiveMaxWidth,
      centered: centered ?? this.centered,
      padding: padding ?? this.padding,
      responsiveContainerStyle:
          responsiveContainerStyle ?? this.responsiveContainerStyle,
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
    final resolved = resolveResponsiveContainer(
      context,
      maxWidth: maxWidth,
      responsiveMaxWidth: responsiveMaxWidth,
      centered: centered,
      padding: padding,
      responsiveContainerStyle: responsiveContainerStyle,
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

/// Chain sugar mirroring the Flutter `ResponsiveContainer.withStyle`
/// extension — merges a [CoreResponsiveContainerStyle] patch into
/// [ResponsiveContainer.responsiveContainerStyle] via the existing
/// [ResponsiveContainer.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreResponsiveContainerStyle.merge` right-side-wins
/// semantics).
extension ResponsiveContainerStyleChain on ResponsiveContainer {
  /// Returns a copy of this [ResponsiveContainer] with [patch] merged
  /// into [responsiveContainerStyle] (patch fields win on conflict).
  ResponsiveContainer withStyle(CoreResponsiveContainerStyle patch) => copyWith(
    responsiveContainerStyle:
        (responsiveContainerStyle ?? const CoreResponsiveContainerStyle())
            .merge(patch),
  );
}
