/// 블록 마크다운(헤딩 / 문단 / 표 / 코드 / 리스트 …) → 위젯 워커.
library;

import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_document.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_app/src/markdown/inline_renderer.dart';
import 'package:docs_core/internal/preview/native_paragraph_body.dart';
import 'package:markdown/markdown.dart' as md;

/// 표 한 칸이 줄어들 수 있는 하한. 이보다 좁아지면 가로 스크롤이 열린다.
const _kMinTableColumnWidth = 132.0;

/// 코드 펜스에 언어 표시가 없을 때의 기본 모드.
const _kDefaultCodeMode = 'dart';

/// 마크다운 본문을 블록 위젯 리스트로 만든다.
///
/// 커스텀 태그는 파서에 넣기 전에 원본에서 먼저 떼어낸다. 마크다운 파서의
/// HTML 블록은 빈 줄에서 끊기기 때문에 (`<Tabs>` 여는 줄 / 안쪽 마크다운 /
/// `</Tabs>` 닫는 줄이 서로 다른 노드로 흩어진다), 노드를 다 만든 뒤에는
/// 태그의 안쪽 마크다운을 원본 그대로 복원할 수 없다.
List<Widget> buildDocsBlocks(
  BuildContext context, {
  required String markdown,
  required DocsTagRegistry registry,
  DocsInternalLinkCallback? onInternalLink,
}) {
  final source = markdown.replaceAll('\r\n', '\n');
  final blocks = <Widget>[];
  var cursor = 0;

  void addSegment(String segment) {
    blocks.addAll(
      _renderMarkdownSegment(
        context,
        source: segment,
        registry: registry,
        onInternalLink: onInternalLink,
      ),
    );
  }

  for (final match in findDocsTags(source)) {
    addSegment(source.substring(cursor, match.start));
    final built = registry.builderFor(match.tag.name)?.call(context, match.tag);
    if (built != null) blocks.add(built);
    cursor = match.end;
  }
  addSegment(source.substring(cursor));

  return _withBlockSpacing(blocks);
}

List<Widget> _renderMarkdownSegment(
  BuildContext context, {
  required String source,
  required DocsTagRegistry registry,
  DocsInternalLinkCallback? onInternalLink,
}) {
  if (source.trim().isEmpty) return const [];
  return [
    for (final node in parseDocsMarkdownNodes(source))
      ?_renderBlock(
        context,
        node: node,
        registry: registry,
        onInternalLink: onInternalLink,
      ),
  ];
}

/// 블록 사이 간격을 넣는다.
///
/// 각 블록이 "위쪽 여백" 만 선언하고 첫 블록은 그걸 버린다 — CSS 의 마진
/// 상쇄와 같은 결과를 아래 여백 없이 얻는다.
List<Widget> _withBlockSpacing(List<Widget> blocks) =>
    withNativeDocsBlockSpacing(blocks);

Widget? _renderBlock(
  BuildContext context, {
  required md.Node node,
  required DocsTagRegistry registry,
  DocsInternalLinkCallback? onInternalLink,
}) {
  if (node is DocsRawHtml) return _renderRawHtml(context, node, registry);
  // 커스텀 문법을 거치지 않은 최상위 텍스트는 그릴 게 없다.
  if (node is! md.Element) return null;

  final children = node.children ?? const <md.Node>[];

  switch (node.tag) {
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      return _heading(context, node, onInternalLink);
    case 'p':
      return _paragraph(context, children, onInternalLink);
    case 'pre':
      return _codeBlock(node);
    case 'blockquote':
      return _blockquote(context, children, registry, onInternalLink);
    case 'hr':
      return const Divider();
    case 'ul':
      return _list(context, node, registry, onInternalLink, ordered: false);
    case 'ol':
      return _list(context, node, registry, onInternalLink, ordered: true);
    case 'table':
      return _table(context, node, onInternalLink);
    default:
      final rendered = [
        for (final child in children)
          ?_renderBlock(
            context,
            node: child,
            registry: registry,
            onInternalLink: onInternalLink,
          ),
      ];
      if (rendered.isEmpty) return null;
      if (rendered.length == 1) return rendered.single;
      return Column(
        crossAxisAlignment: .start,
        children: _withBlockSpacing(rendered),
      );
  }
}

/// 커스텀 문법이 놓친 HTML 블록 — 아는 태그면 그리고, 아니면 버린다.
Widget? _renderRawHtml(
  BuildContext context,
  DocsRawHtml node,
  DocsTagRegistry registry,
) {
  final tag = parseDocsTag(node.text);
  if (tag == null) return null;
  return registry.builderFor(tag.name)?.call(context, tag);
}

