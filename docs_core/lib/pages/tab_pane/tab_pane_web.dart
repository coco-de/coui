/// TabPane 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="tab-pane/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`tab_pane_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'tab_pane_page.dart';

/// 속성 → Component.
///
/// 선택 · 닫기 · 순서는 눌러야 바뀌므로 빌더가 기억한다. 서버에서 그리는
/// 블록에서는 처음 상태만 보이고, 브라우저에서 깨어나는 플레이그라운드에서는
/// 탭을 누르고 닫고 끌 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _TabPanePreview(props: props);

/// 장면 이름(`tab-pane/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'tab-pane/anatomy': () => _framed(
    kTabPaneAnatomyWidth,
    TabPane(
      tabs: [
        CoreTabItem(
          label: kTabPaneAnatomyLabels[0],
          leading: Icon(LucideIcons.file),
          // `data-docs-part` 는 구조 번호가 이 자리를 찾는 표지다.
          badge: span(
            attributes: const {'data-docs-part': 'badge'},
            styles: Styles(raw: {'display': 'inline-flex'}),
            [_countBadge('2')],
          ),
          onClose: () {},
          content: _panel('문서 설정이 여기에 옵니다.'),
        ),
        CoreTabItem(label: kTabPaneAnatomyLabels[1], content: _panel('일반 설정이 여기에 옵니다.')),
        CoreTabItem(label: kTabPaneAnatomyLabels[2], content: _panel('선택한 탭의 내용이 여기에 옵니다.')),
      ],
      selectedIndex: 2,
      onChanged: (_) {},
    ),
  ),
  'tab-pane/variant-boxed': () => _framed(
    kTabPaneVariantRowWidth,
    TabPane(tabs: _settingTabs(2), selectedIndex: 0, onChanged: (_) {}),
  ),
  'tab-pane/variant-editor-strip': () => _framed(
    kTabPaneVariantRowWidth,
    TabPane(
      variant: CoreTabPaneVariant.editorStrip,
      tabs: _fileTabs(2),
      selectedIndex: 0,
      onChanged: (_) {},
    ),
  ),
  'tab-pane/editor-strip': () => _framed(
    kTabPaneWideWidth,
    div(classes: '${WebLayout.flex} ${WebLayout.flexCol}', [
      TabPane(
        variant: CoreTabPaneVariant.editorStrip,
        tabs: [
          for (final file in kTabPanePreviewFiles)
            CoreTabItem(label: file, leading: Icon(LucideIcons.file), onClose: () {}),
        ],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
      // 편집기 본문은 TabPane 이 아니라 호출자가 그린다.
      div(
        classes: 'p-${CoreSpace.scale.space12}',
        styles: Styles(raw: {'background-color': const CoreColor.token(CoreColors.surface).toValue()}),
        [const Text(kTabPaneEditorBody).codeSm.onSurface],
      ),
    ]),
  ),
  'tab-pane/badge': () => _framed(
    kTabPaneWideWidth,
    TabPane(
      tabs: [
        CoreTabItem(label: '받은편지함', badge: _countBadge('3'), content: _panel('읽지 않은 메일이 세 통 있어요.')),
        CoreTabItem(label: '보낸편지함', content: _panel('보낸 메일을 모아 둬요.')),
      ],
      selectedIndex: 0,
      onChanged: (_) {},
    ),
  ),
  'tab-pane/slots': () => _framed(
    kTabPaneWideWidth,
    TabPane(
      variant: CoreTabPaneVariant.editorStrip,
      tabs: [
        CoreTabItem(label: 'main.dart', leading: Icon(LucideIcons.file), onClose: () {}),
        CoreTabItem(
          label: 'pubspec.lock',
          leading: Icon(LucideIcons.file),
          trailing: Icon(LucideIcons.lock),
          onClose: () {},
        ),
        CoreTabItem(label: 'README.md', onClose: () {}),
      ],
      selectedIndex: 1,
      onChanged: (_) {},
    ),
  ),
  'tab-pane/states': _tabPaneStates,
  'tab-pane/do-content': () => _framed(
    kTabPaneCardWidth,
    TabPane(tabs: _settingTabs(2), selectedIndex: 0, onChanged: (_) {}),
  ),
  'tab-pane/dont-empty-content': () => _framed(
    kTabPaneCardWidth,
    TabPane(tabs: _fileTabs(2), selectedIndex: 0, onChanged: (_) {}),
  ),
  'tab-pane/do-editor-strip': () => _framed(
    kTabPaneCardWidth,
    TabPane(
      variant: CoreTabPaneVariant.editorStrip,
      tabs: _fileTabs(3),
      selectedIndex: 0,
      onChanged: (_) {},
    ),
  ),
  'tab-pane/dont-button-strip': () => _framed(
    kTabPaneCardWidth,
    div(classes: '${WebLayout.flex} flex-wrap', [
      for (final file in kTabPanePreviewFiles)
        Button(variant: CoreButtonVariant.ghost, size: CoreComponentSize.sm, onPressed: () {}, child: Text(file)),
    ]),
  ),
  'tab-pane/placement-actions': () => _framed(
    kTabPaneCardWidth,
    TabPane(
      variant: CoreTabPaneVariant.editorStrip,
      tabs: _fileTabs(2),
      selectedIndex: 0,
      onChanged: (_) {},
      trailing: [_addButton()],
    ),
  ),
  'tab-pane/placement-scroll': () => _framed(
    kTabPaneScrollWidth,
    TabPane(
      tabs: [
        for (final label in kTabPaneScrollLabels) CoreTabItem(label: label, content: _panel('$label 설정이에요.')),
      ],
      selectedIndex: 0,
      onChanged: (_) {},
    ),
  ),
  'tab-pane/related-tabs': () => _framed(
    kTabPaneRelatedWidth,
    Tabs.labels(labels: const ['개요', '리뷰'], selectedIndex: 0, onChanged: (_) {}),
  ),
  'tab-pane/related-accordion': () => _framed(
    kTabPaneRelatedWidth,
    Accordion(
      items: [
        AccordionItem(title: '배송은 얼마나 걸리나요?', content: const Text('보통 2~3일 걸려요.'), expanded: true),
        AccordionItem(title: '환불할 수 있나요?', content: const Text('30일 안에 요청할 수 있어요.')),
      ],
    ),
  ),
};

