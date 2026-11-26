import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// A glyph with more than one stroke (`house` is two paths) takes ONE colour
/// from the button, on every stroke, in every state.
///
/// The button hands the glyph its colour through the ambient icon theme and
/// the icon paints the whole picture under a single colour filter — so there
/// is no per-stroke colour to land on only the first mark. These tests read
/// both halves back from the tree: the glyph really has several strokes, and
/// the one filter over them is the state's foreground.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required bool enabled,
    CoreButtonVariant variant = .primary,
  }) async {
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: Center(
          child: Button(
            variant: variant,
            onPressed: enabled ? () {} : null,
            leading: const Icon(LucideIcons.house),
            child: const Text('Add'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SvgPicture glyph(WidgetTester tester) => tester.widget<SvgPicture>(
    find.descendant(
      of: find.byType(Button),
      matching: find.byType(SvgPicture),
    ),
  );

  Future<String> source(WidgetTester tester) async {
    final loader = glyph(tester).bytesLoader as SvgStringLoader;

    return loader.provideSvg(null);
  }

  int strokes(String svg) => RegExp('<path').allMatches(svg).length;

  testWidgets('the glyph under test really has more than one stroke', (
    tester,
  ) async {
    await pumpButton(tester, enabled: true);

    expect(strokes(await source(tester)), greaterThan(1));
  });

  for (final enabled in [true, false]) {
    testWidgets(
      '${enabled ? 'enabled' : 'disabled'}: one filter paints every stroke',
      (tester) async {
        await pumpButton(tester, enabled: enabled);
        final picture = glyph(tester);
        final svg = await source(tester);

        // No stroke states its own colour — a per-stroke colour is the only
        // thing that could leave one mark behind the others.
        expect(RegExp('stroke="(?!currentColor|none)').hasMatch(svg), isFalse);
        expect(picture.colorFilter, isNotNull);
        expect(strokes(svg), greaterThan(1));
      },
    );
  }

  testWidgets('hover and pressed keep the single filter on every stroke', (
    tester,
  ) async {
    await pumpButton(tester, enabled: true);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.moveTo(tester.getCenter(find.byType(Button)));
    await tester.pumpAndSettle();
    expect(glyph(tester).colorFilter, isNotNull);
    expect(strokes(await source(tester)), greaterThan(1));

    await mouse.down(tester.getCenter(find.byType(Button)));
    await tester.pump();
    expect(glyph(tester).colorFilter, isNotNull);
    expect(strokes(await source(tester)), greaterThan(1));
    await mouse.up();
  });

  testWidgets('the filter colour is the state foreground', (tester) async {
    await pumpButton(tester, enabled: true);
    final rest = glyph(tester).colorFilter.toString();
    await pumpButton(tester, enabled: false);
    final disabled = glyph(tester).colorFilter.toString();

    expect(disabled, isNot(rest));
  });
}
