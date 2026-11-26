/// 두 레이아웃이 함께 쓰는 `<head>` — 토큰 · 시트 · 스크립트.
///
/// 문서 레이아웃과 랜딩 레이아웃은 같은 헤더를 그리고 같은 토큰을 읽는다.
/// 그 준비물을 레이아웃마다 따로 적으면 한쪽에서만 스크립트가 빠지고, 그
/// 차이는 "랜딩에서만 검색이 안 열린다" 로 나타난다. 그래서 한 컴포넌트다.
///
/// ## 문서가 렌더 트리의 루트다
///
/// jaspr 는 렌더된 트리의 **맨 위**에서 `<html>` 을 찾고, 없으면 바깥에 문서를
/// 하나 세운다. 앱 루트(`CoUIWeb`)는 상자를 그리므로, 그것을 문서 위에 놓으면
/// 레이아웃이 낸 `<html><head>` 는 그 상자 안 — 본문 한가운데 — 에 남는다.
/// 브라우저는 거기 든 제목 · 설명 · `<base>` · 문자셋을 본문의 요소로 읽는다:
/// 한글이 깨지고, 상대 주소가 페이지 경로에 붙고, 에러는 나지 않는다.
///
/// 그래서 앱 루트는 문서 **안**에 놓는다. 레이아웃은 본문을 [siteAppRoot] 로
/// 감싸고, 문서를 스스로 세우지 않는 라우트(옛 주소의 안내, `/embed`)는
/// 라우터가 같은 것으로 감싼다.
library;

import 'package:coui_web/coui_web.dart' show CoUIWeb, Locale, ThemeData;
import 'package:docs_core/shared/docs_locale.dart';
import 'package:docs_core/site_head.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import '../components/component_grid.dart';
import '../components/site_motion.dart';
import '../components/site_theme_toggle.dart';
import '../components/surface_style_switcher.dart';

/// 문서 셸의 시트 — 헤더 · 사이드바 · 본문 · 문서 블록.
const String kDocsShellStylesheet = '/docs-shell.css';

/// 문서 셸의 스크립트 — 복사, 플랫폼 고르기, 등장.
const String kDocsShellScript = '/docs-shell.js';

/// "이 페이지에서" 의 읽는 자리 스크립트.
const String kDocsTocScript = '/docs-toc.js';

/// 사이트의 앱 루트 — 킷의 테마 · 로케일 · 오버레이 호스트.
///
/// 문서의 본문 안에 놓는다(위 문서). 문서 위에 놓으면 문서가 둘이 된다.
Component siteAppRoot({required Component child}) {
  return CoUIWeb(theme: ThemeData.coui, locale: const Locale(kDocsLanguageCode), child: child);
}

/// 두 레이아웃이 문서의 `<head>` 에 싣는 것 — 본문 트리의 맨 앞에 놓는다.
///
/// `Document.head` 는 트리의 어디에 놓이든 문서의 `<head>` 에 붙는다. 두
/// 레이아웃이 같은 컴포넌트 하나를 놓으므로 한쪽에서만 빠질 수 없다.
class SiteChromeHead extends StatelessComponent {
  /// 머리 준비물을 만든다.
  const SiteChromeHead({super.key});

  @override
  Component build(BuildContext context) => Document.head(children: _children().toList());
}

Iterable<Component> _children() sync* {
  // 문자셋 · Tailwind 설정 · CSS 변수 · 글꼴 — `/embed` 라우트와 글자 그대로
  // 같은 것이라, 두 표면이 디자인 시스템을 같게 푼다.
  yield* docsSharedHead();

  // 밝기와 서페이스 스타일의 첫 값. 둘 다 첫 페인트 전에 문서 속성에
  // 적혀야 한다 — 뒤에 적으면 페이지를 옮길 때마다 기본값이 먼저 그려진다.
  yield Component.element(tag: 'script', children: [const RawText(kSiteThemeRestoreScript)]);
  yield Component.element(tag: 'script', children: [RawText(kSurfaceStyleScript)]);

  // 모션 어휘. 시트보다 먼저 온다 — 시트의 전환이 읽는 변수다.
  yield Component.element(tag: 'style', children: [RawText(siteMotionRootCss)]);
  yield link(rel: 'stylesheet', href: kDocsShellStylesheet);
  yield script(src: kDocsShellScript, attributes: const {'defer': ''});
  yield script(src: kDocsTocScript, attributes: const {'defer': ''});

  yield script(src: '/flutter_bootstrap.js', attributes: const {'async': ''});

  // LivePreview 코드 패널의 highlight.js.
  yield Component.element(
    tag: 'link',
    attributes: const {
      'rel': 'stylesheet',
      'href': 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css',
    },
  );
  yield script(src: 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js');
  yield script(src: 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/dart.min.js');
  yield Component.element(tag: 'script', children: [const RawText(_kHighlightScript)]);

  yield Component.element(
    tag: 'style',
    children: [
      const RawText(
        '@keyframes shimmer{0%{background-position:200% 0}'
        '100%{background-position:-200% 0}}',
      ),
    ],
  );

  yield Style(
    styles: [
      // Preflight reset + LivePreview — `/embed` 라우트와 함께 쓴다.
      ...docsPreviewStyles(),
      // 갤러리 카드 — `/components-overview` 의 것.
      ...showcaseStyles(),
    ],
  );
}

/// LivePreview 코드 패널을 highlight.js 로 칠한다 — 나중에 붙는 패널까지.
const String _kHighlightScript =
    'document.addEventListener("DOMContentLoaded",function(){'
    'if(typeof hljs!=="undefined"){'
    'document.querySelectorAll("code.language-dart")'
    '.forEach(function(el){hljs.highlightElement(el)});'
    'new MutationObserver(function(ms){ms.forEach(function(m){'
    'm.addedNodes.forEach(function(n){'
    'if(n.nodeType===1){'
    'n.querySelectorAll&&n.querySelectorAll("code.language-dart:not(.hljs)")'
    '.forEach(function(el){hljs.highlightElement(el)})'
    '}'
    '})})})'
    '.observe(document.body,{childList:true,subtree:true})'
    '}'
    '})';
