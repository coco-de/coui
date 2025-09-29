import 'package:core/core.dart' hide UseCase;
import 'package:flutter/material.dart';
import 'package:icons_launcher/cli_commands.dart';
import 'package:coui_widgetbook/foundation/group.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Button', type: KBButton, path: '[Component]')
/// KBButton 유즈케이스
Widget buildWidgetbookButtonUseCase(BuildContext context) {
  final text = getIt<Faker>().lorem.word(length: 10).capitalize();

  return WidgetbookGroup(
    label: 'Coui Button',
    children: [
      WidgetbookButton(
        button: KBButton(
          onPressed: () {},
          text: context.knobs.string(initialValue: text, label: 'Text'),
        ),
        label: 'Elevated Button',
      ),
      WidgetbookButton(
        button: KBButton(
          buttonType: ButtonType.filled,
          onPressed: () {},
          text: context.knobs.string(initialValue: text, label: 'Text'),
        ),
        label: 'Filled Button',
      ),
      WidgetbookButton(
        button: KBButton(
          buttonType: ButtonType.outlined,
          onPressed: () {},
          text: context.knobs.string(initialValue: text, label: 'Text'),
        ),
        label: 'Outlined Button',
      ),
      WidgetbookButton(
        button: KBButton(
          buttonType: ButtonType.text,
          onPressed: () {},
          text: context.knobs.string(initialValue: text, label: 'Text'),
        ),
        label: 'Text Button',
      ),
      WidgetbookButton(
        button: KBButton(
          buttonType: ButtonType.tonal,
          onPressed: () {},
          text: context.knobs.string(initialValue: text, label: 'Text'),
        ),
        label: 'Tonal Button',
      ),
      WidgetbookButton(
        button: KBButton(
          buttonType: ButtonType.filled,
          isEnabled: false,
          onPressed: () {},
          text: context.knobs.string(initialValue: text, label: 'Text'),
        ),
        label: 'Disabled (Filled)',
      ),
      WidgetbookButton(
        button: KBButton(
          icon: const Icon(Icons.add),
          onPressed: () {},
          text: context.knobs.string(initialValue: text, label: 'Text'),
        ),
        label: 'With Icon (Elevated)',
      ),
      WidgetbookButton(
        button: KBButton(
          buttonType: ButtonType.outlined,
          isExpanded: true,
          onPressed: () {},
          text: context.knobs.string(initialValue: text, label: 'Text'),
        ),
        label: 'Expanded (Outlined)',
      ),
    ],
  );
}

/// BookButton 위젯
class WidgetbookButton extends StatelessWidget {
  /// WidgetbookButton 생성자
  const WidgetbookButton({
    required this.label,
    required this.button,
    super.key,
  });

  /// 라벨
  final String label;

  /// 버튼
  final KBButton button;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Insets.xxSmall),
      child: Column(
        children: [
          Text(label, style: context.textTheme.titleMedium),
          Gap.xxSmall(),
          button,
        ],
      ),
    );
  }
}
