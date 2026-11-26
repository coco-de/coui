// Tests for `RichEditor` images: the toolbar button that only exists when the
// app can store the file and delete it again, the pick → upload → insert flow
// and its failure
// rows, when an image the user took out is reported for deletion, and how
// image blocks are drawn. The picker is faked at the platform interface; the
// pictures are `data:` addresses so nothing touches the network.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/markdown_document_codec.dart';
import 'package:coui_flutter/src/components/form/rich_editor/markdown/markdown_features.dart'
    show MarkdownBlockFeatures;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/file_drop_picker_fake.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// A valid 1×1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwACh'
  'wGA60e6kgAAAABJRU5ErkJggg==',
);

String _dataUrl(Uint8List bytes) =>
    'data:image/png;base64,${base64Encode(bytes)}';

final String _pngUrl = _dataUrl(_png);

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

/// The upload answer that mirrors a real server: the picture's own data.
Future<String> _echo(CoreRichEditorImageFile file) async =>
    _dataUrl(file.bytes);

/// A delete that does nothing: the other half of an upload the test is not
/// about. The editor takes images only with both.
Future<void> _noDelete(String url) async {}

Future<void> _pump(
  WidgetTester tester, {
  RichEditorController? controller,
  FocusNode? focusNode,
  String? initialValue,
  CoreRichEditorImageUpload? upload,
  CoreRichEditorImageDelete? delete,
  int? maxImageBytes = CoreRichEditorContract.defaultMaxImageBytes,
  bool readOnly = false,
}) async {
  await tester.pumpWidget(
    _buildApp(
      RichEditor(
        controller: controller,
        focusNode: focusNode,
        initialValue: initialValue,
        readOnly: readOnly,
        onImageUpload: upload,
        onImageDelete: delete ?? (upload == null ? null : _noDelete),
        maxImageBytes: maxImageBytes,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets the microtask chain of the picker flow run and the result build.
Future<void> _flow(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

final Finder _imageButton = find.byKey(const ValueKey('richEditor.image'));

LogicalKeyboardKey get _mod => defaultTargetPlatform == TargetPlatform.macOS
    ? LogicalKeyboardKey.metaLeft
    : LogicalKeyboardKey.controlLeft;

Finder _row(int id) => find.byKey(ValueKey<String>('richEditor.imageRow.$id'));

Future<void> _pick(
  WidgetTester tester,
  FileDropPickerFake picker,
  String name,
) async {
  picker.singleResult = Future.value(PickedFileFixture(name, _png));
  await tester.tap(_imageButton);
  await _flow(tester);
}

List<quill.Line> _lines(RichEditorController controller) =>
    MarkdownDocumentCodec.lines(controller.document).toList();

quill.Line _imageLine(RichEditorController controller) => _lines(
  controller,
).firstWhere((line) => MarkdownDocumentCodec.kindOf(line) == 'img');

String _imageNodeId(RichEditorController controller) =>
    MarkdownDocumentCodec.lineId(_imageLine(controller));

int _imageNodes(RichEditorController controller) => _lines(
  controller,
).where((line) => MarkdownDocumentCodec.kindOf(line) == 'img').length;

void _select(
  RichEditorController controller,
  String nodeId, {
  required bool whole,
}) {
  final line = _lines(
    controller,
  ).singleWhere((line) => MarkdownDocumentCodec.lineId(line) == nodeId);
  final start = line.documentOffset;
  controller.setSelection(
    TextSelection(
      baseOffset: whole ? start : start + 1,
      extentOffset: start + 1,
    ),
  );
}

void _caretIn(RichEditorController controller, quill.Line line, int offset) =>
    controller.setSelection(
      TextSelection.collapsed(offset: line.documentOffset + offset),
    );

quill.Line _caretLine(RichEditorController controller) =>
    controller.document.queryChild(controller.selection!.extentOffset).node!
        as quill.Line;

void _newLine(RichEditorController controller) {
  final at = controller.selection!.extentOffset;
  controller.editor.replaceText(
    at,
    0,
    '\n',
    TextSelection.collapsed(offset: at + 1),
  );
}

/// Uploads one image into [controller]'s document, caret at the end first.
Future<String> _upload(
  WidgetTester tester,
  FileDropPickerFake picker,
  RichEditorController controller, {
  String name = 'photo.png',
}) async {
  controller.moveCaretToEnd();
  await _pick(tester, picker, name);
  await tester.pumpAndSettle();
  return _dataUrl(_png);
}

void main() {
  late FileDropPickerFake picker;

  setUp(() {
    picker = FileDropPickerFake()..install();
  });

  group('the image button', () {
    testWidgets('does not exist without an upload and a delete', (
      tester,
    ) async {
      await _pump(tester);
      expect(_imageButton, findsNothing);
      // A delete alone has nothing to take off the server.
      await _pump(tester, delete: _noDelete);
      expect(_imageButton, findsNothing);
      // …and nothing else left a gap: the groups are the other four.
      expect(
        find.byKey(const ValueKey('richEditor.quote')),
        findsOneWidget,
      );
    });

    testWidgets('exists with both, and opens the picker on images only', (
      tester,
    ) async {
      await _pump(tester, upload: _echo);
      expect(_imageButton, findsOneWidget);
      await tester.tap(_imageButton);
      await _flow(tester);
      expect(picker.singleCalls, 1);
      expect(picker.allowedExtensions, CoreRichEditorImage.extensions);
    });

    testWidgets('is off in a read-only editor', (tester) async {
      await _pump(tester, upload: _echo, readOnly: true);
      expect(tester.widget<Button>(_imageButton).enabled, isFalse);
      await tester.tap(_imageButton, warnIfMissed: false);
      await _flow(tester);
      expect(picker.singleCalls, 0);
    });

    testWidgets('a cancelled picker changes nothing', (tester) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      var uploads = 0;
      await _pump(
        tester,
        controller: controller,
        upload: (file) async {
          uploads++;
          return _pngUrl;
        },
      );
      picker.singleResult = Future.value();
      await tester.tap(_imageButton);
      await _flow(tester);
      expect(uploads, 0);
      expect(_row(0), findsNothing);
      expect(controller.markdown, 'hello');
    });
  });

  group('adding an image', () {
    testWidgets('shows a row while it uploads, then puts the image in', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      final gate = Completer<String>();
      final received = <CoreRichEditorImageFile>[];
      await _pump(
        tester,
        controller: controller,
        upload: (file) {
          received.add(file);
          return gate.future;
        },
      );
      controller.moveCaretToEnd();

      await _pick(tester, picker, 'photo.png');
      expect(received.single.name, 'photo.png');
      expect(received.single.mimeType, 'image/png');
      expect(received.single.bytes, _png);
      expect(_row(0), findsOneWidget);
      expect(find.text('Uploading image… · photo.png'), findsOneWidget);
      expect(controller.markdown, 'hello', reason: 'not in the document yet');

      gate.complete(_pngUrl);
      await tester.pumpAndSettle();
      expect(_row(0), findsNothing);
      expect(controller.markdown, 'hello\n\n![photo]($_pngUrl)');
      expect(controller.imageUrls, {_pngUrl});
      // The caret waits below the image.
      final caret = _caretLine(controller);
      expect(caret.hasEmbed, isFalse);
      expect(caret, same(_lines(controller).last));
    });

    testWidgets('goes below the block the caret was in when it was pressed', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'a\n\nb');
      addTearDown(controller.dispose);
      final gate = Completer<String>();
      await _pump(tester, controller: controller, upload: (_) => gate.future);
      _caretIn(controller, _lines(controller).first, 1);

      await _pick(tester, picker, 'photo.png');
      controller.moveCaretToEnd(); // the user keeps going while it uploads
      gate.complete(_pngUrl);
      await tester.pumpAndSettle();

      expect(controller.markdown, 'a\n\n![photo]($_pngUrl)\n\nb');
    });

    testWidgets('replaces the empty paragraph the caret was in', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller, upload: _echo);
      controller.moveCaretToEnd();
      _newLine(controller);
      expect(_lines(controller).length, 2);

      await _pick(tester, picker, 'photo.png');
      await tester.pumpAndSettle();

      expect(
        [
          for (final line in _lines(controller))
            MarkdownDocumentCodec.kindOf(line),
        ],
        ['p', 'img', 'p'],
      );
      expect(controller.markdown, 'a\n\n![photo]($_pngUrl)');
    });

    testWidgets('an editor nobody focused yet takes the image at the end', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'a\n\nb');
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller, upload: _echo);
      expect(controller.selection, isNull);

      await _pick(tester, picker, 'photo.png');
      await tester.pumpAndSettle();

      expect(controller.markdown, 'a\n\nb\n\n![photo]($_pngUrl)');
    });

    testWidgets('the document reports the new Markdown', (tester) async {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      final changes = <String>[];
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            onChanged: changes.add,
            onImageUpload: _echo,
            onImageDelete: _noDelete,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _upload(tester, picker, controller);
      expect(changes.last, 'a\n\n![photo]($_pngUrl)');
    });

    testWidgets('one undo takes the image out again', (tester) async {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller, upload: _echo);
      await _upload(tester, picker, controller);
      expect(_imageNodes(controller), 1);
      controller.undo();
      await tester.pumpAndSettle();
      expect(controller.markdown, 'a');
    });
  });

  group('an image that is not added', () {
    testWidgets('too large: never read or uploaded, and the row can go', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      var uploads = 0;
      final big = PickedFileFixture('big.png', Uint8List(10));
      await _pump(
        tester,
        controller: controller,
        maxImageBytes: 3,
        upload: (file) async {
          uploads++;
          return _pngUrl;
        },
      );
      picker.singleResult = Future.value(big);
      await tester.tap(_imageButton);
      await _flow(tester);

      expect(find.text('The image is too large. · big.png'), findsOneWidget);
      expect(uploads, 0);
      expect(big.reads, 0, reason: 'a refused file is not read into memory');
      expect(controller.markdown, 'a');

      await tester.tap(
        find.descendant(of: _row(0), matching: find.byType(Button)),
      );
      await tester.pumpAndSettle();
      expect(_row(0), findsNothing);
    });

    testWidgets('no limit when maxImageBytes is null', (tester) async {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        maxImageBytes: null,
        upload: _echo,
      );
      picker.singleResult = Future.value(
        PickedFileFixture('big.png', Uint8List(2000)),
      );
      controller.moveCaretToEnd();
      await tester.tap(_imageButton);
      await _flow(tester);
      await tester.pumpAndSettle();
      expect(controller.imageUrls, hasLength(1));
    });

    for (final name in const ['notes.svg', 'README', 'photo.heic']) {
      testWidgets('$name is not an allowed type', (tester) async {
        var uploads = 0;
        await _pump(
          tester,
          upload: (file) async {
            uploads++;
            return _pngUrl;
          },
        );
        await _pick(tester, picker, name);
        expect(
          find.text(
            'Only PNG, JPEG, GIF and WebP images can be added. · $name',
          ),
          findsOneWidget,
        );
        expect(uploads, 0);
      });
    }

    testWidgets('an upload that throws leaves a failed row', (tester) async {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        upload: (file) async => throw StateError('503'),
      );
      await _pick(tester, picker, 'photo.png');
      await tester.pumpAndSettle();
      expect(
        find.text("Couldn't upload the image. · photo.png"),
        findsOneWidget,
      );
      expect(controller.markdown, 'a');
    });

    testWidgets('an address the editor refuses fails the upload', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        upload: (file) async => 'javascript:alert(1)',
      );
      await _pick(tester, picker, 'photo.png');
      await tester.pumpAndSettle();
      expect(
        find.text("Couldn't upload the image. · photo.png"),
        findsOneWidget,
      );
      expect(_imageNodes(controller), 0);
    });

    testWidgets(
      'a file stored under an address the editor cannot show is reported for '
      'deletion, not left on the server',
      (tester) async {
        final deleted = <String>[];
        final controller = RichEditorController(markdown: 'a');
        addTearDown(controller.dispose);
        await _pump(
          tester,
          controller: controller,
          upload: (file) async => 'blob:https://x.test/0123-4567',
          delete: (url) async => deleted.add(url),
        );
        await _pick(tester, picker, 'photo.png');
        await tester.pumpAndSettle();
        expect(
          find.text("Couldn't upload the image. · photo.png"),
          findsOneWidget,
        );
        expect(_imageNodes(controller), 0);
        expect(deleted, ['blob:https://x.test/0123-4567']);
      },
    );

    testWidgets('rows stack in order, each with its own dismiss', (
      tester,
    ) async {
      await _pump(tester, upload: (file) async => throw StateError('no'));
      await _pick(tester, picker, 'one.png');
      await _pick(tester, picker, 'two.png');
      await tester.pumpAndSettle();
      expect(_row(0), findsOneWidget);
      expect(_row(1), findsOneWidget);
      await tester.tap(
        find.descendant(of: _row(0), matching: find.byType(Button)),
      );
      await tester.pumpAndSettle();
      expect(_row(0), findsNothing);
      expect(_row(1), findsOneWidget);
    });
  });

  group('deleting what the editor uploaded', () {
    late List<String> deleted;
    late RichEditorController controller;

    setUp(() {
      deleted = [];
      controller = RichEditorController(markdown: 'hello');
    });

    tearDown(() => controller.dispose());

    Future<String> uploaded(WidgetTester tester) async {
      await _pump(
        tester,
        controller: controller,
        upload: _echo,
        delete: (url) async => deleted.add(url),
      );
      await _upload(tester, picker, controller);
      expect(_imageNodes(controller), 1);
      return _pngUrl;
    }

    testWidgets('only after the image has been out for the delay, once', (
      tester,
    ) async {
      final url = await uploaded(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      expect(controller.deleteSelection(), isTrue);
      await tester.pump();
      expect(controller.imageUrls, isEmpty);
      expect(deleted, isEmpty);

      await tester.pump(const Duration(seconds: 9));
      expect(deleted, isEmpty, reason: 'still within the undo window');
      await tester.pump(const Duration(seconds: 2));
      expect(deleted, [url]);
      await tester.pump(const Duration(minutes: 5));
      expect(deleted, [url], reason: 'reported once');
    });

    testWidgets('an undo inside the window keeps the file', (tester) async {
      await uploaded(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      controller.deleteSelection();
      await tester.pump(const Duration(seconds: 5));
      controller.undo();
      await tester.pump();
      expect(controller.imageUrls, hasLength(1));
      await tester.pump(const Duration(minutes: 1));
      expect(deleted, isEmpty);
    });

    testWidgets('cutting the image and pasting it elsewhere keeps the file', (
      tester,
    ) async {
      await uploaded(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      final cut = controller.selectedMarkdown!;
      controller.deleteSelection();
      await tester.pump(const Duration(seconds: 4));
      expect(controller.imageUrls, isEmpty);

      controller.moveCaretToEnd();
      expect(controller.paste(cut), isTrue);
      await tester.pump(const Duration(minutes: 1));
      expect(controller.imageUrls, hasLength(1));
      expect(deleted, isEmpty);
    });

    testWidgets('copying and pasting an image makes two of it', (
      tester,
    ) async {
      await uploaded(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      final copy = controller.selectedMarkdown!;
      expect(copy, '![photo]($_pngUrl)');
      controller.moveCaretToEnd();
      expect(controller.paste(copy), isTrue);
      await tester.pump();
      expect(_imageNodes(controller), 2);
      expect(controller.imageUrls, hasLength(1));
    });

    testWidgets('one of two copies going does not delete the file', (
      tester,
    ) async {
      await uploaded(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      final copy = controller.selectedMarkdown!;
      controller
        ..moveCaretToEnd()
        ..paste(copy);
      await tester.pump();

      _select(controller, _imageNodeId(controller), whole: true);
      controller.deleteSelection();
      await tester.pump(const Duration(minutes: 1));
      expect(_imageNodes(controller), 1);
      expect(deleted, isEmpty);
    });

    testWidgets('replacing the content from outside is not a removal', (
      tester,
    ) async {
      await uploaded(tester);
      controller.markdown = ''; // the post was sent; the composer is cleared
      await tester.pump(const Duration(minutes: 1));
      expect(controller.imageUrls, isEmpty);
      expect(deleted, isEmpty);
    });

    testWidgets('the editor going away reports what was removed', (
      tester,
    ) async {
      final url = await uploaded(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      controller.deleteSelection();
      await tester.pump();
      expect(deleted, isEmpty);

      await tester.pumpWidget(const SizedBox());
      expect(deleted, [url]);
    });

    testWidgets('the editor going away leaves an image still in it alone', (
      tester,
    ) async {
      await uploaded(tester);
      await tester.pumpWidget(const SizedBox());
      expect(deleted, isEmpty);
    });

    testWidgets('an image that was in the Markdown to begin with is never '
        'deleted', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            initialValue: 'a\n\n![old]($_pngUrl)',
            onImageUpload: _echo,
            onImageDelete: (url) async => deleted.add(url),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final own = tester
          .state<RichEditorState>(find.byType(RichEditor))
          .controller;
      expect(own.imageUrls, {_pngUrl});

      _select(own, _imageNodeId(own), whole: true);
      own.deleteSelection();
      await tester.pump(const Duration(minutes: 1));
      expect(own.imageUrls, isEmpty);
      await tester.pumpWidget(const SizedBox());
      expect(deleted, isEmpty);
    });

    testWidgets('a delete that does nothing is still an answer, and images '
        'are taken', (tester) async {
      // An app whose server cleans up on its own passes a delete that does
      // nothing: the editor takes images all the same, and asks nothing else
      // of the server.
      await _pump(
        tester,
        controller: controller,
        upload: _echo,
        delete: _noDelete,
      );
      await _upload(tester, picker, controller);
      expect(controller.imageUrls, {_pngUrl});
      _select(controller, _imageNodeId(controller), whole: true);
      controller.deleteSelection();
      await tester.pump(const Duration(minutes: 1));
      expect(controller.imageUrls, isEmpty);
      expect(deleted, isEmpty);
    });

    // The first key press of a session flips the focus highlight mode, and
    // the editor rebuilds from the top on that alone — which hides a fault in
    // the order the layers are built in. These tests press a key first, as
    // anyone who has typed in the editor has.
    Future<FocusNode> keyboardSession(WidgetTester tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await _pump(
        tester,
        controller: controller,
        focusNode: focus,
        upload: _echo,
        delete: (url) async => deleted.add(url),
      );
      await _upload(tester, picker, controller);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      return focus;
    }

    testWidgets('Backspace at the lower edge of an image removes it', (
      tester,
    ) async {
      await keyboardSession(tester);
      _select(controller, _imageNodeId(controller), whole: false);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.imageUrls, isEmpty);
      await tester.pump(const Duration(seconds: 11));
      expect(deleted, [_pngUrl]);
    });

    testWidgets('Delete over a selected image removes it', (tester) async {
      await keyboardSession(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(controller.imageUrls, isEmpty);
      await tester.pump(const Duration(seconds: 11));
      expect(deleted, [_pngUrl]);
    });

    testWidgets('cutting a selected image removes it', (tester) async {
      await keyboardSession(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      await tester.pump();

      await tester.sendKeyDownEvent(_mod);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.sendKeyUpEvent(_mod);
      await tester.pump();
      expect(controller.imageUrls, isEmpty);
      await tester.pump(const Duration(seconds: 11));
      expect(deleted, [_pngUrl]);
    });

    testWidgets('undoing a key press brings the image back as it was', (
      tester,
    ) async {
      await keyboardSession(tester);
      _select(controller, _imageNodeId(controller), whole: true);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(controller.imageUrls, isEmpty);

      await tester.sendKeyDownEvent(_mod);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(_mod);
      await tester.pump();
      expect(controller.imageUrls, {_pngUrl});
      await tester.pump(const Duration(minutes: 1));
      expect(deleted, isEmpty);
    });
  });

  group('an image block', () {
    testWidgets('is drawn from a data address, aligned with the text', (
      tester,
    ) async {
      final bytes = await _picture(tester, 120, 80);
      final controller = RichEditorController(
        markdown: 'hello\n\n![shot](${_dataUrl(bytes)})',
      );
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      final image = find.byType(material.Image);
      expect(image, findsOneWidget);
      final size = tester.getSize(image);
      expect(size, const Size(120, 80), reason: 'a small image keeps its size');
      final textLeft = tester
          .getTopLeft(find.text('hello', findRichText: true))
          .dx;
      expect(tester.getTopLeft(image).dx, textLeft);
    });

    testWidgets('is scaled down to the height cap, keeping its shape', (
      tester,
    ) async {
      final bytes = await _picture(tester, 600, 800);
      final controller = RichEditorController(
        markdown: '![tall](${_dataUrl(bytes)})',
      );
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      final size = tester.getSize(find.byType(material.Image));
      expect(size.height, CoreRichEditorStyle.defaultImageMaxHeight);
      expect(size.width / size.height, closeTo(600 / 800, 0.01));
    });

    testWidgets('says so in an Alert when the picture cannot be shown', (
      tester,
    ) async {
      // Well-formed base64 that is not an image.
      final controller = RichEditorController(
        markdown:
            '![a note](data:image/png;base64,AAAAAAAA)\n\n'
            '![](data:image/png;base64,AAAAAAAA)',
      );
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      // The name follows the message when the image has one.
      expect(find.text('Image unavailable · a note'), findsOneWidget);
      expect(find.text('Image unavailable'), findsOneWidget);
      expect(find.byType(Alert), findsNWidgets(2));
    });

    testWidgets("gives that Alert the editor's uploadAlertStyle", (
      tester,
    ) async {
      final controller = RichEditorController(
        markdown: '![](data:image/png;base64,AAAAAAAA)',
      );
      addTearDown(controller.dispose);
      const style = CoreAlertStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
      );
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            richEditorStyle: const CoreRichEditorStyle(uploadAlertStyle: style),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      final alert = tester.widget<Alert>(find.byType(Alert));
      expect(alert.alertStyle?.borderRadius, style.borderRadius);
    });

    testWidgets('has the alternative text as its label', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = RichEditorController(
        markdown: '![holiday photo]($_pngUrl)',
      );
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller);
      expect(find.bySemanticsLabel('holiday photo'), findsWidgets);
      handle.dispose();
    });

    for (final (side, key, _) in [
      ('left', LogicalKeyboardKey.delete, TextAffinity.upstream),
      ('right', LogicalKeyboardKey.backspace, TextAffinity.downstream),
    ]) {
      testWidgets(
        'a click on its $side half puts the caret at that edge, where '
        '${key.keyLabel} removes it',
        (tester) async {
          final bytes = await _picture(tester, 120, 80);
          final focus = FocusNode();
          addTearDown(focus.dispose);
          final controller = RichEditorController(
            markdown: 'hello\n\n![shot](${_dataUrl(bytes)})',
          );
          addTearDown(controller.dispose);
          await _pump(tester, controller: controller, focusNode: focus);
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)),
          );
          await tester.pump();
          focus.requestFocus();
          await tester.pump();
          // As anyone who has typed in the editor has already pressed a key.
          await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);

          final box = tester.getRect(find.byType(material.Image).first);
          await tester.tapAt(
            side == 'left'
                ? box.centerLeft + const Offset(10, 0)
                : box.centerRight - const Offset(10, 0),
          );
          await tester.pump();
          final caret = controller.selection!;
          final imageOffset = _imageLine(controller).documentOffset;
          expect(caret.isCollapsed, isTrue);
          expect(
            caret.extentOffset,
            side == 'left' ? imageOffset : imageOffset + 1,
          );

          await tester.sendKeyEvent(key);
          await tester.pump(const Duration(seconds: 1));
          expect(controller.imageUrls, isEmpty);
        },
      );
    }

    testWidgets('takes its corner, cap and fill from the Style slot', (
      tester,
    ) async {
      final bytes = await _picture(tester, 600, 800);
      final controller = RichEditorController(
        markdown:
            '![tall](${_dataUrl(bytes)})\n\n![](data:image/png;base64,AAAAAAAA)',
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            richEditorStyle: const CoreRichEditorStyle(
              imageBorderRadius: CoreBorderRadius.all(CoreRadius.radius20),
              imageMaxHeight: 40,
              imageBackgroundColor: CoreColor(0xFF112233),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      expect(clip.borderRadius, BorderRadius.circular(20));
      final fill = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(ClipRRect).first,
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.color, const Color(0xFF112233));
      expect(tester.getSize(find.byType(material.Image).first).height, 40);
    });

    testWidgets('keeps its bitmap when the selection moves over it', (
      tester,
    ) async {
      final controller = RichEditorController(
        markdown: 'a\n\n![x]($_pngUrl)\n\nb',
      );
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller);
      final image = tester.widget<material.Image>(find.byType(material.Image));
      _select(controller, _imageNodeId(controller), whole: true);
      await tester.pump();
      _caretIn(controller, _lines(controller).first, 0);
      await tester.pump();
      final after = tester.widget<material.Image>(find.byType(material.Image));
      expect(after.image, image.image, reason: 'same provider, no re-decode');
    });
  });

  group('image Markdown', () {
    for (final markdown in const [
      '![a](https://x.test/a.png)',
      '![a](https://x.test/a.png "a title")',
      "![a](https://x.test/a.png 'single')",
      '![a b](data:image/png;base64,iVBORw0KGgo=)',
      'before\n\n![a](https://x.test/a.png)\n\nafter',
      'text\n\n![a](https://x.test/a.png)',
      '![a](https://x.test/a.png)\n\n![b](https://x.test/b.png)',
      '![](https://x.test/a.png)',
      '![a](<https://x.test/a b.png>)',
      '# Title\n\n![a](/uploads/a.png)\n\n- item',
    ]) {
      test('round-trips ${markdown.replaceAll('\n', r'\n')}', () {
        final controller = RichEditorController(markdown: markdown);
        addTearDown(controller.dispose);
        expect(controller.markdown, markdown);
        expect(controller.imageUrls, isNotEmpty);
      });
    }

    test(
      'a line of its own becomes an image block with its alt and address',
      () {
        final controller = RichEditorController(
          markdown: '![holiday photo](https://x.test/a.png "t")',
        );
        addTearDown(controller.dispose);
        final data = MarkdownDocumentCodec.imageData(
          _imageLine(controller).toDelta().first.data,
        )!;
        expect(data.url, 'https://x.test/a.png');
        expect(data.alt, 'holiday photo');
      },
    );

    test('the document still ends with a text block', () {
      final controller = RichEditorController(
        markdown: '![a](https://x.test/a.png)',
      );
      addTearDown(controller.dispose);
      expect(_lines(controller).last.hasEmbed, isFalse);
      expect(_lines(controller).length, 2);
    });

    test('an edited image block is written as the canonical form', () {
      final controller = RichEditorController(
        markdown: '![a](https://x.test/a.png "t")\n\ntail',
      );
      addTearDown(controller.dispose);
      controller.insertImage(
        url: 'https://x.test/b.png',
        alt: 'b [x]',
        afterNodeId: MarkdownDocumentCodec.lineId(_lines(controller).first),
      );
      expect(
        controller.markdown,
        '![a](https://x.test/a.png "t")\n\n![b \\[x\\]](https://x.test/b.png)'
        '\n\ntail',
        reason: 'the untouched block keeps its title; the new one is written',
      );
    });

    for (final markdown in const [
      '![x](javascript:alert(1))',
      '![x](file:///etc/passwd)',
      'see ![a](https://x.test/a.png) here',
      '![a](https://x.test/a.png)\n![b](https://x.test/b.png)',
      '![a](data:image/svg+xml;base64,PHN2Zz4=)',
    ]) {
      test('stays a literal block: ${markdown.replaceAll('\n', r'\n')}', () {
        final controller = RichEditorController(markdown: markdown);
        addTearDown(controller.dispose);
        expect(controller.imageUrls, isEmpty);
        expect(MarkdownDocumentCodec.kindOf(_lines(controller).first), 'raw');
        expect(controller.markdown, markdown);
      });
    }

    test('turned off by the features, the line stays a literal block', () {
      final controller = RichEditorController(
        markdown: '![a](https://x.test/a.png)',
        features: const MarkdownBlockFeatures(images: false),
      );
      addTearDown(controller.dispose);
      expect(controller.imageUrls, isEmpty);
      expect(controller.markdown, '![a](https://x.test/a.png)');
    });

    test('features compare and hash on every flag', () {
      expect(
        const MarkdownBlockFeatures(images: false),
        isNot(MarkdownBlockFeatures.all),
      );
      expect(MarkdownBlockFeatures.comment.images, isTrue);
    });

    test('a pasted image line becomes an image, and the document keeps a '
        'last text block', () {
      final controller = RichEditorController(markdown: 'hello world')
        ..moveCaretToEnd();
      addTearDown(controller.dispose);
      expect(controller.paste('![z](https://x.test/z.png)'), isTrue);
      expect(controller.imageUrls, {'https://x.test/z.png'});
      expect(_lines(controller).last.hasEmbed, isFalse);
    });
  });

  group('RichEditorController.insertImage', () {
    test('goes after the given block, and the caret waits below it', () {
      final controller = RichEditorController(markdown: 'a\n\nb');
      addTearDown(controller.dispose);
      final id = controller.insertImage(
        url: 'https://x.test/a.png',
        alt: 'pic',
        afterNodeId: MarkdownDocumentCodec.lineId(_lines(controller).first),
      );
      expect(id, isNotNull);
      expect(controller.markdown, 'a\n\n![pic](https://x.test/a.png)\n\nb');
      final line = _caretLine(controller);
      expect(controller.selection!.extentOffset, line.documentOffset);
      final lines = _lines(controller);
      expect(
        MarkdownDocumentCodec.kindOf(lines[lines.indexOf(line) - 1]),
        'img',
      );
    });

    test('a missing block means the end', () {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      controller.insertImage(url: 'https://x.test/a.png', afterNodeId: 'gone');
      expect(controller.markdown, 'a\n\n![](https://x.test/a.png)');
    });

    test('an empty paragraph is replaced, not left above', () {
      final controller = RichEditorController(markdown: 'a')..moveCaretToEnd();
      addTearDown(controller.dispose);
      _newLine(controller);
      controller.insertImage(
        url: 'https://x.test/a.png',
        afterNodeId: controller.selectedLineId,
      );
      expect(
        [
          for (final line in _lines(controller))
            MarkdownDocumentCodec.kindOf(line),
        ],
        ['p', 'img', 'p'],
      );
    });

    test('is one undo step', () {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      controller.insertImage(url: 'https://x.test/a.png');
      expect(controller.imageUrls, hasLength(1));
      controller.undo();
      expect(controller.markdown, 'a');
      controller.redo();
      expect(controller.imageUrls, hasLength(1));
    });

    test('is refused in a read-only editor', () {
      final controller = RichEditorController(markdown: 'a')..readOnly = true;
      addTearDown(controller.dispose);
      expect(controller.insertImage(url: 'https://x.test/a.png'), isNull);
      expect(controller.markdown, 'a');
    });

    test('counts as an edit, so the Markdown is rewritten', () {
      final controller = RichEditorController(markdown: '*a*');
      addTearDown(controller.dispose);
      controller.insertImage(url: 'https://x.test/a.png');
      expect(controller.markdown, startsWith('*a*\n\n![]'));
    });

    test('replacements counts content set from outside, not edits', () {
      final controller = RichEditorController(markdown: 'a');
      addTearDown(controller.dispose);
      final start = controller.replacements;
      controller.insertImage(url: 'https://x.test/a.png');
      expect(controller.replacements, start);
      controller.markdown = 'b';
      expect(controller.replacements, start + 1);
      controller.features = const MarkdownBlockFeatures(headings: false);
      expect(controller.replacements, start + 2);
    });
  });
}

/// A PNG of [width] × [height] drawn by the engine.
Future<Uint8List> _picture(WidgetTester tester, int width, int height) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..color = const ui.Color(0xFF3366CC),
    );
    final image = await recorder.endRecording().toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  return bytes!;
}
