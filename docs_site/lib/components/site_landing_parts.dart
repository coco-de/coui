/// 랜딩의 섹션들이 함께 쓰는 작은 조각.
library;

import 'package:coui_web/coui_web.dart';

export 'package:docs_core/internal/preview/web_card_view.dart' show siteArrow, siteOrder;

/// 스크롤해서 처음 보일 때 들어오는 요소의 표시.
///
/// 이 속성만으로는 아무것도 숨기지 않는다. 숨김은 문서가 "스크립트가
/// 등장을 맡았다" 고 표시했을 때만 걸리므로(`data-site-motion`), 스크립트가
/// 없는 환경에서는 처음부터 보인다.
const Map<String, String> kSiteReveal = {'data-reveal': ''};

/// 본문 색의 밑줄 링크 — 타일 머리와 섹션 머리의 "보기" 류.
///
/// [semanticLabel] 은 보이는 글자만으로 목적지를 알 수 없을 때 준다 —
/// 한 화면에 "보기" 가 둘이면 링크 목록에서 서로를 가릴 수 없다.
Component siteTextLink(String label, String href, {String? semanticLabel}) => Link(
  href: href,
  underline: true,
  linkStyle: const CoreLinkStyle(
    color: CoreColor.token(CoreColors.onSurface),
    underlineColor: CoreColor.token(CoreColors.onSurface),
  ),
  attributes: {'aria-label': ?semanticLabel},
  child: Text(label).labelLarge,
);
