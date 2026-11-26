# Select Examples

This document contains example code for the select component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)
- [Example 4: Example 4](#example-4)

## Example 1

**Basic Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class SelectExample1 extends StatefulWidget {
  const SelectExample1({super.key});

  @override
  State<SelectExample1> createState() => _SelectExample1State();
}

class _SelectExample1State extends State<SelectExample1> {
  String? selectedValue;
  @override
  Widget build(BuildContext context) {
    return Select<String>(
      itemBuilder: (context, item) {
        return Text(item);
      },
      onChanged: (value) {
        setState(() {
          selectedValue = value;
        });
      },
      placeholder: Text(t.docs.components.select.placeholder),
      popup: (context) => SelectPopup(
        items: SelectItemList(
          children: [
            SelectItemButton(
              value: t.docs.components.select.apple,
              child: Text(t.docs.components.select.apple),
            ),
            SelectItemButton(
              value: t.docs.components.select.banana,
              child: Text(t.docs.components.select.banana),
            ),
            SelectItemButton(
              value: t.docs.components.select.cherry,
              child: Text(t.docs.components.select.cherry),
            ),
          ],
        ),
      ),
      popupConstraints: const BoxConstraints(maxWidth: 200, maxHeight: 300),
      value: selectedValue,
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class SelectExample2 extends StatefulWidget {
  const SelectExample2({super.key});

  @override
  State<SelectExample2> createState() => _SelectExample2State();
}

class _SelectExample2State extends State<SelectExample2> {
  Map<String, List<String>> get fruits => {
        t.docs.components.select.apple: [
          t.docs.components.select.red_apple,
          t.docs.components.select.green_apple,
        ],
        t.docs.components.select.banana: [
          t.docs.components.select.yellow_banana,
          t.docs.components.select.brown_banana,
        ],
        t.docs.components.select.lemon: [
          t.docs.components.select.yellow_lemon,
          t.docs.components.select.green_lemon,
        ],
        t.docs.components.select.tomato: [
          t.docs.components.select.red,
          t.docs.components.select.green,
          t.docs.components.select.yellow,
          t.docs.components.select.brown,
        ],
      };
  String? selectedValue;

  Iterable<MapEntry<String, List<String>>> _filteredFruits(
    String searchQuery,
  ) sync* {
    for (final entry in fruits.entries) {
      final filteredValues = entry.value
          .where((value) => _filterName(value, searchQuery))
          .toList();
      if (filteredValues.isNotEmpty) {
        yield MapEntry(entry.key, filteredValues);
      } else if (_filterName(entry.key, searchQuery)) {
        yield entry;
      }
    }
  }

  bool _filterName(String name, String searchQuery) {
    return name.toLowerCase().contains(searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Select<String>(
      constraints: const BoxConstraints(minWidth: 200),
      itemBuilder: (context, item) {
        return Text(item);
      },
      onChanged: (value) {
        setState(() {
          selectedValue = value;
        });
      },
      placeholder: Text(t.docs.components.select.placeholder),
      popup: (context) => SelectPopup.builder(
        builder: (context, searchQuery) {
          final filteredFruits = searchQuery == null
              ? fruits.entries
              : _filteredFruits(searchQuery);
          return SelectItemList(
            children: [
              for (final entry in filteredFruits)
                SelectGroup(
                  headers: [SelectLabel(child: Text(entry.key))],
                  children: [
                    for (final value in entry.value)
                      SelectItemButton(value: value, child: Text(value)),
                  ],
                ),
            ],
          );
        },
        searchPlaceholder: Text(t.docs.components.select.search_fruit),
      ),
      value: selectedValue,
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class SelectExample3 extends StatefulWidget {
  const SelectExample3({super.key});

  @override
  State<SelectExample3> createState() => _SelectExample3State();
}

class _SelectExample3State extends State<SelectExample3> {
  final Map<String, List<String>> fruits = {
    'Apple': ['Red Apple', 'Green Apple'],
    'Banana': ['Yellow Banana', 'Brown Banana'],
    'Lemon': ['Yellow Lemon', 'Green Lemon'],
    'Tomato': ['Red', 'Green', 'Yellow', 'Brown'],
  };
  String? selectedValue;

  Iterable<MapEntry<String, List<String>>> _filteredFruits(
    String searchQuery,
  ) sync* {
    for (final entry in fruits.entries) {
      final filteredValues = entry.value
          .where((value) => _filterName(value, searchQuery))
          .toList();
      if (filteredValues.isNotEmpty) {
        yield MapEntry(entry.key, filteredValues);
      } else if (_filterName(entry.key, searchQuery)) {
        yield entry;
      }
    }
  }

  bool _filterName(String name, String searchQuery) {
    return name.toLowerCase().contains(searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Select<String>(
      constraints: const BoxConstraints(minWidth: 200),
      itemBuilder: (context, item) {
        return Text(item);
      },
      onChanged: (value) {
        setState(() {
          selectedValue = value;
        });
      },
      placeholder: Text(t.docs.components.select.placeholder),
      popup: (context) => SelectPopup.builder(
        builder: (context, searchQuery) async {
          final filteredFruits = searchQuery == null
              ? fruits.entries.toList()
              : _filteredFruits(searchQuery).toList();

          /// Simulate a delay for loading.
          /// In a real-world scenario, you would fetch data from an API or database.
          await Future.delayed(const Duration(milliseconds: 500));
          return SelectItemBuilder(
            builder: (context, index) {
              final entry = filteredFruits[index % filteredFruits.length];
              return SelectGroup(
                headers: [SelectLabel(child: Text(entry.key))],
                children: [
                  for (final value in entry.value)
                    SelectItemButton(value: value, child: Text(value)),
                ],
              );
            },
            childCount: filteredFruits.isEmpty ? 0 : null,
          );
        },
        emptyBuilder: (context) {
          return Center(child: Text(t.docs.components.select.no_fruit_found));
        },
        loadingBuilder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
        searchPlaceholder: Text(t.docs.components.select.search_fruit),
      ),
      value: selectedValue,
    );
  }
}

```

## Example 4

**Example 4**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class SelectExample4 extends StatefulWidget {
  const SelectExample4({super.key});

  @override
  State<SelectExample4> createState() => _SelectExample4State();
}

class _SelectExample4State extends State<SelectExample4> {
  String? selectedValue;
  @override
  Widget build(BuildContext context) {
    return Select<String>(
      itemBuilder: (context, item) {
        return Text(item);
      },
      onChanged: (value) {
        setState(() {
          selectedValue = value;
        });
      },
      placeholder: Text(t.docs.components.select.placeholder),
      popup: (context) => SelectPopup.noVirtualization(
        items: SelectItemList(
          children: [
            SelectItemButton(
              value: t.docs.components.select.apple,
              child: Text(t.docs.components.select.apple),
            ),
            SelectItemButton(
              value: t.docs.components.select.banana,
              child: Text(t.docs.components.select.banana),
            ),
            SelectItemButton(
              value: t.docs.components.select.cherry,
              child: Text(t.docs.components.select.cherry),
            ),
          ],
        ),
      ),
      popupConstraints: const BoxConstraints(maxWidth: 200, maxHeight: 300),
      popupWidthConstraint: PopoverConstraint.intrinsic,
      value: selectedValue,
    );
  }
}

```

