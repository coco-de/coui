// `link` as the Figma export publishes it — the slot read at the point where
// a designer's variable is created, not at the scheme.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` relative to its working directory): the aliases
// are a property of the whole emitted document, so a fixture would only prove
// the fixture.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const _kModes = ['Light', 'Dark', 'HCLight', 'HCDark'];

void main() {
  late Map<String, Map<String, dynamic>> semanticColour;

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_link_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final result = Process.runSync(Platform.resolvedExecutable, [
      'run',
      script,
    ], workingDirectory: tmp.path);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final doc =
        jsonDecode(
              File('${tmp.path}/build/tokens.figma.json').readAsStringSync(),
            )
            as Map<String, dynamic>;

    // Brand id -> that brand's `color/...` rows by name.
    semanticColour = {
      for (final c in (doc['collections'] as List).cast<Map<String, dynamic>>())
        if ((c['name'] as String).startsWith('Semantic/ Color · '))
          (c['name'] as String).split(' · ').last.toLowerCase(): {
            for (final v
                in (c['variables'] as List).cast<Map<String, dynamic>>())
              v['name'] as String: v,
          },
    };
  });

  String aliasOf(String brand, String variable, String mode) {
    final row = semanticColour[brand]![variable] as Map<String, dynamic>?;
    expect(row, isNotNull, reason: '$brand has no $variable');
    final values = row!['valuesByMode'] as Map<String, dynamic>;
    expect(values, contains(mode), reason: '$brand $variable');
    final value = values[mode] as Map<String, dynamic>;

    return value['alias'] as String;
  }

  test('the library brand publishes the slot', () {
    expect(semanticColour.keys, ['coui']);
    expect(semanticColour['coui'], contains('color/link'));
  });

  test('CoUI aliases the info ramp at 700 · 400 · 800 · 200', () {
    expect(
      [for (final mode in _kModes) aliasOf('coui', 'color/link', mode)],
      [
        'Primitives/color/coui/info/700',
        'Primitives/color/coui/info/400',
        'Primitives/color/coui/info/800',
        'Primitives/color/coui/info/200',
      ],
    );
  });
}
