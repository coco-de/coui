/// MockupFoldable 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `mockup_foldable_web.dart` · `mockup_foldable_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 위젯 파라미터 이름을 그대로 쓴다(`foldAngle` · `width` ·
/// `showCamera` · `showStatus` · `showGestureBar` · `screenBrightness`).
/// `duration=0` 하나만 스타일 필드다. 두 플랫폼의 속성 빌더와 코드가 같은
/// 뜻으로 읽도록 해석은 이 파일에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/mockup-foldable.md`.
const String slug = 'mockup-foldable';

/// 구조 그림의 폭 — 390px 화면에서도 번호가 무대 안에 놓이게 양옆을 비운다.
const double mockupFoldableAnatomyWidth = 264;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// MockupFoldable 의 크기는 크기 단계가 아니라 너비(`width`) 하나다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 화면 안의 장면이 읽은 접힘을 두 낱말로 — (자세, 화면의 칸). 커버 화면에는
/// 접힘이 없어 자세가 `null` 이다. 두 플랫폼 장면이 함께 읽는다.
(String, String) mockupFoldableReadout(CoreFoldPosture? posture) => switch (posture) {
  CoreFoldPosture.book => ('반접힘', '두 칸'),
  CoreFoldPosture.flat => ('펼침', '한 칸'),
  _ => ('커버', '접힘 없음'),
};

/// 속성의 `foldAngle` → 각도. 없거나 숫자가 아니면 위젯의 기본값.
double mockupFoldablePreviewAngle(Map<String, String> props) =>
    double.tryParse(props['foldAngle'] ?? '') ?? CoreMockupFoldableContract.defaultFoldAngle;

/// 속성의 `width` → 펼친 본체의 너비. 없으면 `null`(위젯의 기본 너비).
double? mockupFoldablePreviewWidth(Map<String, String> props) => double.tryParse(props['width'] ?? '');

/// 속성의 `screenBrightness` → 화면의 밝기. 없으면 `null`(페이지의 밝기).
CoreBrightness? mockupFoldablePreviewBrightness(Map<String, String> props) {
  for (final brightness in CoreBrightness.values) {
    if (brightness.name == props['screenBrightness']) return brightness;
  }
  return null;
}

/// 속성의 `duration=0` → 각도를 바로 따라가는 스타일. 그 밖에는 `null`.
CoreMockupFoldableStyle? mockupFoldablePreviewStyle(Map<String, String> props) =>
    props['duration'] == '0' ? const CoreMockupFoldableStyle(duration: Duration.zero) : null;

/// 플레이그라운드에서 고르는 각도 — 이름 있는 각도와 경계, 그리고 그 사이의 90°.
const List<double> _angles = [
  CoreMockupFold.closed,
  CoreMockupFold.coverUntil,
  90,
  CoreMockupFold.halfOpen,
  CoreMockupFold.flatFrom,
  CoreMockupFold.flat,
];

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'foldAngle': docsSizeNumber(CoreMockupFold.halfOpen), 'width': '240'},
  controls: [
    DocsPlaygroundChoice(
      label: 'foldAngle',
      prop: 'foldAngle',
      options: [for (final angle in _angles) docsSizeNumber(angle)],
    ),
    const DocsPlaygroundChoice(label: 'width', prop: 'width', options: ['240', '280', '320'], segmented: true),
    const DocsPlaygroundFlag(label: '커버 카메라 숨기기', on: {'showCamera': 'false'}),
    const DocsPlaygroundFlag(label: '상태 표시 숨기기', on: {'showStatus': 'false'}),
    const DocsPlaygroundFlag(label: '홈 제스처 바', on: {'showGestureBar': 'true'}),
    DocsPlaygroundFlag(label: '화면만 어둡게', on: {'screenBrightness': CoreBrightness.dark.name}),
    const DocsPlaygroundFlag(label: '움직임 없이 바로 바꾸기', on: {'duration': '0'}),
  ],
  code: _code,
);

/// 각도를 코드로 — 이름 있는 각도와 경계는 상수 이름으로 적는다.
String _angleCode(double angle) => switch (angle) {
  CoreMockupFold.closed => 'CoreMockupFold.closed',
  CoreMockupFold.coverUntil => 'CoreMockupFold.coverUntil',
  CoreMockupFold.halfOpen => 'CoreMockupFold.halfOpen',
  CoreMockupFold.flatFrom => 'CoreMockupFold.flatFrom',
  _ => docsSizeNumber(angle),
};

/// 속성 → 코드. 기본값과 같은 파라미터는 적지 않는다. `AppScreen` 은 화면에
/// 놓을 여러분의 위젯 자리다.
String _code(Map<String, String> props, String? label) {
  final angle = mockupFoldablePreviewAngle(props);
  final width = mockupFoldablePreviewWidth(props);
  final brightness = mockupFoldablePreviewBrightness(props);
  final lines = [
    if (angle != CoreMockupFoldableContract.defaultFoldAngle) 'foldAngle: ${_angleCode(angle)},',
    if (width != null && width != CoreMockupFoldableStyle.defaultWidth) 'width: ${docsSizeNumber(width)},',
    if (!previewFlag(props, 'showCamera', fallback: CoreMockupFoldableContract.defaultShowCamera)) 'showCamera: false,',
    if (!previewFlag(props, 'showStatus', fallback: CoreMockupFoldableContract.defaultShowStatus)) 'showStatus: false,',
    if (previewFlag(props, 'showGestureBar')) 'showGestureBar: true,',
    if (brightness != null) 'screenBrightness: CoreBrightness.${brightness.name},',
    if (mockupFoldablePreviewStyle(props) != null)
      'mockupFoldableStyle: CoreMockupFoldableStyle(duration: Duration.zero),',
    'child: AppScreen(),',
  ];
  return 'MockupFoldable(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
