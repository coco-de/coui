import 'package:test/test.dart';

import '../../src/manifest/changed_components.dart';

void main() {
  group('changedComponentsFor — component-scoped paths', () {
    test('a Flutter component path maps to that component', () {
      final result = changedComponentsFor([
        'packages/coui_flutter/lib/src/components/form/checkbox/checkbox.dart',
      ]);
      expect(result, isA<ChangedComponentSet>());
      expect((result as ChangedComponentSet).slugs, {'checkbox'});
    });

    test('a Web component path maps to the same component slug', () {
      final result = changedComponentsFor([
        'packages/coui_web/lib/src/components/layout/card/card_style.dart',
      ]);
      expect(result, isA<ChangedComponentSet>());
      expect((result as ChangedComponentSet).slugs, {'card'});
    });

    test('a Core contract path maps to that component', () {
      final result = changedComponentsFor([
        'packages/coui_core/lib/src/component/contracts/checkbox/checkbox_style.dart',
      ]);
      expect(result, isA<ChangedComponentSet>());
      expect((result as ChangedComponentSet).slugs, {'checkbox'});
    });

    test('a snake_case directory name maps to the kebab-case catalog slug', () {
      final result = changedComponentsFor([
        'packages/coui_flutter/lib/src/components/form/date_picker/date_picker.dart',
      ]);
      expect(result, isA<ChangedComponentSet>());
      expect((result as ChangedComponentSet).slugs, {'date-picker'});
    });

    test('multiple components across platforms union into one set', () {
      final result = changedComponentsFor([
        'packages/coui_flutter/lib/src/components/form/checkbox/checkbox.dart',
        'packages/coui_web/lib/src/components/layout/card/card.dart',
        'packages/coui_core/lib/src/component/contracts/checkbox/checkbox_theme.dart',
      ]);
      expect(result, isA<ChangedComponentSet>());
      expect((result as ChangedComponentSet).slugs, {'checkbox', 'card'});
    });

    test('a nested file deep under a component directory still maps', () {
      final result = changedComponentsFor([
        'packages/coui_web/lib/src/components/form/checkbox/nested/deep.dart',
      ]);
      expect(result, isA<ChangedComponentSet>());
      expect((result as ChangedComponentSet).slugs, {'checkbox'});
    });
  });

  group('changedComponentsFor — fallback to all ("모르면 전체")', () {
    test('a component-shaped path with an unknown slug falls back', () {
      final result = changedComponentsFor([
        'packages/coui_web/lib/src/components/form/not-a-real-component/x.dart',
      ]);
      expect(result, isA<ChangedComponentFallbackToAll>());
    });

    // The exact example paths #3610's own body names as infra — these must
    // trigger the fallback without a maintained infra-path list, purely by
    // being pipeline library source outside any component's own directory.
    for (final infraPath in [
      'packages/coui_web/lib/src/base/theme_config.dart',
      'packages/coui_core/lib/src/surface/surface_recipe.dart',
      'packages/coui_web/lib/src/util/core_to_css.dart',
      'packages/coui_flutter/lib/src/util/core_to_flutter.dart',
    ]) {
      test('infra path triggers fallback: $infraPath', () {
        final result = changedComponentsFor([infraPath]);
        expect(result, isA<ChangedComponentFallbackToAll>(), reason: infraPath);
      });
    }

    test('one infra path outweighs many matched component paths', () {
      final result = changedComponentsFor([
        'packages/coui_flutter/lib/src/components/form/checkbox/checkbox.dart',
        'packages/coui_web/lib/src/components/layout/card/card.dart',
        'packages/coui_core/lib/src/surface/surface_recipe.dart',
      ]);
      expect(result, isA<ChangedComponentFallbackToAll>());
    });

    test('the fallback reason names the path that triggered it', () {
      final result =
          changedComponentsFor([
                'packages/coui_web/lib/src/base/theme_config.dart',
              ])
              as ChangedComponentFallbackToAll;
      expect(result.reason, contains('theme_config.dart'));
    });
  });

  group('changedComponentsFor — component-agnostic PRs exit early', () {
    test('no changed paths at all is none', () {
      expect(changedComponentsFor(const []), isA<ChangedComponentNone>());
    });

    test('a README-only diff is none, not a fallback', () {
      final result = changedComponentsFor(['README.md']);
      expect(
        result,
        isA<ChangedComponentNone>(),
        reason:
            '컴포넌트 무관 PR(예: README)은 매트릭스가 비어 조기 종료해야 한다 — '
            '전체로 폴백하면 매 README PR 마다 불필요하게 전체 매트릭스가 돈다',
      );
    });

    test('docs and CI paths outside the pipeline library trees are none', () {
      final result = changedComponentsFor([
        '.github/workflows/ci.yaml',
        'docs_core/content/components/card.md',
      ]);
      expect(result, isA<ChangedComponentNone>());
    });

    test('an irrelevant path alongside a real component still narrows', () {
      final result = changedComponentsFor([
        'README.md',
        'packages/coui_flutter/lib/src/components/form/checkbox/checkbox.dart',
      ]);
      expect(result, isA<ChangedComponentSet>());
      expect((result as ChangedComponentSet).slugs, {'checkbox'});
    });
  });
}
