// Text.keepAll — the Flutter half of the shared keep-all vectors.
//
// Flutter has no line-breaking mode, so `.keepAll` draws CoreKeepAll's
// display string. These tests read the table the Core test pins and the
// Chrome probe (tool/parity) checks against the browser's own
// `word-break: keep-all`: the drawn string for every join vector, and the
// lines every line vector breaks into at its width in the vendored
// Pretendard — measured grapheme by grapheme the way the Chrome probe
// measures them.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph, SelectedContent;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../parity/parity_fonts.dart';

/// The table shared with the Core keep-all test and the Chrome probe.
const String kKeepAllVectorsPath =
    '../coui_core/test/fixtures/keep_all_vectors.json';

/// Line height the line vectors are laid out with (`fontSize` × 1.5 at
/// 16) — a glyph's line is the line box its vertical centre falls in.
const double _kLineHeightFactor = 1.5;

const String _kSentence = '리포머 심화 플로우와 회복 스트레칭';

const String _kJ = CoreKeepAll.wordJoiner;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// The `RichText` the keep-all chain rendered.
RichText _richText(WidgetTester tester) => tester.widget<RichText>(
  find
      .descendant(of: find.byType(WrappedText), matching: find.byType(RichText))
      .first,
);

/// Renders the joiners visibly so a failing expectation reads at a glance.
String _visible(String text) => text.replaceAll(_kJ, '⁀');

/// The lines [paragraph] broke into — grapheme by grapheme, the way the
/// Chrome probe reads them — with the joiners removed and trailing spaces
/// trimmed.
List<String> _lines(RenderParagraph paragraph, double lineHeight) {
  final text = paragraph.text.toPlainText();
  final lines = <String>[];
  var current = StringBuffer();
  int? lastLine;
  var offset = 0;
  for (final grapheme in text.characters) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + grapheme.length),
    );
    var line = lastLine;
    if (boxes.isNotEmpty) {
      final box = boxes.first;
      line = ((box.top + (box.bottom - box.top) / 2) / lineHeight).floor();
    }
    if (lastLine != null && line != lastLine) {
      lines.add(current.toString());
      current = StringBuffer();
    }
    lastLine = line;
    current.write(grapheme);
    offset += grapheme.length;
  }
  lines.add(current.toString());

  return [for (final line in lines) line.replaceAll(_kJ, '').trimRight()];
}

/// The centre of the glyph at [offset] of [paragraph], in global
/// coordinates.
Offset _glyphCentre(RenderParagraph paragraph, int offset) {
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + 1),
      )
      .first;

  return paragraph.localToGlobal(box.toRect().center);
}

