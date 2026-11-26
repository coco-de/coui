/// Slider 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `slider_web.dart` · `slider_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 장면이 함께 쓰는 값(온도 예시의 범위 · 단계 · 글자, 두 슬라이더 예시의
/// 값)은 아래 상수 한 곳에 둔다 — 두 플랫폼의 그림이 같은 값을 쓴다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/slider.md`.
const String slug = 'slider';

/// 온도 예시의 이름 — 슬라이더 위에 놓는 글자.
const String sliderTemperatureName = '설정 온도';

/// 온도 예시의 범위와 단계 — 16 ~ 30 도를 1 도씩.
const double sliderTemperatureMin = 16;

/// 온도 예시의 최댓값.
const double sliderTemperatureMax = 30;

/// 온도 예시의 칸 수 — `(30 - 16) / 14` 로 1 도씩.
const int sliderTemperatureDivisions = 14;

/// 온도 예시의 지금 값.
const double sliderTemperatureValue = 22;

/// 온도 예시의 지금 값 글자 — `trailing` 슬롯에 놓는다.
const String sliderTemperatureLabel = '22°C';

/// 두 슬라이더로 구간을 만든 예시 — 최솟값이 최댓값을 넘은 상태.
const double sliderPairMinValue = 70;

/// 두 슬라이더 예시의 최댓값 쪽 값.
const double sliderPairMaxValue = 30;

/// 두 슬라이더 예시에서 최솟값 쪽 슬라이더의 앞 슬롯 글자.
const String sliderPairMinLabel = '최소';

/// 두 슬라이더 예시에서 최댓값 쪽 슬라이더의 앞 슬롯 글자.
const String sliderPairMaxLabel = '최대';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// Slider 에는 variant 와 크기 축이 없다. 그래서 값(썸의 자리) 하나와, 썸이
/// 트랙 안에서 움직이는 모습을 보여 주는 맥락(앞 · 뒤 슬롯), 비활성만 바꾼다.
/// `divisions` · `step` 은 손잡이로 두지 않는다 — 눈금을 그리지 않아 정지
/// 그림에서는 아무것도 바뀌지 않는다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'value': '50'},
  controls: [
    DocsPlaygroundChoice(label: 'value', prop: 'value', options: ['0', '25', '50', '75', '100'], segmented: true),
    DocsPlaygroundFlag(label: '앞 · 뒤 아이콘', on: {'leading': 'minus', 'trailing': 'plus'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _sliderCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

String _sliderCode(Map<String, String> props, String? label) {
  final lines = [
    'value: ${props['value'] ?? '50'},',
    if (props['leading'] case final icon?) 'leading: Icon(LucideIcons.${docsIconIdentifier(icon)}),',
    if (props['trailing'] case final icon?) 'trailing: Icon(LucideIcons.${docsIconIdentifier(icon)}),',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setVolume,',
  ];
  return 'Slider(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
