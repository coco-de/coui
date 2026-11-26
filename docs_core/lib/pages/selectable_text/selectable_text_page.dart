/// SelectableText 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `selectable_text_web.dart` · `selectable_text_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 선택 · 복사는 화면에서 글자를 끌어야 보인다. 그래서 정지 장면은 글자 모양과
/// 줄 수를 보이고, 선택은 플레이그라운드에서 해 본다. 속성은 다섯이다 —
/// `role`(글자 역할), `maxLines`(`none` · 숫자), `selectionColor`(`info25`),
/// `enableInteractiveSelection`(`false`), `report`(켜면 `onTap` 이 불린 횟수를
/// 아래에 보인다). 두 플랫폼 빌더와 코드가 같은 뜻으로 읽도록 해석은 이 파일
/// 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/selectable-text.md`.
const String slug = 'selectable-text';

/// 플레이그라운드의 글 — 태그가 `label` 을 주지 않을 때. [demoWidth] 에서
/// `maxLines` 2 에 다 들어가지 않을 길이다.
const String demoText = '주문 번호 A1B2-C3D4. 배송이 시작되면 이 번호로 위치를 확인합니다. 문의할 때도 같은 번호를 알려 주세요.';

/// 글자 모양 장면의 글.
const String demoShortText = '주문 번호 A1B2-C3D4';

/// 줄 수 장면의 긴 글.
const String demoLongText = '배송이 시작되면 주문 번호로 위치를 확인합니다. 문의할 때도 같은 번호를 알려 주세요. 번호는 주문 내역에서도 다시 볼 수 있습니다.';

/// 여러 조각 장면의 첫 조각.
const String demoRichLead = '주문 번호 ';

/// 여러 조각 장면의 굵은 조각.
const String demoRichStrong = 'A1B2-C3D4';

/// '이렇게 하세요' 카드의 이름.
const String demoCopyLabel = '주문 번호';

/// '이렇게 하세요' 카드의 값.
const String demoCopyValue = 'A1B2-C3D4';

/// '이렇게 하지 마세요' 카드의 이름.
const String demoEditLabel = '이름';

/// '이렇게 하지 마세요' 카드의 값 — 입력 자리처럼 읽히는 글.
const String demoEditValue = '이름을 입력하세요';

/// 미리보기 글 상자의 폭(logical px). 만들어진 코드에도 같은 폭이 들어간다.
const double demoWidth = 240;

/// 카드 안 장면의 폭(logical px).
const double demoCardWidth = 200;

/// `selectionColor=info25` 의 색. CoUI 의 `primary` 는 무채색이라 25% 로 칠하면
/// 기본 선택 색(`primaryContainer`)과 거의 구분되지 않아 `info` 를 쓴다.
const CoreColor demoTint = CoreColor.token(CoreColors.info, opacity: CoreOpacity.opacity25);

/// `role` 속성 → 글자 역할. 여기 없는 값(`bodyMedium`)은 기본값이라 코드에
/// 적지 않는다.
const Map<String, CoreTextStyleToken> demoRoles = {
  'bodyLarge': CoreTextStyles.bodyLarge,
  'titleMedium': CoreTextStyles.titleMedium,
};

/// '이렇게 하세요' 카드의 값 스타일.
const CoreSelectableTextStyle demoCopyStyle = CoreSelectableTextStyle(
  textStyle: CoreTextStyle.token(CoreTextStyles.titleMedium),
);

/// '이렇게 하지 마세요' 카드의 값 스타일 — 자리표시 글처럼 옅게.
const CoreSelectableTextStyle demoPlaceholderStyle = CoreSelectableTextStyle(
  textStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSurfaceVariant)),
);

/// `selectable-text/styles` 장면의 줄 — 설명과 `selectableTextStyle`.
const List<(String, CoreSelectableTextStyle?)> demoStyleRows = [
  ('기본값', null),
  (
    'titleMedium 역할',
    CoreSelectableTextStyle(textStyle: CoreTextStyle.token(CoreTextStyles.titleMedium)),
  ),
  (
    '크기 18 · SemiBold',
    CoreSelectableTextStyle(
      textStyle: CoreTextStyle(fontSize: CoreFontSize.s18, fontWeight: CoreFontWeight.semiBold),
    ),
  ),
  (
    'onSurfaceVariant 글자색',
    CoreSelectableTextStyle(textStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSurfaceVariant))),
  ),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'role': 'bodyMedium', 'maxLines': 'none'},
  label: demoText,
  controls: [
    DocsPlaygroundChoice(label: '글자 역할', prop: 'role', options: ['bodyMedium', 'bodyLarge', 'titleMedium']),
    DocsPlaygroundChoice(label: 'maxLines', prop: 'maxLines', options: ['none', '1', '2'], segmented: true),
    DocsPlaygroundFlag(label: '선택 색 바꾸기', on: {'selectionColor': 'info25'}),
    DocsPlaygroundFlag(label: '선택 끄기', on: {'enableInteractiveSelection': 'false'}),
    DocsPlaygroundFlag(label: 'onTap 횟수 보기', on: {'report': 'true'}),
  ],
  code: _selectableTextCode,
  webCode: _selectableTextWebCode,
);

