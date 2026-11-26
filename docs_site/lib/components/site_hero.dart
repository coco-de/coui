/// Server-rendered introduction and entry points for the documentation.
library;

import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:jaspr_content/jaspr_content.dart';

import 'site_landing_data.dart';
import 'site_landing_parts.dart';

/// Markdown `<SiteHero />` handler.
class SiteHero extends CustomComponent {
  SiteHero() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(tag: 'SiteHero')) return const SiteHeroView();
    return null;
  }
}

/// The landing's first screen.
///
/// Navigation uses anchors so every entry point works before hydration.
///
/// The five pieces — pill, the two headline lines, the summary and the
/// actions — arrive in sequence. Each carries its place in that sequence as
/// `--i`; the stylesheet turns it into a delay, and the sequence as a whole
/// ends within `CoreDuration.slow` (see `site_motion.dart`). It is a CSS
/// animation rather than a script, so the headline never waits on anything
/// to become visible.
class SiteHeroView extends StatelessComponent {
  const SiteHeroView({super.key});

  @override
  Component build(BuildContext context) {
    final count = siteComponentFloor;

    return Hero(
      classes: 'site-hero not-content',
      heroStyle: const CoreHeroStyle(
        backgroundColor: CoreColor.transparent,
        padding: CoreEdgeInsets.zero,
        minHeight: 0,
      ),
      child: div(classes: 'site-hero-inner', [
        a(
          href: '/components-overview',
          classes: 'site-hero-eyebrow site-box-link site-rise',
          styles: siteOrder(0),
          [
            Text('$count+ 컴포넌트 · Flutter + Jaspr Web').labelLarge.medium.onSurfaceVariant,
            siteArrow(Text('→').labelLarge.medium.onSurfaceVariant),
          ],
        ),
        h1([
          span(classes: 'site-hero-line site-rise', styles: siteOrder(1), [Text('앱과 웹을 잇는').bold.onSurface]),
          // 줄 사이의 공백 — 두 줄을 한 문장으로 읽는 보조 기술과 복사에
          // 낱말 경계를 남긴다.
          Component.text(' '),
          span(classes: 'site-hero-line site-rise', styles: siteOrder(2), [Text('하나의 디자인 시스템').bold.onSurface]),
        ]),
        p(classes: 'site-hero-description site-rise', styles: siteOrder(3), [
          span([Text('Flutter와 Jaspr Web에서 같은 API와 디자인 토큰을 사용하세요.').onSurfaceVariant]),
          Component.text(' '),
          span([Text('$count개 이상의 컴포넌트로 두 플랫폼의 화면을 일관되게 만듭니다.').onSurfaceVariant]),
        ]),
        div(classes: 'site-hero-actions site-rise', styles: siteOrder(4), [
          Button(
            href: '/getting-started',
            size: CoreComponentSize.lg,
            child: Text('시작하기'),
          ),
          Button(
            href: '/components-overview',
            variant: CoreButtonVariant.outline,
            size: CoreComponentSize.lg,
            child: Text('컴포넌트 둘러보기'),
          ),
        ]),
      ]),
    );
  }
}
