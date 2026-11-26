/// ChipInput 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="chip-input/...">` ·
/// `<Anatomy>` · `<Card demo>` 가 읽는다. 같은 이름의 Web 파일
/// (`chip_input_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'chip_input_page.dart';

/// 속성 → Widget.
///
/// 칩 목록은 부모가 들고 넘기는 값이라 빌더가 기억한다 — Enter 로 칩을 더하고
/// 지우기 버튼으로 지울 수 있다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _sized(_ChipInputPreview(props: props));

/// 장면 이름(`chip-input/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'chip-input/anatomy': () => _sized(_input(chipInputPreviewChips, placeholder: chipInputPreviewPlaceholder)),
  'chip-input/states': _chipInputStates,
  'chip-input/wrap': () => _sized(_input(chipInputWrapChips, placeholder: '태그 추가'), width: 280),
  'chip-input/do-short-tags': () => _sized(_input(chipInputShortChips), width: 240),
  'chip-input/dont-sentence-tags': () => _sized(_input(chipInputSentenceChips), width: 240),
  'chip-input/related-chip': () => docsFlutterDemoRow([
    const Chip(label: '디자인'),
    Chip(label: '개발', onRemove: () {}),
  ]),
  'chip-input/related-text-field': () => _sized(TextField(placeholder: const Text('한 줄 입력')), width: 192),
  'chip-input/related-autocomplete': () => _sized(
    Autocomplete(
      placeholder: '태그 검색',
      onChanged: (_) {},
      suggestions: const ['디자인', '개발', '마케팅'],
    ),
    width: 192,
  ),
  'chip-input/related-form-field': () => _sized(
    FormField(
      label: '태그',
      description: 'Enter 로 추가합니다.',
      child: _input(const ['디자인']),
    ),
    width: 240,
  ),
};

Widget _sized(Widget child, {double width = 320}) => SizedBox(width: width, child: child);

/// 콜백만 이어 둔 ChipInput — 장면은 칩을 바꾸지 않는다.
Widget _input(
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

/// 상태 장면 — Web 과 같은 다섯 칸을 세로로 쌓는다. Hover 칸은 hover 테두리
/// 색을 Core 기본값에서 읽어 고정했다.
Widget _chipInputStates() {
  Widget cell(String state) => switch (state) {
    '칩 있음' => _input(const ['UI']),
    'Hover' => _input(
      const [],
      placeholder: '태그 추가',
      style: const CoreChipInputStyle(borderColor: CoreChipInputStyle.defaultHoverBorderColor),
    ),
    '한도 도달' => _input(const ['UI', 'UX'], maxChips: 2),
    '비활성' => _input(const ['UI'], enabled: false),
    _ => _input(const [], placeholder: '태그 추가'),
  };
  return SizedBox(
    width: 280,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpace.space12,
      children: [
        for (final column in chipInputStateColumns)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CoreSpace.space4,
            children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
          ),
      ],
    ),
  );
}

/// 속성으로 그리는 ChipInput — 칩 목록을 기억한다.
///
/// 속성: `chips` 는 쉼표로 이은 처음 칩, `placeholder` · `maxChips` · `enabled`
/// 는 위젯 속성 그대로, `pasteSplitter` 는 켜면
/// `CoreChipInputContract.splitOnCommonSeparators` 를 넘긴다.
class _ChipInputPreview extends StatefulWidget {
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
    _chips = chipInputPreviewChipList(widget.props);
  }

  @override
  void didUpdateWidget(covariant _ChipInputPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameProps(oldWidget.props, widget.props)) _chips = chipInputPreviewChipList(widget.props);
  }

  void _handleChanged(List<String> chips) => setState(() => _chips = chips);

  void _handleSubmitted(String text) => setState(() => _chips = [..._chips, text]);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
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
