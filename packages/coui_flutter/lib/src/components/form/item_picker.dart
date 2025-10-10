import 'package:coui_flutter/coui_flutter.dart';

/// A widget for selecting items from a collection using various presentation modes.
///
/// This widget provides a flexible item selection interface that can display
/// items in different layouts (grid, list) and presentation modes (dialog, popover).
/// It's suitable for scenarios where users need to pick from a predefined set
/// of items like colors, icons, templates, or any custom objects.
///
/// The ItemPicker uses a delegate pattern to provide items, allowing for both
/// static lists and dynamic item generation. Items are displayed using a
/// custom builder function that determines how each item appears in the picker.
///
/// Example:
/// ```dart
/// ItemPicker<Color>(
///   items: ItemList([Colors.red, Colors.green, Colors.blue]),
///   value: Colors.red,
///   builder: (context, color, isSelected) {
///     return Container(
///       width: 40,
///       height: 40,
///       decoration: BoxDecoration(
///         color: color,
///         shape: BoxShape.circle,
///         border: isSelected ? Border.all(width: 2) : null,
///       ),
///     );
///   },
///   onChanged: (color) => print('Selected color: $color'),
/// );
/// ```
class ItemPicker<T> extends StatelessWidget {
  /// Creates an [ItemPicker].
  ///
  /// The [items] delegate provides the selectable items, and the [builder]
  /// function determines how each item is visually represented. Various
  /// options control the picker's layout and presentation style.
  ///
  /// Parameters:
  /// - [items] (ItemChildDelegate<T>, required): Source of items for selection
  /// - [builder] (ItemPickerBuilder<T>, required): Function to build item representations
  /// - [value] (T?, optional): Currently selected item
  /// - [onChanged] (ValueChanged<T?>?, optional): Callback for selection changes
  /// - [layout] (ItemPickerLayout?, optional): Arrangement style for items
  /// - [placeholder] (Widget?, optional): Content shown when no item is selected
  /// - [title] (Widget?, optional): Title for the picker interface
  /// - [mode] (PromptMode?, optional): Presentation style (dialog or popover)
  /// - [constraints] (BoxConstraints?, optional): Size constraints for the picker
  ///
  /// Example:
  /// ```dart
  /// ItemPicker<IconData>(
  ///   items: ItemList([Icons.home, Icons.star, Icons.favorite]),
  ///   layout: ItemPickerLayout.grid,
  ///   mode: PromptMode.dialog,
  ///   builder: (context, icon, selected) => Icon(icon),
  ///   onChanged: (icon) => updateIcon(icon),
  /// );
  /// ```
  const ItemPicker({
    required this.builder,
    this.constraints,
    required this.items,
    super.key,
    this.layout,
    this.mode,
    this.onChanged,
    this.placeholder,
    this.title,
    this.value,
  });

  /// Delegate providing the collection of items to display for selection.
  ///
  /// This delegate abstracts the item source, supporting both static lists
  /// through [ItemList] and dynamic generation through [ItemBuilder].
  final ItemChildDelegate<T> items;

  /// Builder function that creates the visual representation of each item.
  ///
  /// Called for each item to create its visual representation in the picker.
  /// The builder receives the item value and selection state, allowing
  /// customized appearance based on the current selection.
  final ItemPickerBuilder<T> builder;

  /// The currently selected item, if any.
  ///
  /// When null, no item is selected. The picker highlights this item
  /// visually to indicate the current selection state.
  final T? value;

  /// Callback invoked when the user selects a different item.
  ///
  /// Called when the user taps on an item in the picker. The callback
  /// receives the selected item, or null if the selection is cleared.
  final ValueChanged<T?>? onChanged;

  /// Layout style for arranging items in the picker interface.
  ///
  /// Determines how items are arranged within the picker container,
  /// such as grid or list layout. Defaults to grid layout.
  final ItemPickerLayout? layout;

  /// Widget displayed when no item is currently selected.
  ///
  /// Shown in the picker trigger button when [value] is null.
  /// Provides visual feedback that no selection has been made yet.
  final Widget? placeholder;

  /// Optional title widget for the picker interface.
  ///
  /// Displayed at the top of the picker when shown in dialog mode,
  /// providing context about what the user is selecting.
  final Widget? title;

  /// Presentation mode for the item picker interface.
  ///
  /// Controls whether the picker appears as a modal dialog or a popover
  /// dropdown. Defaults to dialog mode for better item visibility.
  final PromptMode? mode;

  /// Size constraints for the picker interface container.
  ///
  /// Controls the dimensions of the picker when displayed, allowing
  /// customization of the available space for item display.
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final layout = this.layout ?? ItemPickerLayout.grid;
    final mode = this.mode ?? PromptMode.dialog;
    final constraints = this.constraints;

