/// RichEditor 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="rich-editor/...">` 가 읽는다. 같은 이름의 Flutter 파일(`rich_editor_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'dart:convert';

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'rich_editor_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _richEditor;

/// 장면 이름(`rich-editor/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'rich-editor/anatomy': () => _sized(
    const RichEditor(toolbar: page.richEditorAnatomyToolbar, initialValue: page.richEditorPreviewMarkdown),
    width: '22rem',
  ),
  'rich-editor/states': _states,
  'rich-editor/counter': () => _column([
    const RichEditor(showToolbar: false, maxLength: 40, initialValue: page.richEditorCounterMarkdown),
    const RichEditor(showToolbar: false, maxLength: 36, initialValue: page.richEditorCounterMarkdown),
  ]),
  'rich-editor/custom-toolbar': () => _sized(
    const RichEditor(toolbar: page.richEditorHeadingToolbar, initialValue: page.richEditorShortMarkdown),
    width: '24rem',
  ),
  'rich-editor/trailing': () => _sized(
    RichEditor(
      toolbar: page.richEditorStateToolbar,
      initialValue: page.richEditorShortMarkdown,
      toolbarTrailing: Checkbox(label: '바뀐 부분 표시', checked: true, onChanged: (_) {}),
    ),
    width: '24rem',
  ),
  'rich-editor/no-toolbar': () => _sized(
    const RichEditor(showToolbar: false, initialValue: page.richEditorNoToolbarMarkdown),
    width: '22rem',
  ),
  'rich-editor/image': () => _sized(
    const RichEditor(
      placeholder: page.richEditorPreviewPlaceholder,
      initialValue: page.richEditorImageMarkdown,
      maxImageBytes: page.richEditorPreviewMaxImageBytes,
      onImageUpload: _upload,
      onImageDelete: _delete,
    ),
  ),
  'rich-editor/do-few-formats': () => _sized(
    const RichEditor(toolbar: page.richEditorNarrowToolbar, initialValue: page.richEditorShortMarkdown),
    width: '11rem',
  ),
  'rich-editor/dont-plain-field': () => _sized(
    const RichEditor(toolbar: page.richEditorNarrowToolbar, placeholder: '이름을 입력해 주세요'),
    width: '11rem',
  ),
  'rich-editor/related-text-area': () => _sized(const TextArea(rows: 2, placeholder: '내용'), width: '12rem'),
  'rich-editor/related-kbd': () => const Kbd(keys: ['⌘', 'E']),
  'rich-editor/related-tooltip': () => Tooltip(
    message: '굵게',
    child: Button(variant: .outline, size: .sm, onPressed: () {}, child: Icon(LucideIcons.bold)),
  ),
  'rich-editor/related-alert': () => _sized(const Alert.destructive(title: '이미지를 올리지 못했어요'), width: '12rem'),
  'rich-editor/related-popup': () => Popup(
    direction: .horizontal,
    children: [
      for (final icon in [LucideIcons.bold, LucideIcons.italic, LucideIcons.link])
        Button(variant: .ghost, size: .sm, onPressed: () {}, child: Icon(icon)),
    ],
  ),
};

/// 미리보기의 업로드 — 서버 대신 파일을 `data:` 주소로 바꿔 Markdown 안에 담는다.
Future<String> _upload(CoreRichEditorImageFile file) async =>
    'data:${file.mimeType};base64,${base64Encode(file.bytes)}';

/// `data:` 주소는 지울 서버 파일이 없다.
Future<void> _delete(String url) async {}

/// 편집기는 놓인 자리의 폭을 채우므로 장면마다 폭을 정한다.
Component _sized(Component child, {String width = '30rem'}) =>
    div(styles: Styles(raw: {'width': width, 'max-width': '100%'}), [child]);

Component _column(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': spaceCss(CoreSpace.space16),
      'width': '22rem',
      'max-width': '100%',
    },
  ),
  children,
);

Component _richEditor(Map<String, String> props, String? label) {
  final empty = previewFlag(props, 'empty');
  final images = previewFlag(props, 'images');
  return _sized(
    RichEditor(
      // `initialValue` 는 두 플랫폼 모두 처음 한 번만 읽으므로, 빈 편집기로 바꾸면 새로 만든다.
      key: ValueKey('rich-editor-$empty'),
      initialValue: empty ? null : page.richEditorPreviewMarkdown,
      placeholder: page.richEditorPreviewPlaceholder,
      toolbar: page.richEditorPreviewToolbars[props['toolbar']] ?? CoreRichEditorFormat.defaultToolbar,
      showToolbar: previewFlag(props, 'showToolbar', fallback: true),
      showSelectionToolbar: previewFlag(props, 'showSelectionToolbar', fallback: true),
      maxLength: int.tryParse(props['maxLength'] ?? ''),
      readOnly: previewFlag(props, 'readOnly'),
      enabled: previewFlag(props, 'enabled', fallback: true),
      maxImageBytes: page.richEditorPreviewMaxImageBytes,
      onImageUpload: images ? _upload : null,
      onImageDelete: images ? _delete : null,
      onChanged: (_) {},
    ),
  );
}

/// 상태 격자 — 모두 실제 편집기다. 포커스 칸은 테두리 색만 포커스 색으로
/// 바꿔 보인다(바깥 링은 그리지 않는다).
Component _states() {
  Component cell(String title, Component editor) => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': spaceCss(CoreSpace.space8),
        'width': '15rem',
        'max-width': '100%',
      },
    ),
    [Text(title).labelSmall.onSurfaceVariant, editor],
  );
  return div(
    styles: Styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'justify-content': 'center', 'gap': spaceCss(CoreSpace.space16)},
    ),
    [
      cell(
        '기본',
        const RichEditor(toolbar: page.richEditorStateToolbar, placeholder: page.richEditorPreviewPlaceholder),
      ),
      cell(
        '값 있음',
        const RichEditor(toolbar: page.richEditorStateToolbar, initialValue: page.richEditorShortMarkdown),
      ),
      cell(
        '포커스 테두리',
        RichEditor(
          toolbar: page.richEditorStateToolbar,
          initialValue: page.richEditorShortMarkdown,
          richEditorStyle: CoreRichEditorStyle(
            textAreaStyle: CoreTextAreaStyle(borderColor: CoreTextAreaStyle.defaultNormalVariant.focusRingColor),
          ),
        ),
      ),
      cell(
        '비활성',
        const RichEditor(
          toolbar: page.richEditorStateToolbar,
          initialValue: page.richEditorShortMarkdown,
          enabled: false,
        ),
      ),
      cell(
        '읽기 전용',
        const RichEditor(
          toolbar: page.richEditorStateToolbar,
          initialValue: page.richEditorShortMarkdown,
          readOnly: true,
        ),
      ),
    ],
  );
}
