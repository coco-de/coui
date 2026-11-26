/// 랜딩의 벤토 — 킷이 무엇을 주는지 일곱 타일로 보여 준다.
///
/// 컴포넌트 · 테마 / 코드 · 타이포그래피 · 색상 / Figma 라이브러리 · AI · MCP.
///
/// ## 타일은 사이트의 것이고, 안의 값은 킷의 것이다
///
/// 타일 상자는 이 사이트가 그린다 — 컴포넌트가 아니라 지면의 구획이기
/// 때문이다. 대신 색 · 모서리 · 간격은 전부 `--coui-*` 변수로 읽어서
/// 다크 모드와 서페이스 스타일이 바뀌면 타일도 따라간다. 타일 안에서
/// 킷에 있는 것(버튼 · 토글 · 링크 · 글자)은 킷의 컴포넌트다.
///
/// 타일이 말하는 값 — 개수, 변형 이름, 토큰 이름, 글자 크기 — 은 전부
/// `site_landing_data.dart` 가 카탈로그와 계약에서 읽어 온다.
///
/// ## 움직임
///
/// 타일은 스크롤해서 처음 보일 때 줄 단위로 차례로 들어온다. 그 밖의
/// 움직임(숫자 굴림, 탭 전환, 선택 이동)은 `web/docs-landing.js` 가 맡고,
/// 시간과 곡선은 스타일시트와 같은 모션 변수를 읽는다(`site_motion.dart`).
library;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/shared/component_catalog.dart';

import 'site_landing_data.dart';
import 'site_landing_parts.dart';
import 'site_theme_controls.dart';

/// 랜딩의 벤토.
class SiteBento extends StatelessComponent {
  /// 벤토를 만든다.
  const SiteBento({super.key});

  @override
  Component build(BuildContext context) {
    return section(
      classes: 'site-bento not-content',
      attributes: const {'aria-labelledby': 'site-bento-title'},
      [
        // 시안에는 이 구획의 제목이 없다. 그래도 타일 제목(`h3`)이 매달릴
        // 윗단계가 있어야 heading 으로 훑을 수 있으므로 보이지 않게 둔다.
        h2(id: 'site-bento-title', classes: 'site-sr-only', [Text('CoUI 한눈에 보기')]),
        div(classes: 'site-bento-row site-bento-row--lead', [_components(), _theme()]),
        div(classes: 'site-bento-row site-bento-row--tokens', [_code(), _type(), _color()]),
        div(classes: 'site-bento-row site-bento-row--tools', [_figma(), _mcp()]),
      ],
    );
  }

  /// 타일 머리 — 이름과, 있으면 더 보러 가는 링크.
  Component _head(String label, {Component? action}) => div(classes: 'site-tile-head', [
    h3(classes: 'site-tile-label', [Text(label).labelLarge.onSurfaceVariant]),
    ?action,
  ]);

  /// 타일의 두 줄 문장.
  Component _title(String first, String second) => p(classes: 'site-tile-title', [
    span([Text(first).headlineSmall.onSurface]),
    // 두 줄을 한 문장으로 읽는 쪽을 위한 낱말 경계.
    Component.text(' '),
    span([Text(second).headlineSmall.onSurface]),
  ]);

  // ── 컴포넌트 ────────────────────────────────────────────────────

