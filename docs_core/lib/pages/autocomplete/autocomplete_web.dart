/// Autocomplete 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="autocomplete/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`autocomplete_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 필드는 실제 `Autocomplete` 이고, 열린 제안 목록은 그림이다. 목록은 필드에
/// 포커스가 있을 때만 열리고 오버레이 호스트의 층에 올라가므로, 서버가 그리는
/// 무대에 열린 채로 둘 공개 경로가 없다. 그림의 패널 상자는 킷의 `Popup` 에
/// `Autocomplete` 가 넘기는 패널 스타일(`CorePopoverStyle.defaultPanelStyle` 위에
/// `CoreAutocompleteStyle.defaultPopoverStyle.panelStyle`)을 주어 그리고, 행은
/// `CoreAutocompleteStyle` 의 기본값과 `CoreAutocompleteMatch` 의 나눔으로 그린다.
/// 그래서 `CoreComponentTheme.autocomplete` · `autocompleteStyle` 의 덮어쓰기는
/// 행에 닿지 않는다. 실제 목록은 플레이그라운드의 필드에 입력하면 열린다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'autocomplete_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _autocomplete;

/// 장면 이름(`autocomplete/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'autocomplete/anatomy': () => _opened(accented: 0, marked: true),
  'autocomplete/match': () => _sized(_panel(query: page.demoQuery, accented: 1)),
  'autocomplete/states': _states,
  'autocomplete/related-chip-input': () => _sized(
    ChipInput(chips: const ['서울역', '부산역'], placeholder: '역 추가', onChanged: (_) {}),
  ),
};

/// 필드와 그림의 폭 — 패널은 필드 폭보다 좁아지지 않는다(`anchorMinSize`).
const String _width = '15rem';

/// 필드와 패널 사이 — `Autocomplete` 가 넘기는 `placementOffset`.
final double _panelOffset =
    CoreAutocompleteStyle.defaultPopoverStyle.placementOffset ?? CorePopoverStyle.defaultPlacementOffset;

/// 그림의 패널 상자 스타일 — 실제 목록의 패널이 받는 것과 같은 합.
final CorePopupStyle _panelStyle = CorePopoverStyle.defaultPanelStyle.merge(
  CoreAutocompleteStyle.defaultPopoverStyle.panelStyle,
);

Component _sized(Component child) => div(styles: Styles(raw: {'width': _width}), [child]);

Component _autocomplete(Map<String, String> props, String? label) => _sized(
  Autocomplete(
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
Component _opened({int? accented, bool marked = false}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': pinnedLengthCss(_panelOffset),
      'width': _width,
    },
  ),
  [
    Autocomplete(value: page.demoQuery, suggestions: page.demoSuggestions, onChanged: (_) {}),
    _panel(query: page.demoQuery, accented: accented, marked: marked),
  ],
);

/// 열린 목록의 그림 — [query] 로 거른 행, [accented] 행은 hover · 키보드 강조의
/// 모양이다. [marked] 면 구조 블록이 번호를 붙일 부분에 `data-docs-part` 를 단다
/// (첫 행, 끝에서 일치하는 행의 강조 구간).
Component _panel({required String query, int? accented, bool marked = false}) {
  final rest = emitTypography(null, CoreAutocompleteStyle.defaultDropdownTextStyle);
  final hovered = emitTypography(null, CoreAutocompleteStyle.defaultOptionHoverTextStyle);
  final match = emitTypography(null, CoreAutocompleteStyle.defaultMatchTextStyle);
  final fill = emitColor(null, CoreAutocompleteStyle.defaultOptionHoverColor, ColorTarget.background);
  final rows = page.demoFiltered(query);

  Component row(int index, String label) {
    final isAccented = index == accented;
    final text = isAccented ? hovered : rest;
    final split = CoreAutocompleteMatch.of(label, query);
    final markMatch = marked && split.hasMatch && split.after.isEmpty && split.before.isNotEmpty;
    return div(
      attributes: {if (marked && index == 0) 'data-docs-part': 'option'},
      classes: [text.className, if (isAccented) fill.className].where((cls) => cls.isNotEmpty).join(' '),
      styles: Styles(
        raw: {
          'display': 'flex',
          'align-items': 'center',
          'padding': CoreAutocompleteStyle.defaultOptionPadding.toValue(),
          'border-radius': CoreAutocompleteStyle.defaultOptionBorderRadius.toValue(),
          ...?text.inline,
          if (isAccented) ...?fill.inline,
        },
      ),
      [
        if (!split.hasMatch)
          Text(label)
        else
          span([
            if (split.before.isNotEmpty) Text(split.before),
            span(
              attributes: {if (markMatch) 'data-docs-part': 'match'},
              classes: match.className,
              styles: match.inline == null ? null : Styles(raw: match.inline!),
              [Text(split.match)],
            ),
            if (split.after.isNotEmpty) Text(split.after),
          ]),
      ],
    );
  }

  return Popup(
    popupStyle: _panelStyle,
    attributes: const {'data-docs-part': 'panel', 'aria-hidden': 'true'},
    children: [for (final (index, label) in rows.indexed) row(index, label)],
  );
}

/// 상태 — 세 칸 모두 실제 `Autocomplete` 다. hover · 포커스 · 열린 목록은
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _states() {
  Component cell(String title, Component field) => div(
    styles: Styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space8), 'width': '11rem'},
    ),
    [Text(title).labelSmall.onSurfaceVariant, field],
  );
  return div(
    styles: Styles(raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': spaceCss(CoreSpace.space12)}),
    [
      cell('기본', Autocomplete(placeholder: page.demoPlaceholder, suggestions: page.demoSuggestions)),
      cell('값 있음', Autocomplete(value: page.demoQuery, suggestions: page.demoSuggestions)),
      cell('비활성', Autocomplete(value: page.demoQuery, enabled: false, suggestions: page.demoSuggestions)),
    ],
  );
}
