import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/option_list/option_list_style.dart';

/// Unified cross-platform option list — a vertical stack of [OptionItem]s.
///
/// Uses [CoreOptionListContract] from `coui_core`, so the Flutter
/// `OptionList` takes the same named properties. The list owns the
/// arrangement only: the rows in order, [CoreOptionListStyle.spacing] apart,
/// each as wide as the list. Which rows are chosen is the caller's — each row
/// states its own `selection` and `selected`.
///
/// ```dart
/// OptionList(
///   children: [
///     OptionItem(label: const Text('Newest'), selected: true),
///     OptionItem(label: const Text('Oldest'), onPressed: () {}),
///   ],
/// )
/// ```
///
/// The root is a `<div role="group">` with no accessible name of its own; a
/// page that wants it named passes `attributes: {'aria-label': '…'}`.
class OptionList extends UiComponent
    implements CoreOptionListContract<Component> {
  /// Creates an [OptionList].
  const OptionList({
    required this.children,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.optionListStyle,
  }) : super(tag: 'div');

  @override
  final List<Component> children;

  @override
  final CoreOptionListStyle? optionListStyle;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add('role', CoreSemanticRole.group.ariaRole);
  }

  @override
  OptionList copyWith({
    List<Component>? children,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    CoreOptionListStyle? optionListStyle,
  }) => OptionList(
    children: children ?? this.children,
    attributes: attributes ?? userProvidedAttributes,
    classes: classes ?? this.classes,
    css: css ?? this.css,
    eventHandlers: eventHandlers ?? this.eventHandlers,
    id: id ?? this.id,
    key: key ?? this.key,
    optionListStyle: optionListStyle ?? this.optionListStyle,
  );

  @override
  Component build(BuildContext context) {
    final resolved = resolveOptionList(
      context,
      optionListStyle: optionListStyle,
    );
    return div(
      [...children],
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }
}

/// Chain sugar for merging a [CoreOptionListStyle] patch into
/// [OptionList.optionListStyle]. Mirrors the Flutter `OptionList.withStyle`
/// extension so both platforms read identically.
extension OptionListStyleChain on OptionList {
  /// Returns a copy of this [OptionList] with [patch] merged into
  /// [optionListStyle] (patch fields win on conflict).
  OptionList withStyle(CoreOptionListStyle patch) => copyWith(
    optionListStyle: (optionListStyle ?? const CoreOptionListStyle()).merge(
      patch,
    ),
  );
}
