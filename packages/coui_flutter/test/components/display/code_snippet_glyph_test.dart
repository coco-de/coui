// The getter names and token names are the fixture data — naming each one
// would hide the pair the assertion is about.

/// The colour the copy glyph is drawn in, read off the mounted tree.
///
/// `defaultCopyIconStyle` states no colour, so the glyph takes the one the
/// plain `Button` hands its child: `onSurfaceVariant` at rest, `onSurface` on
/// hover and press, `disabledContent` when disabled. A colour stated on the
/// icon outranks that, which is what a solid role face relies on: the
/// resolver states the face's ink on the glyph
/// (`CoreCodeSnippetStyle.inkOnFace`), so it keeps that ink through hover.
///
/// The colour is read the way the screen draws it: the mounted `Icon` is
/// resolved in its own context (so the ambient `IconTheme` the button sets is
/// what it reads) and the result is compared with the colour filter the
/// `SvgPicture` underneath was actually built with.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

/// Faces whose glyph follows the button: the default face, the surface-tone
/// getters, and every other tone the role colours are certified on.
final _kFollowingFaces = <String, CodeSnippet>{
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

Future<void> _pump(
  WidgetTester tester,
  CoreThemeData core,
  Widget child,
) => pumpTestApp(tester, child, theme: ThemeData.fromCore(core));

ColorScheme _scheme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Icon))).colorScheme;

/// The colour the copy glyph is drawn in right now.
Color _glyph(WidgetTester tester) {
  final finder = find.byType(Icon);
  final element = tester.element(finder);
  final icon = element.widget as Icon;
  final color = resolveIcon(
    element,
    icon: icon.icon,
    data: null,
    widgetStyle: icon.iconStyle,
  ).color;
  final picture = tester.widget<SvgPicture>(
    find.descendant(of: finder, matching: find.byType(SvgPicture)),
  );
  expect(
    picture.colorFilter,
    ColorFilter.mode(color, BlendMode.srcIn),
    reason: 'the painted glyph carries the colour the Icon resolved',
  );
  return color;
}

/// The face the snippet paints, resolved against the mounted theme.
Color _face(WidgetTester tester, CoreCodeSnippetStyle? style) => _scheme(tester)
    .resolve(
      style?.backgroundColor ?? CoreCodeSnippetStyle.defaultBackgroundColor,
    )
    .toValue();

Color _slot(WidgetTester tester, CoreColorToken token) =>
    _scheme(tester).resolve(CoreColor.token(token)).toValue();

/// Connects a mouse *before* the snippet mounts.
///
/// `FocusableActionDetector` (inside the button's `Clickable`) snapshots
/// `FocusHighlightMode` in its first post-frame callback, and a pointer
/// connected afterwards never re-triggers that — the button would lock into
/// touch mode and never report hover for the rest of the test.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  return gesture;
}

