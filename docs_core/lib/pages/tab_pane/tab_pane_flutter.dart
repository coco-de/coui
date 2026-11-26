/// TabPane 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="tab-pane/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`tab_pane_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'tab_pane_page.dart';

/// 속성 → Widget.
///
/// 선택 · 닫기 · 순서는 눌러야 바뀌므로 빌더가 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _TabPanePreview(props: props);

/// 장면 이름(`tab-pane/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'tab-pane/anatomy': () => _framed(
    kTabPaneAnatomyWidth,
    TabPane(
      tabs: [
        CoreTabItem(
          label: kTabPaneAnatomyLabels[0],
          leading: Icon(LucideIcons.file),
          badge: _countBadge('2'),
          onClose: () {},
          content: const _Panel('문서 설정이 여기에 옵니다.'),
        ),
        CoreTabItem(label: kTabPaneAnatomyLabels[1], content: const _Panel('일반 설정이 여기에 옵니다.')),
        CoreTabItem(label: kTabPaneAnatomyLabels[2], content: const _Panel('선택한 탭의 내용이 여기에 옵니다.')),
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
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const _EditorBody(),
      ],
    ),
  ),
  'tab-pane/badge': () => _framed(
    kTabPaneWideWidth,
    TabPane(
      tabs: [
        CoreTabItem(label: '받은편지함', badge: _countBadge('3'), content: const _Panel('읽지 않은 메일이 세 통 있어요.')),
        const CoreTabItem(label: '보낸편지함', content: _Panel('보낸 메일을 모아 둬요.')),
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
    Wrap(
      children: [
        for (final file in kTabPanePreviewFiles)
          Button(variant: CoreButtonVariant.ghost, size: CoreComponentSize.sm, onPressed: () {}, child: Text(file)),
      ],
    ),
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
        for (final label in kTabPaneScrollLabels) CoreTabItem(label: label, content: _Panel('$label 설정이에요.')),
      ],
      selectedIndex: 0,
      onChanged: (_) {},
    ),
  ),
  'tab-pane/related-tabs': () => _framed(
    kTabPaneRelatedWidth,
    Tabs.labels(labels: const ['개요', '리뷰'], selectedIndex: 0, onChanged: (_) {}),
  ),
  'tab-pane/related-accordion': () => const SizedBox(
    width: kTabPaneRelatedWidth,
    child: Accordion(
      items: [
        AccordionItem(title: '배송은 얼마나 걸리나요?', content: Text('보통 2~3일 걸려요.'), expanded: true),
        AccordionItem(title: '환불할 수 있나요?', content: Text('30일 안에 요청할 수 있어요.')),
      ],
    ),
  ),
};

/// 장면의 폭을 [width] 로 정한다. 무대가 더 좁으면 무대 폭까지 줄어든다.
Widget _framed(double width, Widget child) => SizedBox(width: width, child: child);

Widget _countBadge(String count) => Badge(
  variant: CoreBadgeVariant.filled,
  form: CoreBadgeForm.count,
  size: CoreComponentSize.xs,
  child: Text(count),
);

/// `boxed` 미리보기 탭 앞의 [count] 개 — 탭마다 패널 글이 있다.
List<CoreTabItem<Widget>> _settingTabs(int count) => [
  for (var i = 0; i < count; i++)
    CoreTabItem(label: kTabPanePreviewLabels[i], content: _Panel(kTabPanePreviewContents[i])),
];

/// 파일 탭 앞의 [count] 개 — 패널 글이 없다.
List<CoreTabItem<Widget>> _fileTabs(int count) => [
  for (final file in kTabPanePreviewFiles.take(count)) CoreTabItem(label: file),
];

/// 바 뒤의 추가 버튼. Flutter 바는 앞뒤 위젯을 바 높이로 늘리므로 가운데에 놓는다.
Widget _addButton() => Center(
  child: Semantics(
    button: true,
    label: kTabPaneAddLabel,
    child: Button(
      variant: CoreButtonVariant.ghost,
      size: CoreComponentSize.sm,
      shape: CoreButtonShape.square,
      onPressed: () {},
      child: Icon(LucideIcons.plus),
    ),
  ),
);

/// 상태 장면 — Web 과 같은 네 예시.
Widget _tabPaneStates() {
  final examples = <(String, Widget)>[
    (
      'boxed',
      TabPane(
        tabs: const [
          CoreTabItem(label: '선택됨', content: _Panel('선택한 탭의 내용이에요.')),
          CoreTabItem(label: '기본'),
          CoreTabItem(label: '비활성', enabled: false),
        ],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
    ),
    (
      'boxed — 선택한 탭이 비활성',
      TabPane(
        tabs: const [
          CoreTabItem(label: '선택됨 · 비활성', enabled: false, content: _Panel('선택한 탭의 내용이에요.')),
          CoreTabItem(label: '기본'),
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
      const TabPane(
        tabs: [
          CoreTabItem(label: '선택됨', content: _Panel('선택한 탭의 내용이에요.')),
          CoreTabItem(label: '기본'),
        ],
        selectedIndex: 0,
      ),
    ),
  ];
  return _framed(
    kTabPanePreviewWidth,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, example) in examples.indexed) ...[
          if (index > 0) const Gap.space24(),
          Text(example.$1).labelSmall.onSurfaceVariant,
          const Gap.space8(),
          example.$2,
        ],
      ],
    ),
  );
}

/// 패널 글 — `space20` 여백 안의 설명 한 줄.
class _Panel extends StatelessWidget {
  const _Panel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
    child: Text(text).bodyMedium.onSurfaceVariant,
  );
}

/// 편집기 본문 — TabPane 이 아니라 호출자가 그리는 자리.
class _EditorBody extends StatelessWidget {
  const _EditorBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.resolve(const CoreColor.token(CoreColors.surface)).toValue(),
      child: Padding(
        padding: const CoreEdgeInsets.all(CoreSpace.space12).toValue(geometry: theme.geometry),
        child: const Text(kTabPaneEditorBody).codeSm.onSurface,
      ),
    );
  }
}

/// 속성으로 그리는 탭 카드 · 탭 줄 — 선택, 닫은 탭, 바꾼 순서를 기억한다.
///
/// 속성: `variant` 와 `reorderable` 은 위젯 속성 그대로, `selectedIndex` 는 처음
/// 선택, `itemLeading` · `badge` · `onClose` · `disabled` 는 탭에 붙는다.
class _TabPanePreview extends StatefulWidget {
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
  void didUpdateWidget(covariant _TabPanePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameProps(oldWidget.props, widget.props)) _reset();
  }

  void _reset() {
    _order = [for (var i = 0; i < kTabPanePreviewLabels.length; i++) i];
    _selected = (int.tryParse(widget.props['selectedIndex'] ?? '') ?? 0).clamp(0, _order.length - 1);
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

  void _handleReorder(List<CoreTabItem<Widget>> next) {
    final labels = tabPanePreviewLabels(tabPanePreviewVariant(widget.props));
    setState(() => _order = [for (final tab in next) labels.indexOf(tab.label)]);
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
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
              content: _Panel(kTabPanePreviewContents[original]),
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
