/// Range 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="range/...">` 가 읽는다. 같은 이름의 Web 파일(`range_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Range 는 부모가 준 폭을 다 채운다(`LayoutBuilder` 의 최대 폭) — 무대는 폭을
/// 정하지 않으므로 미리보기는 늘 `SizedBox` 로 폭을 준다. 장면은 정지 그림이라
/// `onChanged` 는 빈 함수다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'range_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _range;

/// 장면 이름(`range/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  'range/with-values': () => SizedBox(
    width: 192,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpace.space8,
      children: [
        const Text(rangePricePreviewLabel).labelLarge.onSurface,
        Range(
          minValue: rangePricePreviewMinValue,
          maxValue: rangePricePreviewMaxValue,
          max: rangePricePreviewMax,
          step: rangePricePreviewStep,
          onChanged: (_, _) {},
        ),
      ],
    ),
  ),
  'range/related-slider': () => _sized(Slider(value: 60, min: 0, max: 100, onChanged: (_) {}), width: 192),
  'range/related-progress': () => _sized(const Progress(value: 0.6), width: 192),
};

Widget _sized(Widget child, {double width = 240}) => SizedBox(width: width, child: child);

Widget _range(Map<String, String> props, String? label) => _sized(
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

/// 상태 격자 — Web 과 같은 두 칸. Web 의 `.docs-demo-field-states` 처럼 라벨을
/// 칸 가운데에 두고, 칸 사이와 라벨 · 칸 사이를 모두 12 로 띄운다.
Widget _rangeStates() {
  const columns = ['기본', '비활성'];
  Widget cell(String state) => SizedBox(
    width: 160,
    child: Range(
      minValue: rangePreviewMinValue,
      maxValue: rangePreviewMaxValue,
      enabled: state != '비활성',
      onChanged: (_, _) {},
    ),
  );
  return Wrap(
    spacing: CoreSpace.space12,
    runSpacing: CoreSpace.space12,
    children: [
      for (final column in columns)
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CoreSpace.space12,
          children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
        ),
    ],
  );
}
