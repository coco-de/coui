import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// KBSearchBar 유즈케이스
@UseCase(
  name: 'default',
  type: KBSearchBar,
  path: '[Component]',
)
Widget buildKBSearchBarDefaultUseCase(BuildContext context) {
  final hint = context.knobs.string(initialValue: '검색', label: 'hint');
  final dense = context.knobs.boolean(label: 'isDense');
  final elevation = context.knobs.double.slider(
    label: 'elevation',
    max: 8,
  );

  return Padding(
    padding: const EdgeInsets.all(16),
    child: KBSearchBar(
      elevation: elevation,
      hintText: hint,
      isDense: dense,
      onChanged: (value) => debugPrint('changed: $value'),
      onSearch: (value) => debugPrint('search: $value'),
    ),
  );
}
