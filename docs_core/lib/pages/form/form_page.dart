/// Form 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `form_web.dart` · `form_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// Form 에는 겉모습을 고르는 속성이 없어 플레이그라운드는 축소한다 — 속성은
/// `mode`(`FormValidationMode`) 하나이고, 맥락은 제출 버튼이다. 검증 시점을
/// 고르는 속성은 Form 에 없다. `mode` 는 미리보기의 검증기가 어느 시점부터
/// 오류를 내는지를 정한다. 두 플랫폼 빌더와 코드가 같은 뜻으로 읽도록 해석은
/// 이 파일의 [formPreviewMode] · [formPreviewValidator] 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/form.md`.
const String slug = 'form';

/// 플레이그라운드의 필드 라벨 — 미리보기와 코드가 함께 쓴다.
const String formPreviewLabel = '이메일';

/// 플레이그라운드의 안내 글자.
const String formPreviewPlaceholder = 'name@company.com';

/// 플레이그라운드의 주 버튼 글자.
const String formPreviewSubmit = '제출';

/// 제출이 검사를 통과했을 때 미리보기가 보이는 문구.
const String formPreviewPassed = '검사를 통과했습니다.';

/// 도움말 장면의 문구 — 두 플랫폼 장면이 함께 읽는다.
const String formPasswordHelp = '8자 이상, 대소문자 및 숫자를 포함하세요';

/// 고치는 방법을 알려 주는 오류 문구.
const String formHelpfulError = '8자 이상, 대소문자 및 숫자를 포함하세요';

/// 무엇이 틀렸는지 알 수 없는 오류 문구.
const String formVagueError = '유효하지 않은 비밀번호';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'mode': 'submitted'},
  controls: [
    DocsPlaygroundChoice(label: '검증 시점', prop: 'mode', options: ['initial', 'changed', 'submitted'], segmented: true),
  ],
  code: _formCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `mode` → 검증 시점. 없거나 모르는 값은 `submitted`.
FormValidationMode formPreviewMode(Map<String, String> props) =>
    previewEnum(FormValidationMode.values, props['mode'], FormValidationMode.submitted);

/// [from] 시점의 검증기 — `initial` 은 킷의 `RequiredValidator` 그대로다.
Validator<String> formPreviewValidator(FormValidationMode from) =>
    from == FormValidationMode.initial ? const RequiredValidator<String>() : RequiredFrom(from);

/// [from] 시점부터 빈 값을 막고, 그 전에는 통과시키는 검증기.
///
/// 문서의 "검증기 직접 만들기" 코드와 같은 모양이다.
class RequiredFrom extends Validator<String> {
  /// 검증기를 만든다.
  const RequiredFrom(this.from);

  /// 검사를 시작하는 시점.
  final FormValidationMode from;

  @override
  ValidationResult? validate(CoreValidationContext context, String? value, FormValidationMode lifecycle) {
    if (lifecycle.index < from.index) return null;
    if (value != null && value.isNotEmpty) return null;
    return InvalidResult(context.messages.formNotEmpty, state: lifecycle);
  }
}

String _formCode(Map<String, String> props, String? label) {
  final mode = formPreviewMode(props);
  final validator = mode == FormValidationMode.initial
      ? 'const RequiredValidator<String>()'
      : 'const RequiredFrom(FormValidationMode.${mode.name})';
  return [
    '// handleSubmit 은 controller.revalidate 를 submitted 로 부른 뒤',
    '// controller.errors 가 비었는지 확인합니다.',
    if (mode != FormValidationMode.initial) '// RequiredFrom 은 킷에 없습니다. "검증기 직접 만들기"의 클래스를 함께 복사하세요.',
    'Form(',
    '  controller: controller,',
    '  showActions: true,',
    '  showSecondaryAction: false,',
    "  primaryAction: Button(onPressed: handleSubmit, child: Text('$formPreviewSubmit')),",
    '  children: [',
    '    FormField(',
    "      label: '$formPreviewLabel',",
    '      required: true,',
    '      validator: $validator,',
    "      child: TextField(placeholder: Text('$formPreviewPlaceholder')),",
    '    ),',
    '  ],',
    ')',
  ].join('\n');
}
