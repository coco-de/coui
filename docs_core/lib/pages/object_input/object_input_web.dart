/// ObjectInput 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="object-input/...">` ·
/// `<Anatomy>` · `<Card demo>` 가 읽는다. 같은 이름의 Flutter 파일
/// (`object_input_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'object_input_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _objectInput;

/// 장면 이름(`object-input/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 앞 아이콘과 뒤 글자까지 모두 보이게 둔다. 폭을 주지 않아 상자가 무대의
  // 첫 요소가 되고, 구조의 container 가 상자를 가리킨다.
  'object-input/anatomy': () => ObjectInput(
    fields: objectInputAnatomyFields,
    separator: '/',
    leading: const Icon(LucideIcons.calendar),
    trailing: div(
      attributes: const {'data-docs-part': 'trailing'},
      [const Text('까지').bodySmall.onSurfaceVariant],
    ),
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
  'object-input/related-text-field': () => _sized(const TextField(placeholder: Text('YYYY-MM-DD'))),
  'object-input/related-form-field': () => _sized(_labelled()),
};

/// 좁은 카드에 맞춘 폭.
Component _sized(Component child) => div(styles: Styles(raw: {'width': '12rem'}), [child]);

/// 속성으로 그린다. 칸 묶음이나 처음 값이 바뀌면 새 입력창으로 그린다
/// ([objectInputPreviewKey]).
Component _objectInput(Map<String, String> props, String? label) {
  final preset = objectInputPresetFor(props);
  return ObjectInput(
    key: ValueKey(objectInputPreviewKey(props)),
    fields: preset.fields,
    separator: preset.separator,
    values: objectInputPreviewValues(props),
    leading: previewFlag(props, 'leading') ? docsWebIcon(preset.icon) : null,
    enabled: previewFlag(props, 'enabled', fallback: true),
  );
}

Component _labelled() => const FormField(
  label: '시작 시각',
  description: '시와 분을 두 자리씩 입력합니다.',
  child: ObjectInput(fields: objectInputClockFields, separator: ':'),
);

/// 칸 폭 — `maxLength` 마다 칸 하나짜리 입력창.
Component _widthSamples() => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'flex-start', 'gap': 'var(--coui-space-16)'},
  ),
  [
    for (final (caption, field) in objectInputWidthSamples)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'align-items': 'flex-start',
            'gap': 'var(--coui-space-6)',
          },
        ),
        [
          Text(caption).bodySmall.onSurfaceVariant,
          ObjectInput(fields: [field]),
        ],
      ),
  ],
);

/// 상태 격자 — 네 칸 모두 실제 입력창이다. Focus 칸은 포커스 테두리 색을 Core
/// 기본값에서 읽어 고정했고([objectInputFocusLookStyle]), hover 는 포인터를
/// 올려야 보여 표의 설명으로 대신한다.
Component _objectInputStates() {
  const columns = ['빈 칸', '값', 'Focus', '비활성'];
  Component cell(String state) => switch (state) {
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
  return div(
    classes: 'docs-demo-field-states',
    styles: Styles(raw: {'grid-template-columns': 'repeat(${columns.length}, max-content)'}),
    [
      for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
      for (final column in columns) cell(column),
    ],
  );
}
