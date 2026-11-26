/// 랜딩의 본문 — 벤토 · 진입 카드 · 최근 업데이트.
///
/// 마크다운에서 `<SiteShowcase />` 로 부른다. 태그 이름은 네이티브 문서
/// 앱이 같은 `index.md` 를 읽기 때문에 그대로다 — 이름을 바꾸면 그쪽
/// 레지스트리에 없는 태그가 되어 홈이 조용히 비어 버린다.
///
/// ## 왜 카탈로그 전부를 늘어놓지 않나
///
/// 첫 화면의 일은 "무엇을 주는 킷인가"를 **한 번에 읽히게** 하는 것이다.
/// 백 몇십 개를 세로로 쌓으면 그 답 대신 스크롤이 나온다 — 훑어야 할 목록은
/// 목록의 자리(`/components-overview`)가 이미 갖고 있다.
///
/// 그래서 여기는 셋이다:
///
/// 1. **벤토** — 컴포넌트 · 테마 · 코드 · 타이포그래피 · 색상 · Figma · MCP
/// 2. **진입 카드** — 읽는 사람이 어디서 시작할지 고르는 네 갈래
/// 3. **최근 업데이트** — 패키지 CHANGELOG 의 최근 릴리스
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/markdown/repo_root.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'site_bento.dart';
import 'site_landing_data.dart';
import 'site_landing_parts.dart';

/// 마크다운 `<SiteShowcase />` 태그 핸들러.
class SiteShowcase extends CustomComponent {
  /// 랜딩 본문 태그 핸들러를 만든다.
  SiteShowcase() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(tag: 'SiteShowcase')) {
      return const SiteShowcaseView();
    }
    return null;
  }
}

/// 랜딩 본문.
class SiteShowcaseView extends StatelessComponent {
  /// 랜딩 본문을 만든다.
  const SiteShowcaseView({super.key});

  @override
  Component build(BuildContext context) => const Component.fragment([
    SiteBento(),
    SiteEntries(),
    SiteUpdates(),
  ]);
}

/// "어디서부터 시작할까요?" — 네 갈래의 진입 카드.
class SiteEntries extends StatelessComponent {
  /// 진입 카드 구획을 만든다.
  const SiteEntries({super.key});

  @override
  Component build(BuildContext context) {
    return section(
      classes: 'site-section not-content',
      attributes: const {'aria-labelledby': 'site-entries-title'},
      [
        div(classes: 'site-section-head', attributes: kSiteReveal, [
          div([
            h2(id: 'site-entries-title', [Text('어디서부터 시작할까요?').headlineLarge.onSurface]),
            p(classes: 'site-section-lead', [
              Text('처음이라면 빠른 시작부터, 이미 쓰고 있다면 필요한 문서로 바로 가세요.').bodyLarge.onSurfaceVariant,
            ]),
          ]),
        ]),
        ol(classes: 'site-entries', [
          for (final (index, entry) in siteEntryPoints.indexed)
            li(attributes: kSiteReveal, styles: siteOrder(index), [_card(index, entry)]),
        ]),
      ],
    );
  }

  /// 카드 하나 — 카드 전체가 링크다.
  ///
  /// 첫 카드만 채운 면으로 그린다: 처음 온 사람이 갈 곳이 그 하나다.
  Component _card(int index, SiteEntryPoint entry) {
    final number = '${index + 1}'.padLeft(2, '0');

    return a(
      href: entry.href,
      classes: index == 0 ? 'site-entry site-entry--lead site-box-link' : 'site-entry site-box-link',
      [
        // 순번은 `ol` 이 이미 말한다 — 글자로 한 번 더 읽히지 않게 한다.
        span(
          classes: 'site-entry-number',
          attributes: const {'aria-hidden': 'true'},
          [Text(number).codeSm],
        ),
        span(classes: 'site-entry-copy', [
          h3(classes: 'site-entry-title', [Text(entry.title).titleLarge]),
          span(classes: 'site-entry-note', [Text(entry.description).bodyMedium]),
        ]),
        // 밑줄은 글자에만 긋는다 — 줄 전체에 걸면 화살표까지 밑줄이 간다.
        span(classes: 'site-entry-action', [
          Text(entry.action).labelMedium.underline,
          siteArrow(Text('→').labelMedium),
        ]),
      ],
    );
  }
}

/// "최근 업데이트" — 패키지 CHANGELOG 의 최근 릴리스.
///
/// 줄은 손으로 적지 않는다. 빌드할 때 패키지의 `CHANGELOG.md` 를 읽으므로
/// 릴리스가 나가면 다음 빌드에서 따라온다.
class SiteUpdates extends StatelessComponent {
  /// 최근 업데이트 구획을 만든다.
  const SiteUpdates({super.key});

  /// 줄 수.
  static const int count = 3;

  /// 읽어 올 패키지 — 두 플랫폼 중 기준이 되는 쪽.
  static const String package = 'coui_flutter';

  /// 최근 릴리스 [count] 건.
  ///
  /// 파일이 없거나 읽히지 않으면 빈 목록이다 — 랜딩이 멈추는 것보다 이
  /// 구획이 링크만 남기는 편이 낫다.
  static List<SiteUpdate> read() {
    try {
      final file = File('${findRepoRoot().path}/packages/$package/CHANGELOG.md');
      if (!file.existsSync()) return const [];

      return siteUpdatesFrom(file.readAsStringSync(), count: count);
    } on Object {
      return const [];
    }
  }

  @override
  Component build(BuildContext context) {
    final updates = read();

    return section(
      classes: 'site-section site-section--updates not-content',
      attributes: const {'aria-labelledby': 'site-updates-title'},
      [
        div(classes: 'site-section-head', attributes: kSiteReveal, [
          h2(id: 'site-updates-title', [Text('최근 업데이트').headlineLarge.onSurface]),
          siteTextLink('Changelog 전체 보기', '/changelog'),
        ]),
        if (updates.isNotEmpty)
          ol(classes: 'site-updates', [
            for (final (index, update) in updates.indexed)
              li(attributes: kSiteReveal, styles: siteOrder(index), [_row(update)]),
          ]),
      ],
    );
  }

  Component _row(SiteUpdate update) => a(
    href: '/changelog',
    classes: 'site-update site-box-link',
    [
      span(classes: 'site-update-version', [Text(update.version).codeMd.onSurface]),
      span(classes: 'site-update-kind', [
        Badge(tone: _tone(update.kind), child: Text(update.kind.label)),
      ]),
      span(classes: 'site-update-summary', [Text(update.summary).bodyLarge.onSurface]),
      span(classes: 'site-update-date', [Text(update.date).bodySmall]),
    ],
  );

  /// 변경의 종류 → 배지의 톤.
  static CoreBadgeTone _tone(SiteUpdateKind kind) => switch (kind) {
    SiteUpdateKind.feature => CoreBadgeTone.info,
    SiteUpdateKind.fix => CoreBadgeTone.neutral,
    SiteUpdateKind.update => CoreBadgeTone.success,
  };
}
