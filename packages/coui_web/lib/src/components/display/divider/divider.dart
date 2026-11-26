import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/divider/divider_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/core_to_css.dart' show CoreSemanticRoleToAria;
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified divider line for CoUI Web.
///
/// Renders a thin line to visually separate content, optionally with a
/// centered [child]. All chrome / dimensional overrides flow through
/// [dividerStyle] (Epic #1415 option D).
///
/// Per Epic #1603 (옵션 B 최종) the widget is render-only — it calls
/// `resolveDivider` once and reads `resolved.<slot>.className /
/// inlineStyles` straight through. The branch (single line vs grid
/// wrapper + child) is picked from the widget's own `child` slot.
///
/// Per rule 10 (CLAUDE.md) the component owns a single styled DOM root
/// (`resolved.root` is always the outermost `<div>`), so it extends
/// [UiComponent] — the child-mode inner slots render beneath that root.
class Divider extends UiComponent implements CoreDividerContract<Component> {
  /// Creates a [Divider].
  const Divider({
    this.orientation = CoreDividerOrientation.horizontal,
    this.child,
    this.dividerStyle,
    this.semantic = false,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component? child;

  @override
  final CoreDividerOrientation orientation;

  @override
  final CoreDividerStyle? dividerStyle;

  @override
  final bool semantic;
  @override
  Component build(BuildContext context) {
    final currentChild = child;
    final resolved = resolveDivider(
      context,
      orientation: orientation,
      hasChild: currentChild != null,
      dividerStyle: dividerStyle,
    );

    final rootClasses = [
      resolved.root.className,
      ?classes,
    ].join(' ').trim();
    final rootStyles = Styles.combine([
      ?resolved.root.inlineStyles,
      ?css,
    ]);

    // A group boundary (e.g. inside `Menu`) states `role="separator"`
    // (`CoreSemanticRole.separator` — the same ARIA spelling the
    // focusable "window splitter" pattern uses; ARIA distinguishes the
    // two by `tabindex`/`aria-value*`, not by role name, so this widget
    // does not add either) plus an explicit `aria-label`, mirroring the
    // Flutter `Divider`'s `Semantics(label:)`. A bare decorative
    // `Divider` (the default) stays silent to assistive tech.
    final rootAttributes = semantic
        ? {
            ...componentAttributes,
            'role': CoreSemanticRole.separator.ariaRole,
            'aria-label': CouiLocalizations.of(context).dividerSeparatorLabel,
          }
        : componentAttributes;

    // Single-line branch — `root` carries the line chrome directly.
    if (currentChild == null) {
      return Component.element(
        tag: tag,
        id: id,
        classes: rootClasses,
        styles: rootStyles,
        attributes: rootAttributes,
        events: events,
        children: const [],
      );
    }

    // Child branch — `root` is the grid wrapper; the three inner
    // slots render the line / child / line layout, one track each.
    return Component.element(
      tag: tag,
      id: id,
      classes: rootClasses,
      styles: rootStyles,
      attributes: rootAttributes,
      events: events,
      children: [
        Component.element(
          tag: 'div',
          classes: resolved.lineLeading.className,
          styles: resolved.lineLeading.inlineStyles,
          children: const [],
        ),
        Component.element(
          tag: 'div',
          classes: resolved.childWrapper.className,
          styles: resolved.childWrapper.inlineStyles,
          children: [currentChild],
        ),
        Component.element(
          tag: 'div',
          classes: resolved.lineTrailing.className,
          styles: resolved.lineTrailing.inlineStyles,
          children: const [],
        ),
      ],
    );
  }

  @override
  Divider copyWith({
    CoreDividerOrientation? orientation,
    Component? child,
    CoreDividerStyle? dividerStyle,
    bool? semantic,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Divider(
      key: key ?? this.key,
      orientation: orientation ?? this.orientation,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      semantic: semantic ?? this.semantic,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }
}

/// Chain sugar mirroring the Flutter `Divider.withStyle` extension —
/// merges a [CoreDividerStyle] patch into [Divider.dividerStyle] via
/// the existing [Divider.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDividerStyle.merge` right-side-wins semantics).
extension DividerStyleChain on Divider {
  /// Returns a copy of this [Divider] with [patch] merged into
  /// [dividerStyle] (patch fields win on conflict).
  Divider withStyle(CoreDividerStyle patch) => copyWith(
    dividerStyle: (dividerStyle ?? const CoreDividerStyle()).merge(patch),
  );
}
