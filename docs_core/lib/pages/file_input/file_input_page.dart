/// FileInput 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `file_input_web.dart` · `file_input_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 파일 선택 창은 운영체제(Web 은 브라우저)의 것이라 미리보기가 그리지 않는다.
/// 미리보기의 파일 목록은 속성 `selectedFiles`(쉼표로 나눈 이름)가 넘긴 예시
/// 이름이고, 미리보기는 `onFilesSelected` 를 주지 않는다 — 무대에서 파일을
/// 골라도 목록은 바뀌지 않는다. 두 플랫폼 빌더와 코드가 같은 뜻으로 읽도록
/// 목록 속성의 해석은 이 파일의 [fileInputPreviewFiles] ·
/// [fileInputPreviewAccept] 한 곳에 둔다.
///
/// FileInput 에는 variant 와 크기 단계(`defaultsBySize`)가 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/file-input.md`.
const String slug = 'file-input';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 컨트롤은 모두 켜고 끄는 것이다 — FileInput 에는 고를 enum 축이 없다.
/// 처음 값은 안내문 · 선택한 파일 · PNG · JPG 만 · 여러 파일을 켠 영역이다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {
    'accept': fileInputSceneAccept,
    'multiple': 'true',
    'hint': fileInputSceneHint,
    'selectedFiles': fileInputSceneFilesProp,
  },
  controls: [
    DocsPlaygroundFlag(label: '안내문', on: {'hint': fileInputSceneHint}),
    DocsPlaygroundFlag(label: '선택한 파일', on: {'selectedFiles': fileInputSceneFilesProp}),
    DocsPlaygroundFlag(label: 'PNG · JPG 만', on: {'accept': fileInputSceneAccept}),
    DocsPlaygroundFlag(label: '여러 파일', on: {'multiple': 'true'}),
    DocsPlaygroundFlag(label: '폴더 버튼', on: {'allowDirectory': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _fileInputCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// FileInput 의 Core 스타일에는 `defaultsBySize` 가 없다 — 크기 단계가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 무대의 FileInput 폭(logical px) — 두 플랫폼 장면이 같은 폭으로 그린다.
const double fileInputSceneWidth = 280;

/// [fileInputSceneWidth] 의 CSS 길이(`280 / 16`).
const String fileInputSceneWidthCss = '17.5rem';

/// 미리보기의 안내문 — 두 플랫폼 장면과 플레이그라운드가 함께 쓴다.
const String fileInputSceneHint = 'PNG, JPG · 최대 10MB';

/// 미리보기의 허용 형식 — 속성 문자열(쉼표로 나눈 항목).
///
/// 확장자로 적는다. Flutter 는 받은 파일에 MIME 정보가 없어 `image/*` 같은
/// 와일드카드만으로는 파일을 맞추지 못한다(페이지의 "허용 형식" 참조).
const String fileInputSceneAccept = '.png,.jpg';

/// 미리보기의 선택한 파일 — 속성 문자열(쉼표로 나눈 이름).
const String fileInputSceneFilesProp = '로고.png,배너.jpg';

/// [fileInputSceneFilesProp] 의 목록 — 두 플랫폼 장면이 함께 쓴다.
const List<String> fileInputSceneFiles = ['로고.png', '배너.jpg'];

/// `file-input/states` 장면의 칸 하나 — 두 플랫폼 장면이 함께 읽는다.
typedef FileInputSceneState = ({String label, bool enabled, CoreFileInputStyle? style});

/// `file-input/states` 장면의 칸 — 쉴 때 · Hover · 드래그 중 · 비활성.
///
/// 쉴 때와 비활성은 실제 영역이다. Hover 와 드래그 중은 포인터와 끌어 온 파일이
/// 있어야 생기는 상태라, 그 상태의 색을 Core 기본값에서 읽어
/// `fileInputStyle` 로 고정한 그림이다. 드래그 중의 실선은 점 사이 틈을 0 으로
/// 둔 점선이다 — 컴포넌트는 드래그 중에 같은 굵기의 실선을 그린다. 그림 칸의
/// Hover 색은 그 칸의 테두리 색과 같게 둔다 — 포인터를 올려도 칸이 다른
/// 상태로 바뀌어 보이지 않게.
const List<FileInputSceneState> fileInputSceneStates = [
  (label: '쉴 때', enabled: true, style: null),
  (
    label: 'Hover',
    enabled: true,
    style: CoreFileInputStyle(
      borderColor: CoreFileInputStyle.defaultHoverBorderColor,
      hoverBorderColor: CoreFileInputStyle.defaultHoverBorderColor,
    ),
  ),
  (
    label: '드래그 중',
    enabled: true,
    style: CoreFileInputStyle(
      borderColor: CoreFileInputStyle.defaultDragOverBorderColor,
      hoverBorderColor: CoreFileInputStyle.defaultDragOverBorderColor,
      backgroundColor: CoreFileInputStyle.defaultDragActiveBackgroundColor,
      iconBoxColor: CoreFileInputStyle.defaultDragActiveIconBoxColor,
      subtleIconColor: CoreFileInputStyle.defaultDragActiveIconColor,
      dashSpacing: 0,
    ),
  ),
  (label: '비활성', enabled: false, style: null),
];

/// 속성의 `selectedFiles` → 파일 이름 목록. 없거나 비면 `null`.
List<String>? fileInputPreviewFiles(Map<String, String> props) => _list(props['selectedFiles']);

/// 속성의 `accept` → 허용 형식 목록. 없거나 비면 `null`.
List<String>? fileInputPreviewAccept(Map<String, String> props) => _list(props['accept']);

/// 쉼표로 나눈 속성 값 → 목록. 빈 조각은 버린다.
List<String>? _list(String? raw) {
  if (raw == null) return null;
  final items = [
    for (final piece in raw.split(','))
      if (piece.trim() case final item when item.isNotEmpty) item,
  ];
  return items.isEmpty ? null : items;
}

String _fileInputCode(Map<String, String> props, String? label) {
  String quotedList(List<String> items) => '[${items.map((item) => "'$item'").join(', ')}]';
  final accept = fileInputPreviewAccept(props);
  final files = fileInputPreviewFiles(props);
  final lines = [
    'onFilesSelected: handleFiles,',
    if (accept != null) 'accept: ${quotedList(accept)},',
    if (previewFlag(props, 'multiple')) 'multiple: true,',
    if (previewFlag(props, 'allowDirectory')) 'allowDirectory: true,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    if (props['label'] case final text?) "label: '$text',",
    if (props['hint'] case final hint?) "hint: '$hint',",
    if (files != null) 'selectedFiles: ${quotedList(files)},',
  ];
  return 'FileInput(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
