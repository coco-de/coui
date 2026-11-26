/// FileInput 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="file-input/...">` 가 읽는다. 같은 이름의 Web 파일(`file_input_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 파일 선택 창은 운영체제의 것이라 그리지 않는다. 미리보기는
/// `onFilesSelected` 를 주지 않는다 — 무대에서 파일을 골라도 목록은 속성의
/// 예시 이름 그대로다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'file_input_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _fileInput;

/// 장면 이름(`file-input/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  // 구조 — 안내문과 선택한 파일 목록까지 모든 부분이 보이는 영역.
  'file-input/anatomy': () => _sized(
    const FileInput(hint: page.fileInputSceneHint, selectedFiles: page.fileInputSceneFiles),
  ),
  'file-input/states': _fileInputStates,
};

/// 무대의 폭 — Web 장면과 같은 [page.fileInputSceneWidth].
Widget _sized(Widget child) => SizedBox(width: page.fileInputSceneWidth, child: child);

Widget _fileInput(Map<String, String> props, String? label) => _sized(
  FileInput(
    accept: page.fileInputPreviewAccept(props),
    multiple: previewFlag(props, 'multiple'),
    allowDirectory: previewFlag(props, 'allowDirectory'),
    enabled: previewFlag(props, 'enabled', fallback: true),
    label: props['label'] ?? label,
    hint: props['hint'],
    selectedFiles: page.fileInputPreviewFiles(props),
  ),
);

/// 상태 칸 — Web 과 같은 네 칸.
Widget _fileInputStates() => docsFlutterDemoRow([
  for (final state in page.fileInputSceneStates)
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpace.space8,
      children: [
        Text(state.label).labelSmall.onSurfaceVariant,
        _sized(
          FileInput(
            enabled: state.enabled,
            hint: page.fileInputSceneHint,
            fileInputStyle: state.style,
          ),
        ),
      ],
    ),
]);
