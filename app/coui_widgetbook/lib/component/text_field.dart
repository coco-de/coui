import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:coui_widgetbook/foundation/group.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// KBTextField default 유즈케이스
@UseCase(name: 'TextField', type: KBTextField, path: '[Component]')
Widget buildWidgetbookNavigationUseCase(BuildContext context) {
  return WidgetbookGroup(
    label: 'TextFields',
    children: [
      KBTextField(
        autofocus: true,
        controller: TextEditingController(),
        hintText: context.i10n.login.text_field_hint_email,
        labelText: context.i10n.login.label_text_email,
      ),
      KBTextField(
        controller: TextEditingController(),
        hintText: context.i10n.login.text_field_hint_password,
        isPassword: true,
        labelText: context.i10n.login.label_text_password,
        textInputType: TextInputType.visiblePassword,
      ),
    ],
  );
}

/// KBTextField password 유즈케이스
@UseCase(name: 'password', type: KBTextField, path: '[Component]')
Widget buildKBTextFieldPasswordUseCase(BuildContext context) {
  final label = context.knobs.string(initialValue: '비밀번호', label: 'label');
  final hint = context.knobs.string(initialValue: '비밀번호 입력', label: 'hint');

  return Padding(
    padding: const EdgeInsets.all(16),
    child: KBTextField(
      controller: TextEditingController(),
      hintText: hint,
      isPassword: true,
      labelText: label,
      textInputType: TextInputType.visiblePassword,
    ),
  );
}

/// KBTextField dense 유즈케이스
@UseCase(name: 'dense', type: KBTextField, path: '[Component]')
Widget buildKBTextFieldDenseUseCase(BuildContext context) {
  final label = context.knobs.string(initialValue: '이메일', label: 'label');
  final hint = context.knobs.string(
    initialValue: 'example@coui.kr',
    label: 'hint',
  );
  final horizontal = context.knobs.double.slider(
    initialValue: 12,
    label: 'contentPadding.h',
    max: 24,
  );
  final vertical = context.knobs.double.slider(
    initialValue: 8,
    label: 'contentPadding.v',
    max: 16,
  );

  return Padding(
    padding: const EdgeInsets.all(16),
    child: KBTextField(
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      controller: TextEditingController(),
      hintText: hint,
      labelText: label,
    ),
  );
}

/// KBTextField suffix 유즈케이스
@UseCase(name: 'with_suffix', type: KBTextField, path: '[Component]')
Widget buildKBTextFieldWithSuffixUseCase(BuildContext context) {
  final label = context.knobs.string(initialValue: '검색', label: 'label');
  final hint = context.knobs.string(initialValue: '검색어 입력', label: 'hint');

  return Padding(
    padding: const EdgeInsets.all(16),
    child: KBTextField(
      controller: TextEditingController(),
      hintText: hint,
      labelText: label,
      suffix: IconButton(icon: const Icon(Icons.search), onPressed: () {}),
    ),
  );
}

/// KBTextField 최대 길이 유즈케이스
@UseCase(name: 'maxlength', type: KBTextField, path: '[Component]')
Widget buildKBTextFieldMaxLengthUseCase(BuildContext context) {
  final label = context.knobs.string(initialValue: '닉네임', label: 'label');
  final hint = context.knobs.string(initialValue: '최대 10자', label: 'hint');
  final maxLen = context.knobs.int.slider(
    initialValue: 10,
    label: 'maxLength',
    max: 30,
    min: 1,
  );

  return Padding(
    padding: const EdgeInsets.all(16),
    child: KBTextField(
      controller: TextEditingController(),
      hintText: hint,
      labelText: label,
      maxLength: maxLen,
    ),
  );
}
