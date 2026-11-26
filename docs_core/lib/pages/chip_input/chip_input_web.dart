/// ChipInput 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="chip-input/...">` ·
/// `<Anatomy>` · `<Card demo>` 가 읽는다. 같은 이름의 Flutter 파일
/// (`chip_input_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'chip_input_page.dart';

/// 속성 → Component.
///
/// 칩 목록은 부모가 들고 넘기는 값이라 빌더가 기억한다. 서버에서 그리는
/// 블록에서는 처음 칩만 보이고, 브라우저에서 깨어나는 플레이그라운드에서는
/// Enter 로 칩을 더하고 지우기 버튼으로 지울 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _sized(_ChipInputPreview(props: props));

/// 장면 이름(`chip-input/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'chip-input/anatomy': () => _sized(_input(chipInputPreviewChips, placeholder: chipInputPreviewPlaceholder)),
  'chip-input/states': _chipInputStates,
  'chip-input/wrap': () => _sized(_input(chipInputWrapChips, placeholder: '태그 추가'), width: '17.5rem'),
  'chip-input/do-short-tags': () => _sized(_input(chipInputShortChips), width: '15rem'),
  'chip-input/dont-sentence-tags': () => _sized(_input(chipInputSentenceChips), width: '15rem'),
  'chip-input/related-chip': () => docsWebDemoRow([
    Chip(label: '디자인'),
    Chip(label: '개발', onRemove: () {}),
  ]),
  'chip-input/related-text-field': () => _sized(const TextField(placeholder: Text('한 줄 입력')), width: '12rem'),
  'chip-input/related-autocomplete': () => _sized(
    Autocomplete(
      placeholder: '태그 검색',
      onChanged: (_) {},
      suggestions: const ['디자인', '개발', '마케팅'],
    ),
    width: '12rem',
  ),
  'chip-input/related-form-field': () => _sized(
    FormField(
      label: '태그',
      description: 'Enter 로 추가합니다.',
      child: _input(const ['디자인']),
    ),
    width: '15rem',
  ),
};

Component _sized(Component child, {String width = '20rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

/// 콜백만 이어 둔 ChipInput — 장면은 칩을 바꾸지 않는다.
Component _input(
  List<String> chips, {
  String? placeholder,
  int? maxChips,
  bool enabled = true,
  CoreChipInputStyle? style,
}) => ChipInput(
  chips: chips,
  placeholder: placeholder,
  maxChips: maxChips,
  enabled: enabled,
  chipInputStyle: style,
  onChanged: (_) {},
  onSubmitted: (_) {},
);

/// 상태 격자 — 다섯 칸 모두 실제 ChipInput 이다. Hover 칸은 hover 테두리
/// 색을 Core 기본값에서 읽어 고정했다. 포커스 링은 브라우저가 키보드나 포인터
/// 없이 켤 수 없어 표의 설명으로 대신한다.
///
/// 칸 폭은 칸마다 내용에 맞춘다 — 칩과 입력 칸이 한 줄에 놓여야 하는 칸
/// (칩 있음)만 넓다. 한 폭으로 맞추면 다섯 칸이 다른 필드 페이지의 상태
/// 격자(9.5rem × 5)보다 넓어져 무대 밖으로 나간다.
Component _chipInputStates() {
  Component cell(String state) => div(styles: Styles(raw: {'width': _stateCellWidth(state)}), [
    switch (state) {
      '칩 있음' => _input(const ['UI']),
      'Hover' => _input(
        const [],
        placeholder: '태그 추가',
        style: const CoreChipInputStyle(borderColor: CoreChipInputStyle.defaultHoverBorderColor),
      ),
      '한도 도달' => _input(const ['UI', 'UX'], maxChips: 2),
      '비활성' => _input(const ['UI'], enabled: false),
      _ => _input(const [], placeholder: '태그 추가'),
    },
  ]);
  return div(classes: 'docs-demo-field-states', [
    for (final column in chipInputStateColumns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final column in chipInputStateColumns) cell(column),
  ]);
}

/// 상태 칸의 폭 — 칩 하나(약 54)와 입력 칸의 최소 폭(80)이 프레임 여백 ·
/// 테두리(26) 안에 한 줄로 들어가야 하는 칸은 11rem, 칩 둘이나 지우기 버튼
/// 없는 칩 하나와 입력 칸을 담는 칸은 9.5rem, 칩이 없는 칸은 8rem.
String _stateCellWidth(String state) => switch (state) {
  '칩 있음' => '11rem',
  '한도 도달' || '비활성' => '9.5rem',
  _ => '8rem',
};

/// 속성으로 그리는 ChipInput — 칩 목록을 기억한다.
///
/// 속성: `chips` 는 쉼표로 이은 처음 칩, `placeholder` · `maxChips` · `enabled`
/// 는 위젯 속성 그대로, `pasteSplitter` 는 켜면
/// `CoreChipInputContract.splitOnCommonSeparators` 를 넘긴다.
class _ChipInputPreview extends StatefulComponent {
  const _ChipInputPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_ChipInputPreview> createState() => _ChipInputPreviewState();
}

class _ChipInputPreviewState extends State<_ChipInputPreview> {
  late List<String> _chips;

  @override
  void initState() {
    super.initState();
    _chips = chipInputPreviewChipList(component.props);
  }

  @override
  void didUpdateComponent(covariant _ChipInputPreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!_sameProps(oldComponent.props, component.props)) _chips = chipInputPreviewChipList(component.props);
  }

  void _handleChanged(List<String> chips) => setState(() => _chips = chips);

  void _handleSubmitted(String text) => setState(() => _chips = [..._chips, text]);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return ChipInput(
      chips: _chips,
      placeholder: props['placeholder'],
      maxChips: int.tryParse(props['maxChips'] ?? ''),
      enabled: previewFlag(props, 'enabled', fallback: true),
      pasteSplitter: previewFlag(props, 'pasteSplitter') ? CoreChipInputContract.splitOnCommonSeparators : null,
      onChanged: _handleChanged,
      onSubmitted: _handleSubmitted,
    );
  }
}

bool _sameProps(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((entry) => b[entry.key] == entry.value);