/// 장면의 폭을 [width] 로 정한다. 무대가 더 좁으면 무대 폭까지 줄어든다.
Component _framed(double width, Component child) =>
    div(styles: Styles(raw: {'width': '${width / 16}rem', 'max-width': '100%'}), [child]);

/// 패널 글 — `space20` 여백 안의 설명 한 줄.
Component _panel(String text) => div(classes: 'p-${CoreSpace.scale.space20}', [Text(text).bodyMedium.onSurfaceVariant]);

Component _countBadge(String count) => Badge(
  variant: CoreBadgeVariant.filled,
  form: CoreBadgeForm.count,
  size: CoreComponentSize.xs,
  child: Text(count),
);

/// `boxed` 미리보기 탭 앞의 [count] 개 — 탭마다 패널 글이 있다.
List<CoreTabItem<Component>> _settingTabs(int count) => [
  for (var i = 0; i < count; i++)
    CoreTabItem(label: kTabPanePreviewLabels[i], content: _panel(kTabPanePreviewContents[i])),
];

/// 파일 탭 앞의 [count] 개 — 패널 글이 없다.
List<CoreTabItem<Component>> _fileTabs(int count) => [
  for (final file in kTabPanePreviewFiles.take(count)) CoreTabItem(label: file),
];

/// 바 뒤의 추가 버튼. Web 바는 높이를 정한 버튼을 늘리지 않아 위에 붙으므로,
/// 가운데 맞춤 상자로 감싼다. 상자는 높이를 정하지 않아 바 높이로 늘어난다.
Component _addButton() => div(classes: '${WebLayout.flex} ${WebLayout.itemsCenter}', [
  Button(
    variant: CoreButtonVariant.ghost,
    size: CoreComponentSize.sm,
    shape: CoreButtonShape.square,
    attributes: const {'aria-label': kTabPaneAddLabel},
    onPressed: () {},
    child: Icon(LucideIcons.plus),
  ),
]);

