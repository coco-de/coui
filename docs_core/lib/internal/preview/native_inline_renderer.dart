/// 인라인 마크다운(굵게 / 기울임 / 코드 / 링크 …) → [InlineSpan] 워커.
library;

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'native_docs_document.dart';
import 'package:flutter/gestures.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// 인라인 링크에서 내부 경로를 받는 콜백 — href 를 원문 그대로 넘긴다.
typedef DocsInternalLinkCallback = void Function(String path);

/// 인라인 마크다운 한 덩어리를 그린다.
///
/// 타이포그래피/색을 스스로 박지 않는다. 바깥에서
/// `DocsRichText(...).bodyMedium.onSurface` 처럼 chain 으로 감싸면 그 chain 이
/// 깔아둔 `DefaultTextStyle` 을 루트 스팬이 상속하므로, 같은 위젯이 문단 ·
/// 헤딩 · 표 셀 어디에서나 그대로 쓰인다.
///
/// 링크의 탭 인식기를 소유하려고 [StatefulWidget] 이다 — [TapGestureRecognizer]
/// 는 명시적으로 dispose 해야 한다.
class DocsRichText extends StatefulWidget {
  /// 위젯을 만든다.
  const DocsRichText({
    required this.nodes,
    this.onInternalLink,
    this.textAlign,
    super.key,
  });

  /// 그릴 인라인 노드.
  final List<md.Node> nodes;

  /// 내부 링크 콜백 — [buildDocsInlineSpan] 참조.
  final DocsInternalLinkCallback? onInternalLink;

  /// 문단 정렬 — 기본값은 주변 `DefaultTextStyle` 을 따른다.
  final TextAlign? textAlign;

  @override
  State<DocsRichText> createState() => _DocsRichTextState();
}

class _DocsRichTextState extends State<DocsRichText> {
  final _recognizers = <GestureRecognizer>[];

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    // 인식기는 dispose 대상이라 사본을 만들 수 없다 — 소유한 그 리스트를
    // 그대로 비워야 한다.
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이전 빌드의 스팬은 통째로 버려지므로 그때 만든 인식기도 같이 버린다.
    _clearRecognizers();
    return Text.rich(
      buildDocsInlineSpan(
        context,
        nodes: widget.nodes,
        recognizers: _recognizers,
        onInternalLink: widget.onInternalLink,
      ),
      textAlign: widget.textAlign,
    );
  }
}

/// [nodes] 를 하나의 [InlineSpan] 으로 만든다.
///
/// 스팬은 타이포그래피/색을 스스로 박지 않고 **차이만** 싣는다 — 루트 스팬이
/// 주변 `DefaultTextStyle` 을 상속한다.
///
/// 링크에 붙일 [TapGestureRecognizer] 는 [recognizers] 에 쌓아 준다. 호출자가
/// 그걸 dispose 해야 한다 — 보통은 [DocsRichText] 를 쓰면 된다.
InlineSpan buildDocsInlineSpan(
  BuildContext context, {
  required List<md.Node> nodes,
  required List<GestureRecognizer> recognizers,
  DocsInternalLinkCallback? onInternalLink,
}) {
  return TextSpan(
    children: [
      for (final node in nodes)
        _span(
          context,
          node: node,
          recognizers: recognizers,
          onInternalLink: onInternalLink,
        ),
    ],
  );
}

InlineSpan _span(
  BuildContext context, {
  required md.Node node,
  required List<GestureRecognizer> recognizers,
  DocsInternalLinkCallback? onInternalLink,
}) {
  if (node is md.Text) {
    return TextSpan(text: unescapeDocsHtml(node.text));
  }
  if (node is! md.Element) return const TextSpan();

  switch (node.tag) {
    case 'em':
      return _wrap(
        context,
        node,
        const TextStyle(fontStyle: .italic),
        recognizers,
        onInternalLink,
      );
    case 'strong':
      return _wrap(
        context,
        node,
        TextStyle(fontWeight: fontWeightFromInt(CoreFontWeight.semiBold)),
        recognizers,
        onInternalLink,
      );
    case 'del':
      return _wrap(
        context,
        node,
        const TextStyle(decoration: .lineThrough),
        recognizers,
        onInternalLink,
      );
    case 'code':
      return TextSpan(
        text: unescapeDocsHtml(node.textContent),
        style: docsInlineCodeStyle(context),
      );
    case 'br':
      return const TextSpan(text: '\n');
    case 'a':
      return _link(context, node, recognizers, onInternalLink);
    case 'img':
      // 콘텐츠에 이미지가 없다. 언젠가 들어오면 대체 텍스트라도 보이게 둔다.
      final alt = node.attributes['alt'] ?? '';
      return TextSpan(text: alt.isEmpty ? '' : unescapeDocsHtml(alt));
    case 'input':
      // 태스크 리스트 체크박스는 블록 렌더러가 리스트 마커로 그린다.
      return const TextSpan();
    default:
      return _wrap(context, node, null, recognizers, onInternalLink);
  }
}

