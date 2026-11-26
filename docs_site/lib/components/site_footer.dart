/// 랜딩 푸터 — CoUI `Footer`.
///
/// ## 왜 있어야 하나 (측정으로 찾은 결함)
///
/// 헤더의 섹션 내비게이션은 좁은 폭에서 감춰진다. 문서 페이지에서는
/// 같은 목적지가 사이드바(햄버거 토글)에 있어 도달 가능성이 유지되지만,
/// **랜딩에는 사이드바가 없다** — 그래서 390px 에서 랜딩을 열면 시작하기 ·
/// 디자인 토큰 · 가이드 · Changelog 로 가는 길이 화면에서 통째로 사라졌다.
///
/// 브라우저에서 실제로 좁혀 보기 전까지는 보이지 않는 종류의 결함이다.
/// 헤더의 미디어 쿼리만 읽으면 "사이드바가 대신한다" 는 주석이 참으로
/// 읽히고, 그 주석이 참이 아닌 페이지가 하나 있다는 것은 그 페이지를
/// 좁혀 봐야 안다.
///
/// 푸터는 그 길을 되돌려 놓는다 — 그리고 랜딩 페이지에 푸터가 있는 것은
/// 어차피 정상이다.
///
/// ## 가이드 경로는 카탈로그에서 찾는다
///
/// 세 갈래의 이름과 항목은 편집 판단이라 여기 적는다. 다만 가이드로 가는
/// 경로는 문자열로 적지 않고 카탈로그에서 찾는다(`siteGuidePath`) — 가이드가
/// 옮겨지거나 지워지면 죽은 링크가 나가는 대신 빌드가 멈춘다.
library;

import 'package:coui_web/coui_web.dart' hide Document, Style, css;

import 'site_header.dart' show siteMark;
import 'site_landing_data.dart';

/// 랜딩 푸터.
class SiteFooter extends StatelessComponent {
  /// 푸터를 만든다.
  const SiteFooter({super.key});

  @override
  Component build(BuildContext context) {
    return Footer(
      classes: 'site-footer',
      footerStyle: _style,
      aside: div(classes: 'site-footer-brand', [
        div(classes: 'site-footer-logo', [
          siteMark(),
          Text('CoUI').titleMedium.onSurface,
        ]),
        p(classes: 'site-footer-note', [
          span([Text('Flutter와 Jaspr Web을 위한').bodySmall]),
          Component.text(' '),
          span([Text('크로스 플랫폼 디자인 시스템.').bodySmall]),
          Component.text(' '),
          span([Text('© cocode').bodySmall]),
        ]),
      ]),
      sections: [
        _column('Getting Started', [
          ('/getting-started', '빠른 시작'),
          ('/principles', '설계 원칙'),
          (siteGuidePath('cross-platform'), '크로스 플랫폼'),
        ]),
        _column('시스템', const [
          ('/tokens/overview', 'Foundations'),
          ('/components-overview', 'Components'),
          ('/blocks', 'Blocks'),
        ]),
        _column('Resources', [
          (siteGuidePath('figma-library'), 'Figma 라이브러리'),
          (siteGuidePath('mcp'), 'AI · MCP'),
          ('/changelog', 'Changelog'),
        ]),
      ],
    );
  }

  /// 면 · 여백 · 열 제목의 글자.
  ///
  /// 면과 여백은 푸터를 감싼 레이아웃 상자가 정한다 — 면의 색이 페이지
  /// 밝기마다 다른 토큰을 읽어서, 토큰 하나를 받는 이 슬롯으로는 적을 수
  /// 없다.
  static final CoreFooterStyle _style = CoreFooterStyle(
    backgroundColor: CoreColor.transparent,
    padding: CoreEdgeInsets.zero,
    titleTextStyle: const CoreTextStyle.token(
      CoreTextStyles.labelSmall,
      color: CoreColor.token(CoreColors.onSurface),
    ),
    sectionTitleGapStyle: const CoreGapStyle(size: CoreSpace.space12),
  );

  /// 링크의 글자 — 역할은 링크가 갖는다.
  ///
  /// 안쪽 `Text` 에 역할을 적으면 링크 상자는 자기 기본 역할의 줄 높이로
  /// 남아, 줄 간격이 글자보다 큰 상자를 따라간다.
  static const CoreLinkStyle _linkStyle = CoreLinkStyle(
    color: CoreColor.token(CoreColors.onSurfaceVariant),
    labelStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
  );

  /// 한 갈래 — 제목과 그 아래의 링크 목록.
  CoreFooterNavData<Component> _column(String title, List<(String href, String label)> links) {
    return CoreFooterNavData(
      title: title,
      children: [
        ul(classes: 'site-footer-links', [
          for (final (href, label) in links)
            li([
              Link(href: href, linkStyle: _linkStyle, child: Text(label)),
            ]),
        ]),
      ],
    );
  }
}
