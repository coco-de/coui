/// DefinitionList 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="definition-list/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`definition_list_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Web 의 `columns` 목록은 가운데 정렬 무대에서 내용 폭이 되고 Flutter 는 받은
/// 폭을 채운다. 두 플랫폼이 같게 보이도록 장면은 폭을 정한 상자 안에 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'definition_list_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _definitionList;

/// 장면 이름(`definition-list/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 상자를 두르지 않고 목록에 폭을 준다. 번호가 `<dl>` 을 바로 가리키고,
  // 좁은 화면에서는 번호 자리를 남기고 줄어든다.
  'definition-list/anatomy': () => DefinitionList(
    items: definitionListEntries(definitionListAnatomySamples),
    layout: CoreDefinitionLayout.columns,
    // 설명 칸이 글보다 넓으면 구조 번호가 빈자리를 가리키므로 폭을 좁게 둔다.
    css: const Styles(raw: {'width': 'min(10rem, calc(100vw - 8rem))'}),
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
          description: div(classes: '${WebLayout.flex} ${WebLayout.flexCol}', [
            for (final line in definitionListAddressLines) Text(line),
          ]),
        ),
      ],
    ),
  ),
  'definition-list/term-width': () => _box(
    div(classes: '${WebLayout.flex} ${WebLayout.flexCol}', [
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
    ]),
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
        CoreTableRowData<Component>.header(
          cells: [
            CoreTableCellData<Component>(child: Text('주문번호')),
            CoreTableCellData<Component>(child: Text('상태')),
          ],
        ),
        CoreTableRowData<Component>(
          cells: [
            CoreTableCellData<Component>(child: Text('A-1048')),
            CoreTableCellData<Component>(child: Text('발송')),
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

Component _definitionList(Map<String, String> props, String? label) => _box(
  DefinitionList(
    items: definitionListEntries(definitionListOrderSamples),
    layout: definitionListLayoutOf(props),
    numeric: previewFlag(props, 'numeric'),
    mono: previewFlag(props, 'mono'),
  ),
);

/// 장면의 폭(logical px). 부모가 더 좁으면 부모를 따른다.
Component _box(Component child, {double width = CoreSpace.space256}) => div(
  styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}),
  [child],
);

/// 기본 · 고정폭 숫자 · 코드 서체를 위에 이름을 달아 세로로 놓는다.
Component _typography() => _box(
  div(classes: '${WebLayout.flex} ${WebLayout.flexCol}', [
    for (final (index, sample) in definitionListTypographyCases.indexed) ...[
      if (index > 0) const Gap.space24(),
      Text(sample.caption).labelSmall.onSurfaceVariant,
      const Gap.space8(),
      DefinitionList(
        items: definitionListEntries(sample.samples),
        layout: CoreDefinitionLayout.columns,
        numeric: sample.numeric,
        mono: sample.mono,
      ),
    ],
  ]),
);
