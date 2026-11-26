/// FileInput 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="file-input/...">` 가 읽는다. 같은 이름의 Flutter 파일(`file_input_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 파일 선택 창은 브라우저의 것이라 그리지 않는다. 미리보기는
/// `onFilesSelected` 를 주지 않는다 — 무대에서 파일을 골라도 목록은 속성의
/// 예시 이름 그대로다. 폭은 감싸는 상자가 아니라 FileInput 자신에 준다
/// (`css`) — 구조 그림의 바깥 틀이 드롭 영역이어야 해서다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'file_input_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _fileInput;

/// 장면 이름(`file-input/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 안내문과 선택한 파일 목록까지 모든 부분이 보이는 영역.
  'file-input/anatomy': () => FileInput(
    hint: page.fileInputSceneHint,
    selectedFiles: page.fileInputSceneFiles,
    css: _width(),
  ),
  'file-input/states': _fileInputStates,
};

/// 무대의 폭 — [page.fileInputSceneWidth] 와 같은 길이.
Styles _width() => Styles(raw: {'width': page.fileInputSceneWidthCss});

Component _fileInput(Map<String, String> props, String? label) => FileInput(
  accept: page.fileInputPreviewAccept(props),
  multiple: previewFlag(props, 'multiple'),
  allowDirectory: previewFlag(props, 'allowDirectory'),
  enabled: previewFlag(props, 'enabled', fallback: true),
  label: props['label'] ?? label,
  hint: props['hint'],
  selectedFiles: page.fileInputPreviewFiles(props),
  css: _width(),
);

/// 상태 칸 — 쉴 때 · Hover · 드래그 중 · 비활성. Hover 와 드래그 중은 그 상태의
/// 색을 고정한 그림이다([page.fileInputSceneStates]).
Component _fileInputStates() => docsWebDemoRow([
  for (final state in page.fileInputSceneStates)
    div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'flex-direction': 'column',
          'align-items': 'flex-start',
          'gap': spaceCss(CoreSpace.space8),
        },
      ),
      [
        span([Text(state.label).labelSmall.onSurfaceVariant]),
        FileInput(
          enabled: state.enabled,
          hint: page.fileInputSceneHint,
          fileInputStyle: state.style,
          css: _width(),
        ),
      ],
    ),
]);
