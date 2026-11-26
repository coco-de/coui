/// Swiper 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `swiper_web.dart` · `swiper_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자(감싼 영역의 안내 · 패널의 항목 · 버튼)와 그림의 크기는
/// 아래 상수 한 곳에 둔다 — 두 플랫폼의 그림 · 실제 `Swiper` · 플레이그라운드의
/// 코드가 같은 글자를 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/swiper.md`.
const String slug = 'swiper';

/// 패널의 첫째 항목.
const String demoFirstItem = '대시보드';

/// 패널의 둘째 항목.
const String demoSecondItem = '설정';

/// 패널 안의 닫기 버튼.
const String demoClose = '닫기';

/// 감싼 영역의 여는 버튼.
const String demoOpen = '메뉴 열기';

/// 감싼 영역의 폭(logical px).
const double demoAreaWidth = CoreLayout.layout240;

/// 그림 속 화면의 폭(logical px).
const double demoScreenWidth = CoreLayout.layout320;

/// 그림 속 화면의 높이(logical px). `top` · `bottom` 패널이 감싼 영역을 가리지
/// 않는 값이다.
const double demoScreenHeight = CoreLayout.layout280;

/// 플레이그라운드 그림의 화면 높이(logical px). 그림과 실제 `Swiper` 가 Flutter
/// 임베드(높이 400)에 함께 들어가는 값이라, `top` · `bottom` 에서는 패널이 감싼
/// 영역의 가장자리를 조금 덮는다.
const double demoPlaygroundScreenHeight = CoreSpace.space256;

/// 그림 속 좌우 패널의 폭(logical px). 작은 화면 그림에 들어가도록 줄인 값이고,
/// 실제 패널은 `CoreDrawerStyle.defaultPanelWidth` 를 쓴다.
const double demoPanelWidth = CoreLayout.layout160;

/// 플레이그라운드에서 그림과 실제 `Swiper` 사이의 간격.
const double demoOpenerGap = CoreSpace.space16;

/// 감싼 영역의 안내 — 여는 방향은 패널이 나오는 가장자리의 반대쪽이다.
String demoHint(CoreSwiperPosition position) => switch (position) {
  CoreSwiperPosition.left => '여기를 오른쪽으로 밀어 보세요',
  CoreSwiperPosition.right => '여기를 왼쪽으로 밀어 보세요',
  CoreSwiperPosition.top => '여기를 아래로 밀어 보세요',
  CoreSwiperPosition.bottom => '여기를 위로 밀어 보세요',
};

/// 속성의 `position`. 없거나 모르는 값은 기본값.
CoreSwiperPosition demoPositionOf(Map<String, String> props) =>
    previewEnum(CoreSwiperPosition.values, props['position'], CoreSwiperPosition.defaultPosition);

/// 속성의 `variant`. 없거나 모르는 값은 기본값.
CoreSwiperVariant demoVariantOf(Map<String, String> props) =>
    previewEnum(CoreSwiperVariant.values, props['variant'], CoreSwiperVariant.defaultVariant);

/// 속성의 `showDragHandle`. `false` 일 때만 끈다.
bool demoShowDragHandleOf(Map<String, String> props) => previewFlag(props, 'showDragHandle', fallback: true);

/// 속성의 `enabled`. `false` 일 때만 끈다.
bool demoEnabledOf(Map<String, String> props) => previewFlag(props, 'enabled', fallback: true);

/// 속성의 `barrierDismissible`. `false` 일 때만 끈다.
bool demoBarrierDismissibleOf(Map<String, String> props) => previewFlag(props, 'barrierDismissible', fallback: true);

/// `position` 이 여는 `Drawer` 의 가장자리.
CoreDrawerSide demoSideOf(CoreSwiperPosition position) => switch (position) {
  CoreSwiperPosition.left => CoreDrawerSide.left,
  CoreSwiperPosition.right => CoreDrawerSide.right,
  CoreSwiperPosition.top => CoreDrawerSide.top,
  CoreSwiperPosition.bottom => CoreDrawerSide.bottom,
};