  Component _components() {
    final count = siteComponentFloor;

    return article(
      classes: 'site-tile',
      attributes: kSiteReveal,
      styles: siteOrder(0),
      [
        _head('컴포넌트', action: siteTextLink('전체 보기', '/components-overview')),
        div(classes: 'site-figure', [
          p(classes: 'site-count', [
            // 읽히는 값은 이 한 줄이다. 아래의 큰 숫자는 들어올 때 굴러가고
            // 카테고리를 가리키면 그 개수로 바뀌므로, 보조 기술에는 내지
            // 않는다 — 굴러가는 도중의 숫자가 총 개수로 읽히지 않게.
            span(classes: 'site-sr-only', [Component.text('$count개 이상')]),
            // 스크립트가 이 글자를 굴린다. 서버가 적은 값이 최종 값이라
            // 스크립트가 없어도 같은 숫자가 보인다.
            span(
              classes: 'site-count-value',
              attributes: {'aria-hidden': 'true', 'data-count-to': '$count', 'data-count-suffix': '+'},
              [Component.text('$count+')],
            ),
            span(
              classes: 'site-count-unit',
              attributes: const {'aria-hidden': 'true'},
              [Text('개').headlineLarge.onSurface],
            ),
          ]),
          p(classes: 'site-figure-note', [
            Text('Flutter와 Jaspr Web에서 같은 이름, 같은 API로 제공됩니다.').bodyLarge.onSurfaceVariant,
          ]),
        ]),
        ul(
          classes: 'site-chips',
          attributes: const {'aria-label': '카테고리', 'data-count-chips': ''},
          [
            for (final group in kDocsComponentGroups)
              li([
                a(
                  href: '/components-overview#${group.id}',
                  classes: 'site-chip site-box-link',
                  attributes: {'data-count-chip': '${group.items.length}'},
                  [
                    Text(group.title).labelMedium.onSurface,
                    span(classes: 'site-chip-count', [Text('${group.items.length}').codeSm]),
                  ],
                ),
              ]),
          ],
        ),
      ],
    );
  }

  // ── 테마 ────────────────────────────────────────────────────────

  Component _theme() => article(
    classes: 'site-tile',
    attributes: kSiteReveal,
    styles: siteOrder(1),
    [
      _head('테마', action: siteTextLink('테마 가이드', siteGuidePath('theming'))),
      _title('하나의 토큰으로', '라이트와 다크를 함께'),
      div(classes: 'site-inset site-theme-controls', [const SiteThemeControls()]),
    ],
  );

  // ── 코드 ────────────────────────────────────────────────────────

  /// 코드 타일은 페이지가 밝아도 어둡다.
  ///
  /// 색을 따로 고르지 않고 타일을 어두운 밝기 범위로 감싼다 — 그 안의
  /// `--coui-*` 는 다크 값으로 다시 선언되므로, 타일의 면과 그 안의 킷
  /// 버튼이 같은 팔레트로 그려진다.
  Component _code() => BrightnessScope(
    brightness: CoreBrightness.dark,
    child: article(
      classes: 'site-tile site-tile--code',
      attributes: const {...kSiteReveal, 'data-code-tile': ''},
      styles: siteOrder(0),
      [
        div(classes: 'site-code-head', [
          h3(classes: 'site-sr-only', [Text('같은 코드, 두 플랫폼')]),
          div(
            classes: 'site-code-tabs',
            attributes: const {'role': 'tablist', 'aria-label': '플랫폼'},
            [
              // 선택된 탭 뒤의 알약 — 스크립트가 자리를 정한다.
              span(classes: 'site-code-indicator', attributes: const {'aria-hidden': 'true'}, const []),
              for (final (index, sample) in kSiteCodeSamples.indexed)
                button(
                  id: _tabId(sample),
                  classes: 'site-code-tab site-box-link',
                  attributes: {
                    'type': 'button',
                    'role': 'tab',
                    'aria-selected': '${index == 0}',
                    'aria-controls': _panelId(sample),
                    'tabindex': index == 0 ? '0' : '-1',
                  },
                  [Text(sample.label).labelMedium],
                ),
            ],
          ),
          Button(
            // 누름은 정적 스크립트가 받는다 — 서버 렌더에는 콜백이 없으므로
            // 켜진 상태를 직접 말한다.
            enabled: true,
            variant: CoreButtonVariant.plain,
            size: CoreComponentSize.sm,
            attributes: const {
              'data-code-copy': '',
              'data-idle': '복사',
              'data-copied': '복사됨',
              'data-failed': '복사하지 못했습니다',
            },
            // 다른 타일의 "보기" 와 같은 글자 — 밑줄 친 한 낱말.
            child: span(
              attributes: const {'data-code-copy-label': ''},
              [Text('복사').labelLarge.underline],
            ),
          ),
        ]),
        for (final (index, sample) in kSiteCodeSamples.indexed)
          pre(
            id: _panelId(sample),
            classes: 'site-code',
            attributes: {
              'role': 'tabpanel',
              'aria-labelledby': _tabId(sample),
              'tabindex': '0',
              if (index != 0) 'hidden': '',
            },
            [code(_lines(sample))],
          ),
        p(classes: 'site-code-note', [Text('두 플랫폼에서 같은 코드로 같은 화면을 만듭니다.').bodyMedium]),
        span(
          classes: 'site-sr-only',
          attributes: const {'role': 'status', 'aria-live': 'polite', 'data-code-status': ''},
          const [],
        ),
      ],
    ),
  );

