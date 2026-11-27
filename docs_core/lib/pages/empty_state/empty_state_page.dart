/// EmptyState 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `empty_state_web.dart` · `empty_state_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/empty-state.md`.
const String slug = 'empty-state';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. EmptyState 는 `CoreComponentSize` 축이 없다 — 자리에 맞는 크기는
/// `variant`(밀도)가 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기에 넣는 예시 한 벌 — 아이콘(과 코드에 적는 이름), 글, 버튼.
typedef EmptyStatePreviewSample = ({
  IconName icon,
  String iconName,
  String title,
  String description,
  String action,
  String callback,
});

/// 톤에 맞는 예시. 컴포넌트는 톤으로 아이콘이나 글을 고르지 않으므로, 두
/// 플랫폼의 속성 빌더와 플레이그라운드 코드가 여기서 함께 읽는다.
EmptyStatePreviewSample emptyStatePreviewSample(CoreEmptyStateTone tone) => switch (tone) {
  CoreEmptyStateTone.neutral => (
    icon: LucideIcons.search,
    iconName: 'search',
    title: '검색 결과가 없어요',
    description: '검색어나 필터를 바꿔 보세요.',
    action: '필터 초기화',
    callback: 'resetFilters',
  ),
  CoreEmptyStateTone.failure => (
    icon: LucideIcons.circleAlert,
    iconName: 'circleAlert',
    title: '결과를 불러오지 못했어요',
    description: '연결을 확인하고 다시 시도해 주세요.',
    action: '다시 시도',
    callback: 'retry',
  ),
  CoreEmptyStateTone.success => (
    icon: LucideIcons.circleCheck,
    iconName: 'circleCheck',
    title: '모두 끝났어요',
    description: '남은 작업이 없어요.',
    action: '완료 기록 보기',
    callback: 'showHistory',
  ),
};

/// 톤 비교 장면의 제목 — 두 플랫폼 장면이 함께 읽는다.
const Map<CoreEmptyStateTone, String> emptyStateToneTitles = {
  CoreEmptyStateTone.neutral: '아직 없어요',
  CoreEmptyStateTone.failure: '불러오지 못했어요',
  CoreEmptyStateTone.success: '모두 끝났어요',
};

/// 인스턴스 하나를 바꾸는 예시 — 본문의 "저장한 필터" 코드와 같은 값이다.
const CoreEmptyStateStyle emptyStateDemoStyle = CoreEmptyStateStyle(
  minHeight: 0,
  iconBoxBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
  iconBoxColor: CoreColor.token(CoreColors.primaryContainer),
  iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.onPrimaryContainer)),
);

// 선택지는 enum 에서 읽는다 — 밀도나 톤이 늘면 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'variant': CoreEmptyStateVariant.defaultVariant.name,
    'tone': CoreEmptyStateTone.defaultTone.name,
    'icon': 'true',
    'description': 'true',
    'action': 'true',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreEmptyStateVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'tone',
      prop: 'tone',
      options: [for (final tone in CoreEmptyStateTone.values) tone.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '아이콘', on: {'icon': 'true'}),
    const DocsPlaygroundFlag(label: '설명', on: {'description': 'true'}),
    const DocsPlaygroundFlag(label: '행동 버튼', on: {'action': 'true'}),
  ],
  code: _emptyStateCode,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다.
String _emptyStateCode(Map<String, String> props, String? label) {
  final variant = previewEnum(CoreEmptyStateVariant.values, props['variant'], CoreEmptyStateVariant.defaultVariant);
  final tone = previewEnum(CoreEmptyStateTone.values, props['tone'], CoreEmptyStateTone.defaultTone);
  final sample = emptyStatePreviewSample(tone);
  final lines = [
    if (variant != CoreEmptyStateVariant.defaultVariant) 'variant: CoreEmptyStateVariant.${variant.name},',
    if (tone != CoreEmptyStateTone.defaultTone) 'tone: CoreEmptyStateTone.${tone.name},',
    if (previewFlag(props, 'icon')) 'icon: Icon(LucideIcons.${sample.iconName}),',
    "title: Text('${label ?? sample.title}'),",
    if (previewFlag(props, 'description')) "description: Text('${sample.description}'),",
    if (previewFlag(props, 'action')) ...[
      'action: Button(',
      '  variant: CoreButtonVariant.outline,',
      '  onPressed: ${sample.callback},',
      "  child: Text('${sample.action}'),",
      '),',
    ],
  ];
  return 'EmptyState(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
