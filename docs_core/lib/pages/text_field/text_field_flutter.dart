/// TextField 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="text-field/...">` 가 읽는다. 같은 이름의 Web 파일(`text_field_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _textField;

/// 장면 이름(`text-field/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'text-field/anatomy': () => SizedBox(
    width: 280,
    child: TextField(label: '이메일', initialValue: 'hello@cocode.im', description: '업무용 이메일을 권장합니다.'),
  ),
  'text-field/states': () => SizedBox(
    width: 280,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space12,
      children: [
        TextField(placeholder: Text('이메일')),
        TextField(initialValue: 'hello@', variant: CoreTextFieldVariant.error),
        TextField(initialValue: 'hello@cocode.im', enabled: false),
        TextField(initialValue: 'hello@cocode.im', readOnly: true),
      ],
    ),
  ),
  'text-field/do-visible-label': () => _field(label: '이메일', placeholder: 'name@company.com'),
  'text-field/dont-placeholder-label': () => _field(placeholder: '이메일'),
  'text-field/do-helpful-error': () => _field(label: '비밀번호', value: '1234', obscure: true, error: '8자 이상 입력해 주세요.'),
  'text-field/dont-vague-error': () => _field(label: '비밀번호', value: '1234', obscure: true, error: '잘못된 입력입니다.'),
  'text-field/a11y-label': () => _field(label: '이메일', placeholder: 'name@company.com'),
  'text-field/related-select': () => SizedBox(
    width: 200,
    child: Select<String>(
      value: 'all',
      onChanged: (_) {},
      items: const [CoreSelectItem(value: 'all', label: '전체')],
    ),
  ),
  'text-field/related-text-area': () => SizedBox(width: 200, child: TextArea(placeholder: '여러 줄을 입력할 수 있습니다.')),
  'text-field/related-form': () => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space8,
    children: [
      _field(placeholder: '이름'),
      Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('제출')),
    ],
  ),
};

Widget _textField(Map<String, String> props, String? label) {
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

Widget _field({String? label, String? placeholder, String? value, bool obscure = false, String? error}) => SizedBox(
  width: 240,
  child: TextField(
    label: label,
    placeholder: placeholder == null ? null : Text(placeholder),
    initialValue: value,
    obscureText: obscure,
    errorText: error,
  ),
);
