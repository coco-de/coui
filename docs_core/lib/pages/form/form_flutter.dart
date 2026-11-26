/// Form 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="form/...">` ·
/// `<Card demo="form/...">` 가 읽는다. 같은 이름의 Web 파일(`form_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 플레이그라운드의 미리보기는 실제 `FormController` 를 가진 폼이다 — 입력하고
/// 제출 버튼을 누르면 검증기가 고른 시점에 맞춰 오류를 보인다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'form_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _form;

/// 장면 이름(`form/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'form/anatomy': () => _frame(
    Form(
      showActions: true,
      secondaryAction: Button(variant: CoreButtonVariant.ghost, onPressed: () {}, child: const Text('취소')),
      primaryAction: Button(onPressed: () {}, child: const Text('가입하기')),
      children: [
        FormField(
          label: '이메일',
          required: true,
          description: '로그인할 때 씁니다.',
          child: TextField(placeholder: const Text('name@company.com')),
        ),
      ],
    ),
  ),
  'form/actions': _actions,
  'form/states': _states,
  'form/do-required': () => _frame(
    Form(
      children: [
        FormField(
          label: '이름',
          required: true,
          child: TextField(placeholder: const Text('홍길동')),
        ),
        FormField(
          label: '회사',
          description: '선택 입력입니다.',
          child: TextField(placeholder: const Text('회사 이름')),
        ),
      ],
    ),
  ),
  'form/dont-required': () => _frame(
    Form(
      children: [
        FormField(
          label: '이름',
          child: TextField(placeholder: const Text('홍길동')),
        ),
        FormField(
          label: '회사',
          child: TextField(placeholder: const Text('회사 이름')),
        ),
      ],
    ),
  ),
  'form/do-helpful-error': () => _errorField(page.formHelpfulError),
  'form/dont-vague-error': () => _errorField(page.formVagueError),
};

Widget _form(Map<String, String> props, String? label) {
  final mode = page.formPreviewMode(props);
  // 시점이 바뀌면 컨트롤러까지 새로 만든다 — 컨트롤러는 마지막으로 값을 받을 때의
  // 검증기를 계속 쓴다.
  return _FormPreview(mode: mode, key: ValueKey('form-preview-${mode.name}'));
}

/// 버튼 줄 — 위는 기본 버튼, 아래는 직접 넘긴 버튼.
Widget _actions() => _frame(
  _column([
    _captioned('기본 버튼', Form(showActions: true, children: [_nameField()])),
    _captioned(
      '직접 넘긴 버튼',
      Form(
        showActions: true,
        secondaryAction: Button(variant: CoreButtonVariant.ghost, onPressed: () {}, child: const Text('이전')),
        primaryAction: Button(onPressed: () {}, child: const Text('저장')),
        children: [_nameField()],
      ),
    ),
  ]),
);

/// 필드 상태 — 도움말 · 오류 · 비활성 · 라벨 옆 동작과 글자 수.
Widget _states() => _frame(
  Form(
    children: [
      FormField(
        label: '비밀번호',
        description: page.formPasswordHelp,
        child: TextField(placeholder: const Text('비밀번호'), obscureText: true),
      ),
      FormField(
        label: '이메일',
        required: true,
        error: '올바른 이메일을 입력하세요',
        child: TextField(initialValue: 'name@'),
      ),
      FormField(
        label: '이름',
        enabled: false,
        child: TextField(placeholder: const Text('수정 불가')),
      ),
      FormField(
        label: '소개',
        labelAction: Button(
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Text('작성 안내'),
        ),
        counterText: '0 / 40',
        child: TextField(placeholder: const Text('한 줄 소개')),
      ),
    ],
  ),
);

Widget _nameField() => FormField(
  label: '이름',
  child: TextField(placeholder: const Text('홍길동')),
);

Widget _errorField(String error) => _frame(
  FormField(
    label: '비밀번호',
    error: error,
    child: TextField(initialValue: '1234', obscureText: true),
  ),
);

/// 폼의 폭 — 320 을 넘지 않는다. Form 은 자식을 폭 끝까지 늘리므로 가로가
/// 정해진 부모가 필요하다.
Widget _frame(Widget child) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: CoreLayout.layout320),
  child: child,
);

Widget _column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space32,
  children: children,
);

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [Text(caption).labelSmall.onSurfaceVariant, child],
);

class _FormPreview extends StatefulWidget {
  const _FormPreview({required this.mode, super.key});

  final FormValidationMode mode;

  @override
  State<_FormPreview> createState() => _FormPreviewState();
}

class _FormPreviewState extends State<_FormPreview> {
  final FormController _controller = FormController();
  bool _passed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    _controller.revalidate(CoUIValidationContext(context), FormValidationMode.submitted);
    setState(() => _passed = _controller.errors.isEmpty);
  }

  void _handleChanged(String value) {
    if (_passed) setState(() => _passed = false);
  }

  @override
  Widget build(BuildContext context) => _frame(
    Form(
      controller: _controller,
      showActions: true,
      showSecondaryAction: false,
      primaryAction: Button(onPressed: _handleSubmit, child: const Text(page.formPreviewSubmit)),
      children: [
        FormField(
          label: page.formPreviewLabel,
          required: true,
          validator: page.formPreviewValidator(widget.mode),
          child: TextField(placeholder: const Text(page.formPreviewPlaceholder), onChanged: _handleChanged),
        ),
        if (_passed) const ValidatorHint.success(message: Text(page.formPreviewPassed)),
      ],
    ),
  );
}
