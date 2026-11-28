/// DescriptionCard 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="description-card/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`description_card_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'description_card_page.dart'
    show
        descriptionCardEmptyRows,
        descriptionCardLongValue,
        descriptionCardOrderRows,
        descriptionCardProfileRows,
        descriptionCardSampleTitle;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _descriptionCard;

/// 장면 이름(`description-card/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 슬롯에 넣는 아이콘 · 배지 · 버튼에는 번호가 찾을 표지를 단다.
  // 폭은 좁은 화면에서도 번호 자리가 남도록 화면 폭에서 뺀 값으로 막는다.
  'description-card/anatomy': () => _frame(
    width: 'min(22rem, calc(100vw - 8rem))',
    DescriptionCard(
      title: '주문 상세',
      titleLeading: const Icon(LucideIcons.info),
      titleTrailing: Badge(
        tone: CoreBadgeTone.success,
        attributes: const {'data-docs-part': 'title-trailing'},
        child: const Text('결제 완료'),
      ),
      rows: const [
        DescriptionRow(
          label: '메일',
          value: 'order@example.com',
          leading: Icon(LucideIcons.mail, attributes: {'data-docs-part': 'row-leading'}),
        ),
        DescriptionRow(
          label: '주문번호',
          value: 'ORD-00391',
          trailing: Icon(LucideIcons.copy, attributes: {'data-docs-part': 'row-trailing'}),
        ),
        DescriptionRow(label: '합계', value: '369,000원', isEmphasized: true),
      ],
      bottomAction: Button(
        variant: CoreButtonVariant.outline,
        expanded: true,
        onPressed: () {},
        attributes: const {'data-docs-part': 'bottom-action'},
        child: const Text('상세 보기'),
      ),
    ),
  ),
  'description-card/variants': () => _tiles([
    for (final variant in CoreDescriptionCardVariant.values)
      (
        variant.name,
        DescriptionCard(variant: variant, title: '멤버십', rows: _rows(descriptionCardProfileRows)),
      ),
  ]),
  'description-card/sizes': () => _tiles([
    for (final size in CoreDescriptionCardSize.values)
      (size.name, DescriptionCard(size: size, title: '멤버십', rows: _rows(descriptionCardProfileRows))),
  ]),
  'description-card/layouts': () => _tiles([
    for (final layout in CoreDescriptionCardLayout.values)
      (layout.name, DescriptionCard(layout: layout, rows: _rows(descriptionCardProfileRows))),
  ]),
  'description-card/alignment': () => _tiles([
    ('fixed (기본값)', DescriptionCard(rows: _rows(descriptionCardProfileRows))),
    (
      'fixed · valueTextAlign start',
      DescriptionCard(
        rows: _rows(descriptionCardProfileRows),
        descriptionCardStyle: const CoreDescriptionCardStyle(valueTextAlign: CoreTextAlign.start),
      ),
    ),
    (
      'spaceBetween',
      DescriptionCard(
        alignment: CoreDescriptionCardAlignment.spaceBetween,
        rows: _rows(descriptionCardProfileRows),
      ),
    ),
  ]),
  'description-card/row-slots': () => _frame(
    DescriptionCard(
      rows: [
        const DescriptionRow(label: '메일', value: 'order@example.com', leading: Icon(LucideIcons.mail)),
        DescriptionRow(
          label: '배송 상태',
          valueWidget: Badge(tone: CoreBadgeTone.success, showDot: true, child: const Text('배송 완료')),
        ),
        const DescriptionRow(label: '주문번호', value: 'ORD-00391', trailing: Icon(LucideIcons.copy)),
        const DescriptionRow(label: '합계', value: '369,000원', isEmphasized: true),
      ],
    ),
  ),
  'description-card/empty': () => _tiles([
    ('hide (기본값)', DescriptionCard(rows: _rows(descriptionCardEmptyRows))),
    (
      'placeholder',
      DescriptionCard(
        emptyValueBehavior: CoreDescriptionCardEmptyBehavior.placeholder,
        emptyPlaceholder: '정보 없음',
        rows: _rows(descriptionCardEmptyRows),
      ),
    ),
  ]),
  'description-card/overflow': () => _tiles(width: '16rem', [
    for (final overflow in CoreDescriptionCardOverflow.values)
      (
        overflow.name,
        DescriptionCard(
          valueOverflow: overflow,
          rows: const [
            DescriptionRow(label: '주소', value: descriptionCardLongValue),
            DescriptionRow(label: '상태', value: '보관 중'),
          ],
        ),
      ),
  ]),
  'description-card/row-weight': () => _tiles([
    for (final weight in CoreDescriptionCardRowWeight.values)
      (weight.name, DescriptionCard(rowWeight: weight, rows: _rows(descriptionCardProfileRows))),
  ]),
  'description-card/title-action': () => _tiles(width: '18rem', [
    (
      '제목 슬롯 · 하단 액션',
      DescriptionCard(
        title: '주문 상세',
        titleLeading: const Icon(LucideIcons.info),
        titleTrailing: Badge(tone: CoreBadgeTone.success, child: const Text('완료')),
        rows: _rows(_receiptRows),
        bottomAction: _action('영수증 보기'),
      ),
    ),
    (
      '구분선 끄기',
      DescriptionCard(
        title: '주문 상세',
        showDivider: false,
        showRowDividers: false,
        showBottomActionDivider: false,
        rows: _rows(_receiptRows),
        bottomAction: _action('영수증 보기'),
      ),
    ),
  ]),
  'description-card/states': () => _tiles([
    ('표시용', DescriptionCard(title: '멤버십', rows: _rows(descriptionCardProfileRows))),
    ('onTap', DescriptionCard(title: '멤버십', onTap: () {}, rows: _rows(descriptionCardProfileRows))),
    (
      'onTap · enabled false',
      DescriptionCard(title: '멤버십', onTap: () {}, enabled: false, rows: _rows(descriptionCardProfileRows)),
    ),
  ]),
  // 누를 수 있는 행은 세로 레이아웃으로 보인다 — 라벨과 값이 위아래로 놓인다.
  'description-card/row-tap': () => _frame(
    DescriptionCard(
      layout: CoreDescriptionCardLayout.vertical,
      rows: [
        DescriptionRow(label: '배송지', value: '중구 예시로 123', onTap: () {}),
        DescriptionRow(label: '결제 수단', value: '계좌 이체', onTap: () {}),
        const DescriptionRow(label: '합계', value: '369,000원'),
      ],
    ),
  ),
  'description-card/do-emphasis': () => _frame(
    width: '18rem',
    const DescriptionCard(
      rows: [
        DescriptionRow(label: '상품', value: '369,000원'),
        DescriptionRow(label: '배송비', value: '3,000원'),
        DescriptionRow(label: '합계', value: '372,000원', isEmphasized: true),
      ],
    ),
  ),
  'description-card/dont-emphasis': () => _frame(
    width: '18rem',
    const DescriptionCard(
      rows: [
        DescriptionRow(label: '상품', value: '369,000원', isEmphasized: true),
        DescriptionRow(label: '배송비', value: '3,000원', isEmphasized: true),
        DescriptionRow(label: '합계', value: '372,000원', isEmphasized: true),
      ],
    ),
  ),
  'description-card/do-action': () => _frame(
    width: '18rem',
    DescriptionCard(title: '구독', rows: _rows(_planRows), bottomAction: _action('요금제 변경')),
  ),
  'description-card/dont-action': () => _frame(
    width: '18rem',
    DescriptionCard(title: '구독', onTap: () {}, rows: _rows(_planRows), bottomAction: _action('요금제 변경')),
  ),
  'description-card/styled': () => _frame(
    const DescriptionCard(
      rows: [
        DescriptionRow(label: '상품', value: '369,000원'),
        DescriptionRow(label: '합계', value: '372,000원', isEmphasized: true),
      ],
      descriptionCardStyle: CoreDescriptionCardStyle(
        borderColor: CoreColor.token(CoreColors.primary),
        rowPadding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space12),
        labelTextStyle: CoreTextStyle(fontSize: CoreFontSize.s12),
        emphasizedValueTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.primaryText)),
      ),
    ),
  ),
  'description-card/related-card': () => _frame(
    width: '12rem',
    Card(
      variant: CoreCardVariant.outlined,
      header: const Text('배송 안내').titleSmall,
      body: const Text('자유롭게 채우는 상자').bodySmall.onSurfaceVariant,
    ),
  ),
  'description-card/related-stat': () => _frame(
    width: '12rem',
    const Stat(label: '이번 달 주문', value: '1,240'),
  ),
  'description-card/related-table': () => _frame(
    width: '12rem',
    Table(
      rows: [
        CoreTableRowData<Component>.header(
          cells: [
            CoreTableCellData<Component>(child: const Text('주문')),
            CoreTableCellData<Component>(child: const Text('금액')),
          ],
        ),
        for (final (order, amount) in const [('A-001', '12,000원'), ('A-002', '8,500원')])
          CoreTableRowData<Component>(
            cells: [
              CoreTableCellData<Component>(child: Text(order)),
              CoreTableCellData<Component>(child: Text(amount)),
            ],
          ),
      ],
    ),
  ),
  'description-card/related-definition-list': () => _frame(
    width: '12rem',
    const DefinitionList(
      items: [
        CoreDefinitionEntry(term: '업종', description: '서비스'),
        CoreDefinitionEntry(term: '지역', description: '서울'),
      ],
    ),
  ),
};

