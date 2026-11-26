# Item Picker Examples

This document contains example code for the item_picker component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)
- [Example 5: Example 5](#example-5)

## Example 1

**Basic Example**

```dart
// ignore_for_file: use_build_context_synchronously
import 'package:coui_flutter/coui_flutter.dart';

class ItemPickerExample1 extends StatelessWidget {
  const ItemPickerExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Show Item Picker'),
      onPressed: () {
        showItemPicker<int>(
          context,
          builder: (context, item) {
            return ItemPickerOption(
              value: item,
              child: Text(item.toString()).lg,
            );
          },
          items: ItemBuilder(
            itemBuilder: (index) {
              return index;
            },
            itemCount: 1000,
          ),
          title: const Text('Pick an item'),
        ).then((value) {
          if (value != null) {
            showToast(
              builder: (context, overlay) {
                return SurfaceCard(child: Text('You picked $value!'));
              },
              context: context,
            );
          } else {
            showToast(
              builder: (context, overlay) {
                return const SurfaceCard(child: Text('You picked nothing!'));
              },
              context: context,
            );
          }
        });
      },
    );
  }
}

```

## Example 2

**Variant Example**

```dart
// ignore_for_file: use_build_context_synchronously
import 'package:coui_flutter/coui_flutter.dart';

class ItemPickerExample2 extends StatelessWidget {
  const ItemPickerExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Show Item Picker'),
      onPressed: () {
        showItemPickerDialog<int>(
          context,
          builder: (context, item) {
            return ItemPickerOption(
              value: item,
              child: Text(item.toString()).lg,
            );
          },
          items: ItemBuilder(
            itemBuilder: (index) {
              return index;
            },
          ),
          title: const Text('Pick a number'),
        ).then((value) {
          if (value != null) {
            showToast(
              builder: (context, overlay) {
                return SurfaceCard(child: Text('You picked $value!'));
              },
              context: context,
            );
          } else {
            showToast(
              builder: (context, overlay) {
                return const SurfaceCard(child: Text('You picked nothing!'));
              },
              context: context,
            );
          }
        });
      },
    );
  }
}

```

## Example 3

**Custom Example**

```dart
// ignore_for_file: use_build_context_synchronously
import 'package:coui_flutter/coui_flutter.dart';

class NamedColor {
  final String name;
  final Color color;

  const NamedColor(this.name, this.color);
}

class ItemPickerExample3 extends StatefulWidget {
  const ItemPickerExample3({super.key});

  @override
  State<ItemPickerExample3> createState() => _ItemPickerExample3State();
}

class _ItemPickerExample3State extends State<ItemPickerExample3> {
  final List<NamedColor> colors = const [
    NamedColor('Red', Colors.red),
    NamedColor('Green', Colors.green),
    NamedColor('Blue', Colors.blue),
    NamedColor('Yellow', Colors.yellow),
    NamedColor('Purple', Colors.purple),
    NamedColor('Cyan', Colors.cyan),
    NamedColor('Orange', Colors.orange),
    NamedColor('Pink', Colors.pink),
    NamedColor('Teal', Colors.teal),
    NamedColor('Amber', Colors.amber),
  ];
  int selectedColor = 0;
  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Show Item Picker'),
      onPressed: () {
        showItemPickerDialog<NamedColor>(
          context,
          builder: (context, item) {
            return ItemPickerOption(
              label: Text(item.name),
              selectedStyle: const ButtonStyle.primary(
                shape: ButtonShape.circle,
              ),
              style: const ButtonStyle.ghost(shape: ButtonShape.circle),
              value: item,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
                width: 100,
                height: 100,
              ),
            );
          },
          initialValue: colors[selectedColor],
          items: ItemList(colors),
          title: const Text('Pick a color'),
        ).then((value) {
          if (value != null) {
            selectedColor = colors.indexOf(value);
            showToast(
              builder: (context, overlay) {
                return SurfaceCard(child: Text('You picked ${value.name}!'));
              },
              context: context,
            );
          } else {
            showToast(
              builder: (context, overlay) {
                return const SurfaceCard(child: Text('You picked nothing!'));
              },
              context: context,
            );
          }
        });
      },
    );
  }
}

```

## Example 4

**Example 4**

```dart
// ignore_for_file: use_build_context_synchronously
import 'package:coui_flutter/coui_flutter.dart';

class NamedColor {
  final String name;
  final Color color;

  const NamedColor(this.name, this.color);
}

class ItemPickerExample4 extends StatefulWidget {
  const ItemPickerExample4({super.key});

  @override
  State<ItemPickerExample4> createState() => _ItemPickerExample4State();
}

class _ItemPickerExample4State extends State<ItemPickerExample4> {
  final List<NamedColor> colors = const [
    NamedColor('Red', Colors.red),
    NamedColor('Green', Colors.green),
    NamedColor('Blue', Colors.blue),
    NamedColor('Yellow', Colors.yellow),
    NamedColor('Purple', Colors.purple),
    NamedColor('Cyan', Colors.cyan),
    NamedColor('Orange', Colors.orange),
    NamedColor('Pink', Colors.pink),
    NamedColor('Teal', Colors.teal),
    NamedColor('Amber', Colors.amber),
  ];
  int selectedColor = 0;
  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Show Item Picker'),
      onPressed: () {
        showItemPickerDialog<NamedColor>(
          context,
          builder: (context, item) {
            return ItemPickerOption(
              label: Text(item.name),
              value: item,
              child: Container(
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
                width: 40,
                height: 40,
              ),
            );
          },
          initialValue: colors[selectedColor],
          items: ItemList(colors),
          layout: ItemPickerLayout.list,
          title: const Text('Pick a color'),
        ).then((value) {
          if (value != null) {
            selectedColor = colors.indexOf(value);
            showToast(
              builder: (context, overlay) {
                return SurfaceCard(child: Text('You picked ${value.name}!'));
              },
              context: context,
            );
          } else {
            showToast(
              builder: (context, overlay) {
                return const SurfaceCard(child: Text('You picked nothing!'));
              },
              context: context,
            );
          }
        });
      },
    );
  }
}

```

## Example 5

**Example 5**

```dart
// ignore_for_file: avoid_print
import 'package:coui_flutter/coui_flutter.dart';

class NamedColor {
  final String name;
  final Color color;

  const NamedColor(this.name, this.color);
}

class ItemPickerExample5 extends StatefulWidget {
  const ItemPickerExample5({super.key});

  @override
  State<ItemPickerExample5> createState() => _ItemPickerExample5State();
}

class _ItemPickerExample5State extends State<ItemPickerExample5> {
  final List<NamedColor> colors = const [
    NamedColor('Red', Colors.red),
    NamedColor('Green', Colors.green),
    NamedColor('Blue', Colors.blue),
    NamedColor('Yellow', Colors.yellow),
    NamedColor('Purple', Colors.purple),
    NamedColor('Cyan', Colors.cyan),
    NamedColor('Orange', Colors.orange),
    NamedColor('Pink', Colors.pink),
    NamedColor('Teal', Colors.teal),
    NamedColor('Amber', Colors.amber),
  ];
  int selectedColor = 0;
  @override
  Widget build(BuildContext context) {
    return ItemPicker<NamedColor>(
      builder: (context, item) {
        return ItemPickerOption(
          label: Text(item.name),
          selectedStyle: const ButtonStyle.primary(shape: ButtonShape.circle),
          style: const ButtonStyle.ghostIcon(shape: ButtonShape.circle),
          value: item,
          child: Container(
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        );
      },
      items: ItemList(colors),
      mode: PromptMode.popover,
      onChanged: (value) {
        print('You picked $value!');
        if (value != null) {
          setState(() {
            selectedColor = colors.indexOf(value);
          });
        }
      },
      placeholder: const Text('Pick a color'),
      title: const Text('Pick a color'),
      value: colors[selectedColor],
    );
  }
}

```

