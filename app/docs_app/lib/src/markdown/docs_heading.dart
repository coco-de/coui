/// 목차(TOC)용 헤딩 모델과 추출기.
library;

import 'package:docs_app/src/markdown/docs_document.dart';
import 'package:markdown/markdown.dart' as md;

/// 목차에 노출하는 최대 헤딩 깊이 — jaspr 쪽 `maxHeaderDepth: 3` 과 같다.
const _kMaxHeadingDepth = 3;

/// 목차 항목 하나.
class DocsHeading {
  /// 헤딩을 만든다.
  const DocsHeading({
    required this.text,
    required this.level,
    required this.id,
  });

  /// 화면에 보이는 라벨 — 인라인 마크업을 벗긴 순수 텍스트.
  final String text;

  /// 헤딩 깊이 — `2` (h2) 또는 `3` (h3).
  final int level;

  /// 문서 안에서 유일한 앵커 id.
  final String id;
}

/// 문자·숫자·공백·하이픈만 남긴다 — `\p{L}` 이라 한글도 그대로 살아남는다.
final _kSlugStrip = RegExp(r'[^\p{L}\p{N}\s-]', unicode: true);
final _kSlugSeparator = RegExp(r'[\s-]+');

/// 본문([markdown])에서 h2 / h3 헤딩을 원본 순서대로 뽑는다.
///
/// 목차 깊이는 jaspr 쪽 TOC 의 `maxHeaderDepth: 3` (→ `level = depth - 2`) 을
/// 따라 h2/h3 만 담는다. 라벨([DocsHeading.text])도 jaspr 과 같지만
/// [DocsHeading.id] 는 다르다 — jaspr 의 생성기는 한글을 통째로 버리고
/// (`## 개요` → `""`) 중복도 처리하지 않는다. 여기서는 URL 프래그먼트를
/// 공유하지 않으므로 그 버그를 따라할 이유가 없다.
List<DocsHeading> extractDocsHeadings(String markdown) {
  final headings = _collect(parseDocsMarkdownNodes(markdown)).toList();
  final slugs = [for (final (text, _) in headings) _slugify(text)];
  return [
    for (final (index, (text, level)) in headings.indexed)
      DocsHeading(text: text, level: level, id: _uniqueId(slugs, index)),
  ];
}

Iterable<(String, int)> _collect(List<md.Node> nodes) sync* {
  for (final node in nodes) {
    if (node is! md.Element) continue;

    final level = _headingLevel(node.tag);
    if (level != null) {
      if (level >= 2 && level <= _kMaxHeadingDepth) {
        yield (unescapeDocsHtml(node.textContent).trim(), level);
      }
      // 헤딩 안에는 헤딩이 없다.
      continue;
    }

    final children = node.children;
    if (children != null) yield* _collect(children);
  }
}

int? _headingLevel(String tag) {
  if (tag.length != 2 || tag[0] != 'h') return null;
  return int.tryParse(tag[1]);
}

/// 앞쪽에 같은 슬러그가 몇 번 나왔는지로 접미사를 정한다.
///
/// 누적 맵 대신 앞쪽을 세는 이유는 순수 함수로 두기 위해서다. 문서 하나의
/// 헤딩은 수십 개라 O(n²) 가 문제되지 않는다.
String _uniqueId(List<String> slugs, int index) {
  final slug = slugs[index];
  final ordinal = slugs.take(index).where((other) => other == slug).length + 1;
  return ordinal == 1 ? slug : '$slug-$ordinal';
}

String _slugify(String text) {
  final stripped = text.toLowerCase().replaceAll(_kSlugStrip, '').trim();
  final slug = stripped.replaceAll(_kSlugSeparator, '-');
  return slug.isEmpty ? 'section' : slug;
}
