/// 마크다운 파서 설정 — 렌더러와 TOC 추출기가 같은 문서를 보게 하는 단일 출처.
library;

import 'package:docs_core/markdown/heading_slug.dart';
import 'package:markdown/markdown.dart' as md;

/// 커스텀 태그를 원본 그대로 넘겨주는 raw HTML 블록.
///
/// 기본 [md.HtmlBlockSyntax] 는 HTML 을 문자열로 뱉어 `md.Text` 로 흘리는데,
/// 그러면 렌더러가 "이게 HTML 인가 본문인가" 를 구분할 수 없다. 별도 타입으로
/// 표시해 두면 블록 워커가 태그로 해석하거나 조용히 버릴 수 있다.
class DocsRawHtml extends md.Text {
  /// 원본 HTML 을 담은 블록을 만든다.
  DocsRawHtml(super.text);
}

/// [DocsRawHtml] 을 뱉는 HTML 블록 문법.
class DocsRawHtmlBlockSyntax extends md.HtmlBlockSyntax {
  /// 문법을 만든다.
  const DocsRawHtmlBlockSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final lines = parseChildLines(parser);
    return DocsRawHtml(
      lines.map((line) => line.content).join('\n').trimRight(),
    );
  }
}

/// 파서 설정은 docs_site 의 `MarkdownParser` 와 같다 — `docsHeadingAwareExtensionSet`
/// (docs_core) 을 공유해서 실제로 같은 코드로 보장된다(주석으로만 "같다"고
/// 적어두는 대신).
///
/// `gitHubWeb` 확장셋이 GFM 테이블 / 취소선 / autolink 를 켠다. 문서 하나에
/// 재사용하면 안 된다 — [md.Document] 는 링크 참조를 누적하는 상태를 들고
/// 있으므로 파싱할 때마다 새로 만든다.
md.Document buildDocsMarkdownDocument() => md.Document(
  blockSyntaxes: const [DocsRawHtmlBlockSyntax()],
  extensionSet: docsHeadingAwareExtensionSet,
);

/// [source] 를 [buildDocsMarkdownDocument] 설정으로 파싱한다.
List<md.Node> parseDocsMarkdownNodes(String source) =>
    buildDocsMarkdownDocument().parse(source.replaceAll('\r\n', '\n'));

final _kEntity = RegExp('&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);');

/// 유니코드 스칼라 값의 상한 — 이보다 큰 수치 참조는 깨진 엔티티다.
const _kMaxCodePoint = 0x10ffff;
const _kHexRadix = 16;
const _kDecimalRadix = 10;

const _kNamedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'hellip': '…',
  'mdash': '—',
  'ndash': '–',
};

/// 마크다운 파서가 이스케이프한 엔티티를 원래 문자로 되돌린다.
///
/// 마크다운 문서는 기본값 `encodeHtml: true` 로 동작해서 `List<String>` 을
/// `List&lt;String&gt;` 로 바꿔 놓는다 — HTML 로 뱉을 때는 맞지만 위젯으로
/// 그릴 때는 그대로 새어나온다. 파서 설정은 docs_site 와 똑같이 두고, 대신
/// 텍스트를 읽는 쪽에서 되돌린다.
String unescapeDocsHtml(String source) {
  if (!source.contains('&')) return source;
  return source.replaceAllMapped(_kEntity, (match) {
    final body = match.group(1)!;
    if (body.startsWith('#')) {
      final isHex = body.length > 1 && (body[1] == 'x' || body[1] == 'X');
      final digits = isHex ? body.substring(2) : body.substring(1);
      final code = int.tryParse(
        digits,
        radix: isHex ? _kHexRadix : _kDecimalRadix,
      );
      // 유효한 스칼라 값이 아니면 원문을 그대로 둔다 — 깨진 엔티티 하나가
      // 페이지 전체를 죽이는 것보다 낫다.
      if (code == null || code < 0 || code > _kMaxCodePoint) {
        return match.group(0)!;
      }
      return String.fromCharCode(code);
    }
    return _kNamedEntities[body] ?? match.group(0)!;
  });
}
