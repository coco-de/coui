/// NumberInput 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · `<SizeSpec>` · `<Card props>` ·
/// 플레이그라운드가, 장면은 `<Preview demo="number-input/...">` 가 읽는다. 같은
/// 이름의 Flutter 파일(`number_input_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'number_input_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _numberInput;

/// 장면 이름(`number-input/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'number-input/anatomy': () => const NumberInput(
    label: numberInputPreviewLabel,
    description: numberInputPreviewDescription,
    initialValue: numberInputPreviewValue,
    min: numberInputPreviewMin,
    max: numberInputPreviewMax,
  ),
  'number-input/states': _numberInputStates,
  'number-input/do-text-field': () => _sized(
    const TextField(label: '휴대폰 번호', placeholder: Text('010-0000-0000')),
  ),
  'number-input/related-text-field': () => _sized(
    const TextField(placeholder: Text('금액을 입력하세요')),
    width: '12rem',
  ),
};

Component _sized(Component child, {String width = '15rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

Component _numberInput(Map<String, String> props, String? label) => NumberInput(
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

/// 상태 격자 — 다섯 칸 모두 실제 NumberInput 이다. hover · 눌림 · 포커스는
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _numberInputStates() {
  const columns = ['기본', '최솟값', 'filled', '오류', '비활성'];
  Component cell(String state) => switch (state) {
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
  return div(classes: 'docs-demo-field-states', [
    for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final column in columns) cell(column),
  ]);
}
