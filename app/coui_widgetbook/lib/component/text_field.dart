import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.TextField,
)
Widget buildTextFieldDefaultUseCase(BuildContext context) {
  return coui.TextField(
    onChanged: (value) => print('Text changed to: $value'),
    hintText: context.knobs.stringOrNull(label: 'hintText'),
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    readOnly: context.knobs.boolean(label: 'readOnly', initialValue: false),
  );
}

@UseCase(
  name: 'with placeholder',
  type: coui.TextField,
)
Widget buildTextFieldWithPlaceholderUseCase(BuildContext context) {
  return coui.TextField(
    onChanged: (value) => print('Text changed to: $value'),
    placeholder: Text(context.knobs.string(
      label: 'placeholder',
      initialValue: 'Enter your text here...',
    )),
  );
}

@UseCase(
  name: 'password',
  type: coui.TextField,
)
Widget buildTextFieldPasswordUseCase(BuildContext context) {
  return coui.TextField(
    onChanged: (value) => print('Text changed to: $value'),
    obscureText: true,
    hintText: 'Password',
    features: const [coui.InputFeature.passwordToggle()],
  );
}

@UseCase(
  name: 'with features',
  type: coui.TextField,
)
Widget buildTextFieldWithFeaturesUseCase(BuildContext context) {
  return coui.TextField(
    onChanged: (value) => print('Text changed to: $value'),
    hintText: 'Search...',
    features: [
      coui.InputFeature.leading(
        const Icon(Icons.search),
        visibility: coui.InputFeatureVisibility.always,
      ),
      coui.InputFeature.clear(
        visibility: coui.InputFeatureVisibility.textNotEmpty,
      ),
      coui.InputFeature.copy(
        visibility: coui.InputFeatureVisibility.hasSelection,
      ),
    ],
  );
}