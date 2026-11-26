/// PhoneInput 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="phone-input/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`phone_input_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'phone_input_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _phoneInput;

/// 장면 이름(`phone-input/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'phone-input/anatomy': () => _sized(
    const PhoneInput(initialNumber: phoneInputPreviewNumber, placeholder: phoneInputPreviewPlaceholder),
  ),
  'phone-input/states': _phoneInputStates,
  'phone-input/do-form-field': () => _sized(
    const FormField(
      label: phoneInputPreviewLabel,
      child: PhoneInput(placeholder: phoneInputPreviewPlaceholder),
    ),
  ),
  'phone-input/related-form-field': () => _sized(
    const FormField(
      label: phoneInputPreviewLabel,
      child: PhoneInput(placeholder: phoneInputPreviewShortPlaceholder),
    ),
    width: '12rem',
  ),
  'phone-input/related-text-field': () => _sized(
    const TextField(type: CoreInputType.tel, placeholder: Text('전화번호')),
    width: '12rem',
  ),
  'phone-input/related-select': () => _sized(
    Select<String>(
      value: 'KR',
      onChanged: (_) {},
      items: const [
        CoreSelectItem(value: 'KR', label: '대한민국 +82'),
        CoreSelectItem(value: 'US', label: '미국 +1'),
      ],
    ),
    width: '12rem',
  ),
};

/// 상자는 부모 폭을 채우고 번호 칸은 200 에서 멈춘다 — 둘이 함께 보이는 폭.
Component _sized(Component child, {String width = '18rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

/// `initialCountry` · `initialNumber` 는 처음 한 번의 값이라 두 값이 바뀌면
/// `key` 로 새로 그린다.
Component _phoneInput(Map<String, String> props, String? label) => _sized(
  PhoneInput(
    key: ValueKey('${props['initialCountry']}/${props['initialNumber']}'),
    initialCountry: phoneInputPreviewInitialCountry(props),
    initialNumber: props['initialNumber'],
    placeholder: props['placeholder'],
    countries: phoneInputPreviewCountries(props),
    enabled: previewFlag(props, 'enabled', fallback: true),
    onChanged: (_) {},
  ),
);

/// 상태 격자 — 이름과 상자를 한 줄씩 놓는다. Hover · Focus 칸은 쉴 때의
/// 테두리 색을 그 상태의 색으로 바꿔 그린다. Focus 칸은 포인터를 올려도 같은
/// 색이도록 Hover 테두리 색도 바꾼다.
Component _phoneInputStates() => div(
  classes: 'docs-demo-field-states',
  styles: Styles(
    raw: {
      'grid-template-columns': 'max-content 18rem',
      'justify-items': 'start',
      'align-items': 'center',
    },
  ),
  [
    for (final column in phoneInputStateColumns) ...[
      span([Text(column).labelSmall.onSurfaceVariant]),
      _sized(_stateCell(column)),
    ],
  ],
);

Component _stateCell(String state) => switch (state) {
  'Hover' => const PhoneInput(
    placeholder: phoneInputPreviewPlaceholder,
    phoneInputStyle: CorePhoneInputStyle(borderColor: CorePhoneInputStyle.defaultHoverBorderColor),
  ),
  'Focus' => const PhoneInput(
    placeholder: phoneInputPreviewPlaceholder,
    phoneInputStyle: CorePhoneInputStyle(
      borderColor: CorePhoneInputStyle.defaultFocusBorderColor,
      hoverBorderColor: CorePhoneInputStyle.defaultFocusBorderColor,
    ),
  ),
  '비활성' => const PhoneInput(placeholder: phoneInputPreviewPlaceholder, enabled: false),
  _ => const PhoneInput(placeholder: phoneInputPreviewPlaceholder),
};
