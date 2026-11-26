/// SelectableText 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="selectable-text/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`selectable_text_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
///
/// Web 의 루트는 인라인 `<span>` 이라, 글이 줄을 바꾸는 폭은 부모가 정한다.
/// 그래서 모든 미리보기를 폭을 정한 상자에 담는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'selectable_text_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _selectableText;

/// 장면 이름(`selectable-text/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'selectable-text/styles': () => _box(column: true, [
    for (final (index, (caption, style)) in page.demoStyleRows.indexed) ...[
      if (index > 0) const Gap.space16(),
      Text(caption).labelSmall.onSurfaceVariant,
      const Gap.space4(),
      SelectableText(page.demoShortText, selectableTextStyle: style),
    ],
  ]),
  'selectable-text/rich': () => _box([
    SelectableText.rich(
      children: [const Text(page.demoRichLead), const Text(page.demoRichStrong).bold],
    ),
  ]),
  'selectable-text/max-lines': () => _box(column: true, [
    const Text('maxLines 없음').labelSmall.onSurfaceVariant,
    const Gap.space4(),
    const SelectableText(page.demoLongText),
    const Gap.space16(),
    const Text('maxLines: 2').labelSmall.onSurfaceVariant,
    const Gap.space4(),
    const SelectableText(page.demoLongText, maxLines: 2),
  ]),
  'selectable-text/do-copy': () => _box(column: true, width: page.demoCardWidth, [
    const Text(page.demoCopyLabel).labelSmall.onSurfaceVariant,
    const Gap.space4(),
    const SelectableText(page.demoCopyValue, selectableTextStyle: page.demoCopyStyle),
  ]),
  'selectable-text/dont-edit': () => _box(column: true, width: page.demoCardWidth, [
    const Text(page.demoEditLabel).labelSmall.onSurfaceVariant,
    const Gap.space4(),
    const SelectableText(page.demoEditValue, selectableTextStyle: page.demoPlaceholderStyle),
  ]),
};

Component _selectableText(Map<String, String> props, String? label) {
  if (page.demoReportsTap(props)) return _TapReport(props: props, label: label);
  return _box([_text(props, label)]);
}

/// 속성으로 만든 `SelectableText`.
SelectableText _text(Map<String, String> props, String? label, {void Function()? onTap}) => SelectableText(
  label ?? page.demoText,
  selectableTextStyle: page.demoStyleOf(props),
  maxLines: page.demoMaxLinesOf(props),
  enableInteractiveSelection: page.demoSelectionEnabled(props),
  onTap: onTap,
);

/// 폭을 정한 상자 — [column] 이면 자식을 세로로 쌓는다.
Component _box(List<Component> children, {bool column = false, double width = page.demoWidth}) => div(
  styles: Styles(
    raw: {
      'width': pinnedLengthCss(width),
      'max-width': '100%',
      if (column) ...{'display': 'flex', 'flex-direction': 'column', 'align-items': 'flex-start'},
    },
  ),
  children,
);

/// `onTap` 이 불린 횟수를 글 아래에 보인다.
class _TapReport extends StatefulComponent {
  const _TapReport({required this.props, required this.label});

  final Map<String, String> props;
  final String? label;

  @override
  State<_TapReport> createState() => _TapReportState();
}

class _TapReportState extends State<_TapReport> {
  int _taps = 0;

  @override
  Component build(BuildContext context) => _box(column: true, [
    _text(component.props, component.label, onTap: () => setState(() => _taps++)),
    const Gap.space8(),
    Text(page.demoTapLabel(_taps)).bodySmall.onSurfaceVariant,
  ]);
}