  static String _tabId(SiteCodeSample sample) => 'site-code-tab-${sample.id}';

  static String _panelId(SiteCodeSample sample) => 'site-code-panel-${sample.id}';

  /// 한 플랫폼의 코드 — import 한 줄, 빈 줄, 그리고 공통 호출.
  ///
  /// 줄마다 끝에 개행을 담는다. 줄이 블록이라 화면에서는 개행 없이도
  /// 줄이 바뀌지만, 복사는 글자만 가져가므로 개행이 글자로 있어야 한다.
  List<Component> _lines(SiteCodeSample sample) {
    final lines = [sample.importLine, '', ...siteCodeCall];

    return [
      for (final (index, line) in lines.indexed)
        span(
          classes: index == 0 ? 'site-code-line site-code-line--muted' : 'site-code-line',
          styles: siteOrder(index),
          [Component.text('$line\n')],
        ),
    ];
  }

  // ── 타이포그래피 ────────────────────────────────────────────────

  Component _type() => article(
    classes: 'site-tile',
    attributes: kSiteReveal,
    styles: siteOrder(1),
    [
      _head(
        '타이포그래피',
        action: siteTextLink('보기', siteGuidePath('typography'), semanticLabel: '타이포그래피 보기'),
      ),
      ul(classes: 'site-type-rows', [
        for (final sample in kSiteTypeSamples)
          li(classes: 'site-type-row', [
            span(classes: 'site-type-sample', [_typeSample(sample)]),
            span(classes: 'site-type-size', [Text('${sample.size}').codeSm]),
          ]),
      ]),
      p(classes: 'site-tile-foot', [Text('${CoreFontFamily.sans} · ${CoreFontFamily.mono}').codeSm]),
    ],
  );

  /// 견본 한 줄의 글자 — 견본의 역할로 그린다.
  ///
  /// 역할 getter 는 이름이 정해진 체인이라 값으로 넘길 수 없어서, 견본이
  /// 고른 역할을 여기서 체인으로 옮긴다. 목록에 없는 역할을 고르면 랜딩을
  /// 그리는 순간 실패한다 — 견본이 조용히 기본 글자로 그려지지 않게.
  static Component _typeSample(SiteTypeSample sample) {
    final text = Text(sample.label);
    final drawn = switch (sample.role) {
      CoreTextStyles.headlineLarge => text.headlineLarge,
      CoreTextStyles.headlineSmall => text.headlineSmall,
      CoreTextStyles.titleSmall => text.titleSmall,
      CoreTextStyles.labelSmall => text.labelSmall,
      _ => throw StateError('타이포그래피 견본이 그릴 수 없는 역할: ${sample.role.name}'),
    };

    return drawn.onSurface;
  }

  // ── 색상 ────────────────────────────────────────────────────────

