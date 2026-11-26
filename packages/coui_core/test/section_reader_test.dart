// FR-002 — BDD acceptance for the schema v3 `section` fold, from
// `docs/bdd-figma-contract-components.md`'s "섹션 fold" scenario. Runs
// against the real coui_flutter tree for the same reason
// axis_reader_test.dart runs against real contracts: the fold is a claim
// about this codebase's directories, and a fixture would rot silently.
import 'package:test/test.dart';

import '../bin/figma_reader/section_reader.dart';

const _kComponentsRoot = '../coui_flutter/lib/src/components';

void main() {
  final sections = readSections(componentsRoot: _kComponentsRoot);

  test('Scenario: 섹션 fold — 카테고리 단위 fold 만, 근-항등 매핑', () {
    // The fold is near-identity — each category names its own section, so
    // it matches docs_core's kDocsComponentGroups 1:1 (§kSectionFold doc).
    expect(sections['tabs']?.name, 'Navigation');
    expect(sections['tabs']?.sourceCategory, 'navigation');

    expect(sections['badge']?.name, 'Display');
    expect(sections['badge']?.sourceCategory, 'display');

    expect(sections['checkbox']?.name, 'Form');
    expect(sections['accordion']?.name, 'Layout');

    // menu / overlay keep their own section — no longer folded into
    // Control / Display.
    expect(sections['dropdown_menu']?.name, 'Menu');
    expect(sections['dialog']?.name, 'Overlay');
  });

  test('infra gets its own section — docs_core registers an Infra group', () {
    expect(sections['clickable']?.name, 'Infra');
    expect(sections['clickable']?.sourceCategory, 'infra');
  });

  test('locale folds out — recorded with a null section name', () {
    expect(sections['coui_localizations']?.name, isNull);
    expect(sections['coui_localizations']?.sourceCategory, 'locale');
  });

  test('secondary rule — a category directory that is itself a slug', () {
    expect(sections['icon']?.name, 'Icon');
    expect(sections['icon']?.sourceCategory, 'icon');
  });

  test('fold map covers every category directory on disk', () {
    final categories = {
      for (final s in sections.values) s.sourceCategory,
    }.whereType<String>();
    for (final category in categories) {
      expect(
        kSectionFold.containsKey(category),
        isTrue,
        reason:
            'category "$category" exists on disk but has no fold decision — '
            'add it to kSectionFold (a missing entry silently folds to null)',
      );
    }
  });

  test('sectionJson — both keys always present', () {
    expect(sectionJson(.unmapped), {
      'name': null,
      'sourceCategory': null,
    });
  });
}
