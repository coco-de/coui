/// Text 페이지 — 플레이그라운드와 장면이 함께 읽는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `text_web.dart` · `text_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 chain 이름이다 — `role` 은 글자 역할 chain, `color` 는 색 chain 의
/// 이름이고, `bold` · `italic` · `underline` · `clamp` · `keepAll` 은 켜고 끈다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/text.md`.
const String slug = 'text';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Text 의 크기는 크기 단계(`CoreComponentSize`)가 아니라 글자 역할이 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 화면 · 장면 제목처럼 쓰는 글 — 좁은 폭에서 한 낱말이 두 줄로 갈리는지 본다.
const String textSampleTitle = '리포머 심화 플로우와 회복 스트레칭';

/// 여러 줄이 되는 안내 글 — 줄 수 제한과 말줄임 장면이 읽는다.
const String textSampleNotice = '예약한 수업은 시작 두 시간 전까지 취소할 수 있습니다. 그 뒤에 취소하면 수강권이 한 번 차감됩니다.';

/// 역할과 크기의 순서를 보이는 글.
const String textSampleSales = '이번 달 매출';

/// 글자색을 보이는 오류 안내.
const String textSampleError = '비밀번호가 일치하지 않습니다.';

/// `Text.rich` 장면의 조각 — 앞 글, 색 · 굵기, 색 · 기울임, 밑줄.
const String textRichLead = '섞어 쓰기: ';

/// `Text.rich` 장면에서 색과 굵기를 준 조각.
const String textRichStrong = '안내';

/// `Text.rich` 장면에서 색과 기울임을 준 조각.
const String textRichError = '오류';

/// `Text.rich` 장면에서 밑줄을 준 조각.
const String textRichUnderline = '밑줄';

/// 플레이그라운드의 처음 역할.
const String textDefaultRole = 'titleMedium';

/// 플레이그라운드의 처음 색.
const String textDefaultColor = 'onSurface';

/// 플레이그라운드가 고르게 하는 역할 — 묶음마다 대표 하나 이상.
const List<String> textPlaygroundRoles = [
  'displaySmall',
  'headlineMedium',
  'titleLarge',
  textDefaultRole,
  'bodyLarge',
  'bodyMedium',
  'bodySmall',
  'labelMedium',
  'codeMd',
];

/// 플레이그라운드가 고르게 하는 색 — 흰 무대에서 읽히는 글자색.
const List<String> textPlaygroundColors = [
  textDefaultColor,
  'onSurfaceVariant',
  'onPrimaryContainer',
  'onErrorContainer',
  'onSuccessContainer',
  'onWarningContainer',
  'onInfoContainer',
];

/// `text/colors` 장면에 늘어놓는 색.
const List<String> textColorSampleNames = [
  'onSurface',
  'onSurfaceVariant',
  'outline',
  'onPrimaryContainer',
  'onSecondaryContainer',
  'onTertiaryContainer',
  'onErrorContainer',
  'onSuccessContainer',
  'onWarningContainer',
  'onInfoContainer',
];

/// display · headline · title 역할의 chain 이름 — `CoreTextStyles.values` 의
/// 앞 아홉.
final List<String> textHeadingRoleNames = [
  for (final token in CoreTextStyles.values.take(_headingRoleCount)) docsIconIdentifier(token.name),
];

/// body · label · code 역할의 chain 이름.
final List<String> textBodyRoleNames = [
  for (final token in CoreTextStyles.values.skip(_headingRoleCount)) docsIconIdentifier(token.name),
];

const int _headingRoleCount = 9;

/// 속성의 `role` — 선택지에 없으면 처음 역할.
String textPreviewRole(Map<String, String> props) {
  final role = props['role'];
  return textPlaygroundRoles.contains(role) ? role! : textDefaultRole;
}

/// 속성의 `color` — 선택지에 없으면 처음 색.
String textPreviewColor(Map<String, String> props) {
  final color = props['color'];
  return textPlaygroundColors.contains(color) ? color! : textDefaultColor;
}

const DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'role': textDefaultRole, 'color': textDefaultColor},
  controls: [
    DocsPlaygroundChoice(label: 'role', prop: 'role', options: textPlaygroundRoles),
    DocsPlaygroundChoice(label: 'color', prop: 'color', options: textPlaygroundColors),
    DocsPlaygroundFlag(label: '굵게', on: {'bold': 'true'}),
    DocsPlaygroundFlag(label: '기울임', on: {'italic': 'true'}),
    DocsPlaygroundFlag(label: '밑줄', on: {'underline': 'true'}),
    DocsPlaygroundFlag(label: '두 줄 말줄임', on: {'clamp': 'true'}),
    DocsPlaygroundFlag(label: '어절 줄바꿈', on: {'keepAll': 'true'}),
  ],
  label: textSampleTitle,
  code: _textCode,
);

/// 속성 → 코드. 역할을 맨 앞에 적는다 — 역할은 그 앞에 적은 크기 · 굵기를
/// 덮는다.
String _textCode(Map<String, String> props, String? label) {
  final chain = [
    '.${textPreviewRole(props)}',
    '.${textPreviewColor(props)}',
    if (previewFlag(props, 'bold')) '.bold',
    if (previewFlag(props, 'italic')) '.italic',
    if (previewFlag(props, 'underline')) '.underline',
    if (previewFlag(props, 'clamp')) ...['.lineLimit(2)', '.ellipsis'],
    if (previewFlag(props, 'keepAll')) '.keepAll',
  ];
  return "Text('${label ?? textSampleTitle}')\n${chain.map((link) => '    $link').join('\n')}";
}
