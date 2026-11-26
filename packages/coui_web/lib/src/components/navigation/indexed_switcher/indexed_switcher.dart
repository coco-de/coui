import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/navigation/indexed_switcher/indexed_switcher_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Shows one of [children] at a time, keeps every child built, and fades
/// through when [index] changes.
///
/// The switch between top-level destinations — the screens a
/// `NavigationBar`, rail or sidebar moves between. Every child stays in
/// the document while hidden, so a destination keeps its scroll position
/// and input when the user comes back. The switch itself is a fade
/// through: the outgoing view fades out, then the incoming view fades in
/// (see [CoreIndexedSwitcherStyle]).
///
/// Only the shown child takes pointer input, keyboard focus and a place in
/// the accessibility tree — every other slot is `inert`, including the one
/// still fading out.
///
/// The switch is a CSS transition between two rendered states, so it runs
/// wherever the index changes on the client; the first paint shows the
/// indexed child at once. A reduced-motion request makes the switch
/// instant.
class IndexedSwitcher extends UiComponent
    implements CoreIndexedSwitcherContract<Component> {
  /// Creates an [IndexedSwitcher].
  const IndexedSwitcher({
    required this.children,
    this.index = 0,
    this.indexedSwitcherStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final int index;

  @override
  final CoreIndexedSwitcherStyle? indexedSwitcherStyle;

  @override
  final List<Component> children;

  @override
  IndexedSwitcher copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    int? index,
    CoreIndexedSwitcherStyle? indexedSwitcherStyle,
    List<Component>? children,
  }) {
    return IndexedSwitcher(
      key: key ?? this.key,
      index: index ?? this.index,
      indexedSwitcherStyle: indexedSwitcherStyle ?? this.indexedSwitcherStyle,
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
    final resolved = resolveIndexedSwitcher(
      context,
      indexedSwitcherStyle: indexedSwitcherStyle,
    );

    // One slot per child at a fixed position, whatever the index: the
    // browser keeps each slot's element across renders, which is what lets
    // the change of state run as a transition and keeps the child's DOM.
    final slots = <Component>[
      for (var i = 0; i < children.length; i++)
        if (i == index)
          div(
            [children[i]],
            classes: resolved.shownSlot.className,
            styles: resolved.shownSlot.inlineStyles,
          )
        else
          div(
            [children[i]],
            classes: resolved.hiddenSlot.className,
            styles: resolved.hiddenSlot.inlineStyles,
            attributes: const {'inert': ''},
          ),
    ];

    return div(
      slots,
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

/// Generic `withStyle` chain over `CoreIndexedSwitcherStyle.merge`.
extension IndexedSwitcherStyleChain on IndexedSwitcher {
  /// Returns a copy whose style has [patch] merged on top.
  IndexedSwitcher withStyle(CoreIndexedSwitcherStyle patch) => copyWith(
    indexedSwitcherStyle:
        (indexedSwitcherStyle ?? const CoreIndexedSwitcherStyle()).merge(
          patch,
        ),
  );
}