  Component _color() {
    final ramp = siteNeutralRamp;

    return article(
      classes: 'site-tile',
      attributes: kSiteReveal,
      styles: siteOrder(2),
      [
        _head(
          '색상',
          action: siteTextLink('보기', siteGuidePath('colors'), semanticLabel: '색상 보기'),
        ),
        // 견본은 장식이다 — 단계 이름은 가리켰을 때만 아래 줄에 나오고,
        // 색상 문서로 가는 길은 위의 링크가 준다.
        div(
          classes: 'site-swatches',
          attributes: const {'data-swatches': '', 'aria-hidden': 'true'},
          [
            for (final step in kSiteNeutralSteps)
              span(
                classes: 'site-swatch',
                attributes: {'data-swatch': 'neutral-$step · ${ramp[step]?.toHex().toLowerCase()}'},
                styles: Styles(raw: {'--swatch': 'var(--coui-neutral-$step)'}),
                const [],
              ),
          ],
        ),
        p(
          classes: 'site-tile-foot',
          attributes: const {'data-swatch-caption': ''},
          [
            Text('Neutral ${ramp.length}단계 + Semantic').bodySmall,
          ],
        ),
      ],
    );
  }

  // ── Figma 라이브러리 ────────────────────────────────────────────

  Component _figma() => article(
    classes: 'site-tile site-tile--split',
    attributes: kSiteReveal,
    styles: siteOrder(0),
    [
      div(classes: 'site-split-copy', [
        _head('Figma 라이브러리'),
        _title('디자인과 코드가', '같은 이름을 씁니다'),
        siteTextLink('라이브러리 열기', siteGuidePath('figma-library')),
      ]),
      div(
        classes: 'site-inset site-layers',
        attributes: const {'data-layers': ''},
        [
          // 선택된 줄 뒤의 면 — 스크립트가 자리를 정한다.
          span(classes: 'site-layer-indicator', attributes: const {'aria-hidden': 'true'}, const []),
          ul(
            classes: 'site-layer-list',
            attributes: const {'aria-label': 'Figma 레이어'},
            [
              for (final (index, layer) in siteLayers.indexed)
                li([
                  a(
                    href: layer.href,
                    classes: 'site-layer site-box-link',
                    attributes: {
                      'data-layer': '',
                      if (index == 0) 'data-active': '',
                      'data-name': layer.name,
                      'data-property': layer.property,
                      'data-value': layer.value,
                      'data-token': layer.token,
                    },
                    [
                      span(classes: 'site-layer-glyph', attributes: const {'aria-hidden': 'true'}, const []),
                      Text(layer.name).labelMedium.onSurface,
                      span(classes: 'site-layer-property', [Text(layer.figmaProperty).codeSm]),
                    ],
                  ),
                ]),
            ],
          ),
        ],
      ),
    ],
  );

  // ── AI · MCP ────────────────────────────────────────────────────

  /// 응답 예시는 레이어 목록의 선택을 따라간다.
  ///
  /// 서버는 첫 줄의 값을 적고, 스크립트가 선택이 바뀔 때 같은 자리의
  /// 글자를 바꾼다 — 그래서 값은 레이어 줄의 `data-*` 한 곳에만 있다.
  Component _mcp() {
    final layer = siteLayers.first;

    Component field(String name, String value) => span(
      attributes: {'data-mcp-field': name},
      [Component.text(value)],
    );

    return article(
      classes: 'site-tile site-tile--split',
      attributes: kSiteReveal,
      styles: siteOrder(1),
      [
        div(classes: 'site-split-copy', [
          _head('AI · MCP'),
          _title('에이전트가 CoUI를 읽고', '화면을 만듭니다'),
          siteTextLink('연결 가이드', siteGuidePath('mcp')),
        ]),
        pre(
          classes: 'site-inset site-response',
          attributes: const {'data-mcp-response': '', 'aria-label': 'MCP 응답 예시'},
          [
            code([
              Component.text('{\n  "component": "'),
              field('name', layer.name),
              Component.text('",\n  "'),
              field('property', layer.property),
              Component.text('": "'),
              field('value', layer.value),
              Component.text('",\n  "token": "'),
              field('token', layer.token),
              Component.text('"\n}'),
            ]),
          ],
        ),
      ],
    );
  }
}
