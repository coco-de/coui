// The getter names and token names are the fixture data — naming each one
// would hide the pair the assertion is about.

/// The colour the copy button's keyboard focus ring is drawn in, read off the
/// mounted tree.
///
/// The ring meets the face on both sides: it sits 2px off the button with a
/// transparent gap band, so the face shows inside it and around it. On a
/// container tone the system `focusRing` reads there. On a solid role face it
/// does not — 1.00:1 on `primary` and `tertiary`, under 3:1 on the rest — so
/// the resolver states the face's ink on the ring
/// (`CoreCodeSnippetStyle.inkOnFace`), the same ink the gutter and the glyph
/// take.
///
/// The ring is read the way the screen draws it: the copy button is focused
/// from the keyboard, and the colour and opacity come from the bordered box
/// the `FocusOutline` paints over the button.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kSnippet = CodeSnippet(code: 'x', mode: 'dart');

/// The four shipped schemes, with the theme data that carries each.
final _kModes = <String, CoreThemeData>{
  'Light': CoreThemePresets.light,
  'Dark': CoreThemePresets.dark,
  'HCLight': CoreThemePresets.highContrastLight,
  'HCDark': CoreThemePresets.highContrastDark,
};

/// The face token and the ink each solid-face getter states.
final _kSolidFaces =
    <String, ({CodeSnippet Function(CodeSnippet) get, CoreColorToken ink})>{
      'primary': (get: (s) => s.primary, ink: CoreColors.onPrimary),
      'secondary': (get: (s) => s.secondary, ink: CoreColors.onSecondary),
      'tertiary': (get: (s) => s.tertiary, ink: CoreColors.onTertiary),
      'error': (get: (s) => s.error, ink: CoreColors.onError),
      'success': (get: (s) => s.success, ink: CoreColors.onSuccess),
      'warning': (get: (s) => s.warning, ink: CoreColors.onWarning),
      'info': (get: (s) => s.info, ink: CoreColors.onInfo),
      'outline': (get: (s) => s.outline, ink: CoreColors.surface),
    };

/// Faces whose ring stays the system one: the default face, the surface-tone
/// getters, and every other tone the role colours are certified on.
final _kSystemRingFaces = <String, CodeSnippet>{
  'default face (surfaceContainerLow)': _kSnippet,
  '.surface': _kSnippet.surface,
  '.surfaceContainer': _kSnippet.surfaceContainer,
  for (final tone in CoreSyntaxFaces.tones)
    'tone ${tone.name}': _kSnippet.withStyle(
      CoreCodeSnippetStyle(backgroundColor: CoreColor.token(tone)),
    ),
};

double _ratio(Color a, Color b) =>
    CoreContrast.ratio(CoreColor(a.toARGB32()), CoreColor(b.toARGB32()));

ColorScheme _scheme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(CodeSnippet))).colorScheme;

Color _slot(WidgetTester tester, CoreColorToken token) =>
    _scheme(tester).resolve(CoreColor.token(token)).toValue();

/// The face the snippet paints, resolved against the mounted theme.
Color _face(WidgetTester tester, CoreCodeSnippetStyle? style) => _scheme(tester)
    .resolve(
      style?.backgroundColor ?? CoreCodeSnippetStyle.defaultBackgroundColor,
    )
    .toValue();

/// Mounts [snippet] under [core] and gives the copy button keyboard focus, so
/// the ring is the one a keyboard user sees.
///
/// The harness has no traversal shortcuts, so a Tab alone lands nowhere. The
/// node is focused directly while a Tab is held down: the key event is what
/// flips `FocusManager.highlightMode` to traditional, and
/// `FocusableActionDetector` shows the highlight only in that mode.
Future<void> _focusCopyButton(
  WidgetTester tester,
  CoreThemeData core,
  CodeSnippet snippet,
) async {
  await pumpTestApp(tester, snippet, theme: ThemeData.fromCore(core));
  await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
  final node =
      tester
            .widget<FocusableActionDetector>(
              find.descendant(
                of: find.byType(Button),
                matching: find.byType(FocusableActionDetector),
              ),
            )
            .focusNode!
        ..requestFocus();
  await tester.pump();
  await tester.pump();
  await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
  await tester.pump(const Duration(milliseconds: 400));
  expect(
    tester.binding.focusManager.primaryFocus,
    same(node),
    reason: 'the copy button holds focus',
  );
}

