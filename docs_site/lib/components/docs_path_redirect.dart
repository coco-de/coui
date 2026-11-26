/// 옛 문서 경로를 블록 페이지로 옮기는 정적 리다이렉트.
///
/// jaspr 정적 빌드는 HTTP 301 을 내지 않는다. 그래서 이 페이지가
/// `meta refresh` 와 `location.replace` 로 다음 문서를 연다. 스크립트가
/// 막혀도 본문의 링크가 같은 주소로 간다.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// [to] 로 바로 보내는 문서 페이지.
class DocsPathRedirect extends StatelessComponent {
  /// [to] 는 사이트 루트 기준 경로다 (`/blocks/footer`).
  const DocsPathRedirect({required this.to, super.key});

  /// 옮겨진 문서의 경로.
  final String to;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Document.head(
        children: [
          Component.element(
            tag: 'link',
            attributes: {'rel': 'canonical', 'href': to},
          ),
          Component.element(
            tag: 'meta',
            attributes: {
              'http-equiv': 'refresh',
              'content': '0;url=$to',
            },
          ),
          Component.element(
            tag: 'script',
            children: [RawText("location.replace('$to')")],
          ),
        ],
      ),
      p([
        Component.text('이 문서는 '),
        a(href: to, [Component.text(to)]),
        Component.text(' 로 옮겨졌습니다.'),
      ]),
    ]);
  }
}
