/// DisclosureBadge 페이지 — 플레이그라운드와 두 플랫폼이 함께 읽는 예시 값.
/// 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `disclosure_badge_web.dart` · `disclosure_badge_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/disclosure-badge.md`.
const String slug = 'disclosure-badge';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기에 라벨을 주지 않았을 때 kind 마다 적는 글 — 두 플랫폼의 속성
/// 빌더 · 장면과 플레이그라운드 코드가 같은 글을 읽는다.
const Map<CoreDisclosureKind, String> disclosureBadgeSampleLabels = {
  CoreDisclosureKind.open: '근거 공개',
  CoreDisclosureKind.commitment: '계약 시 제공',
  CoreDisclosureKind.private: '비공개 · NDA',
};

/// 속성에 `kind` 가 없을 때와 플레이그라운드를 처음 열 때의 kind. 외곽선과
/// 마커 점을 함께 보여 주는 값이다.
const CoreDisclosureKind _initialKind = CoreDisclosureKind.commitment;

/// 속성의 `kind`.
CoreDisclosureKind disclosureBadgeKind(Map<String, String> props) =>
    previewEnum(CoreDisclosureKind.values, props['kind'], _initialKind);

/// 플레이그라운드의 모양 컨트롤이 만드는 스타일. 켠 것이 없으면 `null`.
CoreDisclosureBadgeStyle? disclosureBadgePlaygroundStyle(Map<String, String> props) {
  final thickBorder = previewFlag(props, 'thickBorder');
  final largeLabel = previewFlag(props, 'largeLabel');
  if (!thickBorder && !largeLabel) return null;
  return CoreDisclosureBadgeStyle(
    borderWidth: thickBorder ? CoreStrokeWidth.stroke2 : null,
    labelStyle: largeLabel ? const CoreTextStyle.token(CoreTextStyles.labelLarge) : null,
  );
}

/// 세 kind 의 색을 하나로 맞춘 스타일 — "이렇게 하지 마세요" 장면이 두
/// 플랫폼에서 함께 읽는다.
const CoreDisclosureBadgeStyle disclosureBadgeOneColorStyle = CoreDisclosureBadgeStyle(
  foregroundColor: CoreColor.token(CoreColors.onSurface),
  borderColor: CoreColor.token(CoreColors.outline),
);

/// 목록 배치 장면의 항목 이름과 kind — 두 플랫폼 장면이 함께 읽는다.
const List<(String, CoreDisclosureKind)> disclosureBadgeRows = [
  ('브랜드 개편 사례', CoreDisclosureKind.open),
  ('물류 시스템 구축 사례', CoreDisclosureKind.commitment),
  ('보안 진단 사례', CoreDisclosureKind.private),
];

// 선택지는 enum 에서 읽는다 — kind 가 늘면 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'kind': _initialKind.name},
  controls: [
    DocsPlaygroundChoice(
      label: 'kind',
      prop: 'kind',
      options: [for (final kind in CoreDisclosureKind.values) kind.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '굵은 외곽선', on: {'thickBorder': 'true'}),
    const DocsPlaygroundFlag(label: '큰 라벨 글자', on: {'largeLabel': 'true'}),
  ],
  code: _disclosureBadgeCode,
);

/// 속성 → 코드. 두 플랫폼의 생성자가 같아 코드도 하나다. 켜지 않은 모양
/// 값은 적지 않는다.
String _disclosureBadgeCode(Map<String, String> props, String? label) {
  final kind = disclosureBadgeKind(props);
  final thickBorder = previewFlag(props, 'thickBorder');
  final largeLabel = previewFlag(props, 'largeLabel');
  final lines = [
    'kind: CoreDisclosureKind.${kind.name},',
    "label: '${label ?? disclosureBadgeSampleLabels[kind]!}',",
    if (thickBorder || largeLabel) ...[
      'disclosureBadgeStyle: CoreDisclosureBadgeStyle(',
      if (thickBorder) '  borderWidth: CoreStrokeWidth.stroke2,',
      if (largeLabel) '  labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),',
      '),',
    ],
  ];
  return 'DisclosureBadge(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