void main() {
  final doc =
      jsonDecode(File(kKeepAllVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final joins = (doc['joins']! as List).cast<Map<String, Object?>>();
  final lineVectors = (doc['lines']! as List).cast<Map<String, Object?>>();

  group('.keepAll draws the shared join vectors', () {
    for (final c in joins) {
      final input = c['input']! as String;
      final expected = c['expected']! as String;
      testWidgets(c['name']! as String, (tester) async {
        await tester.pumpWidget(_buildApp(Text(input).keepAll));

        expect(
          _visible(_richText(tester).text.toPlainText()),
          _visible(expected),
        );
      });
    }
  });

  group('the line vectors break where the table says', () {
    setUpAll(loadParityFonts);

    for (final c in lineVectors) {
      final text = c['text']! as String;
      final fontSize = (c['fontSize']! as num).toDouble();
      final width = (c['width']! as num).toDouble();
      final keepAll = (c['keepAllFlutter'] ?? c['keepAll'])! as List;

      Future<List<String>> layOut(WidgetTester tester, Widget chain) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: .ltr,
            child: Theme(
              data: const ThemeData(),
              child: Align(
                alignment: .topLeft,
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: CoreFontFamily.sans,
                    fontSize: fontSize,
                    height: _kLineHeightFactor,
                  ),
                  child: SizedBox(width: width, child: chain),
                ),
              ),
            ),
          ),
        );

        return _lines(
          tester.renderObject<RenderParagraph>(find.byType(RichText)),
          fontSize * _kLineHeightFactor,
        );
      }

      testWidgets('${c['name']} — keep-all', (tester) async {
        expect(await layOut(tester, Text(text).keepAll), keepAll);
      });

      testWidgets('${c['name']} — without keep-all', (tester) async {
        expect(await layOut(tester, Text(text)), c['normal']);
      });
    }
  });

  group('.keepAll keeps the original string where it is read', () {
    testWidgets('the semantics label is the original string', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_buildApp(const Text(_kSentence).keepAll));

      expect(find.bySemanticsLabel(_kSentence), findsOneWidget);
      expect(_richText(tester).text.toPlainText(), contains(_kJ));
      semantics.dispose();
    });

    testWidgets('a semanticsLabel the caller set is kept', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildApp(const Text(_kSentence, semanticsLabel: '수업 제목').keepAll),
      );

      expect(find.bySemanticsLabel('수업 제목'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a string keep-all does not change is left as it is', (
      tester,
    ) async {
      const latin = Text('Hello world', key: ValueKey('latin'));
      await tester.pumpWidget(_buildApp(latin.keepAll));

      expect(
        identical(tester.widget(find.byKey(const ValueKey('latin'))), latin),
        isTrue,
      );
    });

    testWidgets('selectable text gains no joiner', (tester) async {
      await tester.pumpWidget(
        _buildApp(const SelectableText(_kSentence).keepAll),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, _kSentence);
    });

    testWidgets('a text field gains no joiner', (tester) async {
      final controller = TextEditingController(text: _kSentence);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          material.Material(
            child: material.TextField(controller: controller).keepAll,
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, _kSentence);
    });

    testWidgets('a Text inside another widget is not reached', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Column(children: [Text(_kSentence)]).keepAll),
      );

      expect(
        tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
        _kSentence,
      );
    });
  });

  group('.keepAll on Text.rich', () {
    testWidgets('a word split across spans still holds together, and each '
        'changed span announces its original text', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildApp(
          const Text.rich(
            TextSpan(
              text: '리포',
              children: [
                TextSpan(
                  text: '머',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' 심화'),
              ],
            ),
          ).keepAll,
        ),
      );

      // `Text` wraps the span it is given in one of its own.
      final root = _richText(tester).text as TextSpan;
      final drawn = root.children!.single as TextSpan;
      // The joiner between 포 and 머 lands at the end of the span holding 포.
      expect(_visible(drawn.text!), _visible('리$_kJ포$_kJ'));
      expect(drawn.semanticsLabel, '리포');
      final children = drawn.children!.cast<TextSpan>();
      expect(children[0].text, '머');
      expect(children[0].semanticsLabel, isNull);
      expect(_visible(children[1].text!), _visible(' 심$_kJ화'));
      expect(children[1].semanticsLabel, ' 심화');
      expect(find.bySemanticsLabel('리포머 심화'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('no word joins across an inline widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '가나'),
                WidgetSpan(child: SizedBox.square(dimension: 4)),
                TextSpan(text: '다라'),
              ],
            ),
          ).keepAll,
        ),
      );

      final root = _richText(tester).text as TextSpan;
      final spans = (root.children!.single as TextSpan).children!;
      expect(_visible((spans[0] as TextSpan).text!), _visible('가$_kJ나'));
      expect(_visible((spans[2] as TextSpan).text!), _visible('다$_kJ라'));
    });
  });

  group('.keepAll composes with the rest of the chain', () {
    testWidgets('one wrapper, whichever side of the role it is chained on', (
      tester,
    ) async {
      for (final chain in [
        const Text(_kSentence).keepAll.bodyMedium.lineLimit(1).ellipsis,
        const Text(_kSentence).bodyMedium.lineLimit(1).ellipsis.keepAll,
      ]) {
        expect(chain, isA<WrappedText>());
        expect((chain as WrappedText).child, isA<Text>());
        expect(chain.wordBreakKeepAll, isTrue);

        await tester.pumpWidget(_buildApp(chain));
        final rich = _richText(tester);
        expect(rich.text.toPlainText(), CoreKeepAll.join(_kSentence));
        expect(rich.maxLines, 1);
        expect(rich.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('a later chain keeps keep-all', (tester) async {
      final chain = const Text(_kSentence).keepAll.semiBold.onSurface;

      expect(chain, isA<WrappedText>());
      expect((chain as WrappedText).wordBreakKeepAll, isTrue);
    });
  });

  group('under a selection area', () {
    late FocusNode focusNode;
    late SelectionListenerNotifier notifier;
    SelectedContent? selected;

    setUp(() {
      focusNode = FocusNode();
      notifier = SelectionListenerNotifier();
      selected = null;
    });

    tearDown(() {
      focusNode.dispose();
      notifier.dispose();
    });

    Future<void> pumpSelectable(WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          material.SelectionArea(
            focusNode: focusNode,
            onSelectionChanged: (content) => selected = content,
            child: Center(
              child: SelectionListener(
                selectionNotifier: notifier,
                child: const Text(_kSentence).keepAll,
              ),
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
    }

    testWidgets('the text still breaks between words', (tester) async {
      await pumpSelectable(tester);

      expect(
        _richText(tester).text.toPlainText(),
        CoreKeepAll.join(_kSentence),
      );
    });

    testWidgets('select all reports and copies the original string', (
      tester,
    ) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpSelectable(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(selected?.plainText, _kSentence);
      expect(clipboard, _kSentence);
      final range = notifier.selection.range!;
      expect(
        [range.startOffset, range.endOffset],
        [0, _kSentence.length],
        reason: 'offsets read in the original string, not the drawn one',
      );
    });

    testWidgets('a selected word copies without its joiners', (tester) async {
      await pumpSelectable(tester);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );

      // Double-click 포 (offset 2 in the drawn 리⁀포⁀머 …) selects 리포머.
      final position = _glyphCentre(paragraph, 2);
      final gesture = await tester.startGesture(
        position,
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await gesture.down(position);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(selected?.plainText, '리포머');
      final range = notifier.selection.range!;
      expect([range.startOffset, range.endOffset], [0, '리포머'.length]);
    });
  });
}
