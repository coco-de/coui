import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'colors',
  type: ColorScheme,
)
Widget buildColorSchemeUseCase(BuildContext context) {
  final colorScheme = coui.Theme.of(context).colorScheme;
  final colors = {
    'background': colorScheme.background,
    'foreground': colorScheme.foreground,
    'card': colorScheme.card,
    'cardForeground': colorScheme.cardForeground,
    'popover': colorScheme.popover,
    'popoverForeground': colorScheme.popoverForeground,
    'primary': colorScheme.primary,
    'primaryForeground': colorScheme.primaryForeground,
    'secondary': colorScheme.secondary,
    'secondaryForeground': colorScheme.secondaryForeground,
    'muted': colorScheme.muted,
    'mutedForeground': colorScheme.mutedForeground,
    'accent': colorScheme.accent,
    'accentForeground': colorScheme.accentForeground,
    'destructive': colorScheme.destructive,
    'border': colorScheme.border,
    'input': colorScheme.input,
    'ring': colorScheme.ring,
  };

  return ListView.builder(
    itemBuilder: (context, index) {
      final name = colors.keys.elementAtOrNull(index) ?? '';
      final color = colors.values.elementAtOrNull(index) ?? Colors.transparent;
      return ListTile(
        leading: Container(
          color: color,
          height: 24,
          width: 24,
        ),
        subtitle: Text(color.toString()),
        title: Text(name),
      );
    },
    itemCount: colors.length,
  );
}
