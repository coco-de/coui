// FR-004 — BDD acceptance for the schema v3 `examples` surface, from
// `docs/bdd-figma-contract-components.md`'s "예시는 식 스니펫만" scenario.
import 'package:test/test.dart';

import '../bin/figma_reader/example_reader.dart';

const _kExamplesRoot = '../../docs_core/lib/previews/examples';
const _kComponentsRoot = '../coui_flutter/lib/src/components';

void main() {
  final examples = readExamples(
    examplesRoot: _kExamplesRoot,
    componentsRoot: _kComponentsRoot,
    slugs: const ['tabs', 'badge', 'button', 'gap'],
  );

  test('Scenario: 예시는 식 스니펫만 — 보일러플레이트 배제', () {
    final tabs = examples['tabs']!;
    expect(tabs.withStyle, isNotNull);
    expect(tabs.withStyle, contains('withStyle('));
    expect(tabs.withStyle, contains('CoreTabsStyle'));
    // The docs example's *expression*, never its wrapper class.
    expect(tabs.withStyle, isNot(contains('class ')));
    expect(tabs.withStyle, isNot(contains('StatefulComponent')));
    expect(tabs.withStyle, isNot(contains('StatefulWidget')));
    // Original formatting preserved (multi-line, not toSource() flattening).
    expect(tabs.withStyle, contains('\n'));
  });

  test('tokenChain — 실재 getter 이름으로만 조립', () {
    final tabs = examples['tabs']!;
    expect(tabs.tokenChain, isNotNull);
    expect(tabs.tokenChain, startsWith('Tabs(…).'));

    final badge = examples['badge']!;
    expect(badge.tokenChain, startsWith('Badge(…).'));
  });

  test('tokenChain names the default radius the docs chain teaches', () {
    final taught = readExamples(
      examplesRoot: _kExamplesRoot,
      componentsRoot: _kComponentsRoot,
      contractsRoot: 'lib/src/component/contracts',
      slugs: const ['carousel', 'tree', 'badge'],
    );
    // Carousel's chain ends on `.radius16` and that step is
    // `defaultBorderRadius`, so the stamp agrees with the docs and the
    // canvas binding.
    expect(taught['carousel']!.tokenChain, 'Carousel(…).radius16');
    // Tree's chain also ends on `.radius16`, but its default corner is
    // `radius6`, so the stamp stays the extension's first getter.
    expect(taught['tree']!.tokenChain, 'Tree(…).radius0');
    expect(taught['badge']!.tokenChain, startsWith('Badge(…).'));
  });

  test('chain example 이 없어도 extension 보유 시 canonical 파생', () {
    // Button has a StyleChain extension; whether or not a chain example
    // file exists, withStyle must be non-null (빈 값 금지 — extension 보유
    // 컴포넌트 한정).
    final button = examples['button']!;
    expect(button.withStyle, isNotNull);
    expect(button.withStyle, contains('withStyle('));
  });

  test('extension 이 없는 컴포넌트는 정직한 null (조작 금지)', () {
    final gap = examples['gap']!;
    expect(gap.tokenChain, isNull);
  });

  test('examplesJson — keys always present', () {
    expect(examplesJson(.none), {'withStyle': null, 'tokenChain': null});
  });
}
