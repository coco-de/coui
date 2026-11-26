// FR-003 — BDD acceptance for the schema v3 `docs` surface, from
// `docs/bdd-figma-contract-components.md`'s "설명 우선순위" scenario. Runs
// against the real docs_core tree (same no-fixture reasoning as the other
// reader tests).
import 'package:test/test.dart';

import '../bin/figma_reader/docs_reader.dart';

const _kContentRoot = '../../docs_core/content/components';
const _kBlocksRoot = '../../docs_core/content/blocks';
const _kCatalogPath = '../../docs_core/lib/shared/component_catalog.dart';

/// The docs catalog's entry count at the time of writing — a floor, not an
/// exact pin, so new components don't break this test. 138 following
/// `Group`'s removal (deprecated since 0.128; removed by explicit
/// decision ahead of the two-minor deprecation window).
const _kCatalogEntryFloor = 138;

void main() {
  final docs = readDocs(
    contentRoot: _kContentRoot,
    catalogPath: _kCatalogPath,
    blocksRoot: _kBlocksRoot,
  );

  test('Scenario: 설명 우선순위 — 한국어 md 우선', () {
    final button = docs['button'];
    expect(button?.lang, 'ko');
    expect(button?.description, isNotNull);
    expect(button?.description, contains('버튼'));
  });

  test('catalog fallback fills components the md tree lacks', () {
    // Both sources are keyed by kebab slug; every catalog entry must be
    // present even when no md file exists for it.
    expect(docs.length, greaterThanOrEqualTo(_kCatalogEntryFloor));
    final fallbacks = docs.values.where((d) => d.lang == 'en');
    for (final d in fallbacks) {
      expect(d.description, isNotEmpty);
    }
  });

  test('docsJson — keys always present, three slug spellings agree', () {
    final json = docsJson(docs['radio-group'], snakeSlug: 'radio_group');
    expect(json.keys.toList(), [
      'description',
      'lang',
      'url',
      'order',
      'slugs',
    ]);
    expect(json['url'], '$kDocsSiteBaseUrl/components/radio-group');
    expect(json['slugs'], {
      'kebab': 'radio-group',
      'snake': 'radio_group',
      'pascal': 'RadioGroup',
    });
  });

  test('footer block page wins the Korean description and the /blocks URL', () {
    final footer = docs['footer'];
    expect(footer?.lang, 'ko');
    expect(footer?.section, 'blocks');
    expect(footer?.order, isNull);
    final json = docsJson(footer, snakeSlug: 'footer');
    expect(json['url'], '$kDocsSiteBaseUrl/blocks/footer');
  });

  test('block page wins the Korean description and the /blocks URL', () {
    final hero = docs['hero'];
    expect(hero?.lang, 'ko');
    expect(
      hero?.description,
      '페이지 흐름 안에 놓이는 히어로 블록입니다. 배경색, 선택적 배경 이미지와 '
      '오버레이, 전경 콘텐츠를 그리며 위에 떠 있는 오버레이는 아닙니다. 이전 '
      '이름은 HeroSection입니다.',
    );
    expect(hero?.section, 'blocks');
    final json = docsJson(hero, snakeSlug: 'hero');
    expect(json['url'], '$kDocsSiteBaseUrl/blocks/hero');
    expect(json['order'], isNull);
  });

  test('docsJson — unknown component stays honest (null, not fabricated)', () {
    final json = docsJson(docs['no-such-component'], snakeSlug: 'no_such');
    expect(json['description'], isNull);
    expect(json['lang'], isNull);
    expect(json['order'], isNull);
    expect(json['url'], isNotNull); // URL is derivable regardless
  });

  test('order — the flat, curated position kDocsComponentEntries assigns', () {
    // Control is the catalog's first group; button/command/fab/hover/
    // theme-controller/filter is its item order verbatim — a rewrite of this
    // test to "just assert increasing" would stop catching a reshuffle
    // within the group, which is exactly the kind of edit this field exists
    // to carry into the plugin.
    expect(docsJson(docs['button'], snakeSlug: 'button')['order'], 0);
    expect(docsJson(docs['command'], snakeSlug: 'command')['order'], 1);
    expect(docsJson(docs['fab'], snakeSlug: 'fab')['order'], 2);
    expect(docsJson(docs['hover'], snakeSlug: 'hover')['order'], 3);
    final themeController = docsJson(
      docs['theme-controller'],
      snakeSlug: 'theme_controller',
    );
    expect(themeController['order'], 4);
    expect(docsJson(docs['filter'], snakeSlug: 'filter')['order'], 5);

    // Form is the second group — its first item continues the flat count
    // rather than restarting at 0, because `order` is a position in
    // `kDocsComponentEntries` (one flat list), not a per-group rank.
    expect(
      docsJson(docs['text-field'], snakeSlug: 'text_field')['order'],
      greaterThan(5),
    );

    // `button`'s description came from its Korean md file (`lang: 'ko'`,
    // asserted in the scenario test above), not from the catalog's English
    // fallback — yet its order is still 0. Position is a structural fact the
    // catalog states regardless of which loop last wrote the description.
    expect(docs['button']?.lang, 'ko');
    expect(docsJson(docs['button'], snakeSlug: 'button')['order'], 0);
  });
}
