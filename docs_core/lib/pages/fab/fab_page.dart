/// FAB 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `fab_web.dart` · `fab_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/fab.md`.
const String slug = 'fab';

/// Extended 형태의 라벨.
const String fabPreviewLabel = '새 메모';

/// `tooltip` 을 켰을 때의 문구.
const String fabPreviewTooltip = '새 메모 작성';

/// 메뉴 형태의 액션 하나 — 아이콘 · 코드에 적는 아이콘 이름 · 라벨 · 핸들러 이름.
typedef FabPreviewAction = ({IconName icon, String iconCode, String label, String handler});

/// 메뉴 형태의 액션.
const List<FabPreviewAction> fabPreviewActions = [
  (icon: LucideIcons.pencil, iconCode: 'pencil', label: '편집', handler: 'handleEdit'),
  (icon: LucideIcons.share, iconCode: 'share', label: '공유', handler: 'handleShare'),
];

/// 상태 장면의 칸 이름 — 두 플랫폼이 같은 순서로 그린다.
const List<String> fabStateCaptions = ['기본', 'Hover', 'Pressed', 'Focus', '비활성', '열림'];

/// 크기 표 · 속성 문자열의 크기 이름 → Fab 의 크기. 모르는 이름이면 기본값.
CoreFabSize fabPreviewSize(String? name) {
  for (final size in CoreFabSize.values) {
    if (_specSize(size).name == name) return size;
  }
  return CoreFabSize.defaultSize;
}

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 형태는 위젯 속성이 아니라 문서의 손잡이다 — `label` 과 `actions` 를 함께
/// 줄 수 없으므로 원형 · Extended · 메뉴 셋 중 하나를 고르게 한다. 크기
/// 선택지는 크기 표의 행 이름이고 [fabPreviewSize] 가 Fab 의 크기로 옮긴다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'form': 'menu', 'size': 'md', 'expandDirection': 'up'},
  label: fabPreviewLabel,
  controls: [
    DocsPlaygroundChoice(label: '형태', prop: 'form', options: ['circle', 'extended', 'menu'], segmented: true),
    DocsPlaygroundChoice(
      label: 'size (mini · regular · large)',
      prop: 'size',
      options: ['sm', 'md', 'lg'],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'expandDirection (menu)',
      prop: 'expandDirection',
      options: ['up', 'down', 'left', 'right'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: 'tooltip', on: {'tooltip': fabPreviewTooltip}),
  ],
  code: _fabCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// 원형의 지름 · 아이콘과 Extended 의 여백 · 간격은 `CoreFabStyle` 의 크기
/// 행에서, Extended 의 아이콘 · 라벨은 그 크기가 고르는 Button 행에서 읽는다.
DocsSizeSpec Function()? get sizeSpec => _fabSpec;

CoreComponentSize _specSize(CoreFabSize size) => switch (size) {
  CoreFabSize.mini => CoreComponentSize.sm,
  CoreFabSize.regular => CoreComponentSize.md,
  CoreFabSize.large => CoreComponentSize.lg,
};

String _fabCode(Map<String, String> props, String? label) {
  final form = props['form'] ?? 'circle';
  final size = fabPreviewSize(props['size']);
  final direction = previewEnum(
    CoreFabExpandDirection.values,
    props['expandDirection'],
    CoreFabExpandDirection.defaultDirection,
  );
  final tooltip = props['tooltip'];
  final lines = [
    'trigger: const Icon(LucideIcons.plus),',
    if (form == 'extended') "label: const Text('${label ?? fabPreviewLabel}'),",
    if (size != CoreFabSize.defaultSize) 'size: CoreFabSize.${size.name},',
    if (tooltip != null) "tooltip: '$tooltip',",
    if (form == 'menu') ...[
      if (direction != CoreFabExpandDirection.defaultDirection)
        'expandDirection: CoreFabExpandDirection.${direction.name},',
      'actions: [',
      for (final action in fabPreviewActions) ...[
        '  FabAction(',
        '    icon: const Icon(LucideIcons.${action.iconCode}),',
        "    label: const Text('${action.label}'),",
        '    onPressed: ${action.handler},',
        '  ),',
      ],
      '],',
    ] else
      'onPressed: handleCreate,',
  ];
  return 'Fab(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _fabSpec() {
  return DocsSizeSpec(
    columns: const ['size', 'CoreFabSize', '원형 지름 · 아이콘', 'Extended 좌우 여백 · 아이콘 간격', 'Extended 아이콘 · 라벨'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreFabStyle.defaultsBySize.entries)
        if (CoreButtonStyle.defaultsBySize[size.toExtendedButtonSize()] case final button?)
          DocsSizeSpecRow(
            size: _specSize(size),
            cells: [
              size.name,
              '${docsSizeNumber(row.diameter)} · ${docsSizeNumber(row.iconStyle?.size)}',
              '${docsSizeNumber(row.extendedButtonStyle?.padding?.left)} · '
                  '${docsSizeNumber(row.extendedButtonStyle?.iconLabelGapStyle?.size)}',
              '${docsSizeNumber(button.leadingIconStyle?.size)} · ${docsSizeLabel(button.labelStyle)}',
            ],
          ),
    ],
  );
}