/// 하단 액션이 있는 장면의 영수증 행.
const List<(String, String)> _receiptRows = [('상품', 'AirPods'), ('합계', '369,000원')];

/// 누를 곳을 고르는 장면의 구독 행.
const List<(String, String)> _planRows = [('요금제', '월간'), ('다음 결제', '12월 1일')];

Component _descriptionCard(Map<String, String> props, String? label) {
  final emphasize = previewFlag(props, 'emphasize');
  return DescriptionCard(
    variant: previewEnum(CoreDescriptionCardVariant.values, props['variant'], CoreDescriptionCardVariant.outlined),
    size: previewEnum(CoreDescriptionCardSize.values, props['size'], CoreDescriptionCardSize.md),
    layout: previewEnum(CoreDescriptionCardLayout.values, props['layout'], CoreDescriptionCardLayout.horizontal),
    title: previewFlag(props, 'title') ? label ?? descriptionCardSampleTitle : null,
    showRowDividers: previewFlag(props, 'showRowDividers', fallback: true),
    emptyValueBehavior: previewFlag(props, 'placeholder')
        ? CoreDescriptionCardEmptyBehavior.placeholder
        : CoreDescriptionCardEmptyBehavior.hide,
    rows: [
      for (final (index, (name, value)) in descriptionCardOrderRows.indexed)
        DescriptionRow(
          label: name,
          value: value,
          isEmphasized: emphasize && index == descriptionCardOrderRows.length - 1,
        ),
    ],
    bottomAction: previewFlag(props, 'bottomAction') ? _action('상세 보기') : null,
  );
}

/// (라벨, 값) 목록 → 행 데이터.
List<DescriptionRow> _rows(List<(String, String?)> rows) => [
  for (final (label, value) in rows) DescriptionRow(label: label, value: value),
];

/// 카드 폭을 채우는 하단 액션 버튼.
Component _action(String label) => Button(
  variant: CoreButtonVariant.outline,
  expanded: true,
  onPressed: () {},
  child: Text(label),
);

/// 장면 하나를 정해 둔 폭에 놓는다. 세로 flex 상자라 누를 수 있는 카드도 폭을
/// 채운다.
Component _frame(Component child, {String width = 'min(20rem, 100%)'}) => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'width': width, 'max-width': '100%'},
  ),
  [child],
);

/// 이름표를 아래에 단 카드 여럿을 나란히 놓는다 — 좁으면 다음 줄로 내려간다.
Component _tiles(List<(String, Component)> tiles, {String width = '15rem'}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': 'var(--coui-space-24) var(--coui-space-16)',
      'width': '100%',
    },
  ),
  [
    for (final (caption, card) in tiles)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'gap': 'var(--coui-space-8)',
            'width': 'min($width, 100%)',
          },
        ),
        [card, Text(caption).labelSmall.onSurfaceVariant],
      ),
  ],
);
