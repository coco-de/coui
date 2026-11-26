/// TextField 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="text-field/...">` 가 읽는다. 같은 이름의 Flutter 파일(`text_field_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _textField;

/// 장면 이름(`text-field/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'text-field/anatomy': () => const TextField(
    label: '이메일',
    initialValue: 'hello@cocode.im',
    description: '업무용 이메일을 권장합니다.',
  ),
  'text-field/states': _textFieldStates,
  'text-field/do-visible-label': () => _field(label: '이메일', placeholder: 'name@company.com'),
  'text-field/dont-placeholder-label': () => _field(placeholder: '이메일'),
  'text-field/do-helpful-error': () => _field(label: '비밀번호', value: '1234', obscure: true, error: '8자 이상 입력해 주세요.'),
  'text-field/dont-vague-error': () => _field(label: '비밀번호', value: '1234', obscure: true, error: '잘못된 입력입니다.'),
  'text-field/a11y-label': () => div(classes: 'docs-demo-caption', [
    div(styles: Styles(raw: {'width': '15rem'}), [_field(label: '이메일', placeholder: 'name@company.com')]),
    div([
      code([Component.text("label: '이메일'")]),
      const Text('라벨은 입력창 위에 함께 보입니다. 접근 가능한 이름으로 연결되는 범위는 알려진 제약을 보세요.').bodySmall.onSurfaceVariant,
    ]),
  ]),
  'text-field/related-select': () => div(styles: Styles(raw: {'width': '12rem'}), [
    Select<String>(
      value: 'all',
      onChanged: (_) {},
      items: const [CoreSelectItem(value: 'all', label: '전체')],
    ),
  ]),
  'text-field/related-text-area': () => div(styles: Styles(raw: {'width': '12rem'}), [
    const TextArea(placeholder: '여러 줄을 입력할 수 있습니다.', rows: 2),
  ]),
  'text-field/related-form': () => div(classes: 'docs-demo-stack', [
    const TextField(placeholder: Text('이름')),
    Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('제출')),
  ]),
};

Component _textField(Map<String, String> props, String? label) {
  final placeholder = props['placeholder'];
  return TextField(
    variant: previewEnum(CoreTextFieldVariant.values, props['variant'], CoreTextFieldVariant.defaultVariant),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
    label: props['label'],
    placeholder: placeholder == null ? null : Text(placeholder),
    description: props['description'],
    errorText: props['errorText'],
    initialValue: props['value'],
    enabled: previewFlag(props, 'enabled', fallback: true),
    readOnly: previewFlag(props, 'readOnly'),
  );
}

Component _field({String? label, String? placeholder, String? value, bool obscure = false, String? error}) => div(
  styles: Styles(raw: {'width': '15rem'}),
  [
    TextField(
      label: label,
      placeholder: placeholder == null ? null : Text(placeholder),
      initialValue: value,
      obscureText: obscure,
      errorText: error,
    ),
  ],
);

/// TextField 상태 격자 — 쉬는 상태 · 오류 · 비활성 · 읽기 전용은 실제 입력창,
/// focus 는 포커스 테두리 색을 Core 기본값에서 읽어 고정한 입력창이다.
Component _textFieldStates() {
  const columns = ['기본', 'Focus', '오류', '비활성', '읽기 전용'];
  Component cell(String state) => div(styles: Styles(raw: {'width': '9.5rem'}), [
    switch (state) {
      'Focus' => TextField(
        initialValue: 'hello@',
        textFieldStyle: CoreTextFieldStyle(borderColor: CoreTextFieldStyle.defaultNormalVariant.focusRingColor),
      ),
      '오류' => const TextField(initialValue: 'hello@', variant: CoreTextFieldVariant.error),
      '비활성' => const TextField(initialValue: 'hello@cocode.im', enabled: false),
      '읽기 전용' => const TextField(initialValue: 'hello@cocode.im', readOnly: true),
      _ => const TextField(placeholder: Text('이메일')),
    },
  ]);
  return div(classes: 'docs-demo-field-states', [
    for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final column in columns) cell(column),
  ]);
}
