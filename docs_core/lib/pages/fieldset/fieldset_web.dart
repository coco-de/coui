/// Fieldset 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="fieldset/...">` · `<Card demo>` 가 읽는다. 같은 이름의
/// Flutter 파일(`fieldset_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
///
/// Fieldset 은 부모의 폭을 채우므로(`w-full`) 미리보기마다 폭을 준다 —
/// Flutter 쪽의 288 · 192 와 같은 18rem · 12rem. 좁은 무대(Variant 행)에서는
/// 무대 폭까지 줄어든다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'fieldset_page.dart';

/// 속성 → Component.
///
/// 태그의 `label` 이 범례 글자가 된다. `fields` 는 안에 놓을 필드 수,
/// `legend=false` 는 범례를 빼고, `width=compact` 는 좁은 폭으로 그린다.
WebPropPreviewBuilder? get propPreview => _fieldset;

/// 장면 이름(`fieldset/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 번호가 범례와 설명을 따로 찾도록 두 자리에 표지를 단다.
  'fieldset/anatomy': () => _box(
    Fieldset(
      legend: span(attributes: const {'data-docs-part': 'legend'}, [const Text(fieldsetPreviewLegend)]),
      description: span(
        attributes: const {'data-docs-part': 'description'},
        [
          const Text(fieldsetPreviewDescription),
        ],
      ),
      children: [for (final (placeholder, _) in fieldsetPreviewFields) TextField(placeholder: Text(placeholder))],
    ),
  ),
  'fieldset/states': () => docsWebDemoRow([
    for (final enabled in const [true, false])
      _box(
        Fieldset(
          legend: Text(enabled ? '활성' : '비활성'),
          enabled: enabled,
          children: const [
            TextField(placeholder: Text('이메일')),
            _DemoCheckbox(label: '알림 받기', initial: true),
          ],
        ),
        compact: true,
      ),
  ]),
  'fieldset/do-legend': () => _box(
    const Fieldset(
      legend: Text('결제 정보'),
      description: Text('영수증에 표시되는 정보예요.'),
      children: [
        TextField(placeholder: Text('카드 번호')),
        TextField(placeholder: Text('만료일')),
      ],
    ),
    compact: true,
  ),
  'fieldset/dont-no-legend': () => _box(
    const Fieldset(
      children: [
        TextField(placeholder: Text('카드 번호')),
        TextField(placeholder: Text('만료일')),
      ],
    ),
    compact: true,
  ),
  'fieldset/do-disable-each': () => _box(_disabledPayment(checkboxEnabled: false), compact: true),
  'fieldset/dont-assume-disabled': () => _box(_disabledPayment(), compact: true),
  'fieldset/sections': () => div(
    styles: Styles(
      raw: {
        'width': '18rem',
        'max-width': '100%',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': spaceCss(CoreSpace.space24),
      },
    ),
    const [
      Fieldset(
        legend: Text('기본 정보'),
        children: [
          TextField(placeholder: Text('이름')),
          TextField(placeholder: Text('이메일')),
        ],
      ),
      Fieldset(
        legend: Text('배송 정보'),
        children: [TextField(placeholder: Text('주소'))],
      ),
    ],
  ),
  'fieldset/related-form': () => div(classes: 'docs-demo-stack', [
    const TextField(placeholder: Text('이름')),
    Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('제출')),
  ]),
};

Component _fieldset(Map<String, String> props, String? label) {
  final description = props['description'];
  final count = int.tryParse(props['fields'] ?? '') ?? fieldsetPreviewFields.length;
  return _box(
    Fieldset(
      variant: previewEnum(CoreFieldsetVariant.values, props['variant'], CoreFieldsetVariant.defaultVariant),
      size: previewEnum(CoreComponentSize.values, props['size'], CoreFieldsetStyle.defaultSize),
      legend: previewFlag(props, 'legend', fallback: true) ? Text(label ?? fieldsetPreviewLegend) : null,
      description: description == null ? null : Text(description),
      enabled: previewFlag(props, 'enabled', fallback: true),
      children: [
        for (final (placeholder, _) in fieldsetPreviewFields.take(count)) TextField(placeholder: Text(placeholder)),
      ],
    ),
    compact: props['width'] == 'compact',
  );
}

/// 폭을 정한 상자 — 무대가 더 좁으면 무대 폭까지 줄어든다.
Component _box(Component child, {bool compact = false}) => div(
  styles: Styles(raw: {'width': compact ? '12rem' : '18rem', 'max-width': '100%'}),
  [child],
);

/// 비활성 묶음 안의 필드와 체크박스. [checkboxEnabled] 를 넘기지 않으면
/// 체크박스는 눌리는 채로 남는다.
Component _disabledPayment({bool? checkboxEnabled}) => Fieldset(
  legend: const Text('결제 정보'),
  enabled: false,
  children: [
    const TextField(placeholder: Text('카드 번호')),
    _DemoCheckbox(label: '카드 저장', enabled: checkboxEnabled),
  ],
);

/// 값을 직접 들고 있는 체크박스 — 눌리는 체크박스는 표시가 바뀌어야 눌린
/// 것이 보인다. 서버에서만 그리는 블록에서는 처음 값으로 보인다.
class _DemoCheckbox extends StatefulComponent {
  const _DemoCheckbox({required this.label, this.initial = false, this.enabled});

  final String label;
  final bool initial;
  final bool? enabled;

  @override
  State<_DemoCheckbox> createState() => _DemoCheckboxState();
}

class _DemoCheckboxState extends State<_DemoCheckbox> {
  late bool _checked = component.initial;

  @override
  Component build(BuildContext context) => Checkbox(
    checked: _checked,
    enabled: component.enabled,
    onChanged: (value) => setState(() => _checked = value ?? false),
    label: component.label,
  );
}