/// 그림의 패널이 쓰는 `CoreDrawerStyle` — `Swiper` 가 `variant` 에 따라
/// `Drawer` 에 주는 기본값에, 그림의 폭을 얹는다.
CoreDrawerStyle demoPictureStyle(CoreSwiperVariant variant) =>
    CoreSwiperStyle.defaultsByVariant[variant]!.merge(const CoreDrawerStyle(panelWidth: demoPanelWidth));

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 그림 아래에
/// 같은 속성의 실제 `Swiper` 를 둔다. 플레이그라운드만 켠다: 사이트의 다른
/// 무대는 브라우저에서 깨어나지 않아 밀거나 눌러도 아무것도 열리지 않는다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'position': 'left', 'variant': 'drawer', 'opener': 'true'},
  controls: [
    DocsPlaygroundChoice(
      label: 'position',
      prop: 'position',
      options: ['left', 'right', 'top', 'bottom'],
      segmented: true,
    ),
    DocsPlaygroundChoice(label: 'variant', prop: 'variant', options: ['drawer', 'sheet'], segmented: true),
    DocsPlaygroundFlag(label: '손잡이 숨기기', on: {'showDragHandle': 'false'}),
    DocsPlaygroundFlag(label: '스와이프 끄기', on: {'enabled': 'false'}),
    DocsPlaygroundFlag(label: '배경막 탭 닫기 끄기', on: {'barrierDismissible': 'false'}),
  ],
  code: _swiperCode,
  webCode: _swiperWebCode,
);

/// 크기 표. Swiper 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _swiperCode(Map<String, String> props, String? label) {
  final position = demoPositionOf(props);
  return [
    ..._headLines(props),
    '  overlayContent: Column(',
    '    mainAxisSize: MainAxisSize.min,',
    '    crossAxisAlignment: CrossAxisAlignment.start,',
    '    spacing: CoreSpace.space8,',
    '    children: [',
    "      Text('$demoFirstItem'),",
    "      Text('$demoSecondItem'),",
    '      Button(',
    '        variant: CoreButtonVariant.outline,',
    '        size: CoreComponentSize.sm,',
    '        onPressed: () => setOpen(false),',
    "        child: Text('$demoClose'),",
    '      ),',
    '    ],',
    '  ),',
    '  child: SizedBox(',
    '    width: CoreLayout.layout240,',
    '    child: Card(',
    '      variant: CoreCardVariant.outlined,',
    '      child: Column(',
    '        mainAxisSize: MainAxisSize.min,',
    '        spacing: CoreSpace.space12,',
    '        children: [',
    "          Text('${demoHint(position)}').bodySmall,",
    '          Button(',
    '            size: CoreComponentSize.sm,',
    '            onPressed: () => setOpen(true),',
    "            child: Text('$demoOpen'),",
    '          ),',
    '        ],',
    '      ),',
    '    ),',
    '  ),',
    ')',
  ].join('\n');
}

String _swiperWebCode(Map<String, String> props, String? label) {
  final position = demoPositionOf(props);
  return [
    ..._headLines(props),
    '  overlayContent: div(',
    r"    classes: 'flex flex-col items-start gap-${CoreSpace.scale.space8}',",
    '    [',
    "      Text('$demoFirstItem'),",
    "      Text('$demoSecondItem'),",
    '      Button(',
    '        variant: CoreButtonVariant.outline,',
    '        size: CoreComponentSize.sm,',
    '        onPressed: () => setOpen(false),',
    "        child: Text('$demoClose'),",
    '      ),',
    '    ],',
    '  ),',
    '  child: Card(',
    '    variant: CoreCardVariant.outlined,',
    "    classes: 'select-none',",
    "    css: Styles(raw: {'width': pinnedLengthCss(CoreLayout.layout240), 'max-width': '100%'}),",
    '    child: div(',
    r"      classes: 'flex flex-col items-center gap-${CoreSpace.scale.space12}',",
    '      [',
    "        Text('${demoHint(position)}').bodySmall,",
    '        Button(',
    '          size: CoreComponentSize.sm,',
    '          onPressed: () => setOpen(true),',
    "          child: Text('$demoOpen'),",
    '        ),',
    '      ],',
    '    ),',
    '  ),',
    ')',
  ].join('\n');
}

/// 두 플랫폼이 같이 쓰는 첫 줄들 — 값을 바꾸는 파라미터만 적는다.
List<String> _headLines(Map<String, String> props) => [
  'Swiper(',
  '  position: CoreSwiperPosition.${demoPositionOf(props).name},',
  if (demoVariantOf(props) != CoreSwiperVariant.defaultVariant)
    '  variant: CoreSwiperVariant.${demoVariantOf(props).name},',
  if (!demoShowDragHandleOf(props)) '  showDragHandle: false,',
  if (!demoEnabledOf(props)) '  enabled: false,',
  if (!demoBarrierDismissibleOf(props)) '  barrierDismissible: false,',
  '  open: isOpen,',
  '  onOpenChanged: setOpen,',
];
