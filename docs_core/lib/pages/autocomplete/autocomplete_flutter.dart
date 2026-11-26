/// Autocomplete 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="autocomplete/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`autocomplete_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 필드는 실제 `Autocomplete` 이고, 열린 제안 목록은 그림이다. 목록은 필드에
/// 포커스가 있을 때만 열리고 오버레이에 올라가므로, 무대에 열린 채로 둘 공개
/// 경로가 없다. 그림의 패널 상자는 킷의 `Popup` 에 `Autocomplete` 가 넘기는 패널
/// 스타일을 주어 그리고, 행은 `CoreAutocompleteStyle` 의 기본값과
/// `CoreAutocompleteMatch` 의 나눔으로 그린다 — Web 의 그림과 같다. 그래서
/// `CoreComponentTheme.autocomplete` · `autocompleteStyle` 의 덮어쓰기는 행에
/// 닿지 않는다. 실제 목록은 플레이그라운드의 필드에 입력하면 열린다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'autocomplete_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _autocomplete;

/// 장면 이름(`autocomplete/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'autocomplete/anatomy': () => const _Opened(accented: 0),
  'autocomplete/match': () => const SizedBox(
    width: _width,
    child: _Panel(query: page.demoQuery, accented: 1),
  ),
  'autocomplete/states': _states,
  'autocomplete/related-chip-input': () => SizedBox(
    width: _width,
    child: ChipInput(chips: const ['서울역', '부산역'], placeholder: '역 추가', onChanged: (_) {}),
  ),
};

/// 필드와 그림의 폭 — 패널은 필드 폭보다 좁아지지 않는다(`anchorMinSize`).
const double _width = 240;

/// 그림의 패널 상자 스타일 — 실제 목록의 패널이 받는 것과 같은 합.
final CorePopupStyle _panelStyle = CorePopoverStyle.defaultPanelStyle.merge(
  CoreAutocompleteStyle.defaultPopoverStyle.panelStyle,
);

Widget _autocomplete(Map<String, String> props, String? label) => SizedBox(
  width: _width,
  child: Autocomplete(
    suggestions: page.demoSuggestions,
    // 비운 속성은 빈 글자로 넘긴다 — `value` 에 `null` 을 넘겨서는 이미 보이는
    // 값이 지워지지 않으므로, 플레이그라운드에서 "값 있음" 을 끄면 비워야 한다.
    value: props['value'] ?? '',
    placeholder: props['placeholder'],
    enabled: previewFlag(props, 'enabled', fallback: true),
    mode: previewEnum(CoreAutocompleteMode.values, props['mode'], CoreAutocompleteMode.defaultMode),
    onChanged: (_) {},
    onSelected: (_) {},
  ),
);

/// 필드 아래에 목록 그림을 둔다 — 실제 목록이 열린 자리와 같은 간격 · 폭이다.
class _Opened extends StatelessWidget {
  const _Opened({this.accented});

  final int? accented;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offset =
        (CoreAutocompleteStyle.defaultPopoverStyle.placementOffset ?? CorePopoverStyle.defaultPlacementOffset) *
        theme.scaling;
    return SizedBox(
      width: _width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: offset,
        children: [
          Autocomplete(value: page.demoQuery, suggestions: page.demoSuggestions, onChanged: (_) {}),
          _Panel(query: page.demoQuery, accented: accented),
        ],
      ),
    );
  }
}

/// 열린 목록의 그림 — [query] 로 거른 행, [accented] 행은 hover · 키보드 강조의
/// 모양이다.
class _Panel extends StatelessWidget {
  const _Panel({required this.query, this.accented});

  final String query;

  final int? accented;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rest = CoreAutocompleteStyle.defaultDropdownTextStyle.toValue(theme: theme);
    final hovered = CoreAutocompleteStyle.defaultOptionHoverTextStyle.toValue(theme: theme);
    final match = CoreAutocompleteStyle.defaultMatchTextStyle.toValue(theme: theme);
    final fill = theme.colorScheme.resolve(CoreAutocompleteStyle.defaultOptionHoverColor).toValue();
    final padding = CoreAutocompleteStyle.defaultOptionPadding.toValue(geometry: theme.geometry) * theme.scaling;
    final radius = CoreAutocompleteStyle.defaultOptionBorderRadius.toValue(geometry: theme.geometry);

    Widget label(String text, TextStyle base) {
      final split = CoreAutocompleteMatch.of(text, query);
      if (!split.hasMatch) return Text(text, style: base);
      return Text.rich(
        TextSpan(
          style: base,
          children: [
            if (split.before.isNotEmpty) TextSpan(text: split.before),
            TextSpan(text: split.match, style: match),
            if (split.after.isNotEmpty) TextSpan(text: split.after),
          ],
        ),
      );
    }

    return Popup(
      popupStyle: _panelStyle,
      children: [
        for (final (index, text) in page.demoFiltered(query).indexed)
          Container(
            padding: padding,
            decoration: BoxDecoration(color: index == accented ? fill : null, borderRadius: radius),
            child: label(text, index == accented ? hovered : rest),
          ),
      ],
    );
  }
}

/// 상태 — Web 과 같은 세 칸.
Widget _states() {
  Widget cell(String title, Widget field) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space8,
    children: [
      Text(title).labelSmall.onSurfaceVariant,
      SizedBox(width: 176, child: field),
    ],
  );
  return Wrap(
    spacing: CoreSpace.space12,
    runSpacing: CoreSpace.space12,
    children: [
      cell('기본', const Autocomplete(placeholder: page.demoPlaceholder, suggestions: page.demoSuggestions)),
      cell('값 있음', const Autocomplete(value: page.demoQuery, suggestions: page.demoSuggestions)),
      cell('비활성', const Autocomplete(value: page.demoQuery, enabled: false, suggestions: page.demoSuggestions)),
    ],
  );
}
