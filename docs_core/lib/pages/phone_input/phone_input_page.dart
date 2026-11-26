/// PhoneInput 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `phone_input_web.dart` · `phone_input_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 번호 · 안내 문구 · 라벨은 아래 상수 한 곳에 둔다 — 두 플랫폼의
/// 그림과 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/phone-input.md`.
const String slug = 'phone-input';

/// 미리보기에 채우는 번호 — 국가 번호를 뺀 값.
const String phoneInputPreviewNumber = '1012345678';

/// 미리보기의 안내 문구.
const String phoneInputPreviewPlaceholder = '전화번호를 입력해 주세요';

/// 미리보기의 폼 라벨.
const String phoneInputPreviewLabel = '휴대폰 번호';

/// 좁은 관련 컴포넌트 카드에 쓰는 짧은 안내 문구 — 긴 문구는 카드에서 잘린다.
const String phoneInputPreviewShortPlaceholder = '번호 입력';

/// 상태 격자의 칸 이름 — 두 플랫폼이 같은 순서로 그린다.
const List<String> phoneInputStateColumns = ['기본', 'Hover', 'Focus', '비활성'];

/// 속성 `initialCountry`(ISO 코드)를 국가로 읽는다 — 없거나 모르는 코드면
/// `null`.
CoreCountry? phoneInputPreviewInitialCountry(Map<String, String> props) => switch (props['initialCountry']) {
  final code? => CoreCountry.byCode(code),
  _ => null,
};

/// 속성 `countries`(`KR,US,JP`)의 ISO 코드 목록 — 없으면 `null`.
List<String>? phoneInputPreviewCountryCodes(Map<String, String> props) =>
    props['countries']?.split(',').map((code) => code.trim()).toList();

/// 속성 `countries` 를 국가 목록으로 읽는다 — 없으면 `null`, 모르는 코드는 뺀다.
List<CoreCountry>? phoneInputPreviewCountries(Map<String, String> props) =>
    switch (phoneInputPreviewCountryCodes(props)) {
      final codes? => [for (final code in codes) ?CoreCountry.byCode(code)],
      _ => null,
    };

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 두 플랫폼의 생성자가 같은 이름을 받으므로 코드는 하나다. `initialCountry` ·
/// `initialNumber` 는 처음 한 번의 값이라, 미리보기는 두 값을 `key` 에 실어
/// 컨트롤을 바꿀 때 새로 그린다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'initialCountry': 'KR', 'placeholder': phoneInputPreviewPlaceholder},
  controls: [
    DocsPlaygroundChoice(
      label: 'initialCountry',
      prop: 'initialCountry',
      options: ['KR', 'US', 'JP'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '번호 채움', on: {'initialNumber': phoneInputPreviewNumber}),
    DocsPlaygroundFlag(label: '안내 문구', on: {'placeholder': phoneInputPreviewPlaceholder}),
    DocsPlaygroundFlag(label: '국가 셋만', on: {'countries': 'KR,US,JP'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _phoneInputCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// PhoneInput 에는 크기 축이 없다 — 상자는 늘 같은 높이다.
DocsSizeSpec Function()? get sizeSpec => null;

String _phoneInputCode(Map<String, String> props, String? label) {
  final lines = [
    if (props['initialCountry'] case final code?) "initialCountry: CoreCountry.byCode('$code'),",
    if (props['initialNumber'] case final number?) "initialNumber: '$number',",
    if (props['placeholder'] case final text?) "placeholder: '$text',",
    if (phoneInputPreviewCountryCodes(props) case final codes?) ...[
      'countries: [',
      for (final code in codes) "  CoreCountry.byCode('$code')!,",
      '],',
    ],
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setPhone,',
  ];
  return 'PhoneInput(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
