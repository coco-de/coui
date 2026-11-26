// The getter names and token names are the fixture data — naming each one
// would hide the pair the assertion is about.

/// The colour the copy button's keyboard focus ring is drawn in, read off the
/// rendered markup.
///
/// The ring meets the face on both sides: it sits 2px off the button with a
/// transparent gap, so the face shows inside it and around it. On a container
/// tone the system `focusRing` reads there. On a solid role face it does not —
/// 1.00:1 on `primary` and `tertiary`, under 3:1 on the rest — so the
/// resolver states the face's ink on the ring
/// (`CoreCodeSnippetStyle.inkOnFace`), the same ink the gutter and the glyph
/// take.
///
/// No browser runs here, so the ring is read from the class the `<button>`
/// carries for it — `focus-visible:outline-<token>` — and the token is
/// resolved against the scheme of the mode.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kSnippet = CodeSnippet(code: 'x', mode: 'dart');

/// The four shipped schemes `--coui-*` holds in each mode.
final _kModes = <String, CoreColorScheme>{
  'Light': CouiColorPresets.source.light().resolved(.light),
  'Dark': CouiColorPresets.source.dark().resolved(.dark),
  'HCLight': CouiColorPresets.source.highContrastLight().resolved(.light),
  'HCDark': CouiColorPresets.source.highContrastDark().resolved(.dark),
};

/// The face token and the ink each solid-face getter states.
final _kSolidFaces =
    <
      String,
      ({
        CodeSnippet Function(CodeSnippet) get,
        CoreColorToken face,
        CoreColorToken ink,
      })
    >{
      'primary': (
        get: (snippet) => snippet.primary,
        face: CoreColors.primary,
        ink: CoreColors.onPrimary,
      ),
      'secondary': (
        get: (snippet) => snippet.secondary,
        face: CoreColors.secondary,
        ink: CoreColors.onSecondary,
      ),
      'tertiary': (
        get: (snippet) => snippet.tertiary,
        face: CoreColors.tertiary,
        ink: CoreColors.onTertiary,
      ),
      'error': (
        get: (snippet) => snippet.error,
        face: CoreColors.error,
        ink: CoreColors.onError,
      ),
      'success': (
        get: (snippet) => snippet.success,
        face: CoreColors.success,
        ink: CoreColors.onSuccess,
      ),
      'warning': (
        get: (snippet) => snippet.warning,
        face: CoreColors.warning,
        ink: CoreColors.onWarning,
      ),
      'info': (
        get: (snippet) => snippet.info,
        face: CoreColors.info,
        ink: CoreColors.onInfo,
      ),
      'outline': (
        get: (snippet) => snippet.outline,
        face: CoreColors.outline,
        ink: CoreColors.surface,
      ),
    };

/// Faces whose ring stays the system one: the default face, the surface-tone
/// getters, and every other tone the role colours are certified on.
final _kSystemRingFaces =
    <String, ({CodeSnippet snippet, CoreColorToken face})>{
      'default face (surfaceContainerLow)': (
        snippet: _kSnippet,
        face: CoreColors.surfaceContainerLow,
      ),
      '.surface': (snippet: _kSnippet.surface, face: CoreColors.surface),
      '.surfaceContainer': (
        snippet: _kSnippet.surfaceContainer,
        face: CoreColors.surfaceContainer,
      ),
      for (final tone in CoreSyntaxFaces.tones)
        'tone ${tone.name}': (
          snippet: _kSnippet.withStyle(
            CoreCodeSnippetStyle(backgroundColor: CoreColor.token(tone)),
          ),
          face: tone,
        ),
    };

/// Every token a ring can end up in, by the CSS name the class carries.
final Map<String, CoreColorToken> _kTokensByName = {
  for (final token in <CoreColorToken>[
    CoreColors.focusRing,
    CoreColors.onPrimary,
    CoreColors.onSecondary,
    CoreColors.onTertiary,
    CoreColors.onError,
    CoreColors.onSuccess,
    CoreColors.onWarning,
    CoreColors.onInfo,
    CoreColors.surface,
  ])
    token.name: token,
};

/// The token the copy `<button>`'s ring colour class names.
CoreColorToken _ring(ComponentTester tester) {
  const prefix = 'focus-visible:outline-';
  final classes =
      (find.tag('button').evaluate().single.component as DomComponent).classes!;
  final tokens = [
    for (final name in classes.split(' '))
      if (name.startsWith(prefix) &&
          _kTokensByName[name.substring(prefix.length)] != null)
        _kTokensByName[name.substring(prefix.length)]!,
  ];
  expect(tokens, hasLength(1), reason: 'one ring colour class in $classes');
  return tokens.single;
}

void _pump(ComponentTester tester, CodeSnippet snippet) =>
    pumpWithTheme(tester, snippet);

void main() {
  group('copy button ring — a solid face rings it in its ink', () {
    for (final MapEntry(key: name, value: pair) in _kSolidFaces.entries) {
      testComponents('.$name — the ring class names the ink', (tester) async {
        _pump(tester, pair.get(_kSnippet));
        expect(_ring(tester), pair.ink);
      });

      for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
        testComponents('.$name — the ink reads 3:1 on the face, the system '
            'ring would not — $modeName', (tester) async {
          _pump(tester, pair.get(_kSnippet));
          final face = pair.face.read(scheme)!;
          expect(
            CoreContrast.ratio(_ring(tester).read(scheme)!, face),
            greaterThanOrEqualTo(3),
          );
          expect(
            CoreContrast.ratio(CoreColors.focusRing.read(scheme)!, face),
            lessThan(3),
            reason: 'the system ring is what this replaces',
          );
        });
      }
    }
  });

  group('copy button ring — any other face keeps the system ring', () {
    for (final MapEntry(key: faceName, value: face)
        in _kSystemRingFaces.entries) {
      testComponents('$faceName — focusRing, 3:1 on the face in every mode', (
        tester,
      ) async {
        _pump(tester, face.snippet);
        final ring = _ring(tester);
        expect(ring, CoreColors.focusRing);
        for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
          expect(
            CoreContrast.ratio(ring.read(scheme)!, face.face.read(scheme)!),
            greaterThanOrEqualTo(3),
            reason: modeName,
          );
        }
      });
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
      testComponents('$chain — ${end.ring.name}', (tester) async {
        _pump(tester, end.snippet);
        expect(_ring(tester), end.ring);
      });
    }
  });

  testComponents('a ring colour the caller states replaces the ink', (
    tester,
  ) async {
    _pump(
      tester,
      _kSnippet.primary.withStyle(
        const CoreCodeSnippetStyle(
          copyButtonStyle: CoreButtonStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderColor: CoreColor.token(CoreColors.onError),
            ),
          ),
        ),
      ),
    );
    expect(_ring(tester), CoreColors.onError);
  });
}
