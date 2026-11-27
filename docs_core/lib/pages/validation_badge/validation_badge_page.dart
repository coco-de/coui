/// ValidationBadge 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `validation_badge_web.dart` · `validation_badge_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 다섯이다: `state`(enum 값의 이름) · `size`(크기 표의 행 이름) ·
/// `stateWord`(`true` 면 `label` 뒤에 상태를 말하는 낱말을 붙인다) ·
/// `customIcon`(`true` 면 상태 아이콘을 [validationBadgeCustomIcons] 로
/// 바꾼다) · `bordered`(`true` 면 [validationBadgeBorderStyle] 을 `style` 로
/// 넘긴다).
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/validation-badge.md`.
const String slug = 'validation-badge';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _validationBadgeSpec;

/// 미리보기에 라벨을 주지 않았을 때 배지에 적는 글.
const String validationBadgeSampleLabel = '8자 이상';

/// `state` 를 주지 않았거나 모르는 이름일 때 미리보기가 그리는 상태.
const CoreValidationState validationBadgePreviewDefaultState = CoreValidationState.valid;

/// 상태를 말하는 낱말 — `label` 에 상태를 함께 적는 예가 읽는다.
const Map<CoreValidationState, String> validationBadgeStateWords = {
  CoreValidationState.pending: '확인 전',
  CoreValidationState.valid: '충족',
  CoreValidationState.invalid: '미충족',
};

/// 아이콘을 바꾸는 예가 상태마다 쓰는 아이콘.
const Map<CoreValidationState, IconName> validationBadgeCustomIcons = {
  CoreValidationState.pending: LucideIcons.minus,
  CoreValidationState.valid: LucideIcons.circleCheck,
  CoreValidationState.invalid: LucideIcons.circleAlert,
};

/// 테두리를 켜는 예의 `style` — 두 플랫폼의 속성 빌더가 같은 값을 쓴다.
const CoreValidationBadgeStyle validationBadgeBorderStyle = CoreValidationBadgeStyle(
  borderWidth: CoreStrokeWidth.stroke1,
);

/// 규칙 장면이 "입력한 값" 으로 삼는 글 — 길이 규칙만 채운다.
const String validationBadgeSamplePassword = 'password';

/// 비밀번호 규칙 장면의 라벨과 충족 여부.
List<(String, bool)> validationBadgeRules(String password) => [
  ('8자 이상', password.length >= 8),
  ('영문 대문자 포함', password.contains(RegExp('[A-Z]'))),
  ('숫자 1개 이상', password.contains(RegExp('[0-9]'))),
];

/// 조건을 긍정형으로 적은 예.
const List<(CoreValidationState, String)> validationBadgeClearSamples = [
  (CoreValidationState.valid, '영문 대문자 포함'),
  (CoreValidationState.invalid, '숫자 1개 이상'),
];

/// 조건을 부정형으로 적은 예.
const List<(CoreValidationState, String)> validationBadgeVagueSamples = [
  (CoreValidationState.valid, '대문자 미포함은 안 됨'),
  (CoreValidationState.invalid, '숫자가 없으면 안 됨'),
];

/// 핵심 조건만 보인 예.
const List<String> validationBadgeFewRules = ['8자 이상', '영문 대문자 포함', '숫자 1개 이상'];

/// 조건을 한꺼번에 많이 보인 예.
const List<String> validationBadgeManyRules = [
  '8자 이상',
  '20자 이하',
  '영문 대문자 포함',
  '영문 소문자 포함',
  '숫자 1개 이상',
  '특수문자 1개 이상',
  '공백 없음',
  '같은 글자 3번 연속 금지',
];

/// 좁은 폭 장면의 부모 폭(logical px).
const double validationBadgeNarrowWidth = CoreSpace.space200;

/// 좁은 폭 장면의 긴 라벨.
const String validationBadgeLongLabel = '이름이나 생일처럼 추측하기 쉬운 정보는 넣지 않기';

/// 크기 → 크기 표와 플레이그라운드가 쓰는 크기 단계. 크기 표의 행은
/// `CoreComponentSize` 로 적는다.
CoreComponentSize validationBadgeSizeStep(CoreValidationBadgeSize size) => switch (size) {
  CoreValidationBadgeSize.extraSmall => CoreComponentSize.xs,
  CoreValidationBadgeSize.small => CoreComponentSize.sm,
  CoreValidationBadgeSize.medium => CoreComponentSize.md,
};

/// 속성의 `size`(크기 표의 행 이름) → 크기. 없거나 모르는 이름은 기본 크기.
CoreValidationBadgeSize validationBadgePreviewSize(Map<String, String> props) {
  for (final size in CoreValidationBadgeSize.values) {
    if (validationBadgeSizeStep(size).name == props['size']) return size;
  }
  return CoreValidationBadgeStyle.defaultSize;
}

/// 속성의 `state` → 상태.
CoreValidationState validationBadgePreviewState(Map<String, String> props) =>
    previewEnum(CoreValidationState.values, props['state'], validationBadgePreviewDefaultState);

/// 규칙 문구 뒤에 상태를 말하는 낱말을 붙인 라벨.
String validationBadgeStateLabel(String rule, CoreValidationState state) =>
    '$rule — ${validationBadgeStateWords[state]}';

/// 미리보기와 코드가 쓰는 라벨.
String validationBadgePreviewLabel(Map<String, String> props, String? label) {
  final rule = label ?? validationBadgeSampleLabel;
  if (!previewFlag(props, 'stateWord')) return rule;
  return validationBadgeStateLabel(rule, validationBadgePreviewState(props));
}

// 선택지는 enum 과 크기 행에서 읽는다 — 상태나 크기 행이 늘면
// 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'state': validationBadgePreviewDefaultState.name,
    'size': validationBadgeSizeStep(CoreValidationBadgeStyle.defaultSize).name,
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'state',
      prop: 'state',
      options: [for (final state in CoreValidationState.values) state.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreValidationBadgeStyle.defaultsBySize.keys) validationBadgeSizeStep(size).name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '상태 낱말', on: {'stateWord': 'true'}),
    const DocsPlaygroundFlag(label: '아이콘 바꾸기', on: {'customIcon': 'true'}),
    const DocsPlaygroundFlag(label: '테두리', on: {'bordered': 'true'}),
  ],
  code: _validationBadgeCode,
  label: validationBadgeSampleLabel,
);

/// 속성 → 코드. 기본값과 같은 인자는 적지 않고, 아이콘은 지금 상태의 것만
/// 적는다.
String _validationBadgeCode(Map<String, String> props, String? label) {
  final state = validationBadgePreviewState(props);
  final size = validationBadgePreviewSize(props);
  final icon = validationBadgeCustomIcons[state]!;
  final lines = [
    "label: '${validationBadgePreviewLabel(props, label)}',",
    'state: CoreValidationState.${state.name},',
    if (size != CoreValidationBadgeStyle.defaultSize) 'size: CoreValidationBadgeSize.${size.name},',
    if (previewFlag(props, 'customIcon')) '${state.name}Icon: LucideIcons.${docsIconIdentifier(icon.name)},',
    if (previewFlag(props, 'bordered'))
      'style: CoreValidationBadgeStyle(\n    borderWidth: CoreStrokeWidth.stroke1,\n  ),',
  ];
  return 'ValidationBadge(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _validationBadgeSpec() {
  return DocsSizeSpec(
    columns: const ['size', 'CoreValidationBadgeSize', '높이', '좌우 · 위아래 여백', '아이콘 · 간격', '모서리', '라벨 글자'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreValidationBadgeStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: validationBadgeSizeStep(size),
          cells: [
            size.name,
            docsSizeNumber(row.height),
            '${docsSizeNumber(row.horizontalPadding)} · ${docsSizeNumber(row.verticalPadding)}',
            '${docsSizeNumber(row.iconSize)} · ${docsSizeNumber(row.iconLabelGapStyle.size)}',
            docsSizeNumber(row.borderRadius),
            docsSizeLabel(row.labelStyle),
          ],
        ),
    ],
  );
}
