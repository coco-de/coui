import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

import '../../parity/parity_fonts.dart';

const _kTextKey = ValueKey<String>('keep-all-tracking');
const _kText = '한글 제목 A한B';
const String _kJoiner = CoreKeepAll.wordJoiner;

Future<RenderParagraph> _pumpText(
  WidgetTester tester,
  Widget text, {
  required bool keepAll,
  required TextStyle inheritedStyle,
}) async {
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Align(
          alignment: .topLeft,
          child: DefaultTextStyle(
            style: inheritedStyle,
            child: WrappedText(wordBreakKeepAll: keepAll, child: text),
          ),
        ),
      ),
    ),
  );
  return tester.renderObject<RenderParagraph>(
    find.descendant(of: find.byKey(_kTextKey), matching: find.byType(RichText)),
  );
}

List<Rect> _glyphRects(
  RenderParagraph paragraph,
  String source, {
  required bool keepAll,
}) {
  final offsets = keepAll ? CoreKeepAll.joinOffsets(source) : const <int>[];
  final result = <Rect>[];
  var offset = 0;
  for (final grapheme in source.characters) {
    if (grapheme != _kJoiner && grapheme.trim().isNotEmpty) {
      final displayOffset =
          offset + offsets.where((position) => position <= offset).length;
      result.addAll(
        paragraph
            .getBoxesForSelection(
              TextSelection(
                baseOffset: displayOffset,
                extentOffset: displayOffset + grapheme.length,
              ),
            )
            .map((box) => box.toRect()),
      );
    }
    offset += grapheme.length;
  }
  return result;
}

void _expectRects(List<Rect> actual, List<Rect> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < actual.length; i += 1) {
    expect(
      actual[i].left,
      closeTo(expected[i].left, 0.001),
      reason: 'glyph $i',
    );
    expect(actual[i].top, closeTo(expected[i].top, 0.001), reason: 'glyph $i');
    expect(
      actual[i].width,
      closeTo(expected[i].width, 0.001),
      reason: 'glyph $i',
    );
    expect(
      actual[i].height,
      closeTo(expected[i].height, 0.001),
      reason: 'glyph $i',
    );
  }
}

void main() {
  setUpAll(loadParityFonts);

  for (final explicit in [false, true]) {
    for (final tracking in [-0.4, 0.0, 0.4]) {
      for (final scale in [1.0, 1.7]) {
        testWidgets(
          'keeps glyph advances with tracking $tracking, scale $scale, '
          'explicit style $explicit',
          (tester) async {
            final style = TextStyle(
              fontFamily: CoreFontFamily.sans,
              fontSize: 20,
              height: 1.5,
              letterSpacing: tracking,
            );
            final text = Text(
              _kText,
              key: _kTextKey,
              style: explicit ? style : null,
              textScaler: TextScaler.linear(scale),
            );
            final plain = await _pumpText(
              tester,
              text,
              keepAll: false,
              inheritedStyle: style,
            );
            final size = plain.size;
            expect((plain.text as TextSpan).style?.letterSpacing, tracking);
            final boxes = _glyphRects(plain, _kText, keepAll: false);
            final kept = await _pumpText(
              tester,
              text,
              keepAll: true,
              inheritedStyle: style,
            );

            expect(kept.size.width, closeTo(size.width, 0.001));
            expect(kept.size.height, closeTo(size.height, 0.001));
            _expectRects(_glyphRects(kept, _kText, keepAll: true), boxes);
            expect(kept.text.toPlainText(), CoreKeepAll.join(_kText));
          },
        );
      }
    }
  }

  testWidgets('mixed tracking across rich spans keeps each glyph in place', (
    tester,
  ) async {
    const style = TextStyle(fontFamily: CoreFontFamily.sans, fontSize: 20);
    const text = Text.rich(
      TextSpan(
        text: '한',
        style: TextStyle(letterSpacing: -0.4),
        children: [
          TextSpan(
            text: '글',
            style: TextStyle(fontSize: 24, letterSpacing: 1.2),
          ),
          TextSpan(text: ' 제목', style: TextStyle(letterSpacing: 0.25)),
        ],
      ),
      key: _kTextKey,
    );
    final plain = await _pumpText(
      tester,
      text,
      keepAll: false,
      inheritedStyle: style,
    );
    final size = plain.size;
    final boxes = _glyphRects(plain, '한글 제목', keepAll: false);
    final kept = await _pumpText(
      tester,
      text,
      keepAll: true,
      inheritedStyle: style,
    );

    expect(kept.size.width, closeTo(size.width, 0.001));
    expect(kept.size.height, closeTo(size.height, 0.001));
    _expectRects(_glyphRects(kept, '한글 제목', keepAll: true), boxes);
  });

  testWidgets('moving a caller joiner updates an identical display string', (
    tester,
  ) async {
    const style = TextStyle(
      fontFamily: CoreFontFamily.sans,
      fontSize: 20,
      letterSpacing: 1.5,
    );
    const sources = ['가나$_kJoiner다', '가$_kJoiner나다'];
    expect(CoreKeepAll.join(sources[0]), CoreKeepAll.join(sources[1]));
    final expected = <(Size, List<Rect>)>[];
    for (final source in sources) {
      final plain = await _pumpText(
        tester,
        Text(source, key: _kTextKey),
        keepAll: false,
        inheritedStyle: style,
      );
      expected.add((plain.size, _glyphRects(plain, source, keepAll: false)));
    }
    // No plain span between these frames: the render object must notice
    // that a different joiner is now the inserted, zero-tracking one.
    for (final (i, source) in sources.indexed) {
      final kept = await _pumpText(
        tester,
        Text(source, key: _kTextKey),
        keepAll: true,
        inheritedStyle: style,
      );
      expect(kept.size.width, closeTo(expected[i].$1.width, 0.001));
      _expectRects(_glyphRects(kept, source, keepAll: true), expected[i].$2);
    }
  });

  testWidgets('rich links keep recognition, hover and their original label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      var enters = 0;
      var exits = 0;
      final recognizer = TapGestureRecognizer()..onTap = () => taps += 1;
      addTearDown(recognizer.dispose);
      final text = Text.rich(
        TextSpan(
          text: '한글 링크',
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
          onEnter: (_) => enters += 1,
          onExit: (_) => exits += 1,
          semanticsLabel: '문서 링크',
        ),
        key: _kTextKey,
      );
      final paragraph = await _pumpText(
        tester,
        text,
        keepAll: true,
        inheritedStyle: const TextStyle(
          fontFamily: CoreFontFamily.sans,
          fontSize: 20,
          letterSpacing: -0.4,
        ),
      );
      final boxes = _glyphRects(paragraph, '한글 링크', keepAll: true);
      await tester.tapAt(paragraph.localToGlobal(boxes[0].center));
      await tester.tapAt(paragraph.localToGlobal(boxes[1].center));
      expect(taps, 2);
      final labels = <String>[];
      void collectLabels(SemanticsNode node) {
        labels.add(node.getSemanticsData().label);
        node.visitChildren((child) {
          collectLabels(child);
          return true;
        });
      }

      collectLabels(tester.getSemantics(find.byKey(_kTextKey)));
      expect(labels, contains('문서 링크'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      const outside = Offset(799, 599);
      await mouse.addPointer(location: outside);
      await mouse.moveTo(paragraph.localToGlobal(boxes[0].center));
      await tester.pump();
      await mouse.moveTo(outside);
      await tester.pump();
      expect(enters, 1);
      expect(exits, 1);
    } finally {
      semantics.dispose();
    }
  });
}
