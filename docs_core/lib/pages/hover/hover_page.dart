/// Hover 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `hover_web.dart` · `hover_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기는 테두리 카드 하나를 `Hover` 로 감싼다. 속성은 둘이다 — `effect`
/// (`CoreHoverEffect` 의 이름)와 `report`(켜면 카드의 글자가 `onHover` 가
/// 알려 준 값을 보인다). 카드의 글자 · 스타일 · 해석을 이 파일 한 곳에 두어
/// 두 플랫폼의 미리보기와 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/hover.md`.
const String slug = 'hover';

/// 카드의 글자 — 태그가 `label` 을 주지 않을 때.
const String demoLabel = '올려 보세요';

/// `report` 를 켠 카드의 글자 — `onHover` 가 `true` 를 알려 준 뒤.
const String demoReportOn = 'onHover: true';

/// `report` 를 켠 카드의 글자 — `onHover` 가 `false` 이거나 아직 알려 주기 전.
const String demoReportOff = 'onHover: false';

/// `brighten` 을 고른 카드의 스타일 — 흰 면은 밝기를 곱해도 그대로라서 채운다.
const CoreCardStyle demoBrightenCardStyle = CoreCardStyle(
  backgroundColor: CoreColor.token(CoreColors.primaryContainer),
);

/// `shadow` 를 고른 카드의 스타일 — 카드가 자기 그림자를 겹쳐 그리지 않는다.
const CoreCardStyle demoShadowCardStyle = CoreCardStyle(boxShadow: CoreShadow.none);

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'effect': 'scaleUp'},
  label: demoLabel,
  controls: [
    DocsPlaygroundChoice(
      label: 'effect',
      prop: 'effect',
      options: ['none', 'scaleUp', 'scaleDown', 'fade', 'brighten', 'shadow'],
    ),
    DocsPlaygroundFlag(label: 'onHover 값 보기', on: {'report': 'true'}),
  ],
  code: _hoverCode,
);

/// 크기 표. Hover 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `effect` — 없거나 모르는 값은 위젯의 기본값(`none`).
CoreHoverEffect demoEffectOf(Map<String, String> props) =>
    previewEnum(CoreHoverEffect.values, props['effect'], CoreHoverEffect.defaultEffect);

/// 속성의 `report` — 카드의 글자가 `onHover` 값을 보이는가.
bool demoReportsHover(Map<String, String> props) => previewFlag(props, 'report');

/// [effect] 를 고른 카드의 스타일. 따로 정할 것이 없으면 `null`.
CoreCardStyle? demoCardStyleOf(CoreHoverEffect effect) => switch (effect) {
  CoreHoverEffect.brighten => demoBrightenCardStyle,
  CoreHoverEffect.shadow => demoShadowCardStyle,
  _ => null,
};

/// 코드 속 카드의 `cardStyle` 줄 — [demoCardStyleOf] 와 같은 값이다.
List<String> _cardStyleLines(CoreHoverEffect effect) => switch (effect) {
  CoreHoverEffect.brighten => const [
    'cardStyle: CoreCardStyle(',
    '  backgroundColor: CoreColor.token(CoreColors.primaryContainer),',
    '),',
  ],
  CoreHoverEffect.shadow => const ['cardStyle: CoreCardStyle(boxShadow: CoreShadow.none),'],
  _ => const [],
};

String _hoverCode(Map<String, String> props, String? label) {
  final effect = demoEffectOf(props);
  final report = demoReportsHover(props);
  final text = report ? "hovered ? '$demoReportOn' : '$demoReportOff'" : "'${label ?? demoLabel}'";
  final lines = [
    if (effect != CoreHoverEffect.defaultEffect) 'effect: CoreHoverEffect.${effect.name},',
    if (report) 'onHover: setHovered,',
    'child: Card(',
    '  variant: CoreCardVariant.outlined,',
    for (final line in _cardStyleLines(effect)) '  $line',
    '  child: Text($text),',
    '),',
  ];
  return 'Hover(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
