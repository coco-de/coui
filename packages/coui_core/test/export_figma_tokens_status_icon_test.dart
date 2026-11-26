// The status indicator slots (`color/error-icon` … `color/info-icon`) as the
// Figma export publishes them.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` relative to its working directory): an alias is
// a property of the whole emitted document, so a fixture would only prove the
// fixture. The CoUI rows are the ones the designer's file already holds
// (#5725), so the next Import leaves them as they are.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const _kModes = ['Light', 'Dark', 'HCLight', 'HCDark'];
const _kFamilies = ['error', 'success', 'warning', 'info'];

void main() {
  late Map<String, Map<String, dynamic>> semanticColour;

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_status_icon_');
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

  List<String> aliases(String brand, String variable) {
    final row = semanticColour[brand]![variable] as Map<String, dynamic>?;
    expect(row, isNotNull, reason: '$brand has no $variable');
    final values = row!['valuesByMode'] as Map<String, dynamic>;

    return [
      for (final mode in _kModes)
        (values[mode] as Map<String, dynamic>)['alias'] as String,
    ];
  }

  test('every brand collection publishes the four slots', () {
    expect(semanticColour, isNotEmpty);
    for (final brand in semanticColour.keys) {
      for (final family in _kFamilies) {
        expect(
          semanticColour[brand],
          contains('color/$family-icon'),
          reason: brand,
        );
      }
    }
  });

  test('CoUI aliases each status ramp at 500 · 500 · 700 · 300 '
      '(warning 400 in dark)', () {
    for (final family in _kFamilies) {
      final dark = family == 'warning' ? '400' : '500';
      expect(aliases('coui', 'color/$family-icon'), [
        'Primitives/color/coui/$family/500',
        'Primitives/color/coui/$family/$dark',
        'Primitives/color/coui/$family/700',
        'Primitives/color/coui/$family/300',
      ], reason: family);
    }
  });
}
