import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'colors', type: ColorScheme)
Widget buildColorSchemeUseCase(BuildContext context) {
  final colorScheme = coui.Theme.of(context).colorScheme;
  final colors = {
    'accent': colorScheme.accent,
    'accentForeground': colorScheme.accentForeground,
    'background': colorScheme.background,
    'border': colorScheme.border,
    'card': colorScheme.card,
    'cardForeground': colorScheme.cardForeground,
    'destructive': colorScheme.destructive,
    'foreground': colorScheme.foreground,
    'input': colorScheme.input,
    'muted': colorScheme.muted,
    'mutedForeground': colorScheme.mutedForeground,
    'popover': colorScheme.popover,
    'popoverForeground': colorScheme.popoverForeground,
    'primary': colorScheme.primary,
    'primaryForeground': colorScheme.primaryForeground,
    'ring': colorScheme.ring,
    'secondary': colorScheme.secondary,
    'secondaryForeground': colorScheme.secondaryForeground,
  };

  return ListView.builder(
    itemBuilder: (context, index) {
      final name = colors.keys.elementAtOrNull(index) ?? '';
      final color = colors.values.elementAtOrNull(index) ?? Colors.transparent;

      return ListTile(
        leading: Container(color: color, height: 24, width: 24),
        subtitle: Text(color.toString()),
        title: Text(name),
      );
    },
    itemCount: colors.length,
  );
}
