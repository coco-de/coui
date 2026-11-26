/// `<Code>` 태그 블록 — 여는 줄부터 `</Code>` 줄까지를 코드 그대로 읽는다.
///
/// 문서 사이트의 마크다운은 HTML 블록을 HTML 로 다시 읽는다. 그래서 `<Code>`
/// 안의 코드도 HTML 로 읽혀, 두 모양이 조용히 페이지를 깨뜨렸다:
///
/// - 제네릭(`Select<String>`)은 닫히지 않은 요소로 읽혀 뒤의 섹션을 코드
///   상자 안으로 삼킨다.
/// - 빈 줄에서 HTML 블록이 끝나, 빈 줄 뒤의 코드가 본문 문단이 된다.
///
/// 둘 다 에러 없이 그려졌다. 이 문법은 그 사이의 줄을 HTML 이 아니라 글자로
/// 넘긴다(`<` · `>` · `&` 를 엔티티로 바꿔 HTML 토크나이저가 그대로 글자로
/// 돌려주게 한다). 네이티브 문서 앱은 태그의 원문을 직접 읽으므로 이 문제가
/// 없다 — 이 문법은 사이트(와 사이트와 같은 파이프라인을 쓰는 검사)의 것이다.
library;

import 'package:jaspr_content/jaspr_content.dart' show HtmlText, MarkdownParser;
import 'package:markdown/markdown.dart' as md;

/// 문서 사이트의 블록 문법 — `<Code>` 블록을 먼저 읽고, 나머지는 jaspr_content
/// 의 기본(HTML 블록)이다. 사이트와 그 파이프라인을 따라 하는 검사가 함께 쓴다.
const List<md.BlockSyntax> kDocsBlockSyntaxes = [
  DocsCodeTagBlockSyntax(),
  ...MarkdownParser.defaultBlockSyntaxes,
];

final _open = RegExp(r'^ {0,3}<Code(?:\s[^>]*)?>\s*$');
final _close = RegExp(r'^\s*</Code>\s*$');

/// [kDocsBlockSyntaxes] 의 `<Code>` 블록 문법.
class DocsCodeTagBlockSyntax extends md.BlockSyntax {
  /// 문법을 만든다.
  const DocsCodeTagBlockSyntax();

  @override
  RegExp get pattern => _open;

  /// 여는 줄이 혼자 있고, 뒤에 닫는 줄이 있을 때만 — 닫는 줄이 없는 블록은
  /// 기본 HTML 블록에 맡긴다(페이지 끝까지 코드로 삼키지 않게).
  @override
  bool canParse(md.BlockParser parser) {
    if (!_open.hasMatch(parser.current.content)) return false;
    for (var ahead = 1; ; ahead++) {
      final line = parser.peek(ahead);
      if (line == null) return false;
      if (_close.hasMatch(line.content)) return true;
    }
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final open = parser.current.content.trim();
    parser.advance();
    final body = <String>[];
    while (!parser.isDone && !_close.hasMatch(parser.current.content)) {
      body.add(parser.current.content);
      parser.advance();
    }
    if (!parser.isDone) parser.advance();
    final text = body.map(_escape).join('\n');
    return HtmlText('$open\n$text\n</Code>');
  }
}

String _escape(String line) => line.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
