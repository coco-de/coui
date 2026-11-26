import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/panel_header/panel_header_style.dart';
import 'package:coui_web/src/components/text/text_block/text_block_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform panel head — the panel's title, and one action at
/// the end of the row.
///
/// Uses [CorePanelHeaderContract] from `coui_core`, so the Flutter
/// `PanelHeader` takes the same named properties. The title takes the width
/// the action leaves and wraps; once that would fall under
/// [CorePanelHeaderStyle.minTitleWidth], the action moves under the title,
/// start aligned — the rule `PageHeader` follows.
///
/// ```dart
/// PanelHeader(
///   title: const Text('Recent files'),
///   action: Button(
///     variant: .plain,
///     size: .sm,
///     onPressed: showAll,
///     child: const Text('All'),
///   ),
/// )
/// ```
class PanelHeader extends UiComponent
    implements CorePanelHeaderContract<Component> {
  /// Creates a [PanelHeader].
  const PanelHeader({
    required this.title,
    super.key,
    this.action,
    this.headingLevel = CorePanelHeaderContract.defaultHeadingLevel,
    this.panelHeaderStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : assert(
         headingLevel >= 1 && headingLevel <= 6,
         'a heading level is 1–6',
       ),
       super(tag: 'div');

  @override
  final Component title;

  @override
  final Component? action;

  @override
  final int headingLevel;

  @override
  final CorePanelHeaderStyle? panelHeaderStyle;

  @override
  PanelHeader copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? title,
    Component? action,
    int? headingLevel,
    CorePanelHeaderStyle? panelHeaderStyle,
  }) {
    return PanelHeader(
      key: key ?? this.key,
      title: title ?? this.title,
      action: action ?? this.action,
      headingLevel: headingLevel ?? this.headingLevel,
      panelHeaderStyle: panelHeaderStyle ?? this.panelHeaderStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolvePanelHeader(
      context,
      panelHeaderStyle: panelHeaderStyle,
    );

    return div(
      [
        Component.element(
          tag: textBlockElementTag(CoreTextBlockElement.heading(headingLevel)),
          classes: resolved.title.className,
          styles: resolved.title.inlineStyles,
          children: [title],
        ),
        if (action case final action?)
          div(
            [action],
            classes: resolved.action.className,
            styles: resolved.action.inlineStyles,
          ),
      ],
      id: id,
      classes: mergeClasses(resolved.root.className, classes),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }
}

/// Chain sugar for merging a [CorePanelHeaderStyle] patch into
/// [PanelHeader.panelHeaderStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `PanelHeader.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePanelHeaderStyle.merge` right-side-wins semantics).
extension PanelHeaderStyleChain on PanelHeader {
  /// Returns a copy of this [PanelHeader] with [patch] merged into
  /// [panelHeaderStyle] (patch fields win on conflict).
  PanelHeader withStyle(CorePanelHeaderStyle patch) => copyWith(
    panelHeaderStyle: (panelHeaderStyle ?? const CorePanelHeaderStyle()).merge(
      patch,
    ),
  );
}
