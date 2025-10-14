import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for command selection.
typedef CommandSelectCallback = void Function(String value);

/// A command palette component (searchable menu).
///
/// Example:
/// ```dart
/// Command(
///   placeholder: 'Type a command...',
///   items: [
///     CommandItem(value: 'open', label: 'Open File'),
///     CommandItem(value: 'save', label: 'Save'),
///   ],
/// )
/// ```
class Command extends UiComponent {
  /// Creates a Command component.
  const Command({
    super.key,
    required this.items,
    this.placeholder = 'Type a command or search...',
    this.onSelect,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Command items.
  final List<CommandItem> items;

  /// Search placeholder.
  final String placeholder;

  /// Selection callback.
  final CommandSelectCallback? onSelect;

  static const _divValue = 'div';

  @override
  Command copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<CommandItem>? items,
    String? placeholder,
    CommandSelectCallback? onSelect,
    Key? key,
  }) {
    return Command(
      key: key ?? this.key,
      items: items ?? this.items,
      placeholder: placeholder ?? this.placeholder,
      onSelect: onSelect ?? this.onSelect,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      children: [
        // Search input
        div(
          child: input(
            classes:
                'flex h-11 w-full rounded-md bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50',
            attributes: {
              'type': 'text',
              'placeholder': placeholder,
              'aria-autocomplete': 'list',
            },
          ),
          classes: 'flex items-center border-b px-3',
        ),
        // Items list
        div(
          children: items
              .map(
                (item) => _buildCommandItem(item),
              )
              .toList(),
          classes: 'max-h-[300px] overflow-y-auto overflow-x-hidden',
        ),
      ],
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'role': 'combobox',
        'aria-expanded': 'true',
      },
      events: this.events,
    );
  }

  @override
  String get baseClass =>
      'flex h-full w-full flex-col overflow-hidden rounded-md bg-popover text-popover-foreground';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  Component _buildCommandItem(CommandItem item) {
    return div(
      children: [
        if (item.icon != null) item.icon,
        span(child: text(item.label)),
        if (item.shortcut != null)
          span(
            child: text(item.shortcut),
            classes: 'ml-auto text-xs tracking-widest text-muted-foreground',
          ),
      ],
      classes:
          'relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none hover:bg-accent hover:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
      attributes: {
        'role': 'option',
        if (item.disabled) 'data-disabled': '',
      },
      events: _buildItemEvents(item),
    );
  }

  Map<String, List<dynamic>> _buildItemEvents(CommandItem item) {
    final currentOnSelect = onSelect;

    return currentOnSelect == null || item.disabled
        ? {}
        : {
            'click': [
              (event) => currentOnSelect(item.value),
            ],
          };
  }
}

/// A command item.
class CommandItem {
  /// Creates a CommandItem.
  const CommandItem({
    required this.value,
    required this.label,
    this.icon,
    this.shortcut,
    this.disabled = false,
  });

  /// Item value.
  final String value;

  /// Item label.
  final String label;

  /// Optional icon.
  final Component? icon;

  /// Optional keyboard shortcut.
  final String? shortcut;

  /// Whether item is disabled.
  final bool disabled;
}
