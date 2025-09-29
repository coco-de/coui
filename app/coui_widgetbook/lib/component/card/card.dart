import 'package:flutter/material.dart';
import 'package:coui_widgetbook/foundation/group.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// ToggleCard 유즈케이스
@UseCase(name: 'ToggleCard', type: ToggleCard, path: '[Card]')
Widget buildWidgetbookNavigationUseCase(BuildContext context) {
  return WidgetbookGroup(
    label: 'Cards',
    children: [
      ToggleCard(
        body: context.knobs.string(
          initialValue: 'This is a toggle card',
          label: 'Body',
        ),
        onChanged: ({required bool value}) async {
          WidgetbookState.of(context).updateQueryField(
            field: 'Value',
            group: 'knobs',
            value: value ? 'true' : 'false',
          );

          return value;
        },
        title: context.knobs.string(
          initialValue: 'Toggle Card',
          label: 'Title',
        ),
        value: context.knobs.boolean(initialValue: true, label: 'Value'),
      ),
    ],
  );
}
