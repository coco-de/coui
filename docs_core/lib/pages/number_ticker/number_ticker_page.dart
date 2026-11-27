/// NumberTicker 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `number_ticker_web.dart` · `number_ticker_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 두 플랫폼이 같은 숫자 · 같은 표기를 그리도록 속성 해석, 표기 함수, 장면이
/// 함께 쓰는 값은 이 파일에 둔다.
///
/// 장면은 `initialValue` 를 쓰지 않는다. Web 의 서버 렌더는 `initialValue` 를
/// 그리고, 브라우저에서 실행되지 않는 본문에서는 그 숫자가 그대로 남는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/number-ticker.md`.
const String slug = 'number-ticker';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `value` 를 바꾸면 두 팬이 지금 숫자에서 새 값까지 세어 간다. `initialValue`
/// 는 처음 나타날 때만 읽으므로, 미리보기는 그 값이 바뀌면
/// [numberTickerPreviewKey] 로 컴포넌트를 새로 만든다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {
    'value': '1280',
    'formatter': 'default',
    'duration': '500',
    'curve': 'default',
    'textStyle': 'titleLarge',
  },
  controls: [
    DocsPlaygroundChoice(label: 'value', prop: 'value', options: ['128', '1280', '98765'], segmented: true),
    DocsPlaygroundChoice(label: 'formatter', prop: 'formatter', options: ['default', 'grouped', 'won']),
    DocsPlaygroundChoice(label: 'duration', prop: 'duration', options: ['150', '300', '500', '1000'], segmented: true),
    DocsPlaygroundChoice(label: 'curve', prop: 'curve', options: ['default', 'linear', 'easeOut']),
    DocsPlaygroundChoice(
      label: 'textStyle',
      prop: 'textStyle',
      options: ['titleLarge', 'headlineSmall', 'headlineLarge'],
    ),
    DocsPlaygroundFlag(label: '0부터 세기', on: {'initialValue': '0'}),
  ],
  code: _numberTickerCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// NumberTicker 의 글자 크기는 크기 단계가 아니라 `textStyle` 의 글자 역할이
/// 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `value`. 없거나 숫자가 아니면 처음 값.
num numberTickerPreviewValue(Map<String, String> props) => num.tryParse(props['value'] ?? '') ?? 1280;

/// 속성의 `initialValue`. 없으면 `null`.
num? numberTickerPreviewInitialValue(Map<String, String> props) => num.tryParse(props['initialValue'] ?? '');

/// 미리보기의 key — `initialValue` 를 켜고 끄면 처음부터 다시 만든다.
String numberTickerPreviewKey(Map<String, String> props) =>
    'number-ticker-${numberTickerPreviewInitialValue(props) ?? 'none'}';

/// 속성의 `formatter` → 표기 함수. `default` 는 `null`.
CoreNumberTickerFormatter? numberTickerPreviewFormatter(Map<String, String> props) => switch (props['formatter']) {
  'grouped' => numberTickerGrouped,
  'won' => numberTickerWon,
  _ => null,
};

/// 속성의 `curve` → 곡선 함수. `default` 는 `null`.
double Function(double t)? numberTickerPreviewCurve(Map<String, String> props) => switch (props['curve']) {
  'linear' => _linear,
  'easeOut' => _easeOut,
  _ => null,
};

/// 속성의 `duration` · `textStyle` → 스타일. 둘 다 기본값이면 `null`.
CoreNumberTickerStyle? numberTickerPreviewStyle(Map<String, String> props) {
  final milliseconds = _durationMs(props);
  final role = _role(props);
  if (milliseconds == CoreDuration.slow && role == null) return null;
  return CoreNumberTickerStyle(
    duration: milliseconds == CoreDuration.slow ? null : Duration(milliseconds: milliseconds),
    textStyle: role == null ? null : CoreTextStyle.token(role),
  );
}

/// 반올림한 정수에 천 단위 쉼표를 넣는다.
String numberTickerGrouped(num number) => number.round().toString().replaceAll(RegExp(r'\B(?=(\d{3})+$)'), ',');

