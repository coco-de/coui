/// Validated 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="validated/...">` · `<Card demo>` 가 읽는다. 같은 이름의
/// Flutter 파일(`validated_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'validated_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _validated;

/// 장면 이름(`validated/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'validated/anatomy': () => _sized(
    const Validated(
      state: CoreValidationState.invalid,
      message: Text(validatedInvalidMessage),
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
          child: const TextField(initialValue: validatedPreviewValue),
        ),
      ),
  ]),
  'validated/propagation': () => _columns([
    _captioned(
      'TextField',
      const Validated(
        state: CoreValidationState.invalid,
        message: Text(validatedSceneRetryMessage),
        child: TextField(placeholder: Text('이름')),
      ),
    ),
    _captioned(
      'TextArea',
      const Validated(
        state: CoreValidationState.invalid,
        message: Text(validatedSceneRetryMessage),
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
    const Validated(
      state: CoreValidationState.invalid,
      message: Text(validatedSceneRequiredMessage),
      child: TextField(placeholder: Text('이름')),
    ),
  ),
  'validated/dont-border-color': () => _card(
    const Validated(
      state: CoreValidationState.valid,
      message: Text(validatedSceneCheckedMessage),
      child: TextField(initialValue: validatedPreviewValue, textFieldStyle: validatedSceneErrorBorder),
    ),
  ),
  'validated/do-per-field': () => _card(
    _stack(const [
      Validated(
        state: CoreValidationState.invalid,
        message: Text(validatedSceneFormatMessage),
        child: TextField(placeholder: Text('이메일')),
      ),
      Validated(
        child: TextField(placeholder: Text('이름'), initialValue: validatedSceneNameValue),
      ),
    ]),
  ),
  'validated/dont-wrap-group': () => _card(
    Validated(
      state: CoreValidationState.invalid,
      message: const Text(validatedSceneFormatMessage),
      child: _stack(const [
        TextField(placeholder: Text('이메일')),
        TextField(placeholder: Text('이름'), initialValue: validatedSceneNameValue),
      ]),
    ),
  ),
  'validated/related-validator-hint': () => _card(const ValidatorHint(message: Text('8자 이상 입력해 주세요.'))),
  'validated/related-text-field': () =>
      _card(const TextField(placeholder: Text('이름'), errorText: validatedSceneRequiredMessage)),
  'validated/related-form-field': () =>
      _card(const FormField(label: '이름', error: validatedSceneRequiredMessage, child: TextField())),
};

Component _validated(Map<String, String> props, String? label) {
  final state = validatedPreviewState(props);
  return _sized(
    Validated(
      state: state,
      message: previewFlag(props, 'message') ? Text(validatedPreviewMessage(state)) : null,
      child: const TextField(label: validatedPreviewLabel, initialValue: validatedPreviewValue),
    ),
  );
}

Component _sized(Component child, {String width = '15rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

/// 좁은 카드 무대에 들어가는 폭.
Component _card(Component child) => _sized(child, width: '11rem');

/// 위아래로 쌓은 필드.
Component _stack(List<Component> children) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space8)}),
  children,
);

/// 옆으로 놓고, 좁으면 줄을 바꾸는 장면.
Component _columns(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space16),
    },
  ),
  children,
);

/// 위에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: Styles(
    raw: {'width': '13rem', 'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space8)},
  ),
  [Text(caption).labelSmall.onSurfaceVariant, child],
);
