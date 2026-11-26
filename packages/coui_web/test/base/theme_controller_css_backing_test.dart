import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// A theme name on `CoUIThemeController`, read from source together with
/// whether it carries an `@Deprecated` annotation.
typedef _ThemeConstant = ({String name, bool deprecated});

final _constant = RegExp(
  r'(@Deprecated\((?:[^)]|\)(?!\s*\n\s*static))*\)\s*)?'
  r"static const (\w+) = '(\w+)';",
);

List<_ThemeConstant> _readConstants(String path) {
  final source = File(path).readAsStringSync();
  return [
    for (final match in _constant.allMatches(source))
      (name: match.group(3)!, deprecated: match.group(1) != null),
  ];
}

void main() {
  // What this covers: `CoUIThemeController` advertised thirty theme names
  // that `ThemeConfig` never defined — `setTheme('cupcake')` wrote the
  // attribute and nothing changed, because no rule selects it. The names
  // are deprecated rather than removed (process/deprecation.md), so the
  // lock is two-way: a live name must have CSS behind it, and a
  // deprecated one must still have none (if someone authors the palette,
  // the deprecation has to come off with it).
  final config = ThemeConfig.defaults();
  final emitted = [
    config.cssVariables,
    config.darkVariableBlock,
    config.darkAutoVariableBlock,
    config.surfaceStyleVariableBlocks,
  ].join('\n');

  final web = _readConstants('lib/src/base/theme_controller_web.dart');
  final stub = _readConstants('lib/src/base/theme_controller_stub.dart');

  test('the source scan finds every theme name', () {
    // Guards the regex itself: an empty scan would pass every check below.
    expect(web, hasLength(CoUIThemeController.availableThemes.length));
  });

  test('web and stub controllers declare the same names the same way', () {
    // The stub is what SSR compiles; a name deprecated on one side only
    // warns on one build and stays silent on the other.
    expect(stub, equals(web));
  });

  test('every live theme name is selected by an emitted rule', () {
    final live = web.where((c) => !c.deprecated).map((c) => c.name);
    expect(live, containsAll(<String>['light', 'dark']));
    for (final name in live) {
      expect(
        emitted,
        contains('data-theme="$name"'),
        reason:
            '`$name` is offered without a deprecation, so ThemeConfig '
            'must emit a rule that selects it.',
      );
    }
  });

  test('every deprecated theme name still has no CSS behind it', () {
    final deprecated = web.where((c) => c.deprecated).map((c) => c.name);
    expect(deprecated, isNotEmpty);
    for (final name in deprecated) {
      expect(
        emitted,
        isNot(contains('data-theme="$name"')),
        reason: '`$name` now has CSS — lift its @Deprecated.',
      );
    }
  });
}
