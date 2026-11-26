// A refraction on the Web is an SVG filter named in `backdrop-filter`, and only
// Blink draws it — WebKit and Gecko accept the value and draw nothing for the
// whole list, the surface's own blur included. The answer is read off the user
// agent, and the table both Web targets and the Chrome probes read is what
// pins it: a browser added to one side and not the other fails there.

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String _kVectorsPath = 'test/fixtures/refraction_browser_vectors.json';

List<Map<String, Object?>> _cases() =>
    ((jsonDecode(File(_kVectorsPath).readAsStringSync())
                as Map<String, Object?>)['cases']!
            as List<Object?>)
        .cast<Map<String, Object?>>();

void main() {
  group('the browser answer', () {
    test('is the one the shared table states, for every browser in it', () {
      final cases = _cases();
      // A table that lost its rows, or lost one side of the answer, would pass
      // every loop below.
      expect(cases.length, greaterThanOrEqualTo(15));
      expect(cases.where((each) => each['renders']! as bool), isNotEmpty);
      expect(cases.where((each) => !(each['renders']! as bool)), isNotEmpty);

      for (final each in cases) {
        expect(
          surfaceRefractionBrowserSupported(each['userAgent']! as String),
          each['renders'],
          reason: each['name']! as String,
        );
      }
    });

    test('names the browsers that run WebKit under another name', () {
      final names = {
        for (final each in _cases())
          each['name']! as String: each['userAgent']! as String,
      };

      // Chrome, Edge and Firefox on iOS are WebKit, and the table must keep
      // saying so - they are the rows a `Chrome` substring check gets wrong.
      for (final name in [
        'Chrome on iPhone (WebKit, not Blink)',
        'Edge on iPhone (WebKit, not Blink)',
        'Firefox on iPhone (WebKit, not Gecko)',
      ]) {
        expect(names.keys, contains(name));
        expect(
          surfaceRefractionBrowserSupported(names[name]!),
          isFalse,
          reason: name,
        );
      }
    });

    test('is false where there is no browser to ask', () {
      expect(surfaceRefractionBrowserSupported(''), isFalse);
    });
  });
}
