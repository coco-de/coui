/// Diff 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `diff_web.dart` · `diff_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 비교하는 그림은 내려받지 않고 색 토큰으로 칠한 풍경이다. 속성은 넷이다:
/// `aspectRatio`(프레임 비율), `initialPosition`(시작 위치), `labels`(이름표),
/// `interactive`(분할선 조작).
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/diff.md`.
const String slug = 'diff';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Diff 는 크기 단계(`CoreComponentSize`)가 없고 폭과 `aspectRatio` 로 크기가
/// 정해진다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 풍경 비교의 접근성 이름.
const String diffSceneName = '보정 전과 보정 후 풍경 비교';

/// 왼쪽(`before`) 이름표.
const String diffBeforeText = '전';

/// 오른쪽(`after`) 이름표.
const String diffAfterText = '후';

/// 이름표가 길 때의 예 — 두 이름표가 콘텐츠를 가리고 서로 겹친다.
const String diffLongBeforeText = '보정하기 전의 원본 풍경 사진';

/// 이름표가 길 때의 예 — 오른쪽.
const String diffLongAfterText = '색을 보정한 뒤의 결과 사진';

/// 글자 비교의 접근성 이름.
const String diffTextSceneName = '채운 배경과 표면 배경 글자 비교';

/// 글자 비교의 두 면에 똑같이 적는 글.
const String diffTextSample = 'CoUI';

/// 비율 선택지 → (`aspectRatio` 값, 코드에 적는 글).
const Map<String, (double, String)> diffAspectRatioChoices = {
  _defaultRatioKey: (CoreDiffStyle.defaultAspectRatio, '16 / 9'),
  '4:3': (4 / 3, '4 / 3'),
  '1:1': (1.0, '1'),
};

const String _defaultRatioKey = '16:9';

/// 속성의 `aspectRatio` → 비율 선택지 이름. 모르는 값은 기본 비율.
String diffPreviewRatioKey(Map<String, String> props) {
  final key = props['aspectRatio'];
  return key != null && diffAspectRatioChoices.containsKey(key) ? key : _defaultRatioKey;
}

/// 속성의 `aspectRatio` → 프레임 비율(폭 ÷ 높이).
double diffPreviewAspectRatio(Map<String, String> props) => diffAspectRatioChoices[diffPreviewRatioKey(props)]!.$1;

/// 속성의 `initialPosition` → 시작 위치. 없거나 0~1 밖이면 기본값.
double diffPreviewInitialPosition(Map<String, String> props) {
  final position = double.tryParse(props['initialPosition'] ?? '');
  return position != null && position >= 0 && position <= 1 ? position : CoreDiffStyle.defaultInitialPosition;
}

/// 속성의 `labels` → 두 이름표를 그리는가.
bool diffPreviewLabels(Map<String, String> props) => previewFlag(props, 'labels');

/// 속성의 `interactive` → 분할선을 옮길 수 있는가.
bool diffPreviewInteractive(Map<String, String> props) => previewFlag(props, 'interactive', fallback: true);

/// 인스턴스 하나를 바꾸는 예 — 두 플랫폼 장면이 함께 읽는다.
const CoreDiffStyle diffThemeDemoStyle = CoreDiffStyle(
  aspectRatio: 4 / 3,
  resizerColor: CoreColor.token(CoreColors.primary),
  resizerWidth: CoreStrokeWidth.stroke4,
  handleSize: CoreSpace.space48,
  handleHitSize: CoreSpace.space56,
);

/// 풍경 그림의 원 하나. 왼쪽 · 지름은 프레임 폭, 위쪽은 프레임 높이에 대한
/// 비율이다. 색은 보정 뒤(`vivid`)와 보정 전(`muted`)의 토큰이다.
typedef DiffLandscapeDisc = ({double left, double top, double size, CoreColorToken vivid, CoreColorToken muted});

/// 보정 뒤 하늘색.
const CoreColorToken diffSkyVivid = CoreColors.infoContainer;

/// 보정 전 하늘색.
const CoreColorToken diffSkyMuted = CoreColors.surfaceContainer;

/// 해 하나와 언덕 둘 — 뒤에 있는 것부터.
const List<DiffLandscapeDisc> diffLandscapeDiscs = [
  (left: 0.42, top: 0.12, size: 0.16, vivid: CoreColors.warning, muted: CoreColors.outlineVariant),
  (left: -0.42, top: 0.55, size: 1.6, vivid: CoreColors.info, muted: CoreColors.outlineVariant),
  (left: 0.15, top: 0.72, size: 1.3, vivid: CoreColors.success, muted: CoreColors.outline),
];

/// 관련 컴포넌트의 CodeDiff 그림에 넣는 두 줄.
const List<CoreCodeDiffLine> diffRelatedCodeLines = [
  CoreCodeDiffLine(text: 'final ratio = 16 / 9;', type: CoreCodeDiffLineType.removed),
  CoreCodeDiffLine(text: 'final ratio = 4 / 3;', type: CoreCodeDiffLineType.added),
];

// `initialPosition` 선택지는 글자 그대로 코드에 적는 값이다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: const {'aspectRatio': _defaultRatioKey, 'initialPosition': '0.5', 'labels': 'true'},
  controls: [
    DocsPlaygroundChoice(
      label: 'aspectRatio',
      prop: 'aspectRatio',
      options: [...diffAspectRatioChoices.keys],
      segmented: true,
    ),
    const DocsPlaygroundChoice(
      label: 'initialPosition',
      prop: 'initialPosition',
      options: ['0.25', '0.5', '0.75'],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '이름표', on: {'labels': 'true'}),
    const DocsPlaygroundFlag(label: '조작 끄기', on: {'interactive': 'false'}),
  ],
  code: _diffCode,
);

/// 속성 → 코드. 두 플랫폼의 코드가 같다. 기본값과 같은 값은 적지 않는다.
String _diffCode(Map<String, String> props, String? label) {
  final ratio = diffPreviewRatioKey(props);
  final position = diffPreviewInitialPosition(props);
  final style = [
    if (ratio != _defaultRatioKey) 'aspectRatio: ${diffAspectRatioChoices[ratio]!.$2},',
    if (position != CoreDiffStyle.defaultInitialPosition) 'initialPosition: $position,',
  ];
  final lines = [
    "ariaLabel: '$diffSceneName',",
    if (diffPreviewLabels(props)) ...[
      "beforeLabel: Text('$diffBeforeText'),",
      "afterLabel: Text('$diffAfterText'),",
    ],
    'before: originalPhoto,',
    'after: editedPhoto,',
    if (!diffPreviewInteractive(props)) 'interactive: false,',
    if (style.isNotEmpty) ...[
      'diffStyle: CoreDiffStyle(',
      for (final line in style) '  $line',
      '),',
    ],
  ];
  return 'Diff(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
