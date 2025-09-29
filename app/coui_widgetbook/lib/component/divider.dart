import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.Divider,
)
Widget buildDividerDefaultUseCase(BuildContext context) {
  return coui.Divider(
    color: context.knobs.colorOrNull(label: 'color'),
    thickness: context.knobs.double.slider(
      label: 'thickness',
      initialValue: 1,
      min: 1,
      max: 10,
    ),
    indent: context.knobs.double.slider(
      label: 'indent',
      initialValue: 0,
      min: 0,
      max: 100,
    ),
    endIndent: context.knobs.double.slider(
      label: 'endIndent',
      initialValue: 0,
      min: 0,
      max: 100,
    ),
  );
}

@UseCase(
  name: 'with child',
  type: coui.Divider,
)
Widget buildDividerWithChildUseCase(BuildContext context) {
  return coui.Divider(
    color: context.knobs.colorOrNull(label: 'color'),
    thickness: context.knobs.double.slider(
      label: 'thickness',
      initialValue: 1,
      min: 1,
      max: 10,
    ),
    indent: context.knobs.double.slider(
      label: 'indent',
      initialValue: 20,
      min: 0,
      max: 100,
    ),
    endIndent: context.knobs.double.slider(
      label: 'endIndent',
      initialValue: 20,
      min: 0,
      max: 100,
    ),
    child: Text(context.knobs.string(label: 'child text', initialValue: 'OR')),
  );
}

@UseCase(
  name: 'default',
  type: coui.VerticalDivider,
)
Widget buildVerticalDividerDefaultUseCase(BuildContext context) {
  return SizedBox(
    height: 100,
    child: coui.VerticalDivider(
      color: context.knobs.colorOrNull(label: 'color'),
      thickness: context.knobs.double.slider(
        label: 'thickness',
        initialValue: 1,
        min: 1,
        max: 10,
      ),
      indent: context.knobs.double.slider(
        label: 'indent',
        initialValue: 0,
        min: 0,
        max: 50,
      ),
      endIndent: context.knobs.double.slider(
        label: 'endIndent',
        initialValue: 0,
        min: 0,
        max: 50,
      ),
    ),
  );
}
