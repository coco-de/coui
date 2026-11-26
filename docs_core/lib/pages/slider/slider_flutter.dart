/// Slider 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="slider/...">` 가 읽는다. 같은 이름의 Web 파일(`slider_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 슬라이더는 받은 가로 폭을 채운다 — 폭이 무한한 자리에서는 그릴 폭이 없다.
/// 그래서 모든 장면은 폭을 정한 `SizedBox` 안에 슬라이더를 둔다(Web 과 같은 폭).
/// 장면은 정지 그림이다 — `onChanged` 는 빈 함수라 눌러도 값이 바뀌지 않는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'slider_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _slider;

/// 장면 이름(`slider/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'slider/anatomy': () => _sized(
    Slider(
      value: 30,
      onChanged: (_) {},
      leading: const Icon(LucideIcons.minus),
      trailing: const Icon(LucideIcons.plus),
    ),
    width: 320,
  ),
  'slider/states': _sliderStates,
  'slider/slots': () => _column([
    Slider(
      value: 60,
      onChanged: (_) {},
      leading: const Icon(LucideIcons.minus),
      trailing: const Icon(LucideIcons.plus),
    ),
    Slider(
      value: 60,
      onChanged: (_) {},
      leading: const Text('0').bodySmall.onSurfaceVariant,
      trailing: const Text('100').bodySmall.onSurfaceVariant,
    ),
  ]),
  'slider/value-label': () => _column([
    const Text(sliderTemperatureName).labelLarge.onSurface,
    _temperature(),
  ]),
  'slider/with-number-input': () => SizedBox(
    width: 320,
    child: Row(
      spacing: CoreSpace.space12,
      children: [
        Expanded(child: _temperature(withLabel: false)),
        NumberInput(
          value: sliderTemperatureValue,
          min: sliderTemperatureMin,
          max: sliderTemperatureMax,
          onChanged: (_) {},
        ),
      ],
    ),
  ),
  'slider/two-sliders': () => _column([
    Slider(
      value: sliderPairMinValue,
      onChanged: (_) {},
      leading: const Text(sliderPairMinLabel).bodySmall.onSurfaceVariant,
    ),
    Slider(
      value: sliderPairMaxValue,
      onChanged: (_) {},
      leading: const Text(sliderPairMaxLabel).bodySmall.onSurfaceVariant,
    ),
  ]),
  'slider/related-range': () => _sized(
    Range(minValue: 20, maxValue: 70, onChanged: (_, _) {}),
    width: 192,
  ),
  'slider/related-number-input': () => NumberInput(
    value: sliderTemperatureValue,
    min: sliderTemperatureMin,
    max: sliderTemperatureMax,
    onChanged: (_) {},
  ),
  'slider/related-progress': () => _sized(const Progress(value: 0.6), width: 192),
};

Widget _sized(Widget child, {double width = 240}) => SizedBox(width: width, child: child);

/// 위에서 아래로 쌓는 장면 — 폭은 슬라이더 한 개의 폭.
Widget _column(List<Widget> children) => SizedBox(
  width: 240,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space8,
    children: children,
  ),
);

/// 온도 예시 — 16 ~ 30 도, 1 도씩, 지금 값을 뒤 슬롯에 보인다.
Widget _temperature({bool withLabel = true}) => Slider(
  value: sliderTemperatureValue,
  min: sliderTemperatureMin,
  max: sliderTemperatureMax,
  divisions: sliderTemperatureDivisions,
  onChanged: (_) {},
  trailing: withLabel ? const Text(sliderTemperatureLabel).bodyMedium.onSurface : null,
);

Widget _slider(Map<String, String> props, String? label) => _sized(
  Slider(
    value: _number(props['value'], 50),
    min: _number(props['min'], 0),
    max: _number(props['max'], 100),
    step: double.tryParse(props['step'] ?? ''),
    divisions: int.tryParse(props['divisions'] ?? ''),
    enabled: previewFlag(props, 'enabled', fallback: true),
    onChanged: (_) {},
    leading: docsFlutterIcon(props['leading']),
    trailing: docsFlutterIcon(props['trailing']),
  ),
);

double _number(String? raw, double fallback) => double.tryParse(raw ?? '') ?? fallback;

/// 상태 격자 — Web 과 같은 네 칸.
Widget _sliderStates() {
  const columns = ['value: 0', 'value: 60', 'value: 100', '비활성'];
  Widget cell(String state) => SizedBox(
    width: 152,
    child: switch (state) {
      'value: 0' => Slider(onChanged: (_) {}),
      'value: 100' => Slider(value: 100, onChanged: (_) {}),
      '비활성' => Slider(value: 60, enabled: false, onChanged: (_) {}),
      _ => Slider(value: 60, onChanged: (_) {}),
    },
  );
  return Wrap(
    spacing: CoreSpace.space12,
    runSpacing: CoreSpace.space12,
    children: [
      for (final column in columns)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
        ),
    ],
  );
}