/// 원화 표기.
String numberTickerWon(num number) => '₩${numberTickerGrouped(number)}';

/// 소수 한 자리 퍼센트 표기.
String numberTickerPercent(num number) => '${number.toStringAsFixed(1)}%';

/// `number-ticker/formats` 장면의 줄 — 설명, 값, 표기 함수.
const List<(String, num, CoreNumberTickerFormatter?)> numberTickerSceneFormats = [
  ('formatter 없음', 1234567, null),
  ('천 단위 구분', 1234567, numberTickerGrouped),
  ('원화', 1234567, numberTickerWon),
  ('퍼센트', 99.5, numberTickerPercent),
];

/// `number-ticker/placement` 장면의 지표 — 이름과 값.
const List<(String, num)> numberTickerSceneMetrics = [('방문', 12480), ('주문', 962), ('후기', 87)];

/// `number-ticker/builder` · `number-ticker/styles` 장면의 점수.
const num numberTickerSceneScore = 1280;

/// 권장 · 금지 카드가 함께 보이는 금액.
const num numberTickerSceneAmount = 1234567;

/// `number-ticker/styles` 장면에서 바꿔 본 스타일.
const CoreNumberTickerStyle numberTickerSceneStyle = CoreNumberTickerStyle(
  textStyle: CoreTextStyle.token(CoreTextStyles.headlineSmall, color: CoreColor.token(CoreColors.primary)),
);

/// 권장 · 금지 카드의 글자 스타일.
const CoreNumberTickerStyle numberTickerSceneCardStyle = CoreNumberTickerStyle(
  textStyle: CoreTextStyle.token(CoreTextStyles.headlineSmall),
);

double _linear(double t) => t;

double _easeOut(double t) => 1 - (1 - t) * (1 - t);

int _durationMs(Map<String, String> props) => switch (props['duration']) {
  '150' => CoreDuration.fast,
  '300' => CoreDuration.moderate,
  '1000' => CoreDuration.ms1000,
  _ => CoreDuration.slow,
};

CoreTextStyleToken? _role(Map<String, String> props) => switch (props['textStyle']) {
  'headlineSmall' => CoreTextStyles.headlineSmall,
  'headlineLarge' => CoreTextStyles.headlineLarge,
  _ => null,
};

const String _groupedCode = r"""
formatter: (number) => number
    .round()
    .toString()
    .replaceAll(RegExp(r'\B(?=(\d{3})+$)'), ','),""";

const String _wonCode = r"""
formatter: (number) {
  final digits = number.round().toString();
  return '₩${digits.replaceAll(RegExp(r'\B(?=(\d{3})+$)'), ',')}';
},""";

String _numberTickerCode(Map<String, String> props, String? label) {
  final milliseconds = _durationMs(props);
  final role = _role(props);
  final durationName = switch (milliseconds) {
    CoreDuration.fast => 'fast',
    CoreDuration.moderate => 'moderate',
    CoreDuration.ms1000 => 'ms1000',
    _ => 'slow',
  };
  final lines = [
    'value: ${numberTickerPreviewValue(props)},',
    if (numberTickerPreviewInitialValue(props) case final initialValue?) 'initialValue: $initialValue,',
    if (props['formatter'] == 'grouped') _groupedCode,
    if (props['formatter'] == 'won') _wonCode,
    if (props['curve'] == 'linear') 'curve: (t) => t,',
    if (props['curve'] == 'easeOut') 'curve: (t) => 1 - (1 - t) * (1 - t),',
    if (milliseconds != CoreDuration.slow || role != null) ...[
      'numberTickerStyle: CoreNumberTickerStyle(',
      if (milliseconds != CoreDuration.slow) '  duration: Duration(milliseconds: CoreDuration.$durationName),',
      if (role != null) '  textStyle: CoreTextStyle.token(CoreTextStyles.${props['textStyle']}),',
      '),',
    ],
  ];
  final body = lines.expand((line) => line.split('\n')).map((line) => '  $line').join('\n');
  return 'NumberTicker(\n$body\n)';
}
