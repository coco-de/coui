/// DescriptionCard 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="description-card/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`description_card_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'description_card_page.dart'
    show
        descriptionCardEmptyRows,
        descriptionCardLongValue,
        descriptionCardOrderRows,
        descriptionCardProfileRows,
        descriptionCardSampleTitle;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _descriptionCard;

/// 장면 이름(`description-card/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'description-card/anatomy': () => _frame(
    width: 352,
    DescriptionCard(
      title: '주문 상세',
      titleLeading: const Icon(LucideIcons.info),
      titleTrailing: const Badge(tone: CoreBadgeTone.success, child: Text('결제 완료')),
      rows: const [
        DescriptionRow(label: '메일', value: 'order@example.com', leading: Icon(LucideIcons.mail)),
        DescriptionRow(label: '주문번호', value: 'ORD-00391', trailing: Icon(LucideIcons.copy)),
        DescriptionRow(label: '합계', value: '369,000원', isEmphasized: true),
      ],
      bottomAction: _action('상세 보기'),
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
  // 커스텀 값 위젯은 남은 폭만큼의 자리를 받는다 — 끝에 맞추려면 `Align` 으로 감싼다.
  'description-card/row-slots': () => _frame(
    const DescriptionCard(
      rows: [
        DescriptionRow(label: '메일', value: 'order@example.com', leading: Icon(LucideIcons.mail)),
        DescriptionRow(
          label: '배송 상태',
          valueWidget: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('배송 완료')),
          ),
        ),
        DescriptionRow(label: '주문번호', value: 'ORD-00391', trailing: Icon(LucideIcons.copy)),
        DescriptionRow(label: '합계', value: '369,000원', isEmphasized: true),
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
  'description-card/overflow': () => _tiles(width: 256, [
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
  'description-card/title-action': () => _tiles(width: 288, [
    (
      '제목 슬롯 · 하단 액션',
      DescriptionCard(
        title: '주문 상세',
        titleLeading: const Icon(LucideIcons.info),
        titleTrailing: const Badge(tone: CoreBadgeTone.success, child: Text('완료')),
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
    width: 288,
    const DescriptionCard(
      rows: [
        DescriptionRow(label: '상품', value: '369,000원'),
        DescriptionRow(label: '배송비', value: '3,000원'),
        DescriptionRow(label: '합계', value: '372,000원', isEmphasized: true),
      ],
    ),
  ),
  'description-card/dont-emphasis': () => _frame(
    width: 288,
    const DescriptionCard(
      rows: [
        DescriptionRow(label: '상품', value: '369,000원', isEmphasized: true),
        DescriptionRow(label: '배송비', value: '3,000원', isEmphasized: true),
        DescriptionRow(label: '합계', value: '372,000원', isEmphasized: true),
      ],
    ),
  ),
  'description-card/do-action': () => _frame(
    width: 288,
    DescriptionCard(title: '구독', rows: _rows(_planRows), bottomAction: _action('요금제 변경')),
  ),
  'description-card/dont-action': () => _frame(
    width: 288,
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
  'description-card/related-card': () => SizedBox(
    width: 192,
    child: Card(
      variant: CoreCardVariant.outlined,
      header: const Text('배송 안내').titleSmall,
      body: const Text('자유롭게 채우는 상자').bodySmall.onSurfaceVariant,
    ),
  ),
  'description-card/related-stat': () => const SizedBox(
    width: 192,
    child: Stat(label: '이번 달 주문', value: '1,240'),
  ),
  'description-card/related-table': () => SizedBox(
    width: 192,
    child: Table(
      rows: [
        CoreTableRowData<Widget>.header(
          cells: [
            CoreTableCellData<Widget>(child: const Text('주문')),
            CoreTableCellData<Widget>(child: const Text('금액')),
          ],
        ),
        for (final (order, amount) in const [('A-001', '12,000원'), ('A-002', '8,500원')])
          CoreTableRowData<Widget>(
            cells: [
              CoreTableCellData<Widget>(child: Text(order)),
              CoreTableCellData<Widget>(child: Text(amount)),
            ],
          ),
      ],
    ),
  ),
  'description-card/related-definition-list': () => const SizedBox(
    width: 192,
    child: DefinitionList(
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

Widget _descriptionCard(Map<String, String> props, String? label) {
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
Widget _action(String label) => Button(
  variant: CoreButtonVariant.outline,
  expanded: true,
  onPressed: () {},
  child: Text(label),
);

/// 장면 하나의 폭에 상한을 둔다 — 자리가 더 좁으면 그 폭을 따른다.
Widget _frame(Widget child, {double width = 320}) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: width),
  child: child,
);

/// 이름표를 아래에 단 카드 여럿을 나란히 놓는다 — 좁으면 다음 줄로 내려간다.
Widget _tiles(List<(String, Widget)> tiles, {double width = 240}) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space16,
  runSpacing: CoreSpace.space24,
  children: [
    for (final (caption, card) in tiles)
      SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [card, Text(caption).labelSmall.onSurfaceVariant],
        ),
      ),
  ],
);
