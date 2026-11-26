/// Tabs 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `tabs_web.dart` · `tabs_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/tabs.md`.
const String slug = 'tabs';

/// 미리보기 탭의 라벨 — 두 플랫폼 빌더와 코드가 같은 라벨을 쓴다.
const List<String> kTabsPreviewLabels = ['계정', '비밀번호', '알림'];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'variant': 'pill', 'size': 'md'},
  controls: [
    DocsPlaygroundChoice(label: 'variant', prop: 'variant', options: ['pill', 'underline'], segmented: true),
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg'], segmented: true),
    DocsPlaygroundFlag(label: '배지', on: {'badge': '3'}),
    DocsPlaygroundFlag(label: '닫기 버튼', on: {'onClose': 'true'}),
    DocsPlaygroundFlag(label: '비활성 탭', on: {'disabled': '2'}),
    DocsPlaygroundFlag(label: '가로 채우기', on: {'expand': 'true'}),
  ],
  code: _tabsCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _tabsSpec;

String _tabsCode(Map<String, String> props, String? label) {
  final variant = props['variant'] ?? CoreTabVariant.defaultVariant.name;
  final size = props['size'] ?? CoreTabsSize.defaultSize.name;
  final badge = props['badge'];
  final closable = previewFlag(props, 'onClose');
  final disabled = int.tryParse(props['disabled'] ?? '');

  List<String> item(int index, String name) {
    final fields = [
      "label: '$name',",
      if (index == 0 && badge != null)
        'badge: Badge(variant: CoreBadgeVariant.filled, form: CoreBadgeForm.count, '
            "size: CoreComponentSize.xs, child: Text('$badge')),",
      if (index == disabled) 'enabled: false,',
      if (closable) 'onClose: () => closeTab($index),',
    ];
    if (fields.length == 1) return ["CoreTabItem(label: '$name'),"];
    return ['CoreTabItem(', for (final field in fields) '  $field', '),'];
  }

  final constItems = badge == null && !closable;
  final lines = [
    'tabs: ${constItems ? 'const ' : ''}[',
    for (final (index, name) in kTabsPreviewLabels.indexed)
      for (final line in item(index, name)) '  $line',
    '],',
    'selectedIndex: index,',
    if (variant != CoreTabVariant.defaultVariant.name) 'variant: CoreTabVariant.$variant,',
    if (size != CoreTabsSize.defaultSize.name) 'size: CoreTabsSize.$size,',
    if (previewFlag(props, 'expand')) 'expand: true,',
    if (previewFlag(props, 'scrollable')) 'scrollable: true,',
    'onChanged: (i) => setState(() => index = i),',
  ];
  return 'Tabs(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

/// 크기 행마다 바 높이 · pill 탭 높이 · 라벨. 두 변형의 라벨 굵기는 같으므로
/// pill 행에서 읽는다.
DocsSizeSpec _tabsSpec() {
  final pill = CoreTabsStyle.defaultsByVariant[CoreTabVariant.pill]!;
  String label(CoreTextStyle? role, int? weight) =>
      docsSizeLabel(CoreTextStyle(fontSize: docsSizeResolve(role)?.fontSize, fontWeight: weight));
  return DocsSizeSpec(
    columns: const ['size', '바 높이', 'pill 탭 높이', '라벨', '선택된 라벨'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreTabsStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          // 크기 표의 행은 `CoreComponentSize` 로 적는다 — `CoreTabsSize` 는
          // 같은 이름의 세 단계(sm · md · lg)다.
          size: CoreComponentSize.values.byName(size.name),
          cells: [
            docsSizeNumber(row.itemHeight),
            docsSizeNumber(
              CoreTabsStyle.tabHeight(
                rung: row.itemHeight!,
                trackInset: pill.tabBarPadding.top + pill.tabBarPadding.bottom,
                sizeRungIsTrack: pill.sizeRungIsTrack,
              ),
            ),
            label(row.contentTextStyle, pill.inactiveFontWeight),
            label(row.contentTextStyle, pill.activeFontWeight),
          ],
        ),
    ],
  );
}
