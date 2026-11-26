import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

import '../../../../tool/parity/test/fixtures/core_opacity_scale_cases.dart';

void main() {
  final config = ThemeConfig.defaults().tailwindConfig;
  test('registers exactly the existing Core opacity scale under extend', () {
    final block = RegExp(r'opacity:\{([^}]+)\}').firstMatch(config);
    expect(block, isNotNull);
    final entries = block!.group(1)!.split(',');
    expect(entries.length, coreOpacityCases.length);
    for (final entry in coreOpacityCases.entries) {
      expect(entries, contains('${entry.key}:"${entry.value}"'));
    }
    expect(config, contains('theme:{extend:{'));
  });
}
