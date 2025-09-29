import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// KBDropdown 유즈케이스
@UseCase(
  name: 'default',
  type: KBDropdown,
  path: '[Component]',
)
Widget buildKBDropdownDefaultUseCase(BuildContext context) {
  final isExpanded = context.knobs.boolean(
    initialValue: true,
    label: 'isExpanded',
  );
  final isEnabled = context.knobs.boolean(
    initialValue: true,
    label: 'isEnabled',
  );
  final elevation = context.knobs.int.slider(
    initialValue: 8,
    label: 'elevation',
    max: 16,
  );
  final value = context.knobs.object.dropdown<String>(
    initialOption: 'fiction',
    label: 'value',
    labelBuilder: (v) => v,
    options: const <String>['fiction', 'essay', 'science'],
  );

  return Padding(
    padding: const EdgeInsets.all(16),
    child: KBDropdown<String>(
      elevation: elevation,
      hintText: '카테고리를 선택해주세요',
      isEnabled: isEnabled,
      isExpanded: isExpanded,
      items: const [
        DropdownMenuItem(value: 'fiction', child: Text('소설')),
        DropdownMenuItem(value: 'essay', child: Text('에세이')),
        DropdownMenuItem(value: 'science', child: Text('과학')),
      ],
      labelText: '카테고리',
      onChanged: (v) => debugPrint('onChanged: $v'),
      value: value,
    ),
  );
}

/// KBDropdown 유즈케이스
@UseCase(
  name: 'disabled',
  type: KBDropdown,
  path: '[Component]',
)
Widget buildKBDropdownDisabledUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: KBDropdown<String>(
      hintText: '비활성화 상태',
      isEnabled: false,
      items: const [
        DropdownMenuItem(value: 'fiction', child: Text('소설')),
        DropdownMenuItem(value: 'essay', child: Text('에세이')),
        DropdownMenuItem(value: 'science', child: Text('과학')),
      ],
      labelText: '카테고리',
      onChanged: (_) {},
      value: 'fiction',
    ),
  );
}
