/// Web `Icon` colour emit — a raw colour reaches the glyph.
///
/// The glyph's colour used to be spelt `text-${color.toString()}`. For a
/// token that is a real Tailwind class; for a raw colour it is
/// `text-#FF0000`, which Tailwind does not read, so the caller's colour
/// vanished on Web while Flutter painted it. These tests pin both halves:
/// raw colours go inline, and token colours keep the exact class they had.
library;

import 'package:coui_web/coui_web.dart';
// icon_style.dart is not re-exported by the barrel — import it directly
// for chrome-level assertions.
import 'package:coui_web/src/components/icon/icon_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kRawRed = CoreColor(0xFFFF0000);

/// The rendered glyph elements, in tree order — every icon here is in
/// `CoreBundledIcons`, so each renders as an inline `<svg>`.
List<DomComponent> _glyphs() =>
    find.tag('svg').evaluate().map((e) => e.component as DomComponent).toList();

List<String> _classes(DomComponent glyph) =>
    (glyph.classes ?? '').split(' ').where((c) => c.isNotEmpty).toList();

String? _inlineColor(DomComponent glyph) => glyph.styles?.properties['color'];

void main() {
  group('emitColorOrInherit', () {
    test('null emits nothing — the glyph keeps currentColor', () {
      final emitted = emitColorOrInherit(null, ColorTarget.text);
      expect(emitted.className, isEmpty);
      expect(emitted.inline, isNull);
    });

    test('a raw colour goes inline, never onto a text-#hex class', () {
      final emitted = emitColorOrInherit(_kRawRed, ColorTarget.text);
      expect(emitted.className, isEmpty);
      expect(emitted.inline, {'color': _kRawRed.toValue()});
    });

    test('the transparent sentinel goes inline too', () {
      final emitted = emitColorOrInherit(
        CoreColor.transparent,
        ColorTarget.text,
      );
      expect(emitted.className, isEmpty);
      expect(emitted.inline, {'color': CoreColor.transparent.toValue()});
    });

    // Every opacity on the CoreOpacity scale, plus fully opaque. The old
    // spelling (`text-${toString()}`) rounds the percentage and
    // `tailwindColor` truncates it; they only part on values like 0.29 /
    // 0.57 / 0.58, none of which are on the scale. If a step is ever
    // added there this test is where it shows up.
    const scaleOpacities = [
      0.03, 0.05, 0.08, 0.1, 0.12, 0.15, 0.16, 0.2, 0.25, 0.3, 0.4, //
      0.5, 0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0,
    ];
    test('a token colour keeps the exact class the old spelling produced', () {
      for (final opacity in scaleOpacities) {
        final color = CoreColor.token(CoreColors.primary, opacity: opacity);
        final emitted = emitColorOrInherit(color, ColorTarget.text);
        expect(emitted.className, 'text-$color', reason: 'opacity $opacity');
        expect(emitted.inline, isNull, reason: 'opacity $opacity');
      }
    });
  });

  group('iconElementChrome', () {
    test('size always rides inline next to the colour', () {
      final chrome = iconElementChrome(size: 16, color: _kRawRed);
      final props = chrome.inlineStyles!.properties;
      expect(props['width'], '1.0rem');
      expect(props['height'], '1.0rem');
      expect(props['font-size'], '1.0rem');
      expect(props['color'], _kRawRed.toValue());
    });
  });

  group('Icon render (Web)', () {
    testComponents('a raw iconStyle colour is painted inline', (tester) async {
      pumpWithTheme(
        tester,
        const Icon(
          LucideIcons.heart,
          iconStyle: CoreIconStyle(color: _kRawRed),
        ),
      );

      final glyph = _glyphs().single;
      expect(_classes(glyph).where((c) => c.startsWith('text-#')), isEmpty);
      expect(_inlineColor(glyph), _kRawRed.toValue());
    });

    testComponents('a token iconStyle colour stays a class', (tester) async {
      pumpWithTheme(
        tester,
        const Icon(
          LucideIcons.heart,
          iconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      );

      final glyph = _glyphs().single;
      expect(_classes(glyph), contains('text-primary'));
      expect(_inlineColor(glyph), isNull);
    });

    testComponents('no colour anywhere leaves the glyph on currentColor', (
      tester,
    ) async {
      pumpWithTheme(tester, const Icon(LucideIcons.heart));

      final glyph = _glyphs().single;
      expect(_classes(glyph).where((c) => c.startsWith('text-')), isEmpty);
      expect(_inlineColor(glyph), isNull);
    });

    testComponents('a raw ambient IconTheme colour reaches the glyph', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const IconTheme(
          data: IconThemeData(color: _kRawRed),
          child: Icon(LucideIcons.heart),
        ),
      );

      expect(_inlineColor(_glyphs().single), _kRawRed.toValue());
    });

    testComponents('a raw NavigationBar iconStyle colour reaches the glyph', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          navigationBarStyle: CoreNavigationBarStyle(
            iconStyle: CoreIconStyle(color: _kRawRed),
          ),
          items: [
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.house),
              label: 'Home',
            ),
          ],
        ),
      );

      final glyph = _glyphs().single;
      expect(_classes(glyph).where((c) => c.startsWith('text-#')), isEmpty);
      expect(_inlineColor(glyph), _kRawRed.toValue());
    });

    testComponents('a raw Button leading-slot colour reaches the glyph', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(
          onPressed: () {},
          buttonStyle: const CoreButtonStyle(
            leadingIconStyle: CoreIconStyle(color: _kRawRed),
          ),
          leading: const Icon(LucideIcons.plus),
          child: const Text('Add'),
        ),
      );

      final glyph = _glyphs().single;
      expect(_classes(glyph).where((c) => c.startsWith('text-#')), isEmpty);
      expect(_inlineColor(glyph), _kRawRed.toValue());
    });
  });
}
