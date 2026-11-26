/// Range 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="range/...">` 가 읽는다. 같은 이름의 Flutter 파일(`range_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Range 는 부모가 준 폭을 다 채운다 — 무대는 내용 폭으로 줄어들므로 미리보기는
/// 늘 폭을 정한 상자에 담는다. 장면은 정지 그림이라 `onChanged` 는 빈 함수다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'range_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _range;

/// 장면 이름(`range/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 블록의 번호는 이 마크업의 순서를 읽는다 — 앞 글자(`span`) · 트랙 ·
  // 두 핸들(`role="slider"`) · 뒤 글자.
  'range/anatomy': () => _sized(
    Range(
      minValue: rangePreviewMinValue,
      maxValue: rangePreviewMaxValue,
      onChanged: (_, _) {},
      leading: const Text(rangePreviewLeading),
      trailing: const Text(rangePreviewTrailing),
    ),
  ),
  'range/states': _rangeStates,
  'range/with-values': () => div(classes: 'docs-demo-stack', [
    const Text(rangePricePreviewLabel).labelLarge.onSurface,
    Range(
      minValue: rangePricePreviewMinValue,
      maxValue: rangePricePreviewMaxValue,
      max: rangePricePreviewMax,
      step: rangePricePreviewStep,
      onChanged: (_, _) {},
    ),
  ]),
  'range/related-slider': () => _sized(Slider(value: 60, min: 0, max: 100, onChanged: (_) {}), width: '12rem'),
  'range/related-progress': () => _sized(const Progress(value: 0.6), width: '12rem'),
};

Component _sized(Component child, {String width = '15rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

Component _range(Map<String, String> props, String? label) => _sized(
  Range(
    minValue: rangePreviewValue(props, 'minValue', CoreRangeContract.defaultMin),
    maxValue: rangePreviewValue(props, 'maxValue', CoreRangeContract.defaultMax),
    enabled: previewFlag(props, 'enabled', fallback: true),
    onChanged: (_, _) {},
    leading: switch (props['leading']) {
      final leading? => Text(leading),
      null => null,
    },
    trailing: switch (props['trailing']) {
      final trailing? => Text(trailing),
      null => null,
    },
  ),
);

/// 상태 격자 — 두 칸 모두 실제 Range 다. 끌기 · 포커스는 브라우저가 포인터나
/// 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _rangeStates() {
  const columns = ['기본', '비활성'];
  Component cell(String state) => div(styles: Styles(raw: {'width': '10rem'}), [
    Range(
      minValue: rangePreviewMinValue,
      maxValue: rangePreviewMaxValue,
      enabled: state != '비활성',
      onChanged: (_, _) {},
    ),
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