/// 인라인 코드(`` `foo` ``) 의 스타일 — 모노 폰트 + 옅은 배경.
///
/// 모노 서체는 [kCoreMonoTextStyle] 에서 가져온다 — 서체 이름만 적으면 앱이
/// 그 서체를 등록하지 않은 화면에서 플랫폼 기본 서체로 그려진다. 그 스타일은
/// coui_flutter 가 번들한 Geist Mono 와 한글용 Pretendard 를 fallback 으로
/// 함께 들고 온다.
///
/// [TextStyle.backgroundColor] 는 패딩/라운딩이 없다. 인라인 코드를
/// [WidgetSpan] 으로 그리면 패딩은 얻지만 그 조각이 줄바꿈에서 통째로
/// 튕겨나가 긴 시그니처가 문단 밖으로 삐져나온다 — 배경만 칠하는 쪽이
/// 문서 본문에서는 덜 깨진다.
TextStyle docsInlineCodeStyle(BuildContext context) {
  final scheme = context.colorScheme;
  return kCoreMonoTextStyle.copyWith(
    color: scheme.resolve(const CoreColor.token(CoreColors.onSurfaceVariant)).toValue(),
    backgroundColor: scheme.resolve(const CoreColor.token(CoreColors.surfaceContainerHigh)).toValue(),
  );
}

List<InlineSpan> _children(
  BuildContext context,
  md.Element node,
  List<GestureRecognizer> recognizers,
  DocsInternalLinkCallback? onInternalLink,
) {
  return [
    for (final child in node.children ?? const <md.Node>[])
      _span(
        context,
        node: child,
        recognizers: recognizers,
        onInternalLink: onInternalLink,
      ),
  ];
}

InlineSpan _wrap(
  BuildContext context,
  md.Element node,
  TextStyle? style,
  List<GestureRecognizer> recognizers,
  DocsInternalLinkCallback? onInternalLink,
) {
  return TextSpan(
    style: style,
    children: _children(context, node, recognizers, onInternalLink),
  );
}

/// 링크를 CoUI [Link.inlineSpan] 으로 그린다 — [WidgetSpan] 에 태운 [Link]
/// 위젯이 아니다.
///
/// 위젯 [Link] 는 [WidgetSpan] 안에서 조각째 줄바꿈되지 않아 좁은 칸에서
/// 삐져나가고, 자기 라벨을 `bodyMedium` 으로 박아 표 셀·헤딩 안에서 크기가
/// 튄다. 인라인 팩토리는 [TextSpan] 이라 주변 문장과 함께 줄바꿈되고 크기는
/// 주변에서 상속하며, 색/밑줄만 `CoreLinkStyle` 에서 온다. 링크 안의 굵게 ·
/// 코드 같은 자식 조각에도 같은 탭 인식기가 붙는다.
InlineSpan _link(
  BuildContext context,
  md.Element node,
  List<GestureRecognizer> recognizers,
  DocsInternalLinkCallback? onInternalLink,
) {
  final href = node.attributes['href'];
  if (href == null || href.isEmpty) {
    return _wrap(context, node, null, recognizers, onInternalLink);
  }

  return Link.inlineSpan(
    context,
    href: href,
    children: _children(context, node, recognizers, onInternalLink),
    onPressed: () => handleDocsLinkTap(href, onInternalLink: onInternalLink),
    external: href.startsWith('http://') || href.startsWith('https://'),
    // 싱크는 호출자가 dispose 하려고 소유한 리스트다 — 사본을 만들면 호출자가
    // 인식기를 놓쳐 샌다.
    recognizers: recognizers,
  );
}

/// 외부 링크는 브라우저로, 내부 링크는 호스트가 라우팅하도록 넘긴다.
///
/// 내부 href 는 정규화하지 않고 원문(`/components/card`, `./card.md`)을 그대로
/// 준다 — 상대 경로를 풀려면 현재 문서 경로를 알아야 하는데 그건 렌더러가
/// 아니라 호스트가 가진 정보다.
void handleDocsLinkTap(
  String href, {
  DocsInternalLinkCallback? onInternalLink,
}) {
  if (!href.startsWith('http://') && !href.startsWith('https://')) {
    onInternalLink?.call(href);
    return;
  }
  final uri = Uri.tryParse(href);
  if (uri == null) return;
  unawaited(launchUrl(uri, mode: .externalApplication));
}
