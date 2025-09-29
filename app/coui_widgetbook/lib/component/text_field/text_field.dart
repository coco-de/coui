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
    enabled: context.knobs.boolean(initialValue: true, label: 'enabled'),
    hintText: context.knobs.stringOrNull(label: 'hintText'),
    onChanged: (value) => print('Text changed to: $value'),
    readOnly: context.knobs.boolean(initialValue: false, label: 'readOnly'),
  );
}

@UseCase(
  name: 'with placeholder',
  type: coui.TextField,
)
Widget buildTextFieldWithPlaceholderUseCase(BuildContext context) {
  return coui.TextField(
    onChanged: (value) => print('Text changed to: $value'),
    placeholder: Text(
      context.knobs.string(
        initialValue: 'Enter your text here...',
        label: 'placeholder',
      ),
    ),
  );
}

@UseCase(
  name: 'password',
  type: coui.TextField,
)
Widget buildTextFieldPasswordUseCase(BuildContext context) {
  return coui.TextField(
    features: const [coui.InputFeature.passwordToggle()],
    hintText: 'Password',
    obscureText: true,
    onChanged: (value) => print('Text changed to: $value'),
  );
}

@UseCase(
  name: 'with features',
  type: coui.TextField,
)
Widget buildTextFieldWithFeaturesUseCase(BuildContext context) {
  return coui.TextField(
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
    hintText: 'Search...',
    onChanged: (value) => print('Text changed to: $value'),
  );
}