Widget _heading(
  BuildContext context,
  md.Element node,
  DocsInternalLinkCallback? onInternalLink,
) {
  final text = DocsRichText(
    nodes: node.children ?? const [],
    onInternalLink: onInternalLink,
  );

  // 위 여백은 헤딩이 자기 앞의 본문과 벌어져 보이도록 블록 기본 간격보다
  // 크게 잡는다 — jaspr 쪽 `h2`/`h3` 마진과 같은 결.
  final (styled, top) = switch (node.tag) {
    'h1' => (text.headlineLarge.semiBold.onSurface, CoreSpace.space8),
    'h2' => (text.headlineSmall.semiBold.onSurface, CoreSpace.space24),
    'h3' => (text.titleLarge.semiBold.onSurface, CoreSpace.space16),
    'h4' => (text.titleMedium.semiBold.onSurface, CoreSpace.space8),
    'h5' => (text.titleSmall.semiBold.onSurface, CoreSpace.space8),
    _ => (text.titleSmall.medium.onSurfaceVariant, CoreSpace.space8),
  };

  return Padding(
    padding: .only(top: top),
    child: styled,
  );
}

Widget _paragraph(
  BuildContext context,
  List<md.Node> children,
  DocsInternalLinkCallback? onInternalLink,
) => buildNativeDocsParagraph(context, children, onInternalLink);

/// 펜스 코드 블록 — `<pre><code class="language-dart">` 구조.
Widget _codeBlock(md.Element node) {
  final code = node.children?.whereType<md.Element>().firstOrNull;
  final source = unescapeDocsHtml(
    (code ?? node).textContent,
  ).trimRight();
  return CodeSnippet(code: source, mode: _codeMode(code));
}

/// `class="language-dart"` 에서 언어 id 를 뽑는다.
String _codeMode(md.Element? code) {
  final classes = code?.attributes['class'] ?? '';
  for (final name in classes.split(RegExp(r'\s+'))) {
    if (name.startsWith('language-')) {
      final mode = name.substring('language-'.length).trim();
      if (mode.isNotEmpty) return mode;
    }
  }
  return _kDefaultCodeMode;
}

Widget _blockquote(
  BuildContext context,
  List<md.Node> children,
  DocsTagRegistry registry,
  DocsInternalLinkCallback? onInternalLink,
) {
  final scheme = context.colorScheme;
  final blocks = [
    for (final child in children)
      ?_renderBlock(
        context,
        node: child,
        registry: registry,
        onInternalLink: onInternalLink,
      ),
  ];

  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        left: .new(
          color: scheme
              .resolve(const CoreColor.token(CoreColors.outlineVariant))
              .toValue(),
          width: CoreStrokeWidth.stroke2,
        ),
      ),
    ),
    child: Padding(
      padding: const .only(
        left: CoreSpace.space16,
        top: CoreSpace.space4,
        bottom: CoreSpace.space4,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: _withBlockSpacing(blocks),
      ),
    ),
  );
}

Widget _list(
  BuildContext context,
  md.Element node,
  DocsTagRegistry registry,
  DocsInternalLinkCallback? onInternalLink, {
  required bool ordered,
}) {
  final items = (node.children ?? const <md.Node>[])
      .whereType<md.Element>()
      .where((child) => child.tag == 'li')
      .toList();
  final start = int.tryParse(node.attributes['start'] ?? '') ?? 1;

  return Column(
    crossAxisAlignment: .start,
    children: [
      for (final (index, item) in items.indexed)
        Padding(
          padding: .only(top: index == 0 ? 0 : CoreSpace.space4),
          child: _listItem(
            context,
            item,
            registry,
            onInternalLink,
            marker: ordered ? '${start + index}.' : '•',
          ),
        ),
    ],
  );
}

