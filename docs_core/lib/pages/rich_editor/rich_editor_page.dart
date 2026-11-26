/// RichEditor 페이지 — 플레이그라운드와 예제 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `rich_editor_web.dart` · `rich_editor_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/rich-editor.md`.
const String slug = 'rich-editor';

/// 빈 편집기의 안내 글.
const String richEditorPreviewPlaceholder = '댓글을 입력해 주세요';

/// 플레이그라운드와 구조 장면의 Markdown. 86자라 `maxLength: 100` 을 켜면
/// 글자 수가 보인다.
const String richEditorPreviewMarkdown =
    '## 리뷰 메모\n\n'
    '**좋아요!** 작은 수정 두 가지만 부탁해요.\n\n'
    '- 툴바 그룹 이름 바꾸기\n'
    '- 빠진 툴팁 추가하기\n\n'
    '> CI가 통과하면 배포해 주세요.';

/// 상태 장면의 짧은 글.
const String richEditorShortMarkdown = '**좋아요!** 바로 반영할게요.';

/// 글자 수 장면의 글 — 36자.
const String richEditorCounterMarkdown = '**짧게 써 주세요.** 알림 미리보기에는 앞의 몇 줄만 보여요.';

/// 툴바 없는 장면의 글.
const String richEditorNoToolbarMarkdown = '툴바가 없어도 **단축키**와 `Markdown` 문법은 그대로 쓸 수 있어요.';

/// 이미지 장면의 글.
const String richEditorImageMarkdown = '## 사진 추가\n\n이미지 버튼을 눌러 파일을 골라 보세요.';

/// 미리보기의 업로드는 파일을 `data:` 주소로 바꿔 Markdown 안에 담으므로
/// 작은 파일만 받는다.
const int richEditorPreviewMaxImageBytes = 1024 * 1024;

/// 플레이그라운드의 툴바 선택지. `comment` 의 이미지 버튼은 이미지를 켜야
/// 보인다.
const Map<String, List<List<CoreRichEditorFormat>>> richEditorPreviewToolbars = {
  'default': CoreRichEditorFormat.defaultToolbar,
  'comment': [
    [CoreRichEditorFormat.bold, CoreRichEditorFormat.italic, CoreRichEditorFormat.link],
    [CoreRichEditorFormat.bulletedList, CoreRichEditorFormat.image],
  ],
};

/// 구조 장면의 툴바 — 번호를 붙일 자리가 남도록 두 묶음만 둔다.
const List<List<CoreRichEditorFormat>> richEditorAnatomyToolbar = [
  [CoreRichEditorFormat.blockType],
  [
    CoreRichEditorFormat.bold,
    CoreRichEditorFormat.italic,
    CoreRichEditorFormat.strikethrough,
    CoreRichEditorFormat.code,
    CoreRichEditorFormat.link,
  ],
];

/// 좁은 카드 장면의 툴바 — 한 줄에 들어간다.
const List<List<CoreRichEditorFormat>> richEditorNarrowToolbar = [
  [CoreRichEditorFormat.bold, CoreRichEditorFormat.italic, CoreRichEditorFormat.link],
];

/// 상태 장면의 툴바.
const List<List<CoreRichEditorFormat>> richEditorStateToolbar = [
  [CoreRichEditorFormat.bold, CoreRichEditorFormat.italic, CoreRichEditorFormat.link],
  [CoreRichEditorFormat.bulletedList],
];

/// 제목을 블록 형식 메뉴 대신 버튼으로 둔 툴바.
const List<List<CoreRichEditorFormat>> richEditorHeadingToolbar = [
  [CoreRichEditorFormat.heading1, CoreRichEditorFormat.heading2, CoreRichEditorFormat.heading3],
  [CoreRichEditorFormat.bold, CoreRichEditorFormat.italic, CoreRichEditorFormat.link],
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'toolbar': 'default'},
  controls: [
    DocsPlaygroundChoice(label: 'toolbar', prop: 'toolbar', options: ['default', 'comment'], segmented: true),
    DocsPlaygroundFlag(label: '툴바 숨기기', on: {'showToolbar': 'false'}),
    DocsPlaygroundFlag(label: '선택 툴바 끄기', on: {'showSelectionToolbar': 'false'}),
    DocsPlaygroundFlag(label: '이미지 버튼', on: {'images': 'true'}),
    DocsPlaygroundFlag(label: '글자 수 제한', on: {'maxLength': '100'}),
    DocsPlaygroundFlag(label: '빈 편집기', on: {'empty': 'true'}),
    DocsPlaygroundFlag(label: '읽기 전용', on: {'readOnly': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _richEditorCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

String _richEditorCode(Map<String, String> props, String? label) {
  final lines = [
    "placeholder: '$richEditorPreviewPlaceholder',",
    if (!previewFlag(props, 'empty')) 'initialValue: draft,',
    if (props['toolbar'] == 'comment') 'toolbar: const [[.bold, .italic, .link], [.bulletedList, .image]],',
    if (!previewFlag(props, 'showToolbar', fallback: true)) 'showToolbar: false,',
    if (!previewFlag(props, 'showSelectionToolbar', fallback: true)) 'showSelectionToolbar: false,',
    if (props['maxLength'] case final max?) 'maxLength: $max,',
    if (previewFlag(props, 'readOnly')) 'readOnly: true,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: saveDraft,',
    'onSubmit: post,',
    if (previewFlag(props, 'images')) ...['onImageUpload: uploadImage,', 'onImageDelete: deleteImage,'],
  ];
  return 'RichEditor(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
