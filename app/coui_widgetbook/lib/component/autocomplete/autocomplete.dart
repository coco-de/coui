import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A replaceWord mode [coui.AutoComplete] use case.
@UseCase(
  name: 'replaceWord',
  type: coui.AutoComplete,
)
Widget buildAutoCompleteReplaceWordUseCase(BuildContext context) {
  final fruits = [
    'Apple',
    'Apricot',
    'Banana',
    'Blueberry',
    'Cherry',
    'Cranberry',
    'Grape',
    'Grapefruit',
    'Kiwi',
    'Lemon',
    'Lime',
    'Mango',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Plum',
    'Strawberry',
    'Watermelon',
  ];

  final controller = TextEditingController();
  final suggestions = ValueNotifier<List<String>>([]);

  void onTextChanged() {
    final text = controller.text.toLowerCase();
    if (text.isEmpty) {
      suggestions.value = [];
    } else {
      suggestions.value = fruits
          .where((fruit) => fruit.toLowerCase().contains(text))
          .toList();
    }
  }

  controller.addListener(onTextChanged);

  return ValueListenableBuilder<List<String>>(
    builder: (context, suggestionList, child) {
      return coui.AutoComplete(
        mode: coui.AutoCompleteMode.replaceWord,
        suggestions: suggestionList,
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Type a fruit name...',
            labelText: 'Fruit',
          ),
        ),
      );
    },
    valueListenable: suggestions,
  );
}

/// An append mode [coui.AutoComplete] use case.
@UseCase(
  name: 'append',
  type: coui.AutoComplete,
)
Widget buildAutoCompleteAppendUseCase(BuildContext context) {
  final tags = [
    '#flutter',
    '#dart',
    '#mobile',
    '#web',
    '#backend',
    '#serverpod',
    '#jaspr',
    '#coui',
    '#design',
    '#ui',
    '#ux',
  ];

  final controller = TextEditingController();
  final suggestions = ValueNotifier<List<String>>([]);

  void onTextChanged() {
    final text = controller.text.toLowerCase();
    final lastWord = text.split(' ').last;

    if (lastWord.isEmpty || !lastWord.startsWith('#')) {
      suggestions.value = [];
    } else {
      suggestions.value = tags
          .where((tag) => tag.toLowerCase().startsWith(lastWord))
          .toList();
    }
  }

  controller.addListener(onTextChanged);

  return ValueListenableBuilder<List<String>>(
    builder: (context, suggestionList, child) {
      return coui.AutoComplete(
        completer: (text) => '$text ',
        mode: coui.AutoCompleteMode.append,
        suggestions: suggestionList,
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Type tags starting with #...',
            labelText: 'Tags',
          ),
          maxLines: 3,
        ),
      );
    },
    valueListenable: suggestions,
  );
}

/// A replaceAll mode [coui.AutoComplete] use case.
@UseCase(
  name: 'replaceAll',
  type: coui.AutoComplete,
)
Widget buildAutoCompleteReplaceAllUseCase(BuildContext context) {
  final cities = [
    'Seoul',
    'Busan',
    'Incheon',
    'Daegu',
    'Daejeon',
    'Gwangju',
    'Ulsan',
    'Suwon',
    'Changwon',
    'Seongnam',
  ];

  final controller = TextEditingController();
  final suggestions = ValueNotifier<List<String>>([]);

  void onTextChanged() {
    final text = controller.text.toLowerCase();
    if (text.isEmpty) {
      suggestions.value = [];
    } else {
      suggestions.value = cities
          .where((city) => city.toLowerCase().startsWith(text))
          .toList();
    }
  }

  controller.addListener(onTextChanged);

  return ValueListenableBuilder<List<String>>(
    builder: (context, suggestionList, child) {
      return coui.AutoComplete(
        mode: coui.AutoCompleteMode.replaceAll,
        suggestions: suggestionList,
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Search city...',
            labelText: 'City',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      );
    },
    valueListenable: suggestions,
  );
}
