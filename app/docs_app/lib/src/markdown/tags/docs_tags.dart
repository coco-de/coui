/// 문서 마크다운의 커스텀 태그 전부를 한 레지스트리로 묶는다.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_app/src/markdown/tags/block_catalog_tags.dart';
import 'package:docs_app/src/markdown/tags/block_tags.dart';
import 'package:docs_app/src/markdown/tags/callout_tag.dart';
import 'package:docs_app/src/markdown/tags/foundation_visual_tag.dart';
import 'package:docs_app/src/markdown/tags/preview_block_tags.dart';
import 'package:docs_app/src/markdown/tags/reference_tags.dart';
import 'package:docs_app/src/markdown/tags/release_tags.dart';
import 'package:docs_app/src/markdown/tags/tabs_tag.dart';

export 'package:docs_app/src/markdown/tags/block_catalog_tags.dart';
export 'package:docs_app/src/markdown/tags/block_tags.dart';
export 'package:docs_app/src/markdown/tags/callout_tag.dart';
export 'package:docs_app/src/markdown/tags/foundation_visual_tag.dart';
export 'package:docs_app/src/markdown/tags/reference_tags.dart';
export 'package:docs_app/src/markdown/tags/release_tags.dart';
export 'package:docs_app/src/markdown/tags/tabs_tag.dart';

/// 문서 페이지가 쓰는 모든 커스텀 태그를 배선한 [DocsTagRegistry].
///
/// [onInternalLink] 는 문서 안 링크(`<ComponentGrid />` 카드 탭, 중첩
/// 마크다운의 내부 링크)가 이동을 요청할 때 경로를 받는다.
///
/// [livePreviewBuilder] 는 `<LivePreview ... />` 담당 — 이 파일이 소유하지
/// 않아 주입받는다. `null` 이면 그 태그는 등록되지 않고, 렌더러의 미등록
/// 태그 처리 경로로 저하된다.
///
/// [extraTags] 는 추가/치환용 — 마지막에 병합되므로 같은 이름이면 이긴다.
DocsTagRegistry buildDocsTagRegistry({
  required void Function(String path) onInternalLink,
  DocsTagBuilder? livePreviewBuilder,
  Map<String, DocsTagBuilder> extraTags = const {},
}) {
  // 태그 본문은 다시 마크다운이고, 그 마크다운 안에 또 태그가 있을 수 있다
  // (콜아웃 안의 Tabs 등). 그래서 중첩 렌더러가 자기를 담은 레지스트리를
  // 참조해야 한다 — 클로저는 아래 대입 뒤에만 실행되므로 `late` 로 묶는다.
  late final DocsTagRegistry registry;

  Widget nested(String markdown) => DocsMarkdown(
    markdown: markdown,
    registry: registry,
    onInternalLink: onInternalLink,
  );

  return registry = DocsTagRegistry({
    ...docsCalloutTagBuilders(nested: nested),
    ...docsTabsTagBuilders(nested: nested),
    ...docsBlockTagBuilders(nested: nested, onInternalLink: onInternalLink),
    ...docsBlockCatalogTagBuilders(onInternalLink: onInternalLink),
    ...docsPreviewBlockTagBuilders(nested: nested),
    ...docsReferenceTagBuilders(onInternalLink: onInternalLink),
    ...docsFoundationVisualTagBuilders(nested: nested),
    ...docsReleaseTagBuilders(),
    'LivePreview': ?livePreviewBuilder,
    ...extraTags,
  });
}
