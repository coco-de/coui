/// Link 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="link/...">` · `<Card demo>` · `<Anatomy demo>` 가 읽는다.
/// 같은 이름의 Web 파일(`link_web.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
///
/// Flutter 의 `Link` 는 URL 을 열지 않는다. 미리보기의 `onPressed` 는 비어
/// 있어 눌러도 이동하지 않는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_flutter.dart';
import 'link_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _link;

/// 장면 이름(`link/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'link/anatomy': () => Link(
    href: page.linkDemoHref,
    onPressed: () {},
    leading: const Icon(LucideIcons.link),
    trailing: const Icon(LucideIcons.arrowRight),
    child: const Text(page.linkDemoLabel),
  ),
  'link/underline': () => docsFlutterDemoRow([
    _plainLink('상호작용할 때 밑줄'),
    Link(href: page.linkDemoHref, underline: true, onPressed: () {}, child: const Text('늘 밑줄')),
  ]),
  'link/icons': () => docsFlutterDemoRow([
    Link(
      href: page.linkDemoHref,
      onPressed: () {},
      leading: const Icon(LucideIcons.hash),
      child: const Text('섹션 링크'),
    ),
    Link(
      href: page.linkDemoRepositoryUrl,
      external: true,
      onPressed: () {},
      trailing: const Icon(LucideIcons.externalLink),
      child: const Text('GitHub에서 보기 (새 탭)'),
    ),
  ]),
  'link/inline': () => _inlineSentence(page.linkDemoParagraph, width: page.linkDemoParagraphWidth),
  'link/do-inline': () => _inlineSentence(page.linkDemoSentence, width: page.linkDemoCardWidth),
  // 문장 속에 `underline: false` 인 `Link` 를 끼운, 권하지 않는 모양.
  'link/dont-inline': () => _sentenceBox(
    page.linkDemoCardWidth,
    Text.rich(
      TextSpan(
        children: [
          TextSpan(text: page.linkDemoSentence.$1),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _plainLink(page.linkDemoSentence.$2),
          ),
          TextSpan(text: page.linkDemoSentence.$3),
        ],
      ),
    ).bodyMedium.onSurface,
  ),
  'link/do-label': () => _plainLink('환불 정책 보기'),
  'link/dont-label': () => _plainLink('여기'),
  'link/do-action': () => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('주문 취소')),
  'link/dont-action': () => _plainLink('주문 취소'),
  'link/related-button': () => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('저장하기')),
  'link/related-text': () => const Text('이동하지 않는 글자').bodyMedium.onSurface,
  'link/related-breadcrumb': () => Breadcrumb(items: page.linkDemoTrail, onItemTap: (_) {}),
};

Widget _link(Map<String, String> props, String? label) => Link(
  href: page.linkDemoHref,
  external: previewFlag(props, 'external'),
  underline: previewFlag(props, 'underline'),
  variant: previewEnum(CoreLinkVariant.values, props['variant'], CoreLinkVariant.defaultVariant),
  onPressed: () {},
  leading: docsFlutterIcon(props['leading']),
  trailing: docsFlutterIcon(props['trailing']),
  child: Text(label ?? page.linkDemoLabel),
);

/// 기본값 그대로인 링크 하나.
Widget _plainLink(String label) => Link(href: page.linkDemoHref, onPressed: () {}, child: Text(label));

/// 문장 하나를 [width] 안에 놓는다 — logical px, 좁으면 줄어든다.
Widget _sentenceBox(double width, Widget sentence) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: width),
  child: sentence,
);

/// 문장 가운데에 `Link.inlineSpan` 을 둔다. `onPressed` 를 주지 않아 탭
/// 인식기를 만들지 않으므로 `recognizers` 가 필요 없다.
Widget _inlineSentence((String, String, String) sentence, {required double width}) => _sentenceBox(
  width,
  Builder(
    builder: (context) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: sentence.$1),
          Link.inlineSpan(context, href: page.linkDemoHref, text: sentence.$2),
          TextSpan(text: sentence.$3),
        ],
      ),
    ).bodyMedium.onSurface,
  ),
);
