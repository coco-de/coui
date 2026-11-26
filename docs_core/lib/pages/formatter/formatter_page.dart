/// Formatter 페이지 — 플레이그라운드와 서식 결과 예. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `formatter_web.dart` · `formatter_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// Formatter 는 위젯이 아니라서 미리보기는 서식기를 단 TextField 다.
/// 플레이그라운드의 축은 서식기 하나이고, 두 플랫폼 빌더와 코드가 같은 값을
/// 읽도록 선택지 · 인자 · 안내 글을 이 파일 한 곳에 둔다. 크기 축이 없어
/// 크기 표는 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/formatter.md`.
const String slug = 'formatter';

/// 플레이그라운드 `integerOnly` 의 하한.
const int formatterPreviewMin = 0;

/// 플레이그라운드 `integerOnly` 의 상한.
const int formatterPreviewMax = 100;

/// 플레이그라운드 `decimalOnly` 의 소수 자릿수.
const int formatterPreviewDecimalDigits = 2;

/// 플레이그라운드 `time` 의 길이.
const int formatterPreviewTimeLength = 2;

/// 플레이그라운드가 입력창에 다는 서식기 — 이름이 곧 팩토리 이름이다.
///
/// 두 플랫폼의 `TextInputFormatters` 가 함께 가진 팩토리만 둔다. 그래야 코드
/// 하나가 두 플랫폼에서 그대로 컴파일된다.
enum FormatterPreviewKind {
  integerOnly(
    snippet: 'TextInputFormatters.integerOnly(min: $formatterPreviewMin, max: $formatterPreviewMax)',
    placeholder: '$formatterPreviewMin ~ $formatterPreviewMax 사이 정수',
  ),
  decimalOnly(
    snippet: 'TextInputFormatters.decimalOnly(decimalDigits: $formatterPreviewDecimalDigits)',
    placeholder: '소수 둘째 자리까지',
  ),
  toUpperCase(snippet: 'TextInputFormatters.toUpperCase()', placeholder: '영문을 입력하세요'),
  toLowerCase(snippet: 'TextInputFormatters.toLowerCase()', placeholder: '영문을 입력하세요'),
  time(snippet: 'TextInputFormatters.time(length: $formatterPreviewTimeLength)', placeholder: '분 (두 자리)'),
  mathExpression(snippet: 'TextInputFormatters.mathExpression()', placeholder: '10/4 입력 후 Enter', runsOnSubmit: true);

  const FormatterPreviewKind({required this.snippet, required this.placeholder, this.runsOnSubmit = false});

  /// 코드에 적는 팩토리 호출.
  final String snippet;

  /// 입력창의 안내 글.
  final String placeholder;

  /// `submitFormatters` 에 다는가. 수식은 다 치기 전의 글자를 계산하면 칸이
  /// 비므로 제출할 때만 돌린다.
  final bool runsOnSubmit;
}

/// 속성의 `formatter` → 서식기. 없거나 모르는 이름은 `integerOnly`.
FormatterPreviewKind formatterPreviewKindOf(Map<String, String> props) =>
    previewEnum(FormatterPreviewKind.values, props['formatter'], FormatterPreviewKind.integerOnly);

/// `formatter/samples` 장면의 한 줄.
class FormatterSample {
  const FormatterSample({required this.snippet, required this.input, required this.formatter});

  /// 장면에 적는 팩토리 호출.
  final String snippet;

  /// 서식기에 한 번에 넣는 글자.
  final String input;

  /// 결과를 만드는 서식기 — 두 플랫폼이 함께 쓰는 변환이다.
  final CoreInputFormatter formatter;

  /// `'넣은 글자' → '결과'`. 결과는 손으로 적지 않고 서식기를 돌려 얻는다.
  String get result => "'$input' → '${formatter.formatInitial(input)}'";
}

/// `formatter/samples` 장면의 줄 — 빈 칸에 글자를 한 번에 넣었을 때의 결과.
final List<FormatterSample> formatterSamples = [
  FormatterSample(
    snippet: 'integerOnly(min: 0, max: 100)',
    input: '130',
    formatter: CoreInputFormatters.integerOnly(min: 0, max: 100),
  ),
  FormatterSample(
    snippet: 'decimalOnly(decimalDigits: 2)',
    input: '3.14159',
    formatter: CoreInputFormatters.decimalOnly(decimalDigits: 2),
  ),
  FormatterSample(snippet: 'toUpperCase()', input: 'coui', formatter: CoreInputFormatters.toUpperCase()),
  FormatterSample(snippet: 'toLowerCase()', input: 'CoUI', formatter: CoreInputFormatters.toLowerCase()),
  FormatterSample(snippet: 'time(length: 4)', input: '930', formatter: CoreInputFormatters.time(length: 4)),
  FormatterSample(snippet: 'mathExpression()', input: '10/4', formatter: CoreInputFormatters.mathExpression()),
  FormatterSample(snippet: "allow(r'[0-9]')", input: '010-1234', formatter: CoreInputFormatters.allow(r'[0-9]')),
  FormatterSample(snippet: 'phoneText()', input: '(+82) 10', formatter: CoreInputFormatters.phoneText()),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'formatter': 'integerOnly'},
  controls: [
    DocsPlaygroundChoice(
      label: 'formatter',
      prop: 'formatter',
      options: [for (final kind in FormatterPreviewKind.values) kind.name],
    ),
  ],
  code: _formatterCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

String _formatterCode(Map<String, String> props, String? label) {
  final kind = formatterPreviewKindOf(props);
  final lines = [
    "placeholder: Text('${kind.placeholder}'),",
    if (kind.runsOnSubmit)
      'submitFormatters: [${kind.snippet}],'
    else ...[
      'inputFormatters: [${kind.snippet}],',
      'onChanged: setValue,',
    ],
  ];
  return 'TextField(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