/// 크기 표. SelectableText 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `selectionColor` 가 바꾼 선택 색인가.
bool demoTinted(Map<String, String> props) => props['selectionColor'] == 'info25';

/// 속성 → `selectableTextStyle`. 바꾼 것이 없으면 `null`.
CoreSelectableTextStyle? demoStyleOf(Map<String, String> props) {
  final role = demoRoles[props['role']];
  final tinted = demoTinted(props);
  if (role == null && !tinted) return null;
  return CoreSelectableTextStyle(
    textStyle: role == null ? null : CoreTextStyle.token(role),
    selectionColor: tinted ? demoTint : null,
  );
}

/// 속성의 `maxLines` — `none` 이나 1 보다 작은 값은 `null`(제한 없음).
int? demoMaxLinesOf(Map<String, String> props) {
  final lines = int.tryParse(props['maxLines'] ?? '');
  return lines != null && lines > 0 ? lines : null;
}

/// 속성의 `enableInteractiveSelection` — 없으면 위젯의 기본값(`true`).
bool demoSelectionEnabled(Map<String, String> props) =>
    previewFlag(props, 'enableInteractiveSelection', fallback: true);

/// 속성의 `report` — `onTap` 이 불린 횟수를 보이는가.
bool demoReportsTap(Map<String, String> props) => previewFlag(props, 'report');

/// `report` 를 켠 미리보기의 아래 줄.
String demoTapLabel(int count) => 'onTap: $count';

/// 두 플랫폼이 같이 쓰는 `SelectableText(…),` 줄 — 둘레의 상자만 다르다.
List<String> _selectableTextLines(Map<String, String> props, String? label) {
  final role = props['role'];
  final hasRole = demoRoles.containsKey(role);
  final tinted = demoTinted(props);
  final lines = demoMaxLinesOf(props);
  return [
    'SelectableText(',
    "  '${label ?? demoText}',",
    if (hasRole || tinted) ...[
      '  selectableTextStyle: CoreSelectableTextStyle(',
      if (hasRole) '    textStyle: CoreTextStyle.token(CoreTextStyles.$role),',
      if (tinted) ...[
        '    selectionColor: CoreColor.token(',
        '      CoreColors.info,',
        '      opacity: CoreOpacity.opacity25,',
        '    ),',
      ],
      '  ),',
    ],
    if (lines != null) '  maxLines: $lines,',
    if (!demoSelectionEnabled(props)) '  enableInteractiveSelection: false,',
    if (demoReportsTap(props)) '  onTap: countTap,',
    '),',
  ];
}

Iterable<String> _indented(Iterable<String> lines, int spaces) => lines.map((line) => '${' ' * spaces}$line');

String _selectableTextCode(Map<String, String> props, String? label) {
  final text = _selectableTextLines(props, label);
  final width = demoWidth.toInt();
  if (!demoReportsTap(props)) {
    return [
      'SizedBox(',
      '  width: $width,',
      '  child: ${text.first}',
      ..._indented(text.skip(1), 2),
      ')',
    ].join('\n');
  }
  return [
    'SizedBox(',
    '  width: $width,',
    '  child: Column(',
    '    mainAxisSize: MainAxisSize.min,',
    '    crossAxisAlignment: CrossAxisAlignment.start,',
    '    children: [',
    ..._indented(text, 6),
    '      const Gap.space8(),',
    r"      Text('onTap: $tapCount').bodySmall.onSurfaceVariant,",
    '    ],',
    '  ),',
    ')',
  ].join('\n');
}

String _selectableTextWebCode(Map<String, String> props, String? label) {
  final report = demoReportsTap(props);
  final width = demoWidth.toInt();
  return [
    'div(',
    '  [',
    ..._indented(_selectableTextLines(props, label), 4),
    if (report) ...[
      '    const Gap.space8(),',
      r"    Text('onTap: $tapCount').bodySmall.onSurfaceVariant,",
    ],
    '  ],',
    if (report) "  classes: 'flex flex-col items-start',",
    "  styles: Styles(raw: {'width': '${width}px', 'max-width': '100%'}),",
    ')',
  ].join('\n');
}
