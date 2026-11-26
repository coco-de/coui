/// Fieldset 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<VariantRow>` · `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="fieldset/...">` · `<Card demo>` 가 읽는다. 같은 이름의 Web
/// 파일(`fieldset_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Fieldset 은 부모의 폭을 채우므로(`width: double.infinity`) 폭이 정해진
/// 부모가 필요하다 — 미리보기마다 Web 의 18rem · 12rem 과 같은 288 · 192 를
/// 준다. 좁은 무대에서는 무대 폭까지 줄어든다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'fieldset_page.dart';

/// 속성 → Widget.
///
/// 태그의 `label` 이 범례 글자가 된다. `fields` 는 안에 놓을 필드 수,
/// `legend=false` 는 범례를 빼고, `width=compact` 는 좁은 폭으로 그린다.
FlutterPropPreviewBuilder? get propPreview => _fieldset;

/// 장면 이름(`fieldset/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'fieldset/anatomy': () => _box(
    Fieldset(
      legend: const Text(fieldsetPreviewLegend),
      description: const Text(fieldsetPreviewDescription),
      children: [for (final (placeholder, _) in fieldsetPreviewFields) _field(placeholder)],
    ),
  ),
  'fieldset/states': () => docsFlutterDemoRow([
    for (final enabled in const [true, false])
      _box(
        Fieldset(
          legend: Text(enabled ? '활성' : '비활성'),
          enabled: enabled,
          children: [
            _field('이메일'),
            const _DemoCheckbox(label: '알림 받기', initial: true),
          ],
        ),
        compact: true,
      ),
  ]),
  'fieldset/do-legend': () => _box(
    Fieldset(
      legend: const Text('결제 정보'),
      description: const Text('영수증에 표시되는 정보예요.'),
      children: [_field('카드 번호'), _field('만료일')],
    ),
    compact: true,
  ),
  'fieldset/dont-no-legend': () => _box(
    Fieldset(children: [_field('카드 번호'), _field('만료일')]),
    compact: true,
  ),
  'fieldset/do-disable-each': () => _box(_disabledPayment(checkboxEnabled: false), compact: true),
  'fieldset/dont-assume-disabled': () => _box(_disabledPayment(), compact: true),
  'fieldset/sections': () => _box(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpace.space24,
      children: [
        Fieldset(legend: const Text('기본 정보'), children: [_field('이름'), _field('이메일')]),
        Fieldset(legend: const Text('배송 정보'), children: [_field('주소')]),
      ],
    ),
  ),
  'fieldset/related-form': () => SizedBox(
    width: 192,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpace.space8,
      children: [
        _field('이름'),
        Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('제출')),
      ],
    ),
  ),
};

Widget _fieldset(Map<String, String> props, String? label) {
  final description = props['description'];
  final count = int.tryParse(props['fields'] ?? '') ?? fieldsetPreviewFields.length;
  return _box(
    Fieldset(
      variant: previewEnum(CoreFieldsetVariant.values, props['variant'], CoreFieldsetVariant.defaultVariant),
      size: previewEnum(CoreComponentSize.values, props['size'], CoreFieldsetStyle.defaultSize),
      legend: previewFlag(props, 'legend', fallback: true) ? Text(label ?? fieldsetPreviewLegend) : null,
      description: description == null ? null : Text(description),
      enabled: previewFlag(props, 'enabled', fallback: true),
      children: [for (final (placeholder, _) in fieldsetPreviewFields.take(count)) _field(placeholder)],
    ),
    compact: props['width'] == 'compact',
  );
}

/// 폭을 정한 상자 — 무대가 더 좁으면 무대 폭까지 줄어든다.
Widget _box(Widget child, {bool compact = false}) => SizedBox(width: compact ? 192 : 288, child: child);

Widget _field(String placeholder) => TextField(placeholder: Text(placeholder));

/// 비활성 묶음 안의 필드와 체크박스. [checkboxEnabled] 를 넘기지 않으면
/// 체크박스는 눌리는 채로 남는다.
Widget _disabledPayment({bool? checkboxEnabled}) => Fieldset(
  legend: const Text('결제 정보'),
  enabled: false,
  children: [
    _field('카드 번호'),
    _DemoCheckbox(label: '카드 저장', enabled: checkboxEnabled),
  ],
);

/// 값을 직접 들고 있는 체크박스 — 눌리는 체크박스는 표시가 바뀌어야 눌린
/// 것이 보인다.
class _DemoCheckbox extends StatefulWidget {
  const _DemoCheckbox({required this.label, this.initial = false, this.enabled});

  final String label;
  final bool initial;
  final bool? enabled;

  @override
  State<_DemoCheckbox> createState() => _DemoCheckboxState();
}

class _DemoCheckboxState extends State<_DemoCheckbox> {
  late bool _checked = widget.initial;

  @override
  Widget build(BuildContext context) => Checkbox(
    checked: _checked,
    enabled: widget.enabled,
    onChanged: (value) => setState(() => _checked = value ?? false),
    label: widget.label,
  );
}
