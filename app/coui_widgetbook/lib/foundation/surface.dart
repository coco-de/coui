import 'package:core/core.dart' hide UseCase;
import 'package:flutter/material.dart';
import 'package:coui_widgetbook/foundation/group.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// ColorScheme 유즈케이스
@UseCase(name: 'ColorScheme', type: ColorScheme, path: '[Foundation]')
Widget buildColorUseCase(BuildContext context) {
  return WidgetbookGroup(
    label: 'ColorScheme',
    children: [
      ColorLabel(color: context.colorScheme.primary, label: 'Primary'),
      ColorLabel(color: context.colorScheme.onPrimary, label: 'onPrimary'),
      ColorLabel(
        color: context.colorScheme.primaryContainer,
        label: 'primaryContainer',
      ),
      ColorLabel(
        color: context.colorScheme.onPrimaryContainer,
        label: 'onPrimaryContainer',
      ),
      ColorLabel(color: context.colorScheme.secondary, label: 'secondary'),
      ColorLabel(color: context.colorScheme.onSecondary, label: 'onSecondary'),
      ColorLabel(
        color: context.colorScheme.secondaryContainer,
        label: 'secondaryContainer',
      ),
      ColorLabel(
        color: context.colorScheme.onSecondaryContainer,
        label: 'onSecondaryContainer',
      ),
      ColorLabel(color: context.colorScheme.tertiary, label: 'tertiary'),
      ColorLabel(color: context.colorScheme.onTertiary, label: 'onTertiary'),
      ColorLabel(
        color: context.colorScheme.tertiaryContainer,
        label: 'tertiaryContainer',
      ),
      ColorLabel(
        color: context.colorScheme.onTertiaryContainer,
        label: 'onTertiaryContainer',
      ),
      ColorLabel(color: context.colorScheme.error, label: 'error'),
      ColorLabel(color: context.colorScheme.onError, label: 'onError'),
      ColorLabel(
        color: context.colorScheme.errorContainer,
        label: 'errorContainer',
      ),
      ColorLabel(
        color: context.colorScheme.onErrorContainer,
        label: 'onErrorContainer',
      ),
      ColorLabel(color: context.colorScheme.surface, label: 'surface'),
      ColorLabel(color: context.colorScheme.onSurface, label: 'onSurface'),
      ColorLabel(
        color: context.colorScheme.surfaceContainerHighest,
        label: 'surfaceContainerHighest',
      ),
      ColorLabel(
        color: context.colorScheme.onSurfaceVariant,
        label: 'onSurfaceVariant',
      ),
    ],
  );
}

/// ColorLabel 위젯
class ColorLabel extends StatelessWidget {
  /// ColorLabel 생성자
  const ColorLabel({required this.label, required this.color, super.key});

  /// 라벨
  final String label;

  /// 색상
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Insets.xxSmall),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(4),
              color: color,
            ),
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 16),
          Text(label),
        ],
      ),
    );
  }
}
