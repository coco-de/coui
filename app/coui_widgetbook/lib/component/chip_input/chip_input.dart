import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.ChipInput] use case.
@UseCase(
  name: 'default',
  type: coui.ChipInput,
)
Widget buildChipInputDefaultUseCase(BuildContext _) {
  return coui.ChipInput<String>(
    chipBuilder: (context, chip) {
      return coui.Chip(
        child: Text(chip),
      );
    },
    chips: const ['Flutter', 'Dart', 'CoUI'],
    onChanged: (chips) {
      // ignore: avoid_print
      print('Chips changed: $chips');
    },
  );
}

/// A [coui.ChipInput] with suggestions use case.
@UseCase(
  name: 'with suggestions',
  type: coui.ChipInput,
)
Widget buildChipInputWithSuggestionsUseCase(BuildContext _) {
  final suggestions = [
    'Flutter',
    'Dart',
    'React',
    'Vue',
    'Angular',
    'Svelte',
  ];

  return coui.ChipInput<String>(
    chipBuilder: (context, chip) {
      return coui.Chip(
        child: Text(chip),
      );
    },
    chips: const ['Flutter'],
    onChanged: (chips) {
      // ignore: avoid_print
      print('Chips: $chips');
    },
    suggestionBuilder: (context, suggestion) {
      return coui.Chip(child: Text(suggestion));
    },
    suggestions: suggestions,
  );
}

/// A custom [coui.ChipInput] use case.
@UseCase(
  name: 'custom',
  type: coui.ChipInput,
)
Widget buildChipInputCustomUseCase(BuildContext _) {
  return coui.ChipInput<String>(
    chipBuilder: (context, chip) {
      return coui.Chip(
        leading: const Icon(Icons.tag, size: 16),
        child: Text('#$chip'),
      );
    },
    chips: const ['flutter', 'dart', 'mobile'],
    onChanged: (chips) {
      // ignore: avoid_print
      print('Tags: $chips');
    },
  );
}
