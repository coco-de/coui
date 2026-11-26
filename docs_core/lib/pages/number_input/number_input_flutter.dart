/// NumberInput 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · `<SizeSpec>` · `<Card props>` ·
/// 플레이그라운드가, 장면은 `<Preview demo="number-input/...">` 가 읽는다. 같은
/// 이름의 Web 파일(`number_input_web.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'number_input_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _numberInput;

/// 장면 이름(`number-input/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'number-input/anatomy': () => const NumberInput(
    label: numberInputPreviewLabel,
    description: numberInputPreviewDescription,
    initialValue: numberInputPreviewValue,
    min: numberInputPreviewMin,
    max: numberInputPreviewMax,
  ),
  'number-input/states': _numberInputStates,
  'number-input/do-text-field': () => SizedBox(
    width: 240,
    child: TextField(label: '휴대폰 번호', placeholder: const Text('010-0000-0000')),
  ),
  'number-input/related-text-field': () => SizedBox(
    width: 192,
    child: TextField(placeholder: const Text('금액을 입력하세요')),
  ),
};

Widget _numberInput(Map<String, String> props, String? label) => NumberInput(
  value: numberInputPreviewValueOf(props),
  min: numberInputPreviewMin,
  max: numberInputPreviewMax,
  variant: previewEnum(
    CoreNumberInputVariant.values,
    props['variant'],
    CoreNumberInputVariant.defaultNumberInputVariant,
  ),
  size: previewEnum(CoreNumberInputSize.values, props['size'], CoreNumberInputSize.defaultSize),
  enabled: previewFlag(props, 'enabled', fallback: true),
  label: props['label'],
  description: props['description'],
  errorText: props['errorText'],
  onChanged: (_) {},
);

/// 상태 격자 — Web 과 같은 다섯 칸.
Widget _numberInputStates() {
  const columns = ['기본', '최솟값', 'filled', '오류', '비활성'];
  Widget cell(String state) => switch (state) {
    '최솟값' => const NumberInput(
      initialValue: numberInputPreviewMin,
      min: numberInputPreviewMin,
      max: numberInputPreviewMax,
    ),
    'filled' => const NumberInput(
      variant: CoreNumberInputVariant.filled,
      initialValue: numberInputPreviewValue,
      min: numberInputPreviewMin,
      max: numberInputPreviewMax,
    ),
    '오류' => const NumberInput(
      initialValue: numberInputPreviewValue,
      min: numberInputPreviewMin,
      max: numberInputPreviewMax,
      errorText: numberInputStatesError,
    ),
    '비활성' => const NumberInput(
      initialValue: numberInputPreviewValue,
      min: numberInputPreviewMin,
      max: numberInputPreviewMax,
      enabled: false,
    ),
    _ => const NumberInput(
      initialValue: numberInputPreviewValue,
      min: numberInputPreviewMin,
      max: numberInputPreviewMax,
    ),
  };
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
