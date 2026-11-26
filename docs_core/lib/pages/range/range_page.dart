/// Range 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `range_web.dart` · `range_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 `minValue` · `maxValue`(숫자), `leading` · `trailing`(트랙 앞뒤에
/// 놓는 글자), `enabled` 다. 두 플랫폼 빌더와 코드가 같은 뜻으로 읽도록
/// 숫자 해석은 이 파일의 [rangePreviewValue] 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/range.md`.
const String slug = 'range';

/// 트랙 앞에 놓는 글자 — 트랙의 시작 값(`min` 의 기본값).
const String rangePreviewLeading = '0';

/// 트랙 뒤에 놓는 글자 — 트랙의 끝 값(`max` 의 기본값).
const String rangePreviewTrailing = '100';

/// 장면의 최솟값 — 플레이그라운드의 처음 값과 같다.
const double rangePreviewMinValue = 20;

/// 장면의 최댓값 — 플레이그라운드의 처음 값과 같다.
const double rangePreviewMaxValue = 80;

/// `range/with-values` 장면의 트랙 끝 값(원). 시작 값은 기본값 0 이다.
const double rangePricePreviewMax = 100000;

/// `range/with-values` 장면의 값 단위(원).
const double rangePricePreviewStep = 1000;

/// `range/with-values` 장면의 최솟값(원).
const double rangePricePreviewMinValue = 20000;

/// `range/with-values` 장면의 최댓값(원).
const double rangePricePreviewMaxValue = 80000;

/// `range/with-values` 장면이 Range 위에 적는 글자 — 위 두 값과 같다.
const String rangePricePreviewLabel = '20,000원 – 80,000원';

/// 속성의 숫자 하나 — 없거나 읽을 수 없으면 위젯의 기본값인 [fallback].
double rangePreviewValue(Map<String, String> props, String key, double fallback) =>
    double.tryParse(props[key] ?? '') ?? fallback;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// variant 와 크기 축이 없다. 바꿔 볼 것은 두 값과, 트랙 앞뒤의 글자, 비활성
/// 이다. 두 값의 선택지는 서로 겹치지 않게 나눈다 — 최솟값이 최댓값을
/// 넘는 조합은 Range 가 만들지 않는 상태다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'minValue': '20', 'maxValue': '80'},
  controls: [
    DocsPlaygroundChoice(label: 'minValue', prop: 'minValue', options: ['0', '20', '40'], segmented: true),
    DocsPlaygroundChoice(label: 'maxValue', prop: 'maxValue', options: ['60', '80', '100'], segmented: true),
    DocsPlaygroundFlag(
      label: '앞뒤 글자',
      on: {'leading': rangePreviewLeading, 'trailing': rangePreviewTrailing},
    ),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _rangeCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Range 에는 크기 사다리(`defaultsBySize`)가 없다 — 트랙 높이 · 핸들 크기는
/// `CoreRangeStyle` 의 낱개 기본값 하나씩이다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 코드에 적는 숫자 — 정수면 소수점 없이.
String _literal(double value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value';

String _rangeCode(Map<String, String> props, String? label) {
  final lines = [
    'minValue: ${_literal(rangePreviewValue(props, 'minValue', CoreRangeContract.defaultMin))},',
    'maxValue: ${_literal(rangePreviewValue(props, 'maxValue', CoreRangeContract.defaultMax))},',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: updateRange,',
    if (props['leading'] case final leading?) "leading: Text('$leading'),",
    if (props['trailing'] case final trailing?) "trailing: Text('$trailing'),",
  ];
  return 'Range(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
