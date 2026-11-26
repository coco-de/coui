/// Validated 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="validated/...">` · `<Card demo>` 가 읽는다. 같은 이름의 Web
/// 파일(`validated_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'validated_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _validated;

/// 장면 이름(`validated/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'validated/anatomy': () => _sized(
    Validated(
      state: CoreValidationState.invalid,
      message: const Text(validatedInvalidMessage),
      child: TextField(initialValue: validatedPreviewValue),
    ),
  ),
  'validated/states': () => _columns([
    for (final state in CoreValidationState.values)
      _captioned(
        state.name,
        Validated(
          state: state,
          message: Text(validatedPreviewMessage(state)),
          child: TextField(initialValue: validatedPreviewValue),
        ),
      ),
  ]),
  'validated/propagation': () => _columns([
    _captioned(
      'TextField',
      Validated(
        state: CoreValidationState.invalid,
        message: const Text(validatedSceneRetryMessage),
        child: TextField(placeholder: const Text('이름')),
      ),
    ),
    _captioned(
      'TextArea',
      Validated(
        state: CoreValidationState.invalid,
        message: const Text(validatedSceneRetryMessage),
        child: TextArea(placeholder: '자기소개', rows: 2),
      ),
    ),
    _captioned(
      'Checkbox',
      Validated(
        state: CoreValidationState.invalid,
        message: const Text(validatedSceneRetryMessage),
        child: Checkbox(checked: false, onChanged: (_) {}, label: '약관 동의'),
      ),
    ),
  ]),
  'validated/do-state': () => _card(
    Validated(
      state: CoreValidationState.invalid,
      message: const Text(validatedSceneRequiredMessage),
      child: TextField(placeholder: const Text('이름')),
    ),
  ),
  'validated/dont-border-color': () => _card(
    Validated(
      state: CoreValidationState.valid,
      message: const Text(validatedSceneCheckedMessage),
      child: TextField(initialValue: validatedPreviewValue, textFieldStyle: validatedSceneErrorBorder),
    ),
  ),
  'validated/do-per-field': () => _card(
    _stack([
      Validated(
        state: CoreValidationState.invalid,
        message: const Text(validatedSceneFormatMessage),
        child: TextField(placeholder: const Text('이메일')),
      ),
      Validated(
        child: TextField(placeholder: const Text('이름'), initialValue: validatedSceneNameValue),
      ),
    ]),
  ),
  'validated/dont-wrap-group': () => _card(
    Validated(
      state: CoreValidationState.invalid,
      message: const Text(validatedSceneFormatMessage),
      child: _stack([
        TextField(placeholder: const Text('이메일')),
        TextField(placeholder: const Text('이름'), initialValue: validatedSceneNameValue),
      ]),
    ),
  ),
  'validated/related-validator-hint': () => _card(const ValidatorHint(message: Text('8자 이상 입력해 주세요.'))),
  'validated/related-text-field': () =>
      _card(TextField(placeholder: const Text('이름'), errorText: validatedSceneRequiredMessage)),
  'validated/related-form-field': () =>
      _card(FormField(label: '이름', error: validatedSceneRequiredMessage, child: TextField())),
};

Widget _validated(Map<String, String> props, String? label) {
  final state = validatedPreviewState(props);
  return _sized(
    Validated(
      state: state,
      message: previewFlag(props, 'message') ? Text(validatedPreviewMessage(state)) : null,
      child: TextField(label: validatedPreviewLabel, initialValue: validatedPreviewValue),
    ),
  );
}

Widget _sized(Widget child, {double width = 240}) => SizedBox(width: width, child: child);

/// 좁은 카드 무대에 들어가는 폭.
Widget _card(Widget child) => _sized(child, width: 176);

/// 위아래로 쌓은 필드.
Widget _stack(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: CoreSpace.space8,
  children: children,
);

/// 옆으로 놓고, 좁으면 줄을 바꾸는 장면.
Widget _columns(List<Widget> children) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space16,
  runSpacing: CoreSpace.space16,
  children: children,
);

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => SizedBox(
  width: 208,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space8,
    children: [Text(caption).labelSmall.onSurfaceVariant, child],
  ),
);