Widget _listItem(
  BuildContext context,
  md.Element item,
  DocsTagRegistry registry,
  DocsInternalLinkCallback? onInternalLink, {
  required String marker,
}) {
  final children = item.children ?? const <md.Node>[];
  final task = _taskState(children);

  // `- 텍스트` 는 `<li>` 안에 문단 없이 인라인 노드만 들어온다 (loose list 면
  // `<p>` 로 감싸진다). 두 모양을 같은 자리에서 처리한다.
  final leading = <md.Node>[];
  final blocks = <md.Node>[];
  for (final child in children) {
    if (child is md.Element && _isBlockTag(child.tag)) {
      blocks.add(child);
    } else {
      leading.add(child);
    }
  }

  final body = <Widget>[
    if (leading.isNotEmpty)
      DocsRichText(
        nodes: leading,
        onInternalLink: onInternalLink,
      ).bodyMedium.onSurface,
    for (final block in blocks)
      ?_renderBlock(
        context,
        node: block,
        registry: registry,
        onInternalLink: onInternalLink,
      ),
  ];

  return Row(
    crossAxisAlignment: .start,
    children: [
      SizedBox(
        width: CoreSpace.space24,
        child: task == null
            ? Text(marker).bodyMedium.onSurfaceVariant
            : Icon(
                task ? LucideIcons.squareCheck : LucideIcons.square,
                iconStyle: const CoreIconStyle(size: CoreSize.size16),
              ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: .start,
          children: _withBlockSpacing(body),
        ),
      ),
    ],
  );
}

/// 태스크 리스트 항목이면 체크 여부를, 아니면 `null`.
bool? _taskState(List<md.Node> children) {
  for (final child in children) {
    if (child is! md.Element) continue;
    if (child.tag == 'input' && child.attributes['type'] == 'checkbox') {
      return child.attributes.containsKey('checked');
    }
    final nested = child.children;
    if (nested != null) {
      final state = _taskState(nested);
      if (state != null) return state;
    }
  }
  return null;
}

bool _isBlockTag(String tag) => const {
  'p',
  'pre',
  'ul',
  'ol',
  'blockquote',
  'table',
  'hr',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
}.contains(tag);

/// GFM 표 — `<table><thead><tr><th>…`.
///
/// 넓이가 남으면 열을 늘려 채우고, 좁아지면 열 하한
/// ([_kMinTableColumnWidth]) 까지만 줄인 뒤 가로 스크롤로 넘긴다. 그래서
/// 좁은 화면에서도 셀이 뭉개지거나 오버플로가 터지지 않는다.
Widget _table(
  BuildContext context,
  md.Element node,
  DocsInternalLinkCallback? onInternalLink,
) {
  final rows = <CoreTableRowData<Widget>>[];

  for (final section
      in (node.children ?? const <md.Node>[]).whereType<md.Element>()) {
    final header = section.tag == 'thead';
    for (final row
        in (section.children ?? const <md.Node>[]).whereType<md.Element>()) {
      if (row.tag != 'tr') continue;
      // 머리줄이 빈 표는 이름 · 값 표다 — 읽을 것이 없는 줄이라 그리지
      // 않는다(사이트의 `DocsTableExtension` 과 같은 판정).
      if (header && row.textContent.trim().isEmpty) continue;
      final cells = [
        for (final cell
            in (row.children ?? const <md.Node>[]).whereType<md.Element>())
          CoreTableCellData(
            child: _tableCell(context, cell, onInternalLink),
          ),
      ];
      if (cells.isEmpty) continue;
      rows.add(
        header
            ? CoreTableRowData.header(cells: cells)
            : CoreTableRowData(cells: cells),
      );
    }
  }

  if (rows.isEmpty) return const SizedBox.shrink();

  final columnCount = rows.map((row) => row.cells.length).reduce(math.max);
  final minWidth = columnCount * _kMinTableColumnWidth;

  return LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth;
      final width = available.isFinite
          ? math.max(available, minWidth)
          : minWidth;
      return SingleChildScrollView(
        scrollDirection: .horizontal,
        child: SizedBox(
          width: width,
          child: Table(rows: rows),
        ),
      );
    },
  );
}

Widget _tableCell(
  BuildContext context,
  md.Element cell,
  DocsInternalLinkCallback? onInternalLink,
) {
  return Align(
    alignment: _cellAlignment(cell),
    child: DocsRichText(
      nodes: cell.children ?? const [],
      onInternalLink: onInternalLink,
      textAlign: _cellTextAlign(cell),
    ),
  );
}

/// 마크다운 파서는 열 정렬을 `style="text-align: center"` 로 실어 보낸다.
String? _cellAlign(md.Element cell) {
  final style = cell.attributes['style'];
  if (style == null) return null;
  final match = RegExp(r'text-align:\s*([a-z]+)').firstMatch(style);
  return match?.group(1);
}

AlignmentGeometry _cellAlignment(md.Element cell) => switch (_cellAlign(cell)) {
  'center' => Alignment.center,
  'right' => Alignment.centerRight,
  _ => Alignment.centerLeft,
};

TextAlign _cellTextAlign(md.Element cell) => switch (_cellAlign(cell)) {
  'center' => .center,
  'right' => .right,
  _ => .left,
};
