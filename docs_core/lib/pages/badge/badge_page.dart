/// Badge 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `badge_web.dart` · `badge_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/badge.md`.
const String slug = 'badge';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _badgeSpec;

/// 미리보기에 라벨을 주지 않았을 때 배지 안에 넣는 글 — 담는 것(form)에
/// 맞춰 낱말 또는 숫자. 두 플랫폼의 속성 빌더와 플레이그라운드 코드가 같은
/// 글을 쓰도록 한 곳에 둔다.
String badgeSampleText(CoreBadgeForm form, String? label) => label ?? (form == CoreBadgeForm.count ? '12' : '신규');

/// 톤마다 배지에 적는 낱말 — 톤 × 세기 표의 두 플랫폼 장면이 함께 읽는다.
const Map<CoreBadgeTone, String> badgeToneWords = {
  CoreBadgeTone.neutral: '중립',
  CoreBadgeTone.primary: '주요',
  CoreBadgeTone.info: '정보',
  CoreBadgeTone.success: '성공',
  CoreBadgeTone.warning: '경고',
  CoreBadgeTone.destructive: '위험',
};

/// 상태 라벨 장면의 톤과 글 — 두 플랫폼 장면이 함께 읽는다.
const List<(CoreBadgeTone, String)> badgeStatusSamples = [
  (CoreBadgeTone.info, '검토 중'),
  (CoreBadgeTone.success, '승인됨'),
  (CoreBadgeTone.warning, '대기 중'),
  (CoreBadgeTone.destructive, '반려됨'),
  (CoreBadgeTone.neutral, '임시 저장'),
];

/// 값이 정해지는 순서의 단계 — 뒤로 갈수록 우선한다. 두 플랫폼 장면이 함께 읽는다.
const List<String> badgeThemeOrder = [
  '디자인 시스템 기본값',
  '테마 기본값',
  '테마 tone별 값',
  '테마 variant별 값',
  '인스턴스 badgeStyle',
];

// 선택지는 enum 과 크기 행에서 읽는다 — 톤이나 크기 행이 늘면 플레이그라운드도
// 따라온다(Badge 의 enum 값은 전부 공개 값이라 빼 둘 내부용 값이 없다).
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'tone': CoreBadgeTone.info.name,
    'variant': CoreBadgeVariant.defaultVariant.name,
    'form': CoreBadgeForm.defaultForm.name,
    'size': CoreBadgeContract.defaultSize.name,
    'showDot': 'true',
  },
  controls: [
    DocsPlaygroundChoice(label: 'tone', prop: 'tone', options: [for (final tone in CoreBadgeTone.values) tone.name]),
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreBadgeVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'form',
      prop: 'form',
      options: [for (final form in CoreBadgeForm.values) form.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreBadgeStyle.defaultsBySize.keys) size.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '상태 점', on: {'showDot': 'true'}),
    const DocsPlaygroundFlag(label: 'leading 아이콘', on: {'leading': 'star'}),
    const DocsPlaygroundFlag(label: 'trailing 아이콘', on: {'trailing': 'arrow-right'}),
    const DocsPlaygroundFlag(label: '누를 수 있음', on: {'pressable': 'true'}),
  ],
  code: _badgeCode,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않고, 점(dot)에는 그리지 않는 부분
/// (`variant` · `showDot` · 아이콘 · `child`)을 적지 않는다.
String _badgeCode(Map<String, String> props, String? label) {
  final tone = previewEnum(CoreBadgeTone.values, props['tone'], CoreBadgeTone.defaultTone);
  final variant = previewEnum(CoreBadgeVariant.values, props['variant'], CoreBadgeVariant.defaultVariant);
  final form = previewEnum(CoreBadgeForm.values, props['form'], CoreBadgeForm.defaultForm);
  final size = previewEnum(CoreComponentSize.values, props['size'], CoreBadgeContract.defaultSize);
  final isDot = form == CoreBadgeForm.dot;
  final lines = [
    'tone: CoreBadgeTone.${tone.name},',
    if (!isDot && variant != CoreBadgeVariant.defaultVariant) 'variant: CoreBadgeVariant.${variant.name},',
    if (form != CoreBadgeForm.defaultForm) 'form: CoreBadgeForm.${form.name},',
    if (size != CoreBadgeContract.defaultSize) 'size: CoreComponentSize.${size.name},',
    if (!isDot && previewFlag(props, 'showDot')) 'showDot: true,',
    if (!isDot && props['leading'] != null) 'leading: Icon(LucideIcons.${docsIconIdentifier(props['leading']!)}),',
    if (!isDot && props['trailing'] != null) 'trailing: Icon(LucideIcons.${docsIconIdentifier(props['trailing']!)}),',
    if (previewFlag(props, 'pressable')) 'onPressed: showDetails,',
    if (!isDot) "child: Text('${badgeSampleText(form, label)}'),",
  ];
  return 'Badge(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _badgeSpec() {
  return DocsSizeSpec(
    columns: const ['size', '높이 · 좌우 여백', '글자 · label 모서리', '아이콘 · 간격', '점 지름 · 앞 점 지름'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreBadgeStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [
            '${docsSizeNumber(row.minHeight)} · ${docsSizeNumber(row.padding?.left)}',
            '${docsSizeLabel(row.labelStyle)} · ${docsSizeNumber(row.borderRadius?.topLeft)}',
            '${docsSizeNumber(row.iconStyle?.size)} · ${docsSizeNumber(row.iconLabelGapStyle?.size)}',
            '${docsSizeNumber(row.dotSize)} · ${docsSizeNumber(row.leadingDotSize)}',
          ],
        ),
    ],
  );
}
