/// 마크다운 본문을 CoUI 위젯으로 그리는 공개 위젯.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/block_renderer.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_app/src/markdown/inline_renderer.dart';
import 'package:docs_core/internal/preview/native_paragraph_body.dart';

/// 마크다운 본문 하나를 세로로 쌓아 그린다.
///
/// 높이를 스스로 정하므로 스크롤 뷰 안에 그대로 넣으면 된다. 가로로는 부모가
/// 준 폭을 채운다 — 폭이 무한한 곳(가로 스크롤 뷰 등)에 직접 넣지 마라. 표가
/// 폭을 잡을 수 없다.
class DocsMarkdown extends StatelessWidget {
  /// 위젯을 만든다.
  const DocsMarkdown({
    required this.markdown,
    required this.registry,
    this.onInternalLink,
    super.key,
  });

  /// 마크다운 본문 — frontmatter 는 뺀 상태다.
  final String markdown;

  /// 커스텀 태그(`<LivePreview />`, `<Callout>` …) 빌더.
  ///
  /// 여기 없는 태그는 조용히 빠진다 — 문서 하나에 처음 보는 태그가 있다고
  /// 페이지 전체가 죽으면 안 된다.
  final DocsTagRegistry registry;

  /// 내부 링크를 눌렀을 때 — href 를 원문 그대로 준다
  /// (`/components/card`, `./card.md`).
  ///
  /// 상대 경로는 현재 문서 경로를 알아야 풀 수 있어서 호스트 몫으로 남긴다.
  /// 외부 링크(`http`/`https`)는 이 콜백을 타지 않고 브라우저로 열린다.
  final DocsInternalLinkCallback? onInternalLink;

  @override
  Widget build(BuildContext context) {
    return buildNativeDocsBlockColumn(
      buildDocsBlocks(
        context,
        markdown: markdown,
        registry: registry,
        onInternalLink: onInternalLink,
      ),
    );
  }
}
