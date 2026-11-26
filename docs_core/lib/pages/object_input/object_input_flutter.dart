/// ObjectInput 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="object-input/...">` ·
/// `<Anatomy>` · `<Card demo>` 가 읽는다. 같은 이름의 Web 파일
/// (`object_input_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'object_input_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _objectInput;

/// 장면 이름(`object-input/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  // 앞 아이콘과 뒤 글자까지 모두 보이게 둔다.
  'object-input/anatomy': () => ObjectInput(
    fields: objectInputAnatomyFields,
    separator: '/',
    leading: const Icon(LucideIcons.calendar),
    trailing: const Text('까지').bodySmall.onSurfaceVariant,
  ),
  'object-input/widths': _widthSamples,
  'object-input/states': _objectInputStates,
  'object-input/do-form-field': () => _sized(_labelled()),
  'object-input/dont-bare': () => const ObjectInput(fields: objectInputClockFields, separator: ':'),
  'object-input/do-pattern': () => const ObjectInput(
    fields: objectInputClockFields,
    separator: ':',
    values: objectInputTimeExample,
  ),
  'object-input/dont-no-pattern': () => const ObjectInput(
    fields: objectInputUnfilteredClockFields,
    separator: ':',
    values: objectInputUnfilteredExample,
  ),
  'object-input/related-formatted-input': () => _sized(const FormattedInput.date(value: '11252026')),
  'object-input/related-text-field': () => _sized(TextField(placeholder: const Text('YYYY-MM-DD'))),
  'object-input/related-form-field': () => _sized(_labelled()),
};

/// 좁은 카드에 맞춘 폭.
Widget _sized(Widget child) => SizedBox(width: 192, child: child);

/// 속성으로 그린다. 칸 묶음이나 처음 값이 바뀌면 새 입력창으로 그린다
/// ([objectInputPreviewKey]).
Widget _objectInput(Map<String, String> props, String? label) {
  final preset = objectInputPresetFor(props);
  return ObjectInput(
    key: ValueKey(objectInputPreviewKey(props)),
    fields: preset.fields,
    separator: preset.separator,
    values: objectInputPreviewValues(props),
    leading: previewFlag(props, 'leading') ? docsFlutterIcon(preset.icon) : null,
    enabled: previewFlag(props, 'enabled', fallback: true),
  );
}

Widget _labelled() => const FormField(
  label: '시작 시각',
  description: '시와 분을 두 자리씩 입력합니다.',
  child: ObjectInput(fields: objectInputClockFields, separator: ':'),
);

/// 칸 폭 — `maxLength` 마다 칸 하나짜리 입력창.
Widget _widthSamples() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space16,
  children: [
    for (final (caption, field) in objectInputWidthSamples)
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpace.space6,
        children: [
          Text(caption).bodySmall.onSurfaceVariant,
          ObjectInput(fields: [field]),
        ],
      ),
  ],
);

/// 상태 격자 — Web 과 같은 네 칸.
Widget _objectInputStates() {
  const columns = ['빈 칸', '값', 'Focus', '비활성'];
  Widget cell(String state) => switch (state) {
    '값' => const ObjectInput(fields: objectInputClockFields, separator: ':', values: objectInputTimeExample),
    'Focus' => const ObjectInput(
      fields: objectInputClockFields,
      separator: ':',
      values: objectInputTimeExample,
      objectInputStyle: objectInputFocusLookStyle,
    ),
    '비활성' => const ObjectInput(
      fields: objectInputClockFields,
      separator: ':',
      values: objectInputTimeExample,
      enabled: false,
    ),
    _ => const ObjectInput(fields: objectInputClockFields, separator: ':'),
  };
  return Wrap(
    spacing: CoreSpace.space16,
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
