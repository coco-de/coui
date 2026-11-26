import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const List<CoreShadowLayer> _hardOffset = [
  (
    offsetX: 4.0,
    offsetY: 4.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

const List<CoreShadowLayer> _dual = [
  (
    offsetX: -6.0,
    offsetY: -6.0,
    blurRadius: 12.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
  (
    offsetX: 6.0,
    offsetY: 6.0,
    blurRadius: 12.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

Future<List<BoxShadow>> _shadowOf(
  WidgetTester tester,
  CoreOutlinedContainerStyle style, {
  bool dark = false,
  ResolvedColorScheme? scheme,
}) async {
  late ResolvedOutlinedContainer resolved;

  // The scheme is stated outright: an app picks its brightness from the
  // platform, and a test that wants a dark pass has to say so.
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: ThemeData(
          colorScheme:
              scheme ??
              (dark
                  ? CoreThemePresets.darkColorScheme
                  : CoreThemePresets.lightColorScheme),
        ),
        child: Builder(
          builder: (context) {
            resolved = resolveOutlinedContainer(context, containerStyle: style);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  return resolved.boxShadow;
}

void main() {
  group('an explicit stack replaces the elevation preset', () {
    testWidgets('it wins when both are set', (tester) async {
      // Layering them would deliver a hard offset shadow with the preset's
      // soft ambient blur still underneath, so the look a caller asked for
      // would only ever be approximated.
      final shadow = await _shadowOf(
        tester,
        const CoreOutlinedContainerStyle(
          elevation: .strong,
          boxShadow: _hardOffset,
        ),
      );

      expect(shadow, hasLength(1));
      expect(shadow.single.blurRadius, 0);
      expect(shadow.single.offset, const Offset(4, 4));
    });

    testWidgets('elevation still applies on its own', (tester) async {
      final shadow = await _shadowOf(
        tester,
        const CoreOutlinedContainerStyle(elevation: .strong),
      );

      expect(shadow, isNotEmpty);
      expect(
        shadow.any((s) => s.blurRadius > 0),
        isTrue,
        reason: 'the preset stacks are soft ambient shadows',
      );
    });

    testWidgets('an empty stack means no shadow, not "fall back"', (
      tester,
    ) async {
      final shadow = await _shadowOf(
        tester,
        const CoreOutlinedContainerStyle(elevation: .strong, boxShadow: []),
      );

      expect(shadow, isEmpty);
    });
  });

  group('shadows the enum could not describe', () {
    testWidgets('a hard offset shadow keeps zero blur', (tester) async {
      final shadow = await _shadowOf(
        tester,
        const CoreOutlinedContainerStyle(boxShadow: _hardOffset),
      );

      expect(shadow.single.blurRadius, 0);
    });

    testWidgets('a dual stack keeps both directions', (tester) async {
      // Two layers going opposite ways is what makes a surface read as
      // raised from the page rather than floating above it.
      final shadow = await _shadowOf(
        tester,
        const CoreOutlinedContainerStyle(boxShadow: _dual),
      );

      expect(shadow, hasLength(2));
      expect(shadow.first.offset, const Offset(-6, -6));
      expect(shadow.last.offset, const Offset(6, 6));
    });
  });

  group('the shadow base colour', () {
    const pinned = CoreColor(0xFF000000);

    testWidgets('defaults to the palette slot, which follows the palette', (
      tester,
    ) async {
      // The control for the pinned cases below: CoUI states the same black
      // in both modes, so a palette whose slot says otherwise is what shows
      // the default reads the slot — were the two to resolve alike, "pinned"
      // would prove nothing.
      const style = CoreOutlinedContainerStyle(boxShadow: CoreShadow.xl);
      final tinted = CouiColorPresets.source
          .dark()
          .copyWith(shadow: const CoreColor(0xFFFF0000))
          .resolved(.dark);
      final plain = await _shadowOf(tester, style, dark: true);
      final retinted = await _shadowOf(tester, style, scheme: tinted);

      expect(
        plain.map((s) => s.color.withValues(alpha: 1)).toSet(),
        {const Color(0xFF000000)},
      );
      expect(
        retinted.map((s) => s.color.withValues(alpha: 1)).toSet(),
        {const Color(0xFFFF0000)},
      );
    });

    testWidgets('a raw colour pins the cast in both modes', (tester) async {
      const style = CoreOutlinedContainerStyle(
        boxShadow: CoreShadow.xl,
        shadowBaseColor: pinned,
      );
      final light = await _shadowOf(tester, style);
      final dark = await _shadowOf(tester, style, dark: true);

      expect(dark, equals(light));
      for (final shadow in light) {
        expect(shadow.color.withValues(alpha: 1), const Color(0xFF000000));
      }
      expect(
        light.map((s) => s.color.a),
        [
          for (final layer in CoreShadow.xl) closeTo(layer.opacity, 1 / 255),
        ],
      );
    });

    testWidgets('it tints the elevation preset the same way', (tester) async {
      const style = CoreOutlinedContainerStyle(
        elevation: .medium,
        shadowBaseColor: pinned,
      );
      final dark = await _shadowOf(tester, style, dark: true);

      expect(dark, isNotEmpty);
      for (final shadow in dark) {
        expect(shadow.color.withValues(alpha: 1), const Color(0xFF000000));
      }
    });
  });

  group('existing callers are unaffected', () {
    testWidgets('a style stating no shadow at all still gets none', (
      tester,
    ) async {
      final shadow = await _shadowOf(
        tester,
        const CoreOutlinedContainerStyle(),
      );
      expect(shadow, isEmpty);
    });
  });
}
