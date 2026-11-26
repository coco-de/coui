import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

/// Arbitrary factor — not a token.
const _kTestScaler = 2.0;

Future<double> _lineHeight(WidgetTester tester, Widget chain) async {
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Center(child: chain),
      ),
    ),
  );
  final paragraph = tester.renderObject<RenderParagraph>(
    find.byType(RichText).first,
  );
  return paragraph.size.height;
}

void main() {
  // #5496 — the Flutter half: the code role's 21px box grows with the text
  // scaler (Web carries the same factor in `--coui-text-scale`).
  testWidgets('a scaled code role grows its line box by the factor', (
    tester,
  ) async {
    final plain = await _lineHeight(tester, const Text('x').codeMd);
    final scaled = await _lineHeight(
      tester,
      const Text(
        'x',
        textScaler: TextScaler.linear(_kTestScaler),
      ).codeMd,
    );
    expect(plain, CoreLineBox.px21);
    expect(scaled, CoreLineBox.px21 * _kTestScaler);
  });
}