    return ObjectFormField(
      builder: builder,
      decorate: false,
      dialogTitle: title,
      editorBuilder: (context, handler) {
        if (mode == PromptMode.dialog) {
          final theme = Theme.of(context);

          return ModalBackdrop(
            borderRadius: theme.borderRadiusXl,
            child: ModalContainer(
              borderRadius: theme.borderRadiusXl,
              padding: EdgeInsets.zero,
              child: _InternalItemPicker<T>(
                initialValue: handler.value,
                builder: builder,
                constraints: constraints,
                items: items,
                layout: layout,
                onChanged: (value) {
                  closeOverlay(context, value);
                },
                title: title,
              ),
            ),
          );
        }

        return SurfaceCard(
          padding: EdgeInsets.zero,
          child: _InternalItemPicker<T>(
            initialValue: handler.value,
            builder: builder,
            constraints: constraints,
            items: items,
            layout: layout,
            onChanged: (value) {
              closeOverlay(context, value);
            },
            title: title,
          ),
        );
      },
      mode: mode,
      onChanged: onChanged,
      placeholder: placeholder ?? const SizedBox.shrink(),
      value: value,
    );
  }
}

abstract class ItemChildDelegate<T> {
  const ItemChildDelegate();
  int? get itemCount;

  T? operator [](int index);
}

class ItemList<T> extends ItemChildDelegate<T> {
  const ItemList(this.items);
  final List<T> items;
  @override
  int get itemCount => items.length;

  @override
  T operator [](int index) => items[index];
}

class ItemBuilder<T> extends ItemChildDelegate<T> {
  const ItemBuilder({required this.itemBuilder, this.itemCount});

  @override
  final int? itemCount;
  final T? Function(int index) itemBuilder;

  @override
  T? operator [](int index) => itemBuilder(index);
}

typedef ItemPickerBuilder<T> = Widget Function(BuildContext context, T item);

abstract class ItemPickerLayout {
  const ItemPickerLayout();
  static const list = ListItemPickerLayout();
  static const grid = GridItemPickerLayout();

  Widget build(
    ItemPickerBuilder<dynamic> builder,
    BuildContext context,
    ItemChildDelegate<dynamic> items,
  );
}

class ListItemPickerLayout extends ItemPickerLayout {
  const ListItemPickerLayout();

  @override
  Widget build(
    ItemPickerBuilder<dynamic> builder,
    BuildContext context,
    ItemChildDelegate<dynamic> items,
  ) {
    final padding = MediaQuery.paddingOf(context);

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeTop: true,
      removeRight: true,
      removeBottom: true,
      child: ListView.builder(
        padding: padding,
        itemBuilder: (context, index) {
          final item = items[index];

          return item == null ? null : builder(context, item);
        },
        itemCount: items.itemCount,
      ),
    );
  }
}

class GridItemPickerLayout extends ItemPickerLayout {
  const GridItemPickerLayout({this.crossAxisCount = 4});

  final int crossAxisCount;

  static ItemPickerLayout call({int crossAxisCount = 4}) {
    return GridItemPickerLayout(crossAxisCount: crossAxisCount);
  }

  @override
  Widget build(
    ItemPickerBuilder<dynamic> builder,
    BuildContext context,
    ItemChildDelegate<dynamic> items,
  ) {
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeTop: true,
      removeRight: true,
      removeBottom: true,
      child: GridView.builder(
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: theme.scaling * 4.0,
          crossAxisSpacing: theme.scaling * 4.0,
        ),
        itemBuilder: (context, index) {
          final item = items[index];

          return item == null ? null : builder(context, item);
        },
        itemCount: items.itemCount,
      ),
    );
  }
}

Future<T?> showItemPicker<T>(
  BuildContext context, {
  AlignmentGeometry? alignment,
  AlignmentGeometry? anchorAlignment,
  required ItemPickerBuilder<T> builder,
  BoxConstraints? constraints,
  T? initialValue,
  required ItemChildDelegate<T> items,
  ItemPickerLayout layout = const GridItemPickerLayout(),
  Offset? offset,
  Widget? title,
}) {
  final theme = Theme.of(context);

  return showPopover<T>(
    alignment: alignment ?? AlignmentDirectional.topStart,
    anchorAlignment: anchorAlignment ?? AlignmentDirectional.bottomStart,
    builder: (context) {
      return SurfaceCard(
        padding: EdgeInsets.zero,
        child: _InternalItemPicker<T>(
          initialValue: initialValue,
          builder: builder,
          constraints: constraints,
          items: items,
          layout: layout,
          onChanged: (value) {
            closeOverlay(context, value);
          },
          title: title,
        ),
      );
    },
    context: context,
    offset: offset ?? Offset(0, theme.scaling * 8.0),
  ).future;
}

