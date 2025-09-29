import 'package:core/core.dart' hide UseCase;
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'AppBar',
  type: AppBar,
  path: '[Component]',
)
/// AppBar 유즈케이스
Widget buildWidgetbookAppBarUseCase(BuildContext context) {
  final isBack = context.knobs.boolean(
    initialValue: true,
    label: 'Show Back Button',
  );
  final title = context.knobs.string(
    initialValue: 'AppBar Title',
    label: 'AppBar Title',
  );
  final action = context.knobs.object.dropdown<int>(
    label: 'Actions',
    labelBuilder: (value) {
      return <String>['Home', 'Cart', 'Notification'][value];
    },
    options: List.generate(3, (int i) => i),
  );

  return Scaffold(
    appBar: KBAppBar(
      actions: [
        <Widget>[
              IconButton(icon: Assets.svg.actionHome.svg(), onPressed: () {}),
              IconButton(icon: Assets.svg.actionCart.svg(), onPressed: () {}),
              IconButton(icon: Assets.svg.actionBell.svg(), onPressed: () {}),
            ].elementAtOrNull(action) ??
            const SizedBox.shrink(),
      ],
      leading: isBack
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: context.colorScheme.onSurface,
              ),
              onPressed: () {},
            )
          : null,
      title: title,
    ),
  );
}
