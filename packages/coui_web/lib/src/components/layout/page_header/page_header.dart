import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/page_header/page_header_style.dart';
import 'package:coui_web/src/components/text/text_block/text_block_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform page head — a short eyebrow over the page title,
/// an optional sentence under it, and the page's actions at the end of the
/// row.
///
/// Uses [CorePageHeaderContract] from `coui_core`, so the Flutter
/// `PageHeader` takes the same named properties. The text block takes the
/// width the actions leave; once that would fall under
/// [CorePageHeaderStyle.minTextWidth], the actions move under the text,
/// start aligned, and wrap among themselves if a line of their own is still
/// too narrow — so the header never overflows.
///
/// ```dart
/// PageHeader(
///   eyebrow: const Text('Workspace'),
///   title: const Text('Settings'),
///   actions: [
///     Button(
///       variant: .secondary,
///       onPressed: cancel,
///       child: const Text('Cancel'),
///     ),
///     Button(onPressed: save, child: const Text('Save')),
///   ],
/// )
/// ```
class PageHeader extends UiComponent
    implements CorePageHeaderContract<Component> {
  /// Creates a [PageHeader].
  const PageHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.description,
    this.actions = const [],
    this.headingLevel = CorePageHeaderContract.defaultHeadingLevel,
    this.pageHeaderStyle,
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
  final Component? eyebrow;

  @override
  final Component title;

  @override
  final Component? description;

  @override
  final List<Component> actions;

  @override
  final int headingLevel;

  @override
  final CorePageHeaderStyle? pageHeaderStyle;

  @override
  PageHeader copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? eyebrow,
    Component? title,
    Component? description,
    List<Component>? actions,
    int? headingLevel,
    CorePageHeaderStyle? pageHeaderStyle,
  }) {
    return PageHeader(
      key: key ?? this.key,
      eyebrow: eyebrow ?? this.eyebrow,
      title: title ?? this.title,
      description: description ?? this.description,
      actions: actions ?? this.actions,
      headingLevel: headingLevel ?? this.headingLevel,
      pageHeaderStyle: pageHeaderStyle ?? this.pageHeaderStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolvePageHeader(
      context,
      pageHeaderStyle: pageHeaderStyle,
    );

    final heading = Component.element(
      tag: textBlockElementTag(CoreTextBlockElement.heading(headingLevel)),
      classes: resolved.title.className,
      styles: resolved.title.inlineStyles,
      children: [title],
    );

    return div(
      [
        if (eyebrow case final eyebrow?)
          div(
            [eyebrow],
            classes: resolved.eyebrow.className,
            styles: resolved.eyebrow.inlineStyles,
          ),
        // The actions share the title's line and wrap under it when the line
        // leaves the title less than its floor (the Flutter twin's
        // `HeaderWrapLayout`).
        if (actions.isEmpty)
          heading
        else
          div(
            [
              div(
                [heading],
                classes: resolved.titleBlock.className,
                styles: resolved.titleBlock.inlineStyles,
              ),
              div(
                actions,
                classes: resolved.actions.className,
                styles: resolved.actions.inlineStyles,
              ),
            ],
            classes: resolved.titleRow.className,
            styles: resolved.titleRow.inlineStyles,
          ),
        if (description case final description?)
          div(
            [description],
            classes: resolved.description.className,
            styles: resolved.description.inlineStyles,
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

/// Chain sugar for merging a [CorePageHeaderStyle] patch into
/// [PageHeader.pageHeaderStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `PageHeader.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePageHeaderStyle.merge` right-side-wins semantics).
extension PageHeaderStyleChain on PageHeader {
  /// Returns a copy of this [PageHeader] with [patch] merged into
  /// [pageHeaderStyle] (patch fields win on conflict).
  PageHeader withStyle(CorePageHeaderStyle patch) => copyWith(
    pageHeaderStyle: (pageHeaderStyle ?? const CorePageHeaderStyle()).merge(
      patch,
    ),
  );
}