class _InternalItemPicker<T> extends StatelessWidget {
  const _InternalItemPicker({
    required this.builder,
    this.constraints,
    required this.initialValue,
    required this.items,
    super.key,
    required this.layout,
    required this.onChanged,
    this.title,
  });
  final ItemChildDelegate<T> items;
  final ItemPickerBuilder<T> builder;
  final T? initialValue;
  final ItemPickerLayout layout;
  final Widget? title;
  final BoxConstraints? constraints;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding:
                EdgeInsets.all(theme.scaling * 16.0) +
                EdgeInsets.only(top: padding.top),
            child: title?.large.semiBold,
          ),
        ConstrainedBox(
          constraints:
              constraints ??
              BoxConstraints(
                maxWidth: theme.scaling * 320,
                maxHeight: theme.scaling * 320,
              ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: title == null
                  ? padding + const EdgeInsets.all(8) * theme.scaling
                  : padding.copyWith(top: 0) +
                        const EdgeInsets.only(left: 8, right: 8, bottom: 8) *
                            theme.scaling,
            ),
            child: ItemPickerDialog<T>(
              builder: builder,
              items: items,
              layout: layout,
              onChanged: onChanged,
              value: initialValue,
            ),
          ),
        ),
      ],
    );
  }
}

Future<T?> showItemPickerDialog<T>(
  BuildContext context, {
  required ItemPickerBuilder<T> builder,
  BoxConstraints? constraints,
  T? initialValue,
  required ItemChildDelegate<T> items,
  ItemPickerLayout layout = const GridItemPickerLayout(),
  required Widget title,
}) {
  return showDialog(
    builder: (context) {
      final theme = Theme.of(context);

      return ModalBackdrop(
        borderRadius: theme.borderRadiusXl,
        child: ModalContainer(
          borderRadius: theme.borderRadiusXl,
          padding: EdgeInsets.zero,
          child: _InternalItemPicker<T>(
            initialValue: initialValue,
            builder: builder,
            constraints: constraints,
            items: items,
            layout: layout,
            onChanged: (value) {
              closeOverlay(context, value);
            },
            title: title,
          ),
        ),
      );
    },
    context: context,
  );
}

class ItemPickerDialog<T> extends StatefulWidget {
  const ItemPickerDialog({
    required this.builder,
    required this.items,
    super.key,
    this.layout = const GridItemPickerLayout(),
    this.onChanged,
    this.value,
  });

  final ItemChildDelegate<T> items;
  final ItemPickerBuilder<T> builder;
  final ItemPickerLayout layout;
  final T? value;
  final ValueChanged<T?>? onChanged;

  @override
  State<ItemPickerDialog<T>> createState() => _ItemPickerDialogState<T>();
}

class _ItemPickerDialogState<T> extends State<ItemPickerDialog<T>> {
  void _onChanged(Object? value) {
    widget.onChanged?.call(value as T);
  }

  Widget _buildItem(BuildContext context, Object? item) {
    assert(item is T, 'Item type must be $T');

    return widget.builder(context, item as T);
  }

  @override
  Widget build(BuildContext context) {
    return Data.inherit(
      data: ItemPickerData(
        layout: widget.layout,
        onChanged: _onChanged,
        value: widget.value,
      ),
      child: widget.layout.build(_buildItem, context, widget.items),
    );
  }
}

class ItemPickerData {
  const ItemPickerData({required this.layout, this.onChanged, this.value});

  final Object? value;
  final ValueChanged<Object?>? onChanged;
  final ItemPickerLayout layout;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ItemPickerData) return false;

    return other.value == value &&
        other.onChanged == onChanged &&
        other.layout == layout;
  }

  @override
  int get hashCode => Object.hash(value, onChanged, layout);
}

class ItemPickerOption<T> extends StatelessWidget {
  const ItemPickerOption({
    required this.child,
    super.key,
    this.label,
    this.selectedStyle,
    this.style,
    required this.value,
  });

  final T value;
  final Widget? label;
  final Widget child;
  final AbstractButtonStyle? style;
  final AbstractButtonStyle? selectedStyle;

  @override
  Widget build(BuildContext context) {
    final data = Data.maybeOf<ItemPickerData>(context);
    if (data == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.width == size.height) {
            return Stack(
              fit: StackFit.passthrough,
              children: [
                child,
                if (label != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(child: label),
                  ),
              ],
            );
          }

          return label == null
              ? child
              : BasicLayout(content: label, leading: child);
        },
      );
    }
    if (data.layout is ListItemPickerLayout) {
      return label == null
          ? Button(
              onPressed: data.onChanged == null
                  ? null
                  : () => data.onChanged!(value),
              style: data.value == value
                  ? (selectedStyle ?? ButtonVariance.primary)
                  : (style ?? ButtonVariance.ghost),
              child: child,
            )
          : Button(
              onPressed: data.onChanged == null
                  ? null
                  : () => data.onChanged!(value),
              style: data.value == value
                  ? (selectedStyle ?? ButtonVariance.primary)
                  : (style ?? ButtonVariance.ghost),
              leading: child,
              child: label!,
            );
    }

    return IconButton(
      onPressed: data.onChanged == null ? null : () => data.onChanged!(value),
      icon: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          if (label != null)
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Center(child: label),
            ),
        ],
      ),
      variance: data.value == value
          ? (selectedStyle ?? ButtonVariance.primary)
          : (style ?? ButtonVariance.ghost),
    );
  }
}