/// 상태 장면 — 선택 · 기본 · 비활성 탭, 선택한 탭이 비활성인 카드, 탭 줄,
/// `onChanged` 가 없는 카드. 눌림과 키보드 포커스는 브라우저가 입력 없이 켤 수
/// 없어 표의 설명으로 대신한다.
Component _tabPaneStates() {
  final examples = <(String, Component)>[
    (
      'boxed',
      TabPane(
        tabs: [
          CoreTabItem(label: '선택됨', content: _panel('선택한 탭의 내용이에요.')),
          const CoreTabItem(label: '기본'),
          const CoreTabItem(label: '비활성', enabled: false),
        ],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
    ),
    (
      'boxed — 선택한 탭이 비활성',
      TabPane(
        tabs: [
          CoreTabItem(label: '선택됨 · 비활성', enabled: false, content: _panel('선택한 탭의 내용이에요.')),
          const CoreTabItem(label: '기본'),
        ],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
    ),
    (
      'editorStrip',
      TabPane(
        variant: CoreTabPaneVariant.editorStrip,
        tabs: const [
          CoreTabItem(label: 'main.dart'),
          CoreTabItem(label: 'app.dart'),
          CoreTabItem(label: 'lock.dart', enabled: false),
        ],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
    ),
    (
      'onChanged 없음',
      TabPane(
        tabs: [
          CoreTabItem(label: '선택됨', content: _panel('선택한 탭의 내용이에요.')),
          const CoreTabItem(label: '기본'),
        ],
        selectedIndex: 0,
      ),
    ),
  ];
  return _framed(
    kTabPanePreviewWidth,
    div(classes: '${WebLayout.flex} ${WebLayout.flexCol}', [
      for (final (index, example) in examples.indexed) ...[
        if (index > 0) Gap.space24(),
        Text(example.$1).labelSmall.onSurfaceVariant,
        Gap.space8(),
        example.$2,
      ],
    ]),
  );
}

/// 속성으로 그리는 탭 카드 · 탭 줄 — 선택, 닫은 탭, 바꾼 순서를 기억한다.
///
/// 속성: `variant` 와 `reorderable` 은 위젯 속성 그대로, `selectedIndex` 는 처음
/// 선택, `itemLeading` · `badge` · `onClose` · `disabled` 는 탭에 붙는다.
class _TabPanePreview extends StatefulComponent {
  const _TabPanePreview({required this.props});

  final Map<String, String> props;

  @override
  State<_TabPanePreview> createState() => _TabPanePreviewState();
}

class _TabPanePreviewState extends State<_TabPanePreview> {
  /// 지금 보이는 순서의 탭 — 값은 처음 목록의 자리다.
  late List<int> _order;

  /// 선택한 탭의 처음 자리. 순서가 바뀌어도 같은 탭을 가리킨다.
  late int _selected;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateComponent(covariant _TabPanePreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!_sameProps(oldComponent.props, component.props)) _reset();
  }

  void _reset() {
    _order = [for (var i = 0; i < kTabPanePreviewLabels.length; i++) i];
    _selected = (int.tryParse(component.props['selectedIndex'] ?? '') ?? 0).clamp(0, _order.length - 1);
  }

  void _handleChanged(int index) => setState(() => _selected = _order[index]);

  void _handleClose(int original) {
    setState(() {
      final position = _order.indexOf(original);
      _order.removeAt(position);
      if (_order.isEmpty) {
        // 마지막 탭을 닫으면 처음 상태로 돌아간다 — 미리보기가 비지 않게.
        _reset();
      } else if (original == _selected) {
        _selected = _order[position.clamp(0, _order.length - 1)];
      }
    });
  }

  void _handleReorder(List<CoreTabItem<Component>> next) {
    final labels = tabPanePreviewLabels(tabPanePreviewVariant(component.props));
    setState(() => _order = [for (final tab in next) labels.indexOf(tab.label)]);
  }

  @override
  Component build(BuildContext context) {
    final props = component.props;
    final variant = tabPanePreviewVariant(props);
    final labels = tabPanePreviewLabels(variant);
    final leading = previewFlag(props, 'itemLeading');
    final badge = props['badge'];
    final closable = previewFlag(props, 'onClose');
    final disabled = int.tryParse(props['disabled'] ?? '');
    final reorderable = previewFlag(props, 'reorderable');
    return _framed(
      kTabPanePreviewWidth,
      TabPane(
        variant: variant,
        tabs: [
          for (final original in _order)
            CoreTabItem(
              label: labels[original],
              leading: leading ? Icon(LucideIcons.file) : null,
              badge: original == 0 && badge != null ? _countBadge(badge) : null,
              enabled: original != disabled,
              onClose: closable ? () => _handleClose(original) : null,
              content: _panel(kTabPanePreviewContents[original]),
            ),
        ],
        selectedIndex: _order.indexOf(_selected),
        onChanged: _handleChanged,
        reorderable: reorderable,
        onReorder: reorderable ? _handleReorder : null,
      ),
    );
  }
}

bool _sameProps(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((entry) => b[entry.key] == entry.value);
