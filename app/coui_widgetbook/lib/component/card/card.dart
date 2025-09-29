import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.Card,
)
Widget buildCardDefaultUseCase(BuildContext context) {
  return coui.Card(
    child: SizedBox(
      width: 200,
      height: 100,
      child: Center(
        child: Text(context.knobs.string(label: 'text', initialValue: 'Default Card')),
      ),
    ),
  );
}

@UseCase(
  name: 'filled',
  type: coui.Card,
)
Widget buildCardFilledUseCase(BuildContext context) {
  return coui.Card(
    filled: true,
    fillColor: context.knobs.colorOrNull(label: 'fillColor'),
    child: SizedBox(
      width: 200,
      height: 100,
      child: Center(
        child: Text(context.knobs.string(label: 'text', initialValue: 'Filled Card')),
      ),
    ),
  );
}

@UseCase(
  name: 'with border',
  type: coui.Card,
)
Widget buildCardWithBorderUseCase(BuildContext context) {
  return coui.Card(
    borderColor: context.knobs.color(label: 'borderColor', initialValue: Colors.blue),
    borderWidth: context.knobs.double.slider(
      label: 'borderWidth',
      initialValue: 2,
      min: 1,
      max: 10,
    ),
    borderRadius: BorderRadius.circular(
      context.knobs.double.slider(
        label: 'borderRadius',
        initialValue: 12,
        min: 0,
        max: 32,
      ),
    ),
    child: SizedBox(
      width: 200,
      height: 100,
      child: Center(
        child: Text(context.knobs.string(label: 'text', initialValue: 'Card with Border')),
      ),
    ),
  );
}

@UseCase(
  name: 'with shadow',
  type: coui.Card,
)
Widget buildCardWithShadowUseCase(BuildContext context) {
  return coui.Card(
    boxShadow: [
      BoxShadow(
        color: context.knobs.color(label: 'shadowColor', initialValue: Colors.black.withOpacity(0.2)),
        blurRadius: context.knobs.double.slider(
          label: 'blurRadius',
          initialValue: 8,
          min: 0,
          max: 20,
        ),
        spreadRadius: context.knobs.double.slider(
          label: 'spreadRadius',
          initialValue: 0,
          min: 0,
          max: 10,
        ),
        offset: Offset(
          context.knobs.double.input(label: 'offsetX', initialValue: 0),
          context.knobs.double.input(label: 'offsetY', initialValue: 4),
        ),
      ),
    ],
    child: SizedBox(
      width: 200,
      height: 100,
      child: Center(
        child: Text(context.knobs.string(label: 'text', initialValue: 'Card with Shadow')),
      ),
    ),
  );
}