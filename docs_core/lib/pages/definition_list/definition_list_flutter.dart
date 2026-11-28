/// DefinitionList 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="definition-list/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`definition_list_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// `columns` 목록은 폭 제한이 없는 부모에서 설명 열의 폭이 0 이 된다. 그래서
/// `columns` 장면은 폭을 정한 상자 안에 둔다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'definition_list_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _definitionList;

/// 장면 이름(`definition-list/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'definition-list/anatomy': () => _box(
    DefinitionList(
      items: definitionListEntries(definitionListAnatomySamples),
      layout: CoreDefinitionLayout.columns,
    ),
    width: CoreSpace.space240,
  ),
  'definition-list/stacked': () => _box(
    DefinitionList(items: definitionListEntries(definitionListBusinessSamples)),
  ),
  'definition-list/inline': () => DefinitionList(
    items: definitionListEntries(definitionListInlineSamples),
    layout: CoreDefinitionLayout.inline,
  ),
  'definition-list/typography': _typography,
  'definition-list/rich': () => _box(
    DefinitionList(
      items: [
        CoreDefinitionEntry.rich(
          term: '영수증',
          description: Link(href: definitionListReceiptUrl, onPressed: () {}, child: const Text('영수증 보기')),
        ),
        CoreDefinitionEntry.rich(
          term: '배송지',
          description: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final line in definitionListAddressLines) Text(line)],
          ),
        ),
      ],
    ),
  ),
  'definition-list/term-width': () => _box(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefinitionList(
          items: definitionListEntries(definitionListShortTermSamples),
          layout: CoreDefinitionLayout.columns,
          definitionListStyle: definitionListTermWidthStyle,
        ),
        const Gap.space16(),
        const Divider(),
        const Gap.space16(),
        DefinitionList(
          items: definitionListEntries(definitionListWideTermSamples),
          layout: CoreDefinitionLayout.columns,
          definitionListStyle: definitionListTermWidthStyle,
        ),
      ],
    ),
  ),
  'definition-list/do-term': () => _box(
    DefinitionList(items: definitionListEntries(definitionListRegistrationSamples)),
  ),
  'definition-list/dont-one-line': () => _box(const Text(definitionListOneLineText).bodySmall),
  'definition-list/do-long-term': () => _box(
    DefinitionList(items: definitionListEntries(definitionListLongTermSamples)),
    width: CoreSpace.space240,
  ),
  'definition-list/dont-long-term': () => _box(
    DefinitionList(
      items: definitionListEntries(definitionListLongTermSamples),
      layout: CoreDefinitionLayout.columns,
    ),
    width: CoreSpace.space240,
  ),
  'definition-list/do-numeric': () => _box(
    DefinitionList(
      items: definitionListEntries(definitionListDateSamples),
      layout: CoreDefinitionLayout.columns,
      numeric: true,
    ),
    width: CoreSpace.space240,
  ),
  'definition-list/dont-amount': () => _box(
    DefinitionList(
      items: definitionListEntries(definitionListAmountSamples),
      layout: CoreDefinitionLayout.columns,
      numeric: true,
    ),
    width: CoreSpace.space240,
  ),
  'definition-list/related-table': () => _box(
    Table(
      rows: [
        CoreTableRowData<Widget>.header(
          cells: const [
            CoreTableCellData<Widget>(child: Text('주문번호')),
            CoreTableCellData<Widget>(child: Text('상태')),
          ],
        ),
        CoreTableRowData<Widget>(
          cells: const [
            CoreTableCellData<Widget>(child: Text('A-1048')),
            CoreTableCellData<Widget>(child: Text('발송')),
          ],
        ),
      ],
    ),
  ),
  'definition-list/related-description-card': () => _box(
    const DescriptionCard(
      title: '주문 상세',
      rows: [
        DescriptionRow(label: '주문번호', value: 'A-1048-2711'),
        DescriptionRow(label: '합계', value: '39,000원', isEmphasized: true),
      ],
    ),
  ),
  'definition-list/related-text-block': () => _box(const TextBlock(text: '라벨 없이도 읽히는 설명은 문단으로 씁니다.')),
  'definition-list/related-stat': () => const Stat(label: '결제 합계', value: '39,000', unit: '원'),
};

Widget _definitionList(Map<String, String> props, String? label) => _box(
  DefinitionList(
    items: definitionListEntries(definitionListOrderSamples),
    layout: definitionListLayoutOf(props),
    numeric: previewFlag(props, 'numeric'),
    mono: previewFlag(props, 'mono'),
  ),
);

/// 장면의 폭(logical px). 부모가 더 좁으면 부모를 따른다.
Widget _box(Widget child, {double width = CoreSpace.space256}) => SizedBox(width: width, child: child);

/// 기본 · 고정폭 숫자 · 코드 서체를 위에 이름을 달아 세로로 놓는다.
Widget _typography() => _box(
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space24,
    children: [
      for (final sample in definitionListTypographyCases)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [
            Text(sample.caption).labelSmall.onSurfaceVariant,
            DefinitionList(
              items: definitionListEntries(sample.samples),
              layout: CoreDefinitionLayout.columns,
              numeric: sample.numeric,
              mono: sample.mono,
            ),
          ],
        ),
    ],
  ),
);
