import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Divider] use case.
@UseCase(
  name: 'default',
  type: coui.Divider,
)
Widget buildDividerDefaultUseCase(BuildContext context) {
  return coui.Divider(
    color: context.knobs.colorOrNull(label: 'color'),
    endIndent: context.knobs.double.slider(
      initialValue: 0,
      label: 'endIndent',
      max: 100,
      min: 0,
    ),
    indent: context.knobs.double.slider(
      initialValue: 0,
      label: 'indent',
      max: 100,
      min: 0,
    ),
    thickness: context.knobs.double.slider(
      initialValue: 1,
      label: 'thickness',
      max: 10,
      min: 1,
    ),
  );
}

/// A [coui.Divider] use case with a child widget.
@UseCase(
  name: 'with child',
  type: coui.Divider,
)
Widget buildDividerWithChildUseCase(BuildContext context) {
  return coui.Divider(
    color: context.knobs.colorOrNull(label: 'color'),
    endIndent: context.knobs.double.slider(
      initialValue: 20,
      label: 'endIndent',
      max: 100,
      min: 0,
    ),
    indent: context.knobs.double.slider(
      initialValue: 20,
      label: 'indent',
      max: 100,
      min: 0,
    ),
    thickness: context.knobs.double.slider(
      initialValue: 1,
      label: 'thickness',
      max: 10,
      min: 1,
    ),
    child: Text(context.knobs.string(initialValue: 'OR', label: 'child text')),
  );
}

/// A default [coui.VerticalDivider] use case.
@UseCase(
  name: 'default',
  type: coui.VerticalDivider,
)
Widget buildVerticalDividerDefaultUseCase(BuildContext context) {
  return SizedBox(
    height: 100,
    child: coui.VerticalDivider(
      color: context.knobs.colorOrNull(label: 'color'),
      endIndent: context.knobs.double.slider(
        initialValue: 0,
        label: 'endIndent',
        max: 50,
        min: 0,
      ),
      indent: context.knobs.double.slider(
        initialValue: 0,
        label: 'indent',
        max: 50,
        min: 0,
      ),
      thickness: context.knobs.double.slider(
        initialValue: 1,
        label: 'thickness',
        max: 10,
        min: 1,
      ),
    ),
  );
}
