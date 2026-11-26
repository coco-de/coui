/// Link 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="link/...">` · `<Card demo>` · `<Anatomy demo>` 가 읽는다.
/// 같은 이름의 Flutter 파일(`link_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_web.dart';
import 'link_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _link;

/// 장면 이름(`link/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 서버가 그린 마크업에서 번호가 아이콘을 찾도록, 패키지에 든
  // 아이콘(인라인 `<svg>` 로 그리는 것)을 쓴다.
  'link/anatomy': () => const Link(
    href: page.linkDemoHref,
    leading: Icon(LucideIcons.link),
    trailing: Icon(LucideIcons.arrowRight),
    child: Text(page.linkDemoLabel),
  ),
  'link/underline': () => docsWebDemoRow(const [
    Link(href: page.linkDemoHref, child: Text('상호작용할 때 밑줄')),
    Link(href: page.linkDemoHref, underline: true, child: Text('늘 밑줄')),
  ]),
  'link/icons': () => docsWebDemoRow(const [
    Link(href: page.linkDemoHref, leading: Icon(LucideIcons.hash), child: Text('섹션 링크')),
    Link(
      href: page.linkDemoRepositoryUrl,
      external: true,
      trailing: Icon(LucideIcons.externalLink),
      child: Text('GitHub에서 보기 (새 탭)'),
    ),
  ]),
  'link/inline': () => _inlineSentence(page.linkDemoParagraph, width: page.linkDemoParagraphWidth),
  'link/do-inline': () => _inlineSentence(page.linkDemoSentence, width: page.linkDemoCardWidth),
  // 문장 속에 `underline: false` 인 `Link` 를 끼운, 권하지 않는 모양.
  'link/dont-inline': () => _sentenceBox(page.linkDemoCardWidth, [
    Text(page.linkDemoSentence.$1),
    Link(href: page.linkDemoHref, child: Text(page.linkDemoSentence.$2)),
    Text(page.linkDemoSentence.$3),
  ]),
  'link/do-label': () => const Link(href: page.linkDemoHref, child: Text('환불 정책 보기')),
  'link/dont-label': () => const Link(href: page.linkDemoHref, child: Text('여기')),
  'link/do-action': () => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('주문 취소')),
  'link/dont-action': () => const Link(href: page.linkDemoHref, child: Text('주문 취소')),
  'link/related-button': () => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('저장하기')),
  'link/related-text': () => const Text('이동하지 않는 글자').bodyMedium.onSurface,
  'link/related-breadcrumb': () => Breadcrumb(items: page.linkDemoTrail, onItemTap: (_) {}),
};

Component _link(Map<String, String> props, String? label) => Link(
  href: page.linkDemoHref,
  external: previewFlag(props, 'external'),
  underline: previewFlag(props, 'underline'),
  variant: previewEnum(CoreLinkVariant.values, props['variant'], CoreLinkVariant.defaultVariant),
  leading: docsWebIcon(props['leading']),
  trailing: docsWebIcon(props['trailing']),
  child: Text(label ?? page.linkDemoLabel),
);

/// 문장 하나를 [width] 안에 놓는다 — logical px, 좁으면 줄어든다.
Component _sentenceBox(double width, List<Component> children) => div(
  styles: Styles(raw: {'max-width': pinnedLengthCss(width)}),
  children,
);

/// 문장 가운데에 `Link.inlineSpan` 을 둔다. `BuildContext` 가 필요해
/// `Builder` 안에서 만든다.
Component _inlineSentence((String, String, String) sentence, {required double width}) => Builder(
  builder: (context) => _sentenceBox(width, [
    Text(sentence.$1),
    Link.inlineSpan(context, href: page.linkDemoHref, text: sentence.$2),
    Text(sentence.$3),
  ]),
);
