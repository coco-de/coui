// The line box Flutter lays text out in — the Flutter half of the shared
// line box vectors (`coui_core/test/fixtures/line_box_vectors.json`).
//
// The Web rounds the box a multiplier draws to a whole pixel because
// Flutter's engine does: `LineMetrics.height` is `ascent + descent` rounded,
// so a 14px label at 1.4 sits in a 20px line, not 19.6. That Web rule is only
// right while the engine keeps rounding, so this file reads the line heights
// the engine actually lays out — through the conversion every CoUI text takes
// (`CoreTextStyle.toValue`) — against the table the Chrome probe reads too.
// An engine that stops rounding, or a role whose size or leading moves, fails
// here before the two platforms drift apart.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../parity/parity_fonts.dart';

/// The table shared with the Core test and the Chrome probe.
const String _kLineBoxVectorsPath =
    '../coui_core/test/fixtures/line_box_vectors.json';

/// Every scaling axis at 1, so a measured box is the role's own.
final ThemeData _theme = ThemeData.fromCore(
  CoreThemePresets.previewLight.copyWith(
    textScaling: 1,
    sizeScaling: 1,
    radiusScaling: 1,
  ),
);

/// [lineCount] lines of [style] laid out by the engine — the height of each
/// line and of the whole paragraph.
({List<double> lines, double height}) _layout(TextStyle style, int lineCount) {
  final painter = TextPainter(
    text: TextSpan(
      text: List.filled(lineCount, 'Ag 가').join('\n'),
      style: style,
    ),
    textDirection: .ltr,
  )..layout();
  final laid = (
    lines: [for (final line in painter.computeLineMetrics()) line.height],
    height: painter.height,
  );
  painter.dispose();

  return laid;
}

void main() {
  setUpAll(loadParityFonts);

  final vectors =
      jsonDecode(File(_kLineBoxVectorsPath).readAsStringSync())
          as Map<String, dynamic>;

  group('a role lays every line out in its table box', () {
    for (final row in (vectors['roles'] as List).cast<Map<String, dynamic>>()) {
      final role = row['role'] as String;
      final box = (row['box'] as num).toDouble();
      test(role, () {
        final token = CoreTextStyles.values.firstWhere(
          (candidate) => candidate.name == role,
        );
        final style = CoreTextStyle.token(token).toValue(theme: _theme);
        for (final lineCount in [1, 2, 3]) {
          final laid = _layout(style, lineCount);
          expect(laid.lines, everyElement(box), reason: '$lineCount lines');
          expect(laid.height, box * lineCount, reason: '$lineCount lines');
        }
      });
    }
  });

  group('a stated size and leading lay out in the table box', () {
    for (final row
        in (vectors['overlays'] as List).cast<Map<String, dynamic>>()) {
      test(row['name'] as String, () {
        final style = CoreTextStyle(
          fontSize: (row['fontSize'] as num).toDouble(),
          lineHeight: (row['lineHeight'] as num).toDouble(),
          fontFamily: CoreFontFamily.sans,
        ).toValue();
        final box = (row['box'] as num).toDouble();
        final laid = _layout(style, 2);
        expect(laid.lines, everyElement(box));
        expect(laid.height, box * 2);
      });
    }
  });
}
