import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'typography', type: coui.Typography)
Widget buildTypographyUseCase(BuildContext context) {
  final typography = coui.Theme.of(context).typography;
  final styles = {
    'blockQuote': typography.blockQuote,
    'h1': typography.h1,
    'h2': typography.h2,
    'h3': typography.h3,
    'h4': typography.h4,
    'inlineCode': typography.inlineCode,
    'large': typography.large,
    'lead': typography.lead,
    'p': typography.p,
    'small': typography.small,
    'textMuted': typography.textMuted,
  };

  return ListView.builder(
    itemBuilder: (context, index) {
      final name = styles.keys.elementAtOrNull(index) ?? '';
      final style = styles.values.elementAtOrNull(index);

      return ListTile(
        subtitle: Text(
          'The quick brown fox jumps over the lazy dog',
          style: style,
        ),
        title: Text(name, style: style),
      );
    },
    itemCount: styles.length,
  );
}
