/// TextArea 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="text-area/...">` 가 읽는다. 같은 이름의 Web 파일(`text_area_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _textArea;

/// 장면 이름(`text-area/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'text-area/anatomy': () => _sized(
    TextArea(
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
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('보내기'))],
      ),
    ),
  ),
  'text-area/resizable': () => _sized(
    TextArea(
      expandableHeight: true,
      placeholder: '오른쪽 아래 모서리를 끌어 높이를 바꿔 보세요',
      textAreaStyle: const CoreTextAreaStyle(minHeight: 96, maxHeight: 240),
    ),
  ),
  'text-area/related-form': () => SizedBox(
    width: 192,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpace.space8,
      children: [
        TextField(placeholder: const Text('제목')),
        TextArea(placeholder: '내용', rows: 2),
        Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('보내기')),
      ],
    ),
  ),
};

Widget _sized(Widget child, {double width = 280}) => SizedBox(width: width, child: child);

Widget _textArea(Map<String, String> props, String? label) {
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
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('보내기'))],
            ),
    ),
  );
}

/// 상태 격자 — Web 과 같은 다섯 칸.
Widget _textAreaStates() {
  const columns = ['기본', 'Focus', '오류', '비활성', '읽기 전용'];
  Widget cell(String state) => SizedBox(
    width: 152,
    child: switch (state) {
      'Focus' => TextArea(
        rows: 2,
        initialValue: '배송지를',
        textAreaStyle: CoreTextAreaStyle(borderColor: CoreTextAreaStyle.defaultNormalVariant.focusRingColor),
      ),
      '오류' => TextArea(rows: 2, initialValue: '배송지를', errorText: '10자 이상'),
      '비활성' => TextArea(rows: 2, initialValue: '배송지를 바꾸고 싶어요.', enabled: false),
      '읽기 전용' => TextArea(rows: 2, initialValue: '배송지를 바꾸고 싶어요.', readOnly: true),
      _ => TextArea(rows: 2, placeholder: '내용'),
    },
  );
  return Wrap(
    spacing: CoreSpace.space12,
    runSpacing: CoreSpace.space12,
    children: [
      for (final column in columns)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
        ),
    ],
  );
}
