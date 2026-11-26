/// Slider 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="slider/...">` 가 읽는다. 같은 이름의 Flutter 파일(`slider_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 슬라이더는 받은 폭을 채운다(루트가 `width: 100%`). 무대는 내용 폭으로
/// 줄어드는 flex 상자라, 모든 장면은 폭을 정한 상자 안에 슬라이더를 둔다.
/// 장면은 정지 그림이다 — `onChanged` 는 빈 함수라 눌러도 값이 바뀌지 않는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'slider_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _slider;

/// 장면 이름(`slider/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'slider/anatomy': () => _sized(
    Slider(
      value: 30,
      onChanged: (_) {},
      leading: const Icon(LucideIcons.minus),
      trailing: const Icon(LucideIcons.plus),
    ),
    width: '20rem',
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
  'slider/with-number-input': () => div(
    styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': '0.75rem', 'width': '20rem'}),
    [
      div(styles: Styles(raw: {'flex': '1', 'min-width': '0'}), [_temperature(withLabel: false)]),
      NumberInput(
        value: sliderTemperatureValue,
        min: sliderTemperatureMin,
        max: sliderTemperatureMax,
        onChanged: (_) {},
      ),
    ],
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
    width: '12rem',
  ),
  'slider/related-number-input': () => NumberInput(
    value: sliderTemperatureValue,
    min: sliderTemperatureMin,
    max: sliderTemperatureMax,
    onChanged: (_) {},
  ),
  'slider/related-progress': () => _sized(const Progress(value: 0.6), width: '12rem'),
};

Component _sized(Component child, {String width = '15rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

/// 위에서 아래로 쌓는 장면 — 폭은 슬라이더 한 개의 폭.
Component _column(List<Component> children) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': '0.5rem', 'width': '15rem'}),
  children,
);

/// 온도 예시 — 16 ~ 30 도, 1 도씩, 지금 값을 뒤 슬롯에 보인다.
Component _temperature({bool withLabel = true}) => Slider(
  value: sliderTemperatureValue,
  min: sliderTemperatureMin,
  max: sliderTemperatureMax,
  divisions: sliderTemperatureDivisions,
  onChanged: (_) {},
  trailing: withLabel ? const Text(sliderTemperatureLabel).bodyMedium.onSurface : null,
);

Component _slider(Map<String, String> props, String? label) => _sized(
  Slider(
    value: _number(props['value'], 50),
    min: _number(props['min'], 0),
    max: _number(props['max'], 100),
    step: double.tryParse(props['step'] ?? ''),
    divisions: int.tryParse(props['divisions'] ?? ''),
    enabled: previewFlag(props, 'enabled', fallback: true),
    onChanged: (_) {},
    leading: docsWebIcon(props['leading']),
    trailing: docsWebIcon(props['trailing']),
  ),
);

double _number(String? raw, double fallback) => double.tryParse(raw ?? '') ?? fallback;

/// 상태 격자 — 네 칸 모두 실제 Slider 다. 끄는 동안 · 포커스는 브라우저가
/// 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _sliderStates() {
  const columns = ['value: 0', 'value: 60', 'value: 100', '비활성'];
  Component cell(String state) => div(styles: Styles(raw: {'width': '9.5rem'}), [
    switch (state) {
      'value: 0' => Slider(onChanged: (_) {}),
      'value: 100' => Slider(value: 100, onChanged: (_) {}),
      '비활성' => Slider(value: 60, enabled: false, onChanged: (_) {}),
      _ => Slider(value: 60, onChanged: (_) {}),
    },
  ]);
  return div(
    classes: 'docs-demo-field-states',
    styles: Styles(raw: {'grid-template-columns': 'repeat(${columns.length}, max-content)'}),
    [
      for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
      for (final column in columns) cell(column),
    ],
  );
}
