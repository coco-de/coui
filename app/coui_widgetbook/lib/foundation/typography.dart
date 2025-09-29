import 'package:core/core.dart' hide UseCase;
import 'package:flutter/widgets.dart';
import 'package:coui_widgetbook/foundation/group.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Typography 유즈케이스
@UseCase(name: 'Typography', type: TextStyle, path: '[Foundation]')
Widget buildTypographyThemeDataUseCase(BuildContext context) {
  return WidgetbookGroup(
    label: 'Typography',
    children:
        [
              TypographyLabel(
                label: 'DisplayLarge',
                style: context.textTheme.displayLarge,
              ),
              TypographyLabel(
                label: 'DisplayMedium',
                style: context.textTheme.displayMedium,
              ),
              TypographyLabel(
                label: 'DisplaySmall',
                style: context.textTheme.displaySmall,
              ),
              TypographyLabel(
                label: 'HeadlineLarge',
                style: context.textTheme.headlineLarge,
              ),
              TypographyLabel(
                label: 'HeadlineMedium',
                style: context.textTheme.headlineMedium,
              ),
              TypographyLabel(
                label: 'HeadlineSmall',
                style: context.textTheme.headlineSmall,
              ),
              TypographyLabel(
                label: 'TitleLarge',
                style: context.textTheme.titleLarge,
              ),
              TypographyLabel(
                label: 'TitleMedium',
                style: context.textTheme.titleMedium,
              ),
              TypographyLabel(
                label: 'TitleSmall',
                style: context.textTheme.titleSmall,
              ),
              TypographyLabel(
                label: 'BodyLarge',
                style: context.textTheme.bodyLarge,
              ),
              TypographyLabel(
                label: 'BodyMedium',
                style: context.textTheme.bodyMedium,
              ),
              TypographyLabel(
                label: 'BodySmall',
                style: context.textTheme.bodySmall,
              ),
              TypographyLabel(
                label: 'LabelLarge',
                style: context.textTheme.labelLarge,
              ),
              TypographyLabel(
                label: 'LabelMedium',
                style: context.textTheme.labelMedium,
              ),
              TypographyLabel(
                label: 'LabelSmall',
                style: context.textTheme.labelSmall,
              ),
            ]
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.small),
                child: e,
              ),
            )
            .toList(),
  );
}

/// TypographyLabel 위젯
class TypographyLabel extends StatelessWidget {
  /// TypographyLabel 생성자
  const TypographyLabel({required this.label, this.style, super.key});

  /// 라벨
  final String label;

  /// 스타일
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: style);
  }
}