void main() {
  group('copy glyph — follows the copy button on an admitted face', () {
    for (final MapEntry(key: faceName, value: snippet)
        in _kFollowingFaces.entries) {
      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets(
          '$faceName — onSurfaceVariant at rest, onSurface on hover and press, '
          'all 4.5:1 — $modeName',
          (tester) async {
            final mouse = await _mouse(tester);
            await _pump(tester, core, snippet);
            final face = _face(tester, snippet.codeSnippetStyle);

            final rest = _glyph(tester);
            expect(rest, _slot(tester, CoreColors.onSurfaceVariant));
            expect(_ratio(rest, face), greaterThanOrEqualTo(4.5));

            await mouse.moveTo(tester.getCenter(find.byType(Button)));
            await tester.pump(const Duration(milliseconds: 300));
            final hovered = _glyph(tester);
            expect(hovered, _slot(tester, CoreColors.onSurface));
            expect(hovered, isNot(rest), reason: 'hover changes the glyph');
            expect(_ratio(hovered, face), greaterThanOrEqualTo(4.5));

            await mouse.down(tester.getCenter(find.byType(Button)));
            await tester.pump(const Duration(milliseconds: 300));
            final pressed = _glyph(tester);
            expect(pressed, _slot(tester, CoreColors.onSurface));
            await mouse.up();
            await tester.pump(const Duration(milliseconds: 300));
          },
        );
      }
    }

    for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
      testWidgets(
        'a disabled copy button hands the glyph disabledContent — $modeName',
        (tester) async {
          // The shipped snippet never disables its button; this composes the
          // same button and icon from the resolved slots with no handler, to
          // read the state the glyph would take.
          late ResolvedCodeSnippet resolved;
          await _pump(
            tester,
            core,
            Builder(
              builder: (context) {
                resolved = resolveCodeSnippet(context);
                return Button(
                  variant: .plain,
                  buttonStyle: resolved.copyButtonStyle,
                  child: Icon(
                    LucideIcons.copy,
                    iconStyle: resolved.copyIconStyle,
                  ),
                );
              },
            ),
          );
          expect(_glyph(tester), _slot(tester, CoreColors.disabledContent));
        },
      );
    }
  });

  group('copy glyph — a solid face pins the glyph to its ink', () {
    for (final MapEntry(key: name, value: pair) in _kSolidFaces.entries) {
      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets(
          '.$name — the ink at rest, on hover and on press, 4.5:1 — $modeName',
          (tester) async {
            final snippet = pair.get(_kSnippet);
            final mouse = await _mouse(tester);
            await _pump(tester, core, snippet);
            final face = _face(tester, snippet.codeSnippetStyle);
            final ink = _slot(tester, pair.ink);

            final rest = _glyph(tester);
            expect(rest, ink);
            expect(_ratio(rest, face), greaterThanOrEqualTo(4.5));

            await mouse.moveTo(tester.getCenter(find.byType(Button)));
            await tester.pump(const Duration(milliseconds: 300));
            expect(_glyph(tester), ink, reason: 'hover keeps the ink');

            await mouse.down(tester.getCenter(find.byType(Button)));
            await tester.pump(const Duration(milliseconds: 300));
            expect(_glyph(tester), ink, reason: 'press keeps the ink');
            await mouse.up();
            await tester.pump(const Duration(milliseconds: 300));
          },
        );
      }
    }
  });

  group('copy glyph — the face the chain ends on decides', () {
    // A solid getter followed by a surface-tone getter leaves the glyph on
    // the button again; a tone followed by a solid one, or a solid face stated
    // without a getter, pins it to the face's ink.
    final ends = <String, ({CodeSnippet snippet, CoreColorToken? ink})>{
      '.primary.surface': (snippet: _kSnippet.primary.surface, ink: null),
      '.error.surfaceContainer': (
        snippet: _kSnippet.error.surfaceContainer,
        ink: null,
      ),
      '.outline.transparent': (
        snippet: _kSnippet.outline.transparent,
        ink: null,
      ),
      '.surface.primary': (
        snippet: _kSnippet.surface.primary,
        ink: CoreColors.onPrimary,
      ),
      '.success.warning': (
        snippet: _kSnippet.success.warning,
        ink: CoreColors.onWarning,
      ),
      'withStyle(backgroundColor: tertiary)': (
        snippet: _kSnippet.withStyle(
          const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
        ink: CoreColors.onTertiary,
      ),
    };
    for (final MapEntry(key: chain, value: end) in ends.entries) {
      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets(
          '$chain — ${end.ink == null ? 'the glyph follows the button, '
                    'hover changes it' : 'the glyph keeps the face ink '
                    'through hover'}, 4.5:1 — $modeName',
          (tester) async {
            final mouse = await _mouse(tester);
            await _pump(tester, core, end.snippet);
            final face = _face(tester, end.snippet.codeSnippetStyle);
            // `.transparent` shows the page; every other face here is a tone.
            final onFace =
                end.snippet.codeSnippetStyle!.backgroundColor ==
                    CoreColor.transparent
                ? _slot(tester, CoreColors.surface)
                : face;

            final rest = _glyph(tester);
            await mouse.moveTo(tester.getCenter(find.byType(Button)));
            await tester.pump(const Duration(milliseconds: 300));
            final hovered = _glyph(tester);

            if (end.ink == null) {
              expect(rest, _slot(tester, CoreColors.onSurfaceVariant));
              expect(hovered, _slot(tester, CoreColors.onSurface));
            } else {
              expect(rest, _slot(tester, end.ink!));
              expect(hovered, rest);
            }
            expect(_ratio(rest, onFace), greaterThanOrEqualTo(4.5));
            expect(_ratio(hovered, onFace), greaterThanOrEqualTo(4.5));
          },
        );
      }
    }
  });
}