/// The ring the copy button's `FocusOutline` paints: its colour and the
/// opacity it is shown at.
({Color colour, double opacity}) _ring(WidgetTester tester) {
  final outline = find.descendant(
    of: find.byType(CodeSnippet),
    matching: find.byType(FocusOutline),
  );
  expect(outline, findsOneWidget, reason: 'the copy button is the one ring');
  final rings = [
    for (final fade in tester.widgetList<AnimatedOpacity>(
      find.descendant(of: outline, matching: find.byType(AnimatedOpacity)),
    ))
      if (fade.child case Container(
        decoration: BoxDecoration(border: Border(:final top)),
      ))
        (colour: top.color, opacity: fade.opacity),
  ];
  expect(rings, hasLength(1), reason: 'one bordered ring over the button');
  return rings.single;
}

void main() {
  group('copy button ring — a solid face rings it in its ink', () {
    for (final MapEntry(key: name, value: pair) in _kSolidFaces.entries) {
      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets('.$name — the ink, 3:1 on the face — $modeName', (
          tester,
        ) async {
          final snippet = pair.get(_kSnippet);
          await _focusCopyButton(tester, core, snippet);
          final ring = _ring(tester);
          final face = _face(tester, snippet.codeSnippetStyle);

          expect(ring.opacity, 1, reason: 'the copy button holds focus');
          expect(ring.colour, _slot(tester, pair.ink));
          expect(_ratio(ring.colour, face), greaterThanOrEqualTo(3));
          expect(
            _ratio(_slot(tester, CoreColors.focusRing), face),
            lessThan(3),
            reason: 'the system ring is what this replaces',
          );
        });
      }
    }
  });

  group('copy button ring — any other face keeps the system ring', () {
    for (final MapEntry(key: faceName, value: snippet)
        in _kSystemRingFaces.entries) {
      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets('$faceName — focusRing, 3:1 on the face — $modeName', (
          tester,
        ) async {
          await _focusCopyButton(tester, core, snippet);
          final ring = _ring(tester);

          expect(ring.opacity, 1, reason: 'the copy button holds focus');
          expect(ring.colour, _slot(tester, CoreColors.focusRing));
          expect(
            _ratio(ring.colour, _face(tester, snippet.codeSnippetStyle)),
            greaterThanOrEqualTo(3),
          );
        });
      }
    }
  });

  group('copy button ring — the face the chain ends on decides', () {
    final ends = <String, ({CodeSnippet snippet, CoreColorToken ring})>{
      '.primary.surface': (
        snippet: _kSnippet.primary.surface,
        ring: CoreColors.focusRing,
      ),
      '.outline.transparent': (
        snippet: _kSnippet.outline.transparent,
        ring: CoreColors.focusRing,
      ),
      '.surface.primary': (
        snippet: _kSnippet.surface.primary,
        ring: CoreColors.onPrimary,
      ),
      'withStyle(backgroundColor: tertiary)': (
        snippet: _kSnippet.withStyle(
          const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
        ring: CoreColors.onTertiary,
      ),
    };
    for (final MapEntry(key: chain, value: end) in ends.entries) {
      testWidgets('$chain — ${end.ring.name}', (tester) async {
        await _focusCopyButton(tester, CoreThemePresets.light, end.snippet);
        expect(_ring(tester).colour, _slot(tester, end.ring));
      });
    }
  });

  group('copy button ring — what the caller states wins', () {
    testWidgets('a stated ring colour replaces the ink', (tester) async {
      final snippet = _kSnippet.primary.withStyle(
        const CoreCodeSnippetStyle(
          copyButtonStyle: CoreButtonStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderColor: CoreColor.token(CoreColors.onError),
            ),
          ),
        ),
      );
      await _focusCopyButton(tester, CoreThemePresets.light, snippet);
      expect(_ring(tester).colour, _slot(tester, CoreColors.onError));
    });

    testWidgets('a stated ring width keeps the ink', (tester) async {
      final snippet = _kSnippet.primary.withStyle(
        const CoreCodeSnippetStyle(
          copyButtonStyle: CoreButtonStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderWidth: CoreStrokeWidth.stroke3,
            ),
          ),
        ),
      );
      await _focusCopyButton(tester, CoreThemePresets.light, snippet);
      expect(_ring(tester).colour, _slot(tester, CoreColors.onPrimary));
    });
  });
}
