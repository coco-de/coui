import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

class MultiSelectExample3 extends StatefulWidget {
  const MultiSelectExample3({super.key});

  @override
  State<MultiSelectExample3> createState() => _MultiSelectExample3State();
}

class _MultiSelectExample3State extends State<MultiSelectExample3> {
  final Map<String, List<String>> fruits = {
    'Apple': ['Red Apple', 'Green Apple'],
    'Banana': ['Yellow Banana', 'Brown Banana'],
    'Lemon': ['Yellow Lemon', 'Green Lemon'],
    'Tomato': ['Red', 'Green', 'Yellow', 'Brown'],
  };
  Iterable<String>? selectedValues;

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

  Color _getColorByChip(String text) {
    Random random = Random(text.hashCode);
    double hue = random.nextDouble() * 360;
    return HSLColor.fromAHSL(1, hue, 0.5, 0.5).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSelect<String>(
      constraints: const BoxConstraints(minWidth: 200),
      itemBuilder: (context, item) {
        var color = _getColorByChip(item);
        return MultiSelectChip(
          style: const ButtonStyle.primary().withBackgroundColor(
            color: color,
            hoverColor: color.withLuminance(0.3),
          ),
          value: item,
          child: Text(item),
        );
      },
      onChanged: (value) {
        setState(() {
          selectedValues = value;
        });
      },
      placeholder: const Text('Select a fruit'),
      popup: (context) => SelectPopup.builder(
        builder: (context, searchQuery) async {
          final filteredFruits = searchQuery == null
              ? fruits.entries.toList()
              : _filteredFruits(searchQuery).toList();
          await Future.delayed(const Duration(milliseconds: 500));
          return SelectItemBuilder(
            builder: (context, index) {
              final entry = filteredFruits[index % filteredFruits.length];
              return SelectGroup(
                headers: [SelectLabel(child: Text(entry.key))],
                children: [
                  for (final value in entry.value)
                    SelectItemButton(
                      style: const ButtonStyle.ghost().withBackgroundColor(
                        hoverColor: _getColorByChip(value).withLuminance(0.3),
                      ),
                      value: value,
                      child: Text(value),
                    ),
                ],
              );
            },
            childCount: filteredFruits.isEmpty ? 0 : null,
          );
        },
        emptyBuilder: (context) {
          return const Center(child: Text('No fruit found'));
        },
        loadingBuilder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
        searchPlaceholder: const Text('Search fruit'),
      ),
      value: selectedValues,
    );
  }
}
