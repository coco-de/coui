import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:test/test.dart';

void main() {
  // #5497 — every Web emit of a family goes through one conversion, so a
  // Style override keeps the face's fallback stack (the Hangul in mono text
  // falls to the text face, as Flutter's fallback list does).
  group('a family override keeps its fallback stack', () {
    test('a known face rides its variable', () {
      expect(
        const CoreTextStyle(fontFamily: CoreFontFamily.mono).toInlineCss(),
        containsPair('font-family', 'var(--coui-font-family-mono)'),
      );
      expect(
        const CoreTextStyle(fontFamily: CoreFontFamily.sans).toInlineCss(),
        containsPair('font-family', 'var(--coui-font-family-sans)'),
      );
    });

    test('an app face is named with the text face behind it', () {
      expect(
        const CoreTextStyle(fontFamily: 'Hahmlet').toInlineCss(),
        containsPair(
          'font-family',
          '"Hahmlet", var(--coui-font-family-sans)',
        ),
      );
    });
  });

  // A bare name written by hand loses the stack — this is the shape the nine
  // component resolvers had. Read the sources so a new one cannot appear.
  test('no component writes font-family except through fontFamilyCss', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('core_to_css.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.contains("'font-family'")) continue;
        final next = i + 1 < lines.length ? lines[i + 1] : '';
        if (!'$line$next'.contains('fontFamilyCss(')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
