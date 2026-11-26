/// TextArea 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="text-area/...">` 가 읽는다. 같은 이름의 Flutter 파일(`text_area_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _textArea;

/// 장면 이름(`text-area/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'text-area/anatomy': () => _sized(
    const TextArea(
      label: '문의 내용',
      initialValue: '배송지를 바꾸고 싶어요.',
      description: '답변은 이메일로 보내 드립니다.',
      maxLength: 200,
      showCounter: true,
      rows: 3,
    ),
  ),
  'text-area/states': _textAreaStates,
  'text-area/footer': () => _sized(
    TextArea(
      rows: 1,
      placeholder: '메시지를 입력해 주세요',
      footer: div(classes: 'flex flex-row justify-end', [
        Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('보내기')),
      ]),
    ),
  ),
  'text-area/resizable': () => _sized(
    const TextArea(
      expandableHeight: true,
      placeholder: '오른쪽 아래 모서리를 끌어 높이를 바꿔 보세요',
      textAreaStyle: CoreTextAreaStyle(minHeight: 96, maxHeight: 240),
    ),
  ),
  'text-area/related-form': () => div(classes: 'docs-demo-stack', [
    const TextField(placeholder: Text('제목')),
    const TextArea(placeholder: '내용', rows: 2),
    Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('보내기')),
  ]),
};

Component _sized(Component child, {String width = '17.5rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

Component _textArea(Map<String, String> props, String? label) {
  final maxLength = int.tryParse(props['maxLength'] ?? '');
  return _sized(
    TextArea(
      variant: previewEnum(CoreTextAreaVariant.values, props['variant'], CoreTextAreaVariant.defaultVariant),
      size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
      label: props['label'],
      placeholder: props['placeholder'],
      description: props['description'],
      errorText: props['errorText'],
      initialValue: props['value'],
      maxLength: maxLength,
      showCounter: maxLength != null,
      rows: int.tryParse(props['rows'] ?? ''),
      enabled: previewFlag(props, 'enabled', fallback: true),
      readOnly: previewFlag(props, 'readOnly'),
      footer: props['footer'] == null
          ? null
          : div(classes: 'flex flex-row justify-end', [
              Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('보내기')),
            ]),
    ),
  );
}

/// TextArea 상태 격자 — 쉬는 상태 · 오류 · 비활성 · 읽기 전용은 실제 영역,
/// focus 는 포커스 테두리 색을 Core 기본값에서 읽어 고정한 영역이다.
Component _textAreaStates() {
  const columns = ['기본', 'Focus', '오류', '비활성', '읽기 전용'];
  Component cell(String state) => div(styles: Styles(raw: {'width': '9.5rem'}), [
    switch (state) {
      'Focus' => TextArea(
        rows: 2,
        initialValue: '배송지를',
        textAreaStyle: CoreTextAreaStyle(borderColor: CoreTextAreaStyle.defaultNormalVariant.focusRingColor),
      ),
      '오류' => const TextArea(rows: 2, initialValue: '배송지를', errorText: '10자 이상'),
      '비활성' => const TextArea(rows: 2, initialValue: '배송지를 바꾸고 싶어요.', enabled: false),
      '읽기 전용' => const TextArea(rows: 2, initialValue: '배송지를 바꾸고 싶어요.', readOnly: true),
      _ => const TextArea(rows: 2, placeholder: '내용'),
    },
  ]);
  return div(classes: 'docs-demo-field-states', [
    for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final column in columns) cell(column),
  ]);
}
