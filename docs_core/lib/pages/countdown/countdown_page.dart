/// Countdown 페이지 — 플레이그라운드와 장면이 함께 읽는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `countdown_web.dart` · `countdown_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 숫자는 전부 고정값이다 — 장면과 플레이그라운드는 시계를 읽지 않으므로
/// 서버에서 그린 화면과 브라우저의 화면이 늘 같다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/countdown.md`.
const String slug = 'countdown';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축(`CoreComponentSize`)이 없어 `null` 이다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성에 `value` 가 없을 때의 숫자.
const int countdownPreviewDefaultValue = 42;

/// 플레이그라운드에서 고를 수 있는 글자색 — 속성 값 → 색 토큰.
const Map<String, CoreColorToken> countdownPreviewColors = {
  'onSurface': CoreColors.onSurface,
  'info': CoreColors.info,
  'error': CoreColors.error,
};

/// 플레이그라운드에서 고를 수 있는 글자 역할 — 속성 값 → 역할 토큰.
///
/// Flutter 임베드는 높이가 정해져 있어, 가장 큰 선택지의 줄 높이가 그 안에
/// 들어가야 한다.
const Map<String, CoreTextStyleToken> countdownPreviewRoles = {
  'headlineSmall': CoreTextStyles.headlineSmall,
  'headlineLarge': CoreTextStyles.headlineLarge,
  'displaySmall': CoreTextStyles.displaySmall,
};

/// 아무것도 주지 않았을 때의 글자색 이름.
const String countdownPreviewDefaultColor = 'onSurface';

/// 아무것도 주지 않았을 때의 글자 역할 이름.
const String countdownPreviewDefaultRole = 'headlineLarge';

/// 속성의 `value` — 정수가 아니면 [countdownPreviewDefaultValue].
int countdownPreviewValue(Map<String, String> props) =>
    int.tryParse(props['value'] ?? '') ?? countdownPreviewDefaultValue;

/// 속성의 `max` — 없거나 기본 아래 끝보다 작으면 기본 위 끝.
int countdownPreviewMax(Map<String, String> props) {
  final max = int.tryParse(props['max'] ?? '');
  if (max == null || max < CoreCountdownContract.defaultMinValue) {
    return CoreCountdownContract.defaultMaxValue;
  }
  return max;
}

/// 속성의 `color` — 모르는 이름이면 기본 이름.
String countdownPreviewColorName(Map<String, String> props) {
  final name = props['color'];
  return countdownPreviewColors.containsKey(name) ? name! : countdownPreviewDefaultColor;
}

/// 속성의 `role` — 모르는 이름이면 기본 이름.
String countdownPreviewRoleName(Map<String, String> props) {
  final name = props['role'];
  return countdownPreviewRoles.containsKey(name) ? name! : countdownPreviewDefaultRole;
}

/// 속성 → `countdownStyle`. 색과 역할이 모두 기본이면 `null` 이다.
CoreCountdownStyle? countdownPreviewStyle(Map<String, String> props) {
  final color = countdownPreviewColorName(props);
  final role = countdownPreviewRoleName(props);
  final changesColor = color != countdownPreviewDefaultColor;
  final changesRole = role != countdownPreviewDefaultRole;
  if (!changesColor && !changesRole) return null;
  return CoreCountdownStyle(
    color: changesColor ? CoreColor.token(countdownPreviewColors[color]!) : null,
    labelStyle: changesRole ? CoreTextStyle.token(countdownPreviewRoles[role]!) : null,
  );
}

/// 값과 범위 장면의 칸 — 숫자 아래에 적는 글, `value`, `max`.
const List<(String, int, int)> countdownRangeSamples = [
  ('value: -5', -5, CoreCountdownContract.defaultMaxValue),
  ('value: 42', 42, CoreCountdownContract.defaultMaxValue),
  ('value: 120', 120, CoreCountdownContract.defaultMaxValue),
  ('value: 120, max: 365', 120, 365),
];

/// 시 · 분 · 초를 한 줄로 잇는 장면의 값.
const List<int> countdownTimeSample = [2, 45, 30];

/// [countdownTimeSample] 을 초 하나로 합친 값 — 하지 말아야 할 예.
const int countdownTotalSecondsSample = 9930;

/// 초 하나로 합친 값을 자르지 않고 보이기 위한 위 끝 — 하루의 마지막 초.
const int countdownTotalSecondsMax = 86399;

/// 테마와 스타일 장면 — 낱개 필드로 크기와 색을 바꾼 스타일.
const CoreCountdownStyle countdownDemoFieldStyle = CoreCountdownStyle(
  fontSize: CoreFontSize.s48,
  color: CoreColor.token(CoreColors.primary),
);

/// 테마와 스타일 장면 — 글자 역할만 바꾼 스타일.
const CoreCountdownStyle countdownDemoRoleStyle = CoreCountdownStyle(
  labelStyle: CoreTextStyle.token(CoreTextStyles.titleLarge),
);

/// 테마와 스타일 장면의 칸 — 숫자 아래에 적는 글과 스타일.
const List<(String, CoreCountdownStyle?)> countdownStyleSamples = [
  ('기본', null),
  ('fontSize · color', countdownDemoFieldStyle),
  ('labelStyle', countdownDemoRoleStyle),
];

/// 맥락을 글로 붙이는 장면 — 숫자 앞의 글.
const String countdownContextBefore = '인증번호 재전송까지';

/// 맥락을 글로 붙이는 장면 — 숫자.
const int countdownContextValue = 42;

/// 맥락을 글로 붙이는 장면 — 숫자 뒤의 글.
const String countdownContextAfter = '초';

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  // 처음 값은 위 끝을 올린 세 자리 수다 — `max` 를 끄면 같은 값이 99 로 보인다.
  initial: const {
    'value': '120',
    'max': '365',
    'role': countdownPreviewDefaultRole,
    'color': countdownPreviewDefaultColor,
  },
  controls: [
    const DocsPlaygroundChoice(label: 'value', prop: 'value', options: ['8', '42', '120'], segmented: true),
    const DocsPlaygroundFlag(label: 'max: 365', on: {'max': '365'}),
    DocsPlaygroundChoice(label: 'labelStyle 역할', prop: 'role', options: [...countdownPreviewRoles.keys]),
    DocsPlaygroundChoice(label: 'color', prop: 'color', options: [...countdownPreviewColors.keys], segmented: true),
  ],
  code: _countdownCode,
);

/// 속성 → 코드. 기본값과 같은 인자는 적지 않는다.
String _countdownCode(Map<String, String> props, String? label) {
  final max = countdownPreviewMax(props);
  final color = countdownPreviewColorName(props);
  final role = countdownPreviewRoleName(props);
  final styleLines = [
    if (color != countdownPreviewDefaultColor) 'color: CoreColor.token(CoreColors.$color),',
    if (role != countdownPreviewDefaultRole) 'labelStyle: CoreTextStyle.token(CoreTextStyles.$role),',
  ];
  final lines = [
    'value: ${countdownPreviewValue(props)},',
    if (max != CoreCountdownContract.defaultMaxValue) 'max: $max,',
    if (styleLines.isNotEmpty) ...[
      'countdownStyle: CoreCountdownStyle(',
      for (final line in styleLines) '  $line',
      '),',
    ],
  ];
  return 'Countdown(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
