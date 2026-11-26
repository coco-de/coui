/// FormField 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="form-field/...">` · `<Card demo>` · `<Anatomy demo>` 가 읽는다.
/// 같은 이름의 Flutter 파일(`form_field_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
///
/// FormField 는 부모 폭을 채우므로 미리보기마다 폭을 정한다 — Flutter 의
/// 288 · 200 과 같은 18rem · 12.5rem 이다. 좁은 무대에서는 무대 폭까지 줄어든다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'form_field_page.dart' as page;

/// 속성 → Component.
///
/// 태그의 `label` 은 속성의 `label` 이 없을 때 필드 라벨이 된다. `labelAction=true`
/// 는 라벨 줄 끝에 버튼을 넣고, `width=compact` 는 좁은 폭으로 그린다.
WebPropPreviewBuilder? get propPreview => _formField;

/// 장면 이름(`form-field/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'form-field/anatomy': () => _box(
    FormField(
      label: '소개',
      required: true,
      labelAction: _action(page.formFieldPreviewAction),
      description: '프로필에 보이는 소개입니다.',
      counterText: '0 / 40',
      child: const TextField(placeholder: Text('한 줄 소개')),
    ),
  ),
  'form-field/rows': () => _box(
    _column([
      FormField(
        label: '비밀번호',
        labelAction: _action('비밀번호 찾기'),
        child: const TextField(placeholder: Text('비밀번호'), obscureText: true),
      ),
      const FormField(
        label: '소개',
        counterText: '0 / 40',
        child: TextField(placeholder: Text('한 줄 소개')),
      ),
      const FormField(
        label: '닉네임',
        description: page.formFieldPreviewDescription,
        counterText: '4 / 20',
        child: TextField(initialValue: '코코아빠'),
      ),
      const FormField(
        label: '닉네임',
        error: '두 글자 이상 입력하세요.',
        counterText: '1 / 20',
        child: TextField(initialValue: '코'),
      ),
    ]),
  ),
  'form-field/states': () => _box(
    _column(const [
      FormField(
        label: '이메일',
        required: true,
        description: '회사 이메일을 입력하세요.',
        child: TextField(placeholder: Text('you@company.com')),
      ),
      FormField(
        label: '비밀번호',
        error: '비밀번호는 8자 이상이어야 합니다.',
        child: TextField(initialValue: '1234', obscureText: true),
      ),
      FormField(
        label: '사번',
        required: true,
        enabled: false,
        description: '관리자만 바꿀 수 있습니다.',
        child: TextField(initialValue: 'C-1024'),
      ),
    ]),
  ),
  'form-field/scope-inputs': () => _box(
    _column([
      const FormField(
        label: '비활성 필드의 TextField',
        enabled: false,
        child: TextField(placeholder: Text('입력할 수 없습니다')),
      ),
      FormField(
        label: '비활성 필드의 Checkbox',
        enabled: false,
        child: Checkbox(checked: false, onChanged: (_) {}, label: '이메일 알림 받기'),
      ),
      const FormField(
        label: '오류 필드의 TextField',
        error: '내용을 입력하세요.',
        child: TextField(placeholder: Text('메모')),
      ),
      const FormField(
        label: '오류 필드의 TextArea',
        error: '내용을 입력하세요.',
        child: TextArea(placeholder: '메모', rows: 2),
      ),
    ]),
  ),
  'form-field/do-label': () => _box(
    const FormField(
      label: '이메일',
      required: true,
      child: TextField(placeholder: Text('you@company.com')),
    ),
    compact: true,
  ),
  'form-field/dont-label-widget': () => _box(
    FormField(
      required: true,
      labelWidget: const Text('이메일').labelMedium.onSurfaceVariant,
      child: const TextField(placeholder: Text('you@company.com')),
    ),
    compact: true,
  ),
  'form-field/do-error-with-rule': () => _box(
    const FormField(
      label: '비밀번호',
      error: '비밀번호는 8자 이상이어야 합니다.',
      child: TextField(initialValue: '1234', obscureText: true),
    ),
    compact: true,
  ),
  'form-field/dont-error-without-rule': () => _box(
    const FormField(
      label: '비밀번호',
      description: '8자 이상 입력하세요.',
      error: '비밀번호가 너무 짧습니다.',
      child: TextField(initialValue: '1234', obscureText: true),
    ),
    compact: true,
  ),
  'form-field/related-form-label': () => const FormLabel(label: Text('이메일'), isRequired: true),
  'form-field/related-validator-hint': () => const ValidatorHint.error(message: Text('이메일 형식이 아닙니다.')),
};

Component _formField(Map<String, String> props, String? label) => _box(
  FormField(
    size: previewEnum(CoreComponentSize.values, props['size'], CoreFormFieldStyle.defaultSize),
    label: props['label'] ?? label ?? page.formFieldPreviewLabel,
    required: previewFlag(props, 'required'),
    labelAction: previewFlag(props, 'labelAction') ? _action(page.formFieldPreviewAction) : null,
    description: props['description'],
    error: props['error'],
    counterText: props['counterText'],
    enabled: previewFlag(props, 'enabled', fallback: true),
    child: TextField(placeholder: Text(props['placeholder'] ?? page.formFieldPreviewFallbackPlaceholder)),
  ),
  compact: props['width'] == 'compact',
);

/// 라벨 줄 끝의 버튼.
Component _action(String text) => Button(
  variant: CoreButtonVariant.plain,
  size: CoreComponentSize.sm,
  onPressed: () {},
  child: Text(text),
);

/// 폭을 정한 상자 — 무대가 더 좁으면 무대 폭까지 줄어든다.
Component _box(Component child, {bool compact = false}) => div(
  styles: Styles(raw: {'width': compact ? '12.5rem' : '18rem', 'max-width': '100%'}),
  [child],
);

Component _column(List<Component> children) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space24)}),
  children,
);
