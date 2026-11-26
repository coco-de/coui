import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:dir_picker/dir_picker.dart' as dir_picker;
import 'package:file_picker/file_picker.dart';
import 'package:file_saver_ffi/file_saver_ffi.dart' as saver;
import 'package:file_saver_ffi/src/platform_interface/file_saver_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FilePickerPlatform originalPicker;
  late _FakeFilePicker picker;
  late _FakeDirPicker dirPicker;
  late _FakeFileSaver fileSaver;

  setUp(() {
    originalPicker = FilePickerPlatform.instance;
    picker = _FakeFilePicker();
    FilePickerPlatform.instance = picker;

    dirPicker = _FakeDirPicker();
    dir_picker.DirPickerPlatform.instance = dirPicker;

    fileSaver = _FakeFileSaver();
    FileSaverPlatform.instance = fileSaver;
  });

  tearDown(() {
    FilePickerPlatform.instance = originalPicker;
  });

  testWidgets('single selection preserves the readable platform XFile', (
    tester,
  ) async {
    final file = _MemoryPlatformFile('report.pdf', [1, 2, 3]);
    picker.singleResult = Future.value(file);
    List<XFile>? selected;
    await _pump(
      tester,
      FileInput(onFilesSelected: (files) => selected = files),
    );

    await tester.tap(find.byType(Button));
    await tester.pump();

    expect(picker.singleCalls, 1);
    expect(picker.multipleCalls, 0);
    expect(picker.type, FileType.any);
    expect(picker.allowedExtensions, isNull);
    expect(selected, hasLength(1));
    expect(selected!.single, same(file.xFile));
    expect(selected!.single.name, 'report.pdf');
    expect(await selected!.single.readAsBytes(), [1, 2, 3]);
  });

  testWidgets('multiple selection preserves order and extension filters', (
    tester,
  ) async {
    final first = _MemoryPlatformFile('first.pdf', [4, 5]);
    final second = _MemoryPlatformFile('second.png', [6]);
    picker.multipleResult = Future.value([first, second]);
    List<XFile>? selected;
    await _pump(
      tester,
      FileInput(
        multiple: true,
        accept: const [' .PDF ', 'image/png', 'image/*'],
        onFilesSelected: (files) => selected = files,
      ),
    );

    await tester.tap(find.byType(Button));
    await tester.pump();

    expect(picker.singleCalls, 0);
    expect(picker.multipleCalls, 1);
    expect(picker.type, FileType.custom);
    expect(picker.allowedExtensions, ['pdf', 'png']);
    expect(selected, [same(first.xFile), same(second.xFile)]);
    expect(await selected![0].readAsBytes(), [4, 5]);
    expect(await selected![1].readAsBytes(), [6]);
  });

  for (final multiple in [false, true]) {
    testWidgets('cancel leaves selection unchanged (multiple=$multiple)', (
      tester,
    ) async {
      var callbackCount = 0;
      await _pump(
        tester,
        FileInput(
          multiple: multiple,
          onFilesSelected: (_) => callbackCount++,
        ),
      );

      await tester.tap(find.byType(Button));
      await tester.pump();

      expect(picker.singleCalls + picker.multipleCalls, 1);
      expect(callbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposed input ignores late selection (multiple=$multiple)', (
      tester,
    ) async {
      final single = Completer<PlatformFile?>();
      final many = Completer<List<PlatformFile>>();
      picker
        ..singleResult = single.future
        ..multipleResult = many.future;
      var callbackCount = 0;
      await _pump(
        tester,
        FileInput(
          multiple: multiple,
          onFilesSelected: (_) => callbackCount++,
        ),
      );
      await tester.tap(find.byType(Button));
      expect(picker.singleCalls + picker.multipleCalls, 1);
      await tester.pumpWidget(const SizedBox.shrink());

      final file = _MemoryPlatformFile('late.txt', [7]);
      single.complete(file);
      many.complete([file]);
      await tester.pump();

      expect(callbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('disabled input does not open the picker', (tester) async {
    await _pump(tester, const FileInput(enabled: false));

    await tester.tap(find.byType(Button));
    await tester.pump();

    expect(picker.singleCalls, 0);
    expect(picker.multipleCalls, 0);
  });

  group('folder pick', () {
    testWidgets('the folder button is absent unless allowDirectory', (
      tester,
    ) async {
      await _pump(tester, FileInput(onFilesSelected: (_) {}));

      expect(find.text('Choose folder'), findsNothing);
      expect(find.byType(Button), findsOneWidget);
    });

    testWidgets('picks a folder and forwards its files', (tester) async {
      dirPicker
        ..pickResult = Future.value(
          dir_picker.IOPickedLocation(Uri.file('/tmp/docs')),
        )
        ..entries = [
          dir_picker.FileSystemEntry(
            name: 'report.pdf',
            relativePath: 'report.pdf',
            isDirectory: false,
            uri: Uri.file('/tmp/docs/report.pdf'),
          ),
          const dir_picker.FileSystemEntry(
            name: 'nested',
            relativePath: 'nested',
            isDirectory: true,
          ),
          dir_picker.FileSystemEntry(
            name: 'photo.png',
            relativePath: 'photo.png',
            isDirectory: false,
            uri: Uri.file('/tmp/docs/photo.png'),
          ),
        ];
      List<XFile>? selected;
      await _pump(
        tester,
        FileInput(
          allowDirectory: true,
          onFilesSelected: (files) => selected = files,
        ),
      );

      await tester.tap(find.text('Choose folder'));
      await tester.pumpAndSettle();

      expect(dirPicker.pickCalls, 1);
      expect(dirPicker.lastRecursive, isTrue);
      expect(selected, hasLength(2));
      expect(selected!.map((file) => file.name), [
        'report.pdf',
        'photo.png',
      ]);
    });

    testWidgets('a folder pick applies the accept filter', (tester) async {
      dirPicker
        ..pickResult = Future.value(
          dir_picker.IOPickedLocation(Uri.file('/tmp/docs')),
        )
        ..entries = [
          dir_picker.FileSystemEntry(
            name: 'report.pdf',
            relativePath: 'report.pdf',
            isDirectory: false,
            uri: Uri.file('/tmp/docs/report.pdf'),
          ),
          dir_picker.FileSystemEntry(
            name: 'photo.png',
            relativePath: 'photo.png',
            isDirectory: false,
            uri: Uri.file('/tmp/docs/photo.png'),
          ),
        ];
      List<XFile>? selected;
      await _pump(
        tester,
        FileInput(
          allowDirectory: true,
          accept: const ['.pdf'],
          onFilesSelected: (files) => selected = files,
        ),
      );

      await tester.tap(find.text('Choose folder'));
      await tester.pumpAndSettle();

      expect(selected, hasLength(1));
      expect(selected!.single.name, 'report.pdf');
    });

    testWidgets('a cancelled folder pick leaves the selection untouched', (
      tester,
    ) async {
      dirPicker.pickResult = Future.value();
      var callbackCount = 0;
      await _pump(
        tester,
        FileInput(
          allowDirectory: true,
          onFilesSelected: (_) => callbackCount++,
        ),
      );

      await tester.tap(find.text('Choose folder'));
      await tester.pumpAndSettle();

      expect(dirPicker.pickCalls, 1);
      expect(callbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a disabled input does not open the folder picker', (
      tester,
    ) async {
      await _pump(
        tester,
        FileInput(
          allowDirectory: true,
          enabled: false,
          onFilesSelected: (_) {},
        ),
      );

      await tester.tap(find.text('Choose folder'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(dirPicker.pickCalls, 0);
    });
  });

  group('file save', () {
    testWidgets('no save button for names the input never received', (
      tester,
    ) async {
      await _pump(
        tester,
        FileInput(
          allowSave: true,
          selectedFiles: const ['server.pdf'],
          onFilesSelected: (_) {},
        ),
      );

      expect(find.byType(Button), findsOneWidget);
    });

    testWidgets('a received file gains a save button that writes it out', (
      tester,
    ) async {
      picker.singleResult = Future.value(
        _MemoryPlatformFile('report.pdf', [1, 2, 3]),
      );
      await _pump(
        tester,
        FileInput(
          allowSave: true,
          selectedFiles: const ['report.pdf'],
          onFilesSelected: (_) {},
        ),
      );

      // Pick the file first — only then does the component hold its data.
      await tester.tap(find.byType(Button));
      await tester.pump();
      expect(find.byType(Button), findsNWidgets(2));

      await tester.tap(find.byType(Button).last);
      await tester.pumpAndSettle();

      expect(fileSaver.saved, ['report.pdf']);
    });

    // The save button draws at 16×16 so the glyph sits inside the file row
    // without inflating it. The pointer target reaches the WCAG floor
    // toward the file name — the axis the row has room for. Outward and
    // vertically the 20px file row ends where the button does and rejects
    // the point before the floor sees it (#5113); on Web the floor reaches
    // every side.
    testWidgets('the 16px save button reaches the floor toward the name', (
      tester,
    ) async {
      picker.singleResult = Future.value(
        _MemoryPlatformFile('report.pdf', [1, 2, 3]),
      );
      await _pump(
        tester,
        FileInput(
          allowSave: true,
          selectedFiles: const ['report.pdf'],
          onFilesSelected: (_) {},
        ),
      );
      await tester.tap(find.byType(Button));
      await tester.pump();
      final pickedBefore = picker.singleCalls;

      final save = find.byType(Button).last;
      expect(tester.getSize(save).width, lessThan(CoreTouchTarget.minimum));

      // Just inside half the floor from the centre, toward the name —
      // measured before the floor, the 16px button missed here and the
      // tap fell through to the drop zone.
      const reach = CoreTouchTarget.minimum / 2 - 1;
      await tester.tapAt(tester.getCenter(save) - const Offset(reach, 0));
      await tester.pumpAndSettle();

      expect(
        fileSaver.saved,
        ['report.pdf'],
        reason: 'a tap beside the 16px save button missed it',
      );
      expect(
        picker.singleCalls,
        pickedBefore,
        reason:
            'the miss fell through to the drop zone and opened the '
            'file picker',
      );
    });

    testWidgets('allowSave false never renders the save button', (
      tester,
    ) async {
      picker.singleResult = Future.value(
        _MemoryPlatformFile('report.pdf', [1, 2, 3]),
      );
      await _pump(
        tester,
        FileInput(
          selectedFiles: const ['report.pdf'],
          onFilesSelected: (_) {},
        ),
      );

      await tester.tap(find.byType(Button));
      await tester.pump();

      expect(find.byType(Button), findsOneWidget);
    });
  });

  group('file drop', () {
    testWidgets('forwards dropped files the accept list admits', (
      tester,
    ) async {
      List<XFile>? selected;
      await _pump(
        tester,
        FileInput(
          accept: const ['.pdf'],
          onFilesSelected: (files) => selected = files,
        ),
      );

      await _dragEnter(tester);
      await _dropPaths(tester, const ['/tmp/report.pdf', '/tmp/photo.png']);

      expect(selected, hasLength(1));
      expect(selected!.single.name, 'report.pdf');
    });

    testWidgets('forwards every dropped file when accept is unset', (
      tester,
    ) async {
      List<XFile>? selected;
      await _pump(
        tester,
        FileInput(onFilesSelected: (files) => selected = files),
      );

      await _dragEnter(tester);
      await _dropPaths(tester, const ['/tmp/report.pdf', '/tmp/photo.png']);

      expect(selected, hasLength(2));
      expect(selected!.map((file) => file.name), [
        'report.pdf',
        'photo.png',
      ]);
    });

    testWidgets('a drop that admits nothing leaves the selection untouched', (
      tester,
    ) async {
      var callbackCount = 0;
      await _pump(
        tester,
        FileInput(
          accept: const ['.pdf'],
          onFilesSelected: (_) => callbackCount++,
        ),
      );

      await _dragEnter(tester);
      await _dropPaths(tester, const ['/tmp/photo.png']);

      expect(callbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a disabled input ignores the drop', (tester) async {
      var callbackCount = 0;
      await _pump(
        tester,
        FileInput(
          enabled: false,
          onFilesSelected: (_) => callbackCount++,
        ),
      );

      await _dragEnter(tester);
      await _dropPaths(tester, const ['/tmp/report.pdf']);

      expect(callbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('drag enter raises the drag-active fill, hover does not', (
      tester,
    ) async {
      await _pump(tester, FileInput(onFilesSelected: (_) {}));

      Color? fill() {
        final container = tester.widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byType(FileInput),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );

        return (container.decoration as BoxDecoration?)?.color;
      }

      final idle = fill();

      // Hovering is not dragging — the zone keeps its idle fill until a
      // real drag enters (the hover-driven proxy this replaced lit up on
      // any pointer pass).
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
        location: tester.getCenter(find.byType(FileInput)),
      );
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(FileInput)));
      await tester.pump();
      expect(fill(), idle);

      await _dragEnter(tester);
      expect(fill(), isNot(idle));

      await _sendDropMessage(tester, 'exited');
      expect(fill(), idle);
    });

    testWidgets('the upload glyph wears primary only while a file is dragged '
        'over', (tester) async {
      await _pump(tester, FileInput(onFilesSelected: (_) {}));

      CoreColor? glyph() => tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byType(FileInput),
              matching: find.byType(Icon),
            ),
          )
          .first
          .iconStyle
          ?.color;

      expect(glyph(), CoreFileInputStyle.defaultSubtleIconColor);

      await _dragEnter(tester);
      expect(glyph(), CoreFileInputStyle.defaultDragActiveIconColor);
      expect(glyph(), const CoreColor.token(CoreColors.primary));

      await _sendDropMessage(tester, 'exited');
      expect(glyph(), CoreFileInputStyle.defaultSubtleIconColor);
    });

    testWidgets('a per-instance dragActiveIconColor replaces the drag tone', (
      tester,
    ) async {
      const custom = CoreColor.token(CoreColors.error);
      await _pump(
        tester,
        FileInput(
          onFilesSelected: (_) {},
          fileInputStyle: const CoreFileInputStyle(dragActiveIconColor: custom),
        ),
      );
      await _dragEnter(tester);
      final glyph = tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byType(FileInput),
              matching: find.byType(Icon),
            ),
          )
          .first
          .iconStyle
          ?.color;
      expect(glyph, custom);
    });
  });

  group('redesigned structure', () {
    testWidgets('48 round icon box, 12 / 4 / 16 stack, 32 x 24 padding', (
      tester,
    ) async {
      await _pump(
        tester,
        FileInput(
          onFilesSelected: (_) {},
          label: 'Drop here',
          hint: 'PNG up to 10 MB',
        ),
      );
      final context = tester.element(find.byType(FileInput));
      final resolved = resolveFileInput(context);
      final scaling = Theme.of(context).scaling;
      expect(resolved.padding.top, 32 * scaling);
      expect(resolved.padding.left, 24 * scaling);
      expect(resolved.iconBoxSize, 48 * scaling);
      expect(resolved.itemSpacing, 12 * scaling);
      expect(resolved.textSpacing, 4 * scaling);
      expect(resolved.actionSpacing, 16 * scaling);

      final box = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == resolved.iconBoxSize,
        ),
      );
      final title = tester.getRect(find.text('Drop here'));
      final hint = tester.getRect(find.text('PNG up to 10 MB'));
      final button = tester.getRect(find.byType(Button).first);
      expect(box.width, resolved.iconBoxSize);
      expect(title.top - box.bottom, closeTo(resolved.itemSpacing, 0.5));
      expect(hint.top - title.bottom, closeTo(resolved.textSpacing, 0.5));
      expect(button.top - hint.bottom, closeTo(resolved.actionSpacing, 0.5));
    });

    testWidgets('icon box fill follows drag state', (tester) async {
      late ResolvedFileInput resolved;
      await _pump(
        tester,
        Builder(
          builder: (c) {
            resolved = resolveFileInput(c);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(resolved.iconBoxColorIdle, isNot(resolved.iconBoxColorDragActive));
      expect(resolved.iconBoxBorderRadius.topLeft.x, greaterThan(1000));
    });
  });

  group('idle hover border', () {
    const outline = CoreColor.token(CoreColors.outlineVariant);
    const onSurface = CoreColor.token(CoreColors.onSurface);
    const primary = CoreColor.token(CoreColors.primary);

    Color resolvedToken(WidgetTester tester, CoreColor token) {
      final context = tester.element(find.byType(FileInput));
      return Theme.of(context).colorScheme.resolve(token).toValue();
    }

    /// The render object of the dashed edge — the painter that strokes the
    /// zone's border, found by what it is rather than by where it sits.
    RenderObject dashedEdge(WidgetTester tester) => tester.renderObject(
      find.descendant(
        of: find.byType(FileInput),
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_DashedBorderPainter',
        ),
      ),
    );

    /// What the dashed edge is painting right now, as a matcher over the
    /// recorded canvas — not the style that was requested.
    PaintPattern strokes(Color color) => paints..path(color: color);

    /// The edge as one unbroken rounded rect — the drag-over shape.
    PaintPattern strokesSolid(Color color) => paints..rrect(color: color);

    /// Connects a mouse *before* the zone mounts. The `Clickable` inside
    /// snapshots `FocusHighlightMode` in its first post-frame callback and
    /// a mouse event alone never re-triggers it, so a mouse connected late
    /// locks the zone into touch mode and it never reports a hover.
    Future<TestGesture> connectMouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      return gesture;
    }

    Future<void> hover(WidgetTester tester, TestGesture mouse) async {
      await mouse.moveTo(tester.getCenter(find.byType(FileInput)));
      await tester.pump();
    }

    testWidgets('resolver: idle hover is onSurface — not the drag-over '
        'primary, not the resting outlineVariant', (tester) async {
      late BuildContext context;
      late ResolvedFileInput resolved;
      await _pump(
        tester,
        Builder(
          builder: (c) {
            context = c;
            resolved = resolveFileInput(c);
            return const SizedBox.shrink();
          },
        ),
      );
      final scheme = Theme.of(context).colorScheme;

      expect(resolved.borderColorHover, scheme.resolve(onSurface).toValue());
      expect(resolved.borderColorIdle, scheme.resolve(outline).toValue());
      expect(resolved.borderColorDragOver, scheme.resolve(primary).toValue());
      expect(resolved.borderColorHover, isNot(resolved.borderColorIdle));
      expect(resolved.borderColorHover, isNot(resolved.borderColorDragOver));
    });

    testWidgets(
      'the edge rests on outlineVariant, steps to onSurface under the '
      'pointer and back when it leaves',
      (tester) async {
        final mouse = await connectMouse(tester);
        await _pump(tester, FileInput(onFilesSelected: (_) {}));
        final outlineColor = resolvedToken(tester, outline);
        final onSurfaceColor = resolvedToken(tester, onSurface);
        expect(onSurfaceColor, isNot(outlineColor));

        expect(dashedEdge(tester), strokes(outlineColor));

        await hover(tester, mouse);
        expect(dashedEdge(tester), strokes(onSurfaceColor));

        await mouse.moveTo(const Offset(1, 1));
        await tester.pump();
        expect(dashedEdge(tester), strokes(outlineColor));
      },
    );

    testWidgets('a per-instance hoverBorderColor replaces the hover tone', (
      tester,
    ) async {
      final mouse = await connectMouse(tester);
      await _pump(
        tester,
        FileInput(
          onFilesSelected: (_) {},
          fileInputStyle: const CoreFileInputStyle(
            hoverBorderColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
      );
      final tertiaryColor = resolvedToken(
        tester,
        const CoreColor.token(CoreColors.tertiary),
      );

      await hover(tester, mouse);
      expect(dashedEdge(tester), strokes(tertiaryColor));
    });

    testWidgets('a real drag keeps its primary edge under the pointer, and '
        'hover is back once the drag leaves', (tester) async {
      final mouse = await connectMouse(tester);
      await _pump(tester, FileInput(onFilesSelected: (_) {}));
      final onSurfaceColor = resolvedToken(tester, onSurface);
      final primaryColor = resolvedToken(tester, primary);

      await hover(tester, mouse);
      expect(dashedEdge(tester), strokes(onSurfaceColor));

      await _dragEnter(tester);
      expect(dashedEdge(tester), strokesSolid(primaryColor));

      await _sendDropMessage(tester, 'exited');
      expect(dashedEdge(tester), strokes(onSurfaceColor));
    });

    testWidgets('the edge is solid while a file is over the zone and dashed '
        'otherwise — colour and width unchanged', (tester) async {
      final mouse = await connectMouse(tester);
      await _pump(tester, FileInput(onFilesSelected: (_) {}));
      final primaryColor = resolvedToken(tester, primary);
      final width = resolveFileInput(
        tester.element(find.byType(FileInput)),
      ).borderWidth;

      /// What the edge painter alone draws — its children (the icon box,
      /// the button) paint rounded rects of their own.
      List<RecordedInvocation> edgeCalls() {
        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(FileInput),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_DashedBorderPainter',
            ),
          ),
        );
        final canvas = TestRecordingCanvas();
        paint.painter!.paint(canvas, const Size(320, 200));
        return canvas.invocations
            .where((i) => i.invocation.memberName != #save)
            .toList();
      }

      int count(Symbol member) =>
          edgeCalls().where((i) => i.invocation.memberName == member).length;

      // Idle and hovered: many dashes, no single rounded rect.
      expect(count(#drawRRect), 0);
      expect(count(#drawPath) + count(#drawLine), greaterThan(4));
      await hover(tester, mouse);
      expect(count(#drawRRect), 0);
      expect(count(#drawPath) + count(#drawLine), greaterThan(4));

      await _dragEnter(tester);
      final calls = edgeCalls();
      expect(calls, hasLength(1));
      expect(calls.single.invocation.memberName, #drawRRect);
      final stroke = calls.single.invocation.positionalArguments[1] as Paint;
      expect(stroke.color.toARGB32(), primaryColor.toARGB32());
      expect(stroke.strokeWidth, width);
      expect(stroke.style, PaintingStyle.stroke);

      await _sendDropMessage(tester, 'exited');
      expect(count(#drawRRect), 0);
      expect(count(#drawPath) + count(#drawLine), greaterThan(4));
    });

    testWidgets('a disabled zone has no hover step', (tester) async {
      final mouse = await connectMouse(tester);
      await _pump(
        tester,
        FileInput(enabled: false, onFilesSelected: (_) {}),
      );
      final disabledColor = resolvedToken(
        tester,
        CoreFileInputStyle.defaultDisabledBorderColor,
      );

      expect(dashedEdge(tester), strokes(disabledColor));
      await hover(tester, mouse);
      expect(dashedEdge(tester), strokes(disabledColor));
    });
  });

  group('disabled paint', () {
    Color resolved(WidgetTester tester, CoreColor token) {
      final context = tester.element(find.byType(FileInput));
      return Theme.of(context).colorScheme.resolve(token).toValue();
    }

    const container = CoreColor.token(CoreColors.disabledContainer);
    const content = CoreColor.token(CoreColors.disabledContent);

    Future<void> pumpDisabled(WidgetTester tester, {bool enabled = false}) =>
        _pump(
          tester,
          FileInput(
            enabled: enabled,
            hint: 'PNG up to 10 MB',
            selectedFiles: const ['report.pdf'],
            onFilesSelected: (_) {},
          ),
        );

    testWidgets('the zone and the icon box fill with disabledContainer, '
        'opaque and without an extra fade', (tester) async {
      await pumpDisabled(tester);
      final expected = resolved(tester, container);
      expect(expected.a, 1);

      final zone = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(FileInput),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect((zone.decoration! as BoxDecoration).color, expected);

      final boxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FileInput),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where(
            (b) =>
                b.decoration is BoxDecoration &&
                (b.decoration as BoxDecoration).color == expected,
          );
      expect(boxes, isNotEmpty);
      // No fade over the zone — the tokens already say disabled. (The
      // Button's own disabled fade is its concern, not the zone's tokens.)
      final fades = tester
          .widgetList<Opacity>(
            find.descendant(
              of: find.byType(FileInput),
              matching: find.byType(Opacity),
            ),
          )
          .where((o) => o.opacity < 1);
      expect(fades, isEmpty);
    });

    testWidgets('the hint is Regular under the Medium title (#5881)', (
      tester,
    ) async {
      await pumpDisabled(tester, enabled: true);
      final context = tester.element(find.byType(FileInput));
      TextStyle? styleOf(String text) =>
          tester.widget<Text>(find.text(text)).style;
      final hint = styleOf('PNG up to 10 MB')!;
      final title = styleOf(CoUILocalizations.of(context).fileInputDropLabel)!;
      expect(hint.fontWeight, FontWeight.w400);
      expect(hint.fontSize, CoreFontSize.s13);
      expect(title.fontWeight, FontWeight.w500);
      // Title on-surface, hint on-surface-subtle (#5881).
      expect(
        title.color,
        resolved(tester, const CoreColor.token(CoreColors.onSurface)),
      );
      expect(
        hint.color,
        resolved(tester, const CoreColor.token(CoreColors.onSurfaceSubtle)),
      );
    });

    testWidgets('label, hint, file name and both glyphs wear disabledContent', (
      tester,
    ) async {
      await pumpDisabled(tester);
      final expected = resolved(tester, content);
      final context = tester.element(find.byType(FileInput));

      Color? textColor(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;
      expect(
        textColor(CoUILocalizations.of(context).fileInputDropLabel),
        expected,
      );
      expect(textColor('PNG up to 10 MB'), expected);
      expect(textColor('report.pdf'), expected);

      final icons = tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byType(FileInput),
              matching: find.byType(Icon),
            ),
          )
          .where(
            (i) =>
                i.iconStyle?.color != null &&
                resolved(tester, i.iconStyle!.color!) == expected,
          );
      // The upload glyph and the file glyph.
      expect(icons.length, greaterThanOrEqualTo(2));
    });

    testWidgets('an enabled zone keeps its own tones', (tester) async {
      await pumpDisabled(tester, enabled: true);
      final disabledFill = resolved(tester, container);
      final zone = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(FileInput),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect((zone.decoration! as BoxDecoration).color, isNot(disabledFill));
    });

    testWidgets('a per-instance idle borderColor does not leak into the '
        'disabled edge', (tester) async {
      await _pump(
        tester,
        FileInput(
          enabled: false,
          onFilesSelected: (_) {},
          fileInputStyle: const CoreFileInputStyle(
            borderColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
      );
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(FileInput),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is CustomPaint &&
                    w.painter.runtimeType.toString() == '_DashedBorderPainter',
              ),
            ),
          )
          .painter!;
      expect(
        (painter as dynamic).color,
        resolved(
          tester,
          CoreFileInputStyle.defaultDisabledBorderColor,
        ),
      );
    });
  });
}

/// Delivers a `desktop_drop` platform message, as the OS would.
Future<void> _sendDropMessage(
  WidgetTester tester,
  String method, [
  Object? arguments,
]) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'desktop_drop',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        ),
        (_) {},
      );
  await tester.pump();
}

/// Simulates a drag entering the drop zone — the position must land inside
/// the zone or the plugin never raises its `enter` status.
Future<void> _dragEnter(WidgetTester tester) async {
  final center = tester.getCenter(find.byType(FileInput));
  await _sendDropMessage(tester, 'entered', [center.dx, center.dy]);
}

/// Simulates the drop of [paths] while a drag is over the zone.
Future<void> _dropPaths(WidgetTester tester, List<String> paths) =>
    _sendDropMessage(tester, 'performOperation', paths);

Future<void> _pump(WidgetTester tester, Widget input) => tester.pumpWidget(
  CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    home: Scaffold(child: Center(child: input)),
  ),
);

class _FakeFilePicker extends FilePickerPlatform {
  Future<PlatformFile?> singleResult = Future.value();
  Future<List<PlatformFile>> multipleResult = Future.value([]);
  int singleCalls = 0;
  int multipleCalls = 0;
  FileType? type;
  List<String>? allowedExtensions;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    singleCalls++;
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    return singleResult;
  }

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    multipleCalls++;
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    return multipleResult;
  }
}

final class _MemoryPlatformFile extends PlatformFile {
  _MemoryPlatformFile(this.name, List<int> bytes)
    : xFile = XFile.fromData(Uint8List.fromList(bytes), path: name, name: name);

  @override
  final String name;

  @override
  final XFile xFile;

  // No local path: conversion must also work for browser-backed files.
  @override
  Uri get uri => Uri.parse('blob:https://example.test/$name');

  @override
  int? lengthSync() => null;

  @override
  Future<int> length() => xFile.length();

  @override
  Future<Uint8List> readAsBytes() =>
      throw StateError('FileInput must not eagerly load picked files');

  @override
  Stream<Uint8List> readAsByteStream() =>
      throw StateError('FileInput must not eagerly load picked files');
}

class _FakeDirPicker extends dir_picker.DirPickerPlatform {
  Future<dir_picker.PickedLocation?> pickResult = Future.value();
  List<dir_picker.FileSystemEntry> entries = const [];
  int pickCalls = 0;
  bool? lastRecursive;

  @override
  Future<dir_picker.PickedLocation?> pick({
    dir_picker.PickOptions? options,
  }) {
    pickCalls++;

    return pickResult;
  }

  @override
  Future<List<dir_picker.FileSystemEntry>> listEntries(
    dir_picker.PickedLocation location, {
    bool recursive = false,
  }) {
    lastRecursive = recursive;

    return Future.value(entries);
  }
}

class _FakeFileSaver extends FileSaverPlatform {
  final saved = <String>[];

  @override
  Future<saver.PickedDirectoryLocation?> pickDirectory({
    bool shouldPersist = true,
  }) => Future.value(saver.PickedDirectoryLocation(uri: Uri.file('/tmp')));

  @override
  Stream<saver.SaveProgress> saveAs({
    required saver.SaveInput input,
    required saver.FileType fileType,
    required String fileName,
    required saver.PickedDirectoryLocation saveLocation,
    saver.ConflictResolution conflictResolution =
        saver.ConflictResolution.autoRename,
  }) async* {
    saved.add('$fileName.${fileType.ext}');
    yield saver.SaveProgressComplete(
      Uri.file('/tmp/$fileName.${fileType.ext}'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
