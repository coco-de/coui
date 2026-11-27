import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/option_item/option_item_style.dart';
import 'package:coui_web/src/util/element_scope.dart';

/// Unified cross-platform option row — one choosable line of a list of
/// options (a sheet's "sort by", a filter's "colour").
///
/// Uses [CoreOptionItemContract] from `coui_core`, so the Flutter
/// `OptionItem` takes the same named properties. Anatomy, start to end:
/// `[ leading ] [ label / description ] [ mark ]`. The mark is the chosen
/// state: a check at the end of the chosen row when [selection] is
/// [CoreOptionItemSelection.single], a [Checkbox] on every row when it is
/// [CoreOptionItemSelection.multiple].
///
/// The row is a bordered card. It owns no state of what is chosen —
/// [selected] says it (a filled card with an accent border), and
/// [onPressed] reports the tap. While pressed it paints a rounded face
/// inside its border, under its content.
///
/// ```dart
/// OptionItem(
///   label: const Text('Newest first'),
///   selected: true,
///   onPressed: () {},
/// )
/// ```
///
/// The row is a `Clickable` button; a chosen row carries
/// `aria-current="true"`. The multiple selection's checkbox is a picture of
/// the row's state — the row takes the tap — so it is `inert`, out of the tab
/// order and the accessibility tree.
class OptionItem extends UiComponent
    implements CoreOptionItemContract<Component> {
  /// Creates an [OptionItem].
  const OptionItem({
    required this.label,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.description,
    this.leading,
    this.selection = CoreOptionItemSelection.defaultSelection,
    this.selected = false,
    this.enabled,
    this.onPressed,
    this.optionItemStyle,
  }) : super(tag: 'div');

  @override
  final Component label;

  @override
  final Component? description;

  @override
  final Component? leading;

  @override
  final CoreOptionItemSelection selection;

  @override
  final bool selected;

  @override
  final bool? enabled;

  @override
  final void Function()? onPressed;

  @override
  final CoreOptionItemStyle? optionItemStyle;

  /// Whether the row accepts activation — the kit-wide rule: an explicit
  /// [enabled] wins, otherwise the presence of a handler decides.
  bool get _effectiveEnabled => enabled ?? (onPressed != null);

  @override
  OptionItem copyWith({
    Component? label,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    Component? description,
    Component? leading,
    CoreOptionItemSelection? selection,
    bool? selected,
    bool? enabled,
    void Function()? onPressed,
    CoreOptionItemStyle? optionItemStyle,
  }) => OptionItem(
    label: label ?? this.label,
    attributes: attributes ?? componentAttributes,
    classes: classes ?? this.classes,
    css: css ?? this.css,
    eventHandlers: eventHandlers ?? this.eventHandlers,
    id: id ?? this.id,
    key: key ?? this.key,
    description: description ?? this.description,
    leading: leading ?? this.leading,
    selection: selection ?? this.selection,
    selected: selected ?? this.selected,
    enabled: enabled ?? this.enabled,
    onPressed: onPressed ?? this.onPressed,
    optionItemStyle: optionItemStyle ?? this.optionItemStyle,
  );

  @override
  Component build(BuildContext context) {
    final enabled = _effectiveEnabled;
    // Per-instance class the pressed rule keys on — a class rather than the
    // element id because the composed `Clickable` claims the id.
    final scopeClass = elementScopeId(context, prefix: 'co-option-item');
    final resolved = resolveOptionItem(
      context,
      scopeClass: scopeClass,
      selection: selection,
      selected: selected,
      enabled: enabled,
      hasDescription: description != null,
      optionItemStyle: optionItemStyle,
    );
    final rules = resolveOptionItemRules(
      context,
      scopeClass: scopeClass,
      enabled: enabled,
      optionItemStyle: optionItemStyle,
    );

    final mark = switch (selection) {
      .single =>
        selected
            ? Icon(LucideIcons.check, iconStyle: resolved.checkIconStyle)
            : null,
      .multiple => Component.element(
        tag: 'div',
        classes: resolved.mark.className,
        attributes: const {'inert': ''},
        children: [
          Checkbox(
            checked: selected,
            enabled: enabled,
            size: .lg,
          ),
        ],
      ),
    };

    final seats = <Component>[
      if (rules.css.isNotEmpty)
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      Component.element(
        tag: 'div',
        classes: resolved.wash.className,
        styles: resolved.wash.inlineStyles,
        children: const [],
      ),
      if (leading != null)
        Component.element(
          tag: 'div',
          classes: resolved.leading.className,
          styles: resolved.leading.inlineStyles,
          children: [
            IconTheme(
              data: IconThemeData(size: resolved.leadingIconStyle.size),
              child: leading!,
            ),
          ],
        ),
      Component.element(
        tag: 'div',
        classes: resolved.textColumn.className,
        children: [
          Component.element(
            tag: 'div',
            classes: resolved.label.className,
            styles: resolved.label.inlineStyles,
            children: [label],
          ),
          if (description != null) ...[
            Gap(gapStyle: resolved.descriptionGapStyle),
            Component.element(
              tag: 'div',
              classes: resolved.description.className,
              styles: resolved.description.inlineStyles,
              children: [description!],
            ),
          ],
        ],
      ),
      ?mark,
    ];

    return Clickable(
      attributes: {
        if (selected) 'aria-current': 'true',
        if (!enabled) 'aria-disabled': 'true',
        ...componentAttributes,
      },
      classes: rootClasses(resolved.root.className),
      // The row's own chrome rides in on `css`: `Clickable` composes its
      // resolved styles first and the caller's `css` after.
      css: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      eventHandlers: eventHandlers,
      id: id,
      enabled: enabled,
      onPressed: onPressed,
      clickableStyle: resolved.clickableStyle,
      child: Component.fragment(seats),
    );
  }
}

/// Chain sugar for merging a [CoreOptionItemStyle] patch into
/// [OptionItem.optionItemStyle] without hand-reconstructing every field.
/// Mirrors the Flutter `OptionItem.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreOptionItemStyle.merge` right-side-wins semantics).
extension OptionItemStyleChain on OptionItem {
  /// Sets the content padding.
  OptionItem contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreOptionItemStyle(padding: value));

  /// Sets the border color.
  OptionItem borderColor(CoreColor value) =>
      withStyle(CoreOptionItemStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  OptionItem borderWidth(double value) =>
      withStyle(CoreOptionItemStyle(borderWidth: value));

  /// Returns a copy of this [OptionItem] with [patch] merged into
  /// [optionItemStyle] (patch fields win on conflict).
  OptionItem withStyle(CoreOptionItemStyle patch) => copyWith(
    optionItemStyle: (optionItemStyle ?? const CoreOptionItemStyle()).merge(
      patch,
    ),
  );
}
