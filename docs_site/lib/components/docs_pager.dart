/// 이전 · 다음 페이저 — 읽는 순서로 앞뒤 페이지에 가는 두 장의 카드.
///
/// 앞뒤는 사이트 구조(`docs_navigation.dart`)의 순서에서 온다. 탭의 끝에서는
/// 다음 탭의 첫 페이지로 이어진다 — 문서를 처음부터 따라 읽는 사람이 탭의
/// 경계에서 길을 잃지 않는다.
library;

import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/shared/docs_navigation.dart';

/// 페이저 랜드마크의 이름.
const String kDocsPagerLabel = '이전 · 다음 문서';

/// 이전 · 다음 페이저.
class DocsPager extends StatelessComponent {
  /// 페이저를 만든다.
  const DocsPager({
    required this.location,
    this.showPrevious = true,
    this.previousPage,
    this.nextPage,
    super.key,
  });

  /// 지금 페이지가 구조 안에서 놓인 자리.
  final DocsNavLocation location;
  final bool showPrevious;
  final DocsNavPage? previousPage;
  final DocsNavPage? nextPage;

  @override
  Component build(BuildContext context) {
    final previous = showPrevious ? previousPage ?? location.previous : null;
    final next = nextPage ?? location.next;
    if (previous == null && next == null) return const Component.fragment([]);

    return nav(
      classes: 'docs-pager not-content',
      attributes: const {'aria-label': kDocsPagerLabel},
      [
        // 한쪽만 있으면 그 카드가 줄을 다 쓴다 — 다음 카드는 오른쪽 끝에
        // 글자를 맞춘다(Figma `Doc/Pager`).
        if (previous != null) _card(previous, label: '이전', previous: true),
        if (next != null) _card(next, label: '다음', previous: false),
      ],
    );
  }

  Component _card(DocsNavPage page, {required String label, required bool previous}) {
    return a(
      href: page.path,
      classes: previous
          ? 'docs-pager-card docs-pager-card--previous site-box-link'
          : 'docs-pager-card docs-pager-card--next site-box-link',
      attributes: {'rel': previous ? 'prev' : 'next'},
      [
        // 어느 쪽인지는 이름표와 놓인 자리(왼쪽 · 오른쪽)가 말한다 — 화살표를
        // 덧붙이지 않는다(Figma `Doc/Pager`).
        span(classes: 'docs-pager-label', [Text(label).bodyXs]),
        span(classes: 'docs-pager-title', [Text(page.label).titleSmall.onSurface]),
      ],
    );
  }
}
