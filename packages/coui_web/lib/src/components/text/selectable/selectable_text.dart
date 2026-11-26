import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/text/selectable/selectable_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform selectable-text component for CoUI Web.
///
/// Renders a `<span>` whose content the user can highlight and copy.
/// Pass [text] for a plain string, or [children] for rich-text
/// composition. The `select-text` class overrides any inherited
/// `user-select: none` so the content stays selectable — matching the
/// Flutter `SelectableText`.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [selectableTextStyle] (a
/// [CoreSelectableTextStyle]). Behavioural fields ([maxLines],
/// [textAlign], [textDirection], [enableInteractiveSelection],
/// [semanticsLabel]) stay flat on the component.
/// [CoreSelectableTextStyle.cursorColor] sets CSS `caret-color`.
/// Caret width, height and radius are exposed as
/// custom properties for tooling; this non-editable span retains native
/// browser caret geometry.
///
/// ```dart
/// SelectableText('This text is selectable')
/// SelectableText.rich(children: [span([text('Selectable content')])])
/// ```
class SelectableText extends UiComponent
    implements CoreSelectableTextContract<Component> {
  /// Creates a [SelectableText] from a plain string.
  const SelectableText(
    String this.text, {
    super.key,
    this.onTap,
    this.selectableTextStyle,
    this.maxLines,
    this.textAlign,
    this.textDirection,
    this.enableInteractiveSelection = true,
    this.semanticsLabel,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : children = null,
       super(tag: 'span');

  /// Creates a [SelectableText] from rich-text [children].
  const SelectableText.rich({
    required this.children,
    super.key,
    this.onTap,
    this.selectableTextStyle,
    this.maxLines,
    this.textAlign,
    this.textDirection,
    this.enableInteractiveSelection = true,
    this.semanticsLabel,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : text = null,
       super(tag: 'span');

  /// Plain text content to display. Ignored when [children] is set.
  @override
  final String? text;

  @override
  final List<Component>? children;

  @override
  final CoreSelectableTextStyle? selectableTextStyle;

  @override
  final int? maxLines;

  @override
  final CoreTextAlign? textAlign;

  @override
  final CoreTextDirection? textDirection;

  @override
  final bool enableInteractiveSelection;

  @override
  final String? semanticsLabel;

  @override
  final void Function()? onTap;
  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // 옵션 B 최종 — `WebResolvedChrome` contract). `co_*` reads the
    // paint-ready strings directly without invoking the top-level
    // builder helpers.
    final resolved = resolveSelectableText(
      context,
      selectableTextStyle: selectableTextStyle,
      maxLines: maxLines,
      textAlign: textAlign,
      enableInteractiveSelection: enableInteractiveSelection,
    );

    final currentText = text;
    final currentChildren = children;
    final contentChildren =
        currentChildren ??
        (currentText != null ? [Component.text(currentText)] : <Component>[]);

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    final attrs = <String, String>{
      ...componentAttributes,
      if (textDirection != null) 'dir': textDirection == .rtl ? 'rtl' : 'ltr',
      'aria-label': ?semanticsLabel,
    };

    final currentOnTap = onTap;

    return Component.element(
      tag: tag,
      id: id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: attrs,
      events: {
        ...events,
        if (currentOnTap != null) 'click': (_) => currentOnTap(),
      },
      children: contentChildren,
    );
  }

  @override
  SelectableText copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    String? text,
    List<Component>? children,
    CoreSelectableTextStyle? selectableTextStyle,
    int? maxLines,
    CoreTextAlign? textAlign,
    CoreTextDirection? textDirection,
    bool? enableInteractiveSelection,
    String? semanticsLabel,
    void Function()? onTap,
  }) {
    final resolvedChildren = children ?? this.children;
    if (resolvedChildren != null) {
      return SelectableText.rich(
        key: key ?? this.key,
        onTap: onTap ?? this.onTap,
        selectableTextStyle: selectableTextStyle ?? this.selectableTextStyle,
        maxLines: maxLines ?? this.maxLines,
        textAlign: textAlign ?? this.textAlign,
        textDirection: textDirection ?? this.textDirection,
        enableInteractiveSelection:
            enableInteractiveSelection ?? this.enableInteractiveSelection,
        semanticsLabel: semanticsLabel ?? this.semanticsLabel,
        id: id ?? this.id,
        classes: mergeClasses(this.classes, classes),
        css: css ?? this.css,
        attributes: attributes ?? userProvidedAttributes,
        eventHandlers: eventHandlers ?? this.eventHandlers,
        children: resolvedChildren,
      );
    }
    return SelectableText(
      text ?? this.text ?? '',
      key: key ?? this.key,
      onTap: onTap ?? this.onTap,
      selectableTextStyle: selectableTextStyle ?? this.selectableTextStyle,
      maxLines: maxLines ?? this.maxLines,
      textAlign: textAlign ?? this.textAlign,
      textDirection: textDirection ?? this.textDirection,
      enableInteractiveSelection:
          enableInteractiveSelection ?? this.enableInteractiveSelection,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }
}

/// Chain sugar mirroring the Flutter `SelectableText.withStyle`
/// extension — merges a [CoreSelectableTextStyle] patch into
/// [SelectableText.selectableTextStyle] via the existing
/// [SelectableText.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSelectableTextStyle.merge` right-side-wins semantics).
extension SelectableTextStyleChain on SelectableText {
  /// Returns a copy of this [SelectableText] with [patch] merged into
  /// [selectableTextStyle] (patch fields win on conflict).
  SelectableText withStyle(CoreSelectableTextStyle patch) => copyWith(
    selectableTextStyle:
        (selectableTextStyle ?? const CoreSelectableTextStyle()).merge(patch),
  );
}
